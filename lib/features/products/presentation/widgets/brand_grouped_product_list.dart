import 'package:flutter/cupertino.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/product.dart';
import 'product_card.dart';

class BrandGroupedProductList extends StatelessWidget {
  final List<Product> products;
  final String selectedCategoryId;
  final String categoryName;
  final Function(Product) onProductTap;
  final Function(Product) onProductEditTap;
  final int? crossAxisCount;
  final double? childAspectRatio;

  const BrandGroupedProductList({
    super.key,
    required this.products,
    required this.selectedCategoryId,
    required this.categoryName,
    required this.onProductTap,
    required this.onProductEditTap,
    this.crossAxisCount,
    this.childAspectRatio,
  });

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.borderGold.withValues(alpha: 0.3)),
              ),
              child: const Icon(
                CupertinoIcons.cube_box,
                size: 36,
                color: AppColors.primaryLight,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'No products in $categoryName',
              style: AppTypography.headlineSmall.copyWith(fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap + below to add the first item',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
      );
    }

    // Group products by brand name
    final Map<String, List<Product>> brandGroups = {};
    for (final product in products) {
      final key = product.brandName.trim().isEmpty ? 'General / Unbranded' : product.brandName.trim();
      brandGroups.putIfAbsent(key, () => []).add(product);
    }

    final sortedBrandNames = brandGroups.keys.toList()
      ..sort((a, b) {
        if (a == 'General / Unbranded') return 1;
        if (b == 'General / Unbranded') return -1;
        return a.compareTo(b);
      });

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
      itemCount: sortedBrandNames.length,
      itemBuilder: (context, index) {
        final brandName = sortedBrandNames[index];
        final brandProducts = brandGroups[brandName]!;

        final screenWidth = MediaQuery.of(context).size.width;
        final responsiveCols = screenWidth > 1500
            ? 6
            : screenWidth > 1200
                ? 5
                : screenWidth > 900
                    ? 4
                    : screenWidth > 600
                        ? 3
                        : 2;

        final cols = crossAxisCount ?? responsiveCols;
        final aspect = childAspectRatio ?? (screenWidth > 600 ? 1.45 : 1.25);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Brand Section Header (Apple-like subtle luxury badge)
            Padding(
              padding: EdgeInsets.only(top: index == 0 ? 4 : 20, bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 3.5,
                    height: 16,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    brandName.toUpperCase(),
                    style: AppTypography.caption.copyWith(
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryLight,
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.goldBeigeSubtle,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.borderGold.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      '${brandProducts.length}',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Products Grid for this Brand
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: aspect,
              ),
              itemCount: brandProducts.length,
              itemBuilder: (ctx, pIdx) {
                final product = brandProducts[pIdx];
                return ProductCard(
                  product: product,
                  showEditIcon: true,
                  onTap: () => onProductTap(product),
                  onEditTap: () => onProductEditTap(product),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
