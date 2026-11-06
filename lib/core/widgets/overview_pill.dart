import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'focus_magnify_card.dart';

class OverviewPill extends StatelessWidget {
  final int productCount;
  final int categoryCount;
  final int pendingCount;
  final VoidCallback? onTapProducts;
  final VoidCallback? onTapCategories;
  final VoidCallback? onTapPending;
  final bool showPending;

  const OverviewPill({
    super.key,
    required this.productCount,
    required this.categoryCount,
    this.pendingCount = 0,
    this.onTapProducts,
    this.onTapCategories,
    this.onTapPending,
    this.showPending = true,
  });

  @override
  Widget build(BuildContext context) {
    return FocusMagnifyCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderGold.withValues(alpha: 0.35), width: 1.2),
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
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Products segment
          Expanded(
            child: GestureDetector(
              onTap: onTapProducts,
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(CupertinoIcons.cube_box_fill, size: 15, color: AppColors.primaryLight),
                      const SizedBox(width: 6),
                      Text(
                        '$productCount',
                        style: AppTypography.headlineSmall.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Products',
                    style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),

          Container(width: 1, height: 32, color: AppColors.borderGold.withValues(alpha: 0.25)),

          // Categories segment
          Expanded(
            child: GestureDetector(
              onTap: onTapCategories,
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(CupertinoIcons.square_grid_2x2_fill, size: 15, color: AppColors.primaryLight),
                      const SizedBox(width: 6),
                      Text(
                        '$categoryCount',
                        style: AppTypography.headlineSmall.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Categories',
                    style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),

          if (showPending) ...[
            Container(width: 1, height: 32, color: AppColors.borderGold.withValues(alpha: 0.25)),

            // Pending segment
            Expanded(
              child: GestureDetector(
                onTap: onTapPending,
                behavior: HitTestBehavior.opaque,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.clock_fill,
                          size: 15,
                          color: pendingCount > 0 ? AppColors.yellow : AppColors.primaryLight,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$pendingCount',
                          style: AppTypography.headlineSmall.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: pendingCount > 0 ? AppColors.yellow : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Pending',
                      style: AppTypography.caption.copyWith(
                        color: pendingCount > 0 ? AppColors.yellow : AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
