import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/product.dart';
import '../domain/category.dart';
import '../domain/brand.dart';
import '../data/seed_data.dart';
import '../data/supabase_product_repository.dart';
import '../data/supabase_category_repository.dart';
import '../data/supabase_brand_repository.dart';
import '../../auth/domain/user_role.dart';
import '../../approvals/presentation/approvals_providers.dart';
import '../../approvals/domain/pending_change.dart';
import '../../approvals/domain/activity_log.dart';
import '../../../core/theme/app_colors.dart';

final productRepositoryProvider = Provider<SupabaseProductRepository>((ref) {
  final repo = SupabaseProductRepository();
  ref.onDispose(() => repo.dispose());
  return repo;
});

final categoryRepositoryProvider = Provider<SupabaseCategoryRepository>((ref) {
  final repo = SupabaseCategoryRepository();
  ref.onDispose(() => repo.dispose());
  return repo;
});

final brandRepositoryProvider = Provider<SupabaseBrandRepository>((ref) {
  final repo = SupabaseBrandRepository();
  ref.onDispose(() => repo.dispose());
  return repo;
});

class BrandNotifier extends StateNotifier<List<Brand>> {
  final SupabaseBrandRepository _repo;
  StreamSubscription<List<Brand>>? _sub;

  BrandNotifier(this._repo) : super(_repo.currentBrands) {
    _sub = _repo.watchBrands().listen((brands) => state = brands);
  }

  List<Brand> brandsForCategory(String categoryId) =>
      state.where((b) => b.categoryId == categoryId).toList();

  Future<Brand> addBrand(String name, String categoryId) async {
    final count = state.where((b) => b.categoryId == categoryId).length;
    final brand = Brand(id: '', name: name.trim(), categoryId: categoryId, sortOrder: count);
    return _repo.saveBrand(brand);
  }

  Future<void> deleteBrand(String brandId) => _repo.deleteBrand(brandId);

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final brandsProvider = StateNotifierProvider<BrandNotifier, List<Brand>>((ref) {
  return BrandNotifier(ref.watch(brandRepositoryProvider));
});

class CatalogState {
  final List<Product> products;
  final List<Category> categories;
  final String searchQuery;
  final String selectedCategoryId;

  const CatalogState({
    required this.products,
    required this.categories,
    this.searchQuery = '',
    this.selectedCategoryId = 'all',
  });

  CatalogState copyWith({
    List<Product>? products,
    List<Category>? categories,
    String? searchQuery,
    String? selectedCategoryId,
  }) {
    return CatalogState(
      products: products ?? this.products,
      categories: categories ?? this.categories,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
    );
  }
}

class CatalogNotifier extends StateNotifier<CatalogState> {
  final Ref _ref;
  final SupabaseProductRepository _productRepo;
  final SupabaseCategoryRepository _categoryRepo;
  StreamSubscription<List<Product>>? _prodSub;
  StreamSubscription<List<Category>>? _catSub;

  CatalogNotifier(this._ref, this._productRepo, this._categoryRepo)
      : super(CatalogState(
          products: _productRepo.currentProducts,
          categories: _normalizeCategories(_categoryRepo.currentCategories),
        )) {
    _listenToStreams();
  }

  static List<Category> _normalizeCategories(List<Category> cats) {
    if (cats.isEmpty) {
      return SeedData.defaultCategories;
    }
    // Ensure 'all' is always at the top
    final hasAll = cats.any((c) => c.id == 'all');
    if (!hasAll) {
      return [
        const Category(
          id: 'all',
          name: 'All',
          icon: CupertinoIcons.square_grid_2x2_fill,
          productCount: 0,
          sortOrder: 0,
        ),
        ...cats,
      ];
    }
    return cats;
  }

  void _listenToStreams() {
    _prodSub = _productRepo.watchProducts().listen((prods) {
      state = state.copyWith(products: prods);
      _recalculateCategoryCounts();
    });

    _catSub = _categoryRepo.watchCategories().listen((cats) {
      final normalized = _normalizeCategories(cats);
      state = state.copyWith(categories: normalized);
      _recalculateCategoryCounts();
    });
  }

