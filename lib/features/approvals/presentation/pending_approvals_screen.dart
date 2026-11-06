import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/al_zara_pill.dart';
import '../../../core/widgets/apple_alert.dart';
import '../../products/presentation/product_detail_screen.dart';
import 'approvals_providers.dart';
import 'widgets/pending_diff_card.dart';
import 'widgets/approve_all_dialog.dart';
import 'widgets/reject_reason_dialog.dart';

class PendingApprovalsScreen extends ConsumerStatefulWidget {
  const PendingApprovalsScreen({super.key});

  @override
  ConsumerState<PendingApprovalsScreen> createState() => _PendingApprovalsScreenState();
}

class _PendingApprovalsScreenState extends ConsumerState<PendingApprovalsScreen> {
  String _selectedFilter = 'all'; // 'all', 'edit', 'new_product'

  @override
  Widget build(BuildContext context) {
    final activePending = ref.watch(activePendingChangesProvider);

    final filteredList = activePending.where((p) {
      if (_selectedFilter == 'all') return true;
      return p.type == _selectedFilter;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Flexible(
              child: Text('Pending Approvals', style: AppTypography.headlineSmall, overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(width: 8),
            if (activePending.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.redBadge,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${activePending.length}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
        actions: [
          if (activePending.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.goldBeigeSubtle,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: AppColors.borderGold.withValues(alpha: 0.5)),
                  ),
                ),
                icon: const Icon(CupertinoIcons.checkmark_seal_fill, size: 16, color: AppColors.primaryLight),
                label: const Text(
                  'Approve All',
                  style: TextStyle(color: AppColors.primaryLight, fontWeight: FontWeight.bold),
                ),
                onPressed: () async {
                  final confirm = await ApproveAllDialog.show(context, activePending.length);
                  if (confirm == true && mounted) {
                    final approvedCount =
                        await ref.read(approvalsNotifierProvider.notifier).approveAllPending();
                    if (!mounted) return;
                    AppleAlert.showToast(
                      context,
                      message: 'Successfully approved $approvedCount changes. Live catalog updated.',
                      icon: CupertinoIcons.checkmark_seal_fill,
                    );
                  }
                },
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                AlZaraPill(
                  label: 'All Pending',
                  count: activePending.length,
                  isSelected: _selectedFilter == 'all',
                  onTap: () => setState(() => _selectedFilter = 'all'),
                  variant: PillVariant.gold,
                ),
                const SizedBox(width: 8),
                AlZaraPill(
                  label: 'Price Edits',
                  count: activePending.where((p) => p.type == 'edit').length,
                  isSelected: _selectedFilter == 'edit',
                  onTap: () => setState(() => _selectedFilter = 'edit'),
                  variant: PillVariant.gold,
                ),
                const SizedBox(width: 8),
                AlZaraPill(
                  label: 'New Listings',
                  count: activePending.where((p) => p.type == 'new_product').length,
                  isSelected: _selectedFilter == 'new_product',
                  onTap: () => setState(() => _selectedFilter = 'new_product'),
                  variant: PillVariant.gold,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Pending List or Empty State
          Expanded(
            child: filteredList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.borderGold.withValues(alpha: 0.4)),
                          ),
                          child: const Icon(
                            CupertinoIcons.checkmark_seal_fill,
                            size: 40,
                            color: AppColors.primaryLight,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text('All caught up!', style: AppTypography.headlineMedium),
                        const SizedBox(height: 6),
                        Text(
                          'No pending price or product changes awaiting approval.',
                          style: AppTypography.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final item = filteredList[index];
                      return PendingDiffCard(
                        pendingChange: item,
                        onApprove: () async {
                          await ref
                              .read(approvalsNotifierProvider.notifier)
                              .approvePendingChange(item.id);
                          if (!mounted) return;
                          AppleAlert.showToast(
                            context,
                            message: 'Approved "${item.productName}" change',
                            icon: CupertinoIcons.checkmark_seal_fill,
                          );
                        },
                        onReject: () async {
                          final reason = await RejectReasonDialog.show(context, item.productName);
                          if (reason != null && mounted) {
                            await ref
                                .read(approvalsNotifierProvider.notifier)
                                .rejectPendingChange(item.id, reason: reason);
                            if (!mounted) return;
                            AppleAlert.showToast(
                              context,
                              message: 'Rejected change for "${item.productName}"',
                              icon: CupertinoIcons.xmark_circle_fill,
                              iconColor: AppColors.red,
                            );
                          }
                        },
                        onTap: () {
                          if (item.productId != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProductDetailScreen(productId: item.productId!),
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
