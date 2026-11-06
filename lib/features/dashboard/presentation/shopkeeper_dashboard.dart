import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/al_zara_pill.dart';
import '../../../core/widgets/overview_pill.dart';
import '../../products/presentation/product_providers.dart';
import '../../products/presentation/widgets/brand_grouped_product_list.dart';
import '../../products/presentation/widgets/quick_price_edit_sheet.dart';
import '../../products/presentation/product_detail_screen.dart';
import '../../approvals/presentation/approvals_providers.dart';

class ShopkeeperDashboard extends ConsumerStatefulWidget {
  final Function(int)? onNavigateTab;

  const ShopkeeperDashboard({super.key, this.onNavigateTab});

  @override
  ConsumerState<ShopkeeperDashboard> createState() => _ShopkeeperDashboardState();
}

class _ShopkeeperDashboardState extends ConsumerState<ShopkeeperDashboard> {
  String _selectedCategoryId = 'all';
  bool _sidebarCollapsed = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(catalogNotifierProvider);
    final pendingCount = ref.watch(pendingCountProvider);

    final categories = catalog.categories;
    final totalCategoriesCount = categories.where((c) => c.id != 'all').length;

    final query = catalog.searchQuery.toLowerCase().trim();
    final products = catalog.products.where((p) {
      if (query.isNotEmpty) {
        final matchName = p.name.toLowerCase().contains(query);
        final matchBrand = p.brandName.toLowerCase().contains(query);
        final matchCategory = p.categoryName.toLowerCase().contains(query);
        if (!matchName && !matchBrand && !matchCategory) return false;
      }
      if (_selectedCategoryId != 'all' && p.categoryId != _selectedCategoryId) {
        return false;
      }
      return true;
    }).toList();

    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 700;

    final activeCategoryName = _selectedCategoryId == 'all'
        ? 'All Products'
        : categories.firstWhere((c) => c.id == _selectedCategoryId, orElse: () => categories.first).name;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // ─── SIDEBAR (iPad Wide Screen) ───
            if (isWideScreen)
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                width: _sidebarCollapsed ? 60 : 180,
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  border: Border(right: BorderSide(color: AppColors.borderGold.withValues(alpha: 0.25), width: 1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Brand header
                    Padding(
                      padding: EdgeInsets.all(_sidebarCollapsed ? 10 : 16),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => setState(() => _sidebarCollapsed = !_sidebarCollapsed),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.goldBeigeSubtle,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.borderGold.withValues(alpha: 0.4)),
                              ),
                              child: Icon(
                                _sidebarCollapsed
                                    ? CupertinoIcons.sidebar_right
                                    : CupertinoIcons.sidebar_left,
                                size: 16,
                                color: AppColors.primaryLight,
                              ),
                            ),
                          ),
                          if (!_sidebarCollapsed) ...[
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'AL ZARA',
                                    style: AppTypography.caption.copyWith(
                                      letterSpacing: 1.5,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryLight,
                                    ),
                                  ),
                                  Text(
                                    'iPad POS',
                                    style: AppTypography.titleMedium.copyWith(fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Category list in sidebar
                    Expanded(
                      child: ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: categories.length,
                        padding: EdgeInsets.symmetric(
                          horizontal: _sidebarCollapsed ? 8 : 12,
                        ),
                        itemBuilder: (context, index) {
                          final cat = categories[index];
                          final isSelected = _selectedCategoryId == cat.id;

                          return GestureDetector(
                            onTap: () => setState(() => _selectedCategoryId = cat.id),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.only(bottom: 4),
                              padding: EdgeInsets.symmetric(
                                horizontal: _sidebarCollapsed ? 8 : 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.goldBeigeSubtle
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                border: isSelected
                                    ? Border.all(color: AppColors.borderGold.withValues(alpha: 0.5))
                                    : null,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    cat.icon,
                                    size: 16,
                                    color: isSelected ? AppColors.primaryLight : AppColors.textMuted,
                                  ),
                                  if (!_sidebarCollapsed) ...[
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        cat.name,
                                        style: AppTypography.bodyMedium.copyWith(
                                          color: isSelected
                                              ? AppColors.primaryLight
                                              : AppColors.textSecondary,
                                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

            // ─── MAIN CONTENT ───
            Expanded(
              child: Column(
                children: [
                  // Reusable Overview Pill
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                    child: OverviewPill(
                      productCount: catalog.products.length,
                      categoryCount: totalCategoriesCount,
                      pendingCount: pendingCount,
                      showPending: true,
                    ),
                  ),

                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
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
                                contentPadding: const EdgeInsets.symmetric(vertical: 13),
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
                  ),
                  const SizedBox(height: 10),

                  // Category filter chips (horizontal, mobile view)
                  if (!isWideScreen)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: categories.map((cat) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: AlZaraPill(
                                label: cat.name,
                                icon: cat.icon,
                                isSelected: _selectedCategoryId == cat.id,
                                onTap: () => setState(() => _selectedCategoryId = cat.id),
                                variant: PillVariant.gold,
                                isSmall: true,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),

                  const SizedBox(height: 8),

                  // Brand Grouped Products Grid
                  Expanded(
                    child: BrandGroupedProductList(
                      products: products,
                      selectedCategoryId: _selectedCategoryId,
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
          ],
        ),
      ),
    );
  }
}
