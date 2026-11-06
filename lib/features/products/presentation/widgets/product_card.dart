import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../domain/product.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/focus_magnify_card.dart';
import '../../../../core/widgets/al_zara_pill.dart';
import '../../../../core/widgets/animated_price_text.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;
  final VoidCallback? onEditTap;
  final bool isSelected;
  final bool showEditIcon;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onEditTap,
    this.isSelected = false,
    this.showEditIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    return FocusMagnifyCard(
      onTap: onTap,
      isFocused: isSelected,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.borderGold.withValues(alpha: 0.22),
          width: isSelected ? 1.5 : 1.0,
        ),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.cardElevated,
            AppColors.card,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Category Pill & Edit button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: AlZaraPill(
                  label: product.categoryName,
                  isSmall: true,
                  variant: PillVariant.gold,
                ),
              ),
              if (showEditIcon)
                GestureDetector(
                  onTap: onEditTap,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: AppColors.goldBeigeSubtle,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.borderGold.withValues(alpha: 0.3)),
                    ),
                    child: const Icon(
                      CupertinoIcons.pencil,
                      size: 13,
                      color: AppColors.primaryLight,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Center: Product Name & Brand/Unit
          Text(
            product.name,
            style: AppTypography.headlineSmall.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
              color: AppColors.textPrimary,
              height: 1.25,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (product.brandName.isNotEmpty || product.unit.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              [
                if (product.brandName.isNotEmpty) product.brandName,
                if (product.unit.isNotEmpty) product.unit,
              ].join(' • '),
              style: AppTypography.caption.copyWith(
                color: AppColors.primaryLight.withValues(alpha: 0.8),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          const Spacer(),

          // Bottom Price Shelf
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderGold.withValues(alpha: 0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Selling Price + MRP
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    AnimatedPriceText(
                      value: product.sellingPrice,
                      prefix: '₹',
                      style: AppTypography.priceLarge(color: AppColors.primaryLight).copyWith(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (product.mrp > product.sellingPrice) ...[
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          'MRP ${CurrencyFormatter.format(product.mrp)}',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textMuted,
                            fontSize: 10.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                // AZ Trade Price
                Row(
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        'AZ Trade: ₹${product.alZaraDiscountPrice.toStringAsFixed(0)}',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
