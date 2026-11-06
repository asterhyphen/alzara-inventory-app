import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/overview_pill.dart';
import '../../products/presentation/product_providers.dart';
import '../../approvals/presentation/approvals_providers.dart';
import '../../approvals/presentation/pending_approvals_screen.dart';
import '../../approvals/presentation/activity_logs_screen.dart';

class AdminHomeScreen extends ConsumerWidget {
  final Function(int)? onNavigateTab;

  const AdminHomeScreen({
    super.key,
    this.onNavigateTab,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productsListProvider);
    final categories = ref.watch(categoriesProvider);
    final pendingCount = ref.watch(pendingCountProvider);
    final activities = ref.watch(activitiesProvider);

    final totalCategoriesCount = categories.where((c) => c.id != 'all').length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Header Bar (No notification icon)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome Back',
                    style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 2),
                  Text('Admin', style: AppTypography.headlineLarge),
                  const SizedBox(height: 2),
                  Text(
                    'Al Zara Group',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Big Rectangular Luxury Pill for Overview Stats
              OverviewPill(
                productCount: products.length,
                categoryCount: totalCategoriesCount,
                pendingCount: pendingCount,
                onTapProducts: () => onNavigateTab?.call(1),
                onTapCategories: () => onNavigateTab?.call(1),
                onTapPending: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PendingApprovalsScreen()),
                  );
                },
              ),
              const SizedBox(height: 28),

              // Recent Activity Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'RECENT ACTIVITY',
                    style: AppTypography.caption.copyWith(
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMuted,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ActivityLogsScreen()),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                      child: Row(
                        children: [
                          Text(
                            'See All',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.primaryLight,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            CupertinoIcons.arrow_right,
                            size: 12,
                            color: AppColors.primaryLight,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Activity Feed List (Top 5)
              if (activities.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderGold.withValues(alpha: 0.15)),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'No recent activity recorded.',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                  ),
                )
              else
                ...activities.take(5).map((activity) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.borderGold.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: activity.iconColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            activity.icon,
                            size: 18,
                            color: activity.iconColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                activity.title,
                                style: AppTypography.titleMedium.copyWith(fontSize: 14),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                activity.description,
                                style: AppTypography.bodySmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          activity.timeAgo,
                          style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}
