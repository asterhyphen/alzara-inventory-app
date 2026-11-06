import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/al_zara_pill.dart';
import 'product_providers.dart';
import 'widgets/brand_grouped_product_list.dart';
import 'widgets/quick_price_edit_sheet.dart';
import 'product_detail_screen.dart';

class SearchBrowseScreen extends ConsumerStatefulWidget {
  final String? initialCategoryId;

  const SearchBrowseScreen({super.key, this.initialCategoryId});

  @override
  ConsumerState<SearchBrowseScreen> createState() => _SearchBrowseScreenState();
}

class _SearchBrowseScreenState extends ConsumerState<SearchBrowseScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialCategoryId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(catalogNotifierProvider.notifier).selectCategory(widget.initialCategoryId!);
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(catalogNotifierProvider);
    final results = ref.watch(filteredProductsProvider);
    final categories = catalog.categories;

    final activeCategoryName = catalog.selectedCategoryId == 'all'
        ? 'All Products'
        : categories.firstWhere((c) => c.id == catalog.selectedCategoryId, orElse: () => categories.first).name;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Sticky Search & Category Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              decoration: BoxDecoration(
                color: AppColors.background,
                border: Border(bottom: BorderSide(color: AppColors.borderGold.withValues(alpha: 0.2), width: 1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search Bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.borderGold.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(CupertinoIcons.search, size: 18, color: AppColors.primaryLight),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: (val) {
                              ref.read(catalogNotifierProvider.notifier).setSearchQuery(val);
                            },
                            style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
                            decoration: InputDecoration(
                              hintText: 'Search products, brands, categories...',
                              hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              filled: false,
                              contentPadding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                        if (catalog.searchQuery.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              ref.read(catalogNotifierProvider.notifier).setSearchQuery('');
                            },
                            child: const Icon(CupertinoIcons.xmark_circle_fill, size: 18, color: AppColors.textMuted),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Category Filter Pill Row
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: categories.map((cat) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: AlZaraPill(
                            label: cat.name,
                            icon: cat.icon,
                            isSelected: catalog.selectedCategoryId == cat.id,
                            onTap: () {
                              ref.read(catalogNotifierProvider.notifier).selectCategory(cat.id);
                            },
                            variant: PillVariant.gold,
                            isSmall: true,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            // Hierarchical Brand Grouped Product List
            Expanded(
              child: BrandGroupedProductList(
                products: results,
                selectedCategoryId: catalog.selectedCategoryId,
                categoryName: activeCategoryName,
                onProductTap: (product) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProductDetailScreen(productId: product.id),
                    ),
                  );
                },
                onProductEditTap: (product) {
                  QuickPriceEditSheet.show(context, product);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