  void _recalculateCategoryCounts() {
    final updated = state.categories.map((cat) {
      if (cat.id == 'all') {
        return cat.copyWith(productCount: state.products.length);
      }
      final count = state.products.where((p) => p.categoryId == cat.id).length;
      return cat.copyWith(productCount: count);
    }).toList();

    state = state.copyWith(categories: updated);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void selectCategory(String categoryId) {
    state = state.copyWith(selectedCategoryId: categoryId);
  }

  Product? getProductById(String id) {
    try {
      return state.products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<bool> saveProduct({
    required Product product,
    required UserRole role,
  }) async {
    final isNew = !state.products.any((p) => p.id == product.id);

    if (role == UserRole.admin) {
      final toSave = product.copyWith(
        status: 'live',
        updatedAt: DateTime.now(),
        updatedBy: 'admin',
      );
      await _productRepo.saveProduct(toSave);

      _ref.read(approvalsNotifierProvider.notifier).addActivity(
            ActivityLog(
              id: 'act_${DateTime.now().millisecondsSinceEpoch}',
              title: isNew ? 'Product added' : 'Product updated',
              description: '${product.name} • SP ₹${product.sellingPrice.toStringAsFixed(0)}',
              actorRole: 'admin',
              type: isNew ? 'product_added' : 'price_update',
              icon: isNew ? CupertinoIcons.plus_circle_fill : CupertinoIcons.tag_fill,
              iconColor: AppColors.primary,
              timestamp: DateTime.now(),
            ),
          );

      return true;
    } else {
      // Shopkeeper queues for Admin approval
      final existing = isNew ? null : getProductById(product.id);
      final List<FieldDiff> diffs = [];

      if (isNew) {
        diffs.add(FieldDiff(
          fieldName: 'name',
          label: 'New Product',
          oldValue: 'None',
          newValue: product.name,
          formatType: 'text',
        ));
        diffs.add(FieldDiff(
          fieldName: 'sellingPrice',
          label: 'Selling Price',
          oldValue: 0.0,
          newValue: product.sellingPrice,
          formatType: 'currency',
        ));
      } else if (existing != null) {
        if (existing.name != product.name) {
          diffs.add(FieldDiff(
            fieldName: 'name',
            label: 'Product Name',
            oldValue: existing.name,
            newValue: product.name,
            formatType: 'text',
          ));
        }
        if (existing.costPrice != product.costPrice) {
          diffs.add(FieldDiff(
            fieldName: 'costPrice',
            label: 'Cost Price',
            oldValue: existing.costPrice,
            newValue: product.costPrice,
            formatType: 'currency',
          ));
        }
        if (existing.mrp != product.mrp) {
          diffs.add(FieldDiff(
            fieldName: 'mrp',
            label: 'MRP',
            oldValue: existing.mrp,
            newValue: product.mrp,
            formatType: 'currency',
          ));
        }
        if (existing.marginPercent != product.marginPercent) {
          diffs.add(FieldDiff(
            fieldName: 'marginPercent',
            label: 'Margin %',
            oldValue: existing.marginPercent,
            newValue: product.marginPercent,
            formatType: 'percent',
          ));
        }
        if (existing.sellingPrice != product.sellingPrice) {
          diffs.add(FieldDiff(
            fieldName: 'sellingPrice',
            label: 'Selling Price',
            oldValue: existing.sellingPrice,
            newValue: product.sellingPrice,
            formatType: 'currency',
          ));
        }
        if (existing.alZaraDiscountPercent != product.alZaraDiscountPercent) {
          diffs.add(FieldDiff(
            fieldName: 'alZaraDiscountPercent',
            label: 'Al Zara Discount %',
            oldValue: existing.alZaraDiscountPercent,
            newValue: product.alZaraDiscountPercent,
            formatType: 'percent',
          ));
        }
        if (existing.alZaraDiscountPrice != product.alZaraDiscountPrice) {
          diffs.add(FieldDiff(
            fieldName: 'alZaraDiscountPrice',
            label: 'Al Zara Discount Price',
            oldValue: existing.alZaraDiscountPrice,
            newValue: product.alZaraDiscountPrice,
            formatType: 'currency',
          ));
        }
      }

      if (diffs.isEmpty) {
        diffs.add(const FieldDiff(
          fieldName: 'details',
          label: 'Product Details',
          oldValue: 'Current details',
          newValue: 'Proposed update',
          formatType: 'text',
        ));
      }

      final pending = PendingChange(
        id: 'pen_${DateTime.now().microsecondsSinceEpoch}_${product.id}',
        productId: isNew ? null : product.id,
        productName: product.name,
        categoryName: product.categoryName,
        productIcon: product.icon,
        type: isNew ? 'new_product' : 'edit',
        diffs: diffs,
        proposedProduct: product.copyWith(updatedBy: 'shopkeeper'),
        submittedBy: 'shopkeeper',
        submittedAt: DateTime.now(),
        status: 'pending',
      );

      await _ref.read(approvalsNotifierProvider.notifier).queuePendingChange(pending);
      return true;
    }
  }

  Future<void> deleteProduct(String productId) async {
    final prod = getProductById(productId);
    final name = prod?.name ?? 'Product';
    await _productRepo.deleteProduct(productId);

    _ref.read(approvalsNotifierProvider.notifier).addActivity(
      ActivityLog(
        id: 'act_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Product deleted',
        description: '$name was removed from catalog',
        actorRole: 'admin',
        type: 'product_deleted',
        icon: CupertinoIcons.trash_fill,
        iconColor: AppColors.red,
        timestamp: DateTime.now(),
      ),
    );
  }

  Future<void> addCategory(String name, {IconData icon = Icons.category_rounded}) async {
    final catId = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
    final newCat = Category(
      id: catId,
      name: name,
      icon: icon,
      sortOrder: state.categories.length,
    );
    await _categoryRepo.saveCategory(newCat);

    _ref.read(approvalsNotifierProvider.notifier).addActivity(
      ActivityLog(
        id: 'act_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Category added',
        description: 'Category "$name" created',
        actorRole: 'admin',
        type: 'category_added',
        icon: CupertinoIcons.folder_badge_plus,
        iconColor: AppColors.primary,
        timestamp: DateTime.now(),
      ),
    );
  }

  Future<void> deleteCategory(String categoryId) async {
    if (categoryId == 'all' || categoryId == 'general') return;

    final catName = state.categories.firstWhere(
      (c) => c.id == categoryId,
      orElse: () => Category(id: categoryId, name: categoryId, icon: Icons.folder, productCount: 0, sortOrder: 0),
    ).name;

    // Delete category
    await _categoryRepo.deleteCategory(categoryId);

    // If active category was deleted, reset to 'all'
    if (state.selectedCategoryId == categoryId) {
      state = state.copyWith(selectedCategoryId: 'all');
    }

    // Reassign any products in this category to 'general'
    for (final p in state.products.where((p) => p.categoryId == categoryId)) {
      await _productRepo.saveProduct(p.copyWith(
        categoryId: 'general',
        categoryName: 'General',
      ));
    }

    _ref.read(approvalsNotifierProvider.notifier).addActivity(
      ActivityLog(
        id: 'act_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Category deleted',
        description: 'Category "$catName" deleted (items moved to General)',
        actorRole: 'admin',
        type: 'category_deleted',
        icon: CupertinoIcons.trash_fill,
        iconColor: AppColors.red,
        timestamp: DateTime.now(),
      ),
    );
  }

  Future<void> applyApprovedProduct(Product proposed, {bool isNew = false, String? existingId}) async {
    final toSave = proposed.copyWith(
      id: existingId ?? proposed.id,
      status: 'live',
      updatedAt: DateTime.now(),
      updatedBy: 'admin',
    );
    await _productRepo.saveProduct(toSave);
  }

  @override
  void dispose() {
    _prodSub?.cancel();
    _catSub?.cancel();
    super.dispose();
  }
}

final catalogNotifierProvider = StateNotifierProvider<CatalogNotifier, CatalogState>((ref) {
  final productRepo = ref.watch(productRepositoryProvider);
  final catRepo = ref.watch(categoryRepositoryProvider);
  return CatalogNotifier(ref, productRepo, catRepo);
});

final productsListProvider = Provider<List<Product>>((ref) {
  return ref.watch(catalogNotifierProvider).products;
});

final categoriesProvider = Provider<List<Category>>((ref) {
  return ref.watch(catalogNotifierProvider).categories;
});

final filteredProductsProvider = Provider<List<Product>>((ref) {
  final catalog = ref.watch(catalogNotifierProvider);
  final products = catalog.products;
  final query = catalog.searchQuery.toLowerCase();
  final categoryId = catalog.selectedCategoryId;

  return products.where((p) {
    if (query.isNotEmpty) {
      final matchName = p.name.toLowerCase().contains(query);
      final matchBrand = p.brandName.toLowerCase().contains(query);
      final matchCategory = p.categoryName.toLowerCase().contains(query);
      if (!matchName && !matchBrand && !matchCategory) return false;
    }

    if (categoryId != 'all' && p.categoryId != categoryId) {
      return false;
    }

    return true;
  }).toList();
});
