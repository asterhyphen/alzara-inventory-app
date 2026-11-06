import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../domain/pending_change.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/al_zara_pill.dart';
import '../../../../core/widgets/focus_magnify_card.dart';

class PendingDiffCard extends StatelessWidget {
  final PendingChange pendingChange;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback? onTap;

  const PendingDiffCard({
    super.key,
    required this.pendingChange,
    required this.onApprove,
    required this.onReject,
    this.onTap,
  });

  String _formatValue(dynamic val, String type) {
    if (val == null) return '-';
    if (type == 'currency') {
      if (val is num) return CurrencyFormatter.format(val.toDouble());
      return '₹$val';
    } else if (type == 'percent') {
      if (val is num) return CurrencyFormatter.formatPercent(val.toDouble());
      return '$val%';
    }
    return val.toString();
  }

  @override
  Widget build(BuildContext context) {
    final isNewProduct = pendingChange.type == 'new_product';

    return Dismissible(
      key: Key(pendingChange.id),
      direction: DismissDirection.horizontal,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 24),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          children: [
            Icon(CupertinoIcons.checkmark_alt_circle_fill, color: AppColors.primaryLight, size: 28),
            SizedBox(width: 8),
            Text('Approve', style: TextStyle(color: AppColors.primaryLight, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: AppColors.red.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text('Reject', style: TextStyle(color: AppColors.red, fontWeight: FontWeight.bold)),
            SizedBox(width: 8),
            Icon(CupertinoIcons.xmark_circle_fill, color: AppColors.red, size: 28),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onApprove();
        } else {
          onReject();
        }
        return false;
      },
      child: FocusMagnifyCard(
        onTap: onTap,
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.borderGold.withValues(alpha: 0.3)),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.cardElevated,
              AppColors.card,
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Category Tag + Name + Pending Pill (No placeholder icon box!)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          AlZaraPill(
                            label: pendingChange.categoryName,
                            isSmall: true,
                            variant: PillVariant.gold,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isNewProduct ? 'New Listing' : 'Price / Details Edit',
                            style: AppTypography.caption.copyWith(
                              color: isNewProduct ? AppColors.primaryLight : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        pendingChange.productName,
                        style: AppTypography.titleMedium.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const AlZaraPill(
                  label: 'Pending',
                  isSmall: true,
                  variant: PillVariant.warning,
                  icon: CupertinoIcons.clock_fill,
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Diffs Container
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderGold.withValues(alpha: 0.25)),
              ),
              child: Column(
                children: pendingChange.diffs.map((diff) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            diff.label,
                            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                          ),
                        ),
                        if (diff.oldValue != 'None') ...[
                          Text(
                            _formatValue(diff.oldValue, diff.formatType),
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textMuted,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Icon(
                              CupertinoIcons.arrow_right,
                              size: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                        Text(
                          _formatValue(diff.newValue, diff.formatType),
                          style: AppTypography.titleMedium.copyWith(
                            color: AppColors.primaryLight,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 14),

            // Footer: Submitted By + Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'By ${pendingChange.submittedBy} • ${DateTime.now().difference(pendingChange.submittedAt).inMinutes}m ago',
                  style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                ),
                Row(
                  children: [
                    // Reject button
                    GestureDetector(
                      onTap: onReject,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.red.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.red.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(CupertinoIcons.xmark, size: 14, color: AppColors.red),
                            const SizedBox(width: 4),
                            Text(
                              'Reject',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Approve button
                    GestureDetector(
                      onTap: onApprove,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primaryLight, AppColors.primary],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryGlow,
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(CupertinoIcons.checkmark, size: 14, color: Colors.black),
                            const SizedBox(width: 4),
                            Text(
                              'Approve',
                              style: AppTypography.caption.copyWith(
                                color: Colors.black,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
