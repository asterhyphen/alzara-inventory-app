import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/cupertino.dart';
import '../domain/pending_change.dart';
import '../domain/activity_log.dart';
import '../data/supabase_approvals_repository.dart';
import '../../products/presentation/product_providers.dart';
import '../../../core/theme/app_colors.dart';

final approvalsRepositoryProvider = Provider<SupabaseApprovalsRepository>((ref) {
  final repo = SupabaseApprovalsRepository();
  ref.onDispose(() => repo.dispose());
  return repo;
});

class ApprovalsState {
  final List<PendingChange> pendingChanges;
  final List<ActivityLog> activities;

  const ApprovalsState({
    required this.pendingChanges,
    required this.activities,
  });

  List<PendingChange> get activePendingChanges =>
      pendingChanges.where((c) => c.status == 'pending').toList();

  int get pendingCount => activePendingChanges.length;

  ApprovalsState copyWith({
    List<PendingChange>? pendingChanges,
    List<ActivityLog>? activities,
  }) {
    return ApprovalsState(
      pendingChanges: pendingChanges ?? this.pendingChanges,
      activities: activities ?? this.activities,
    );
  }
}

class ApprovalsNotifier extends StateNotifier<ApprovalsState> {
  final Ref _ref;
  final SupabaseApprovalsRepository _repo;
  StreamSubscription<List<PendingChange>>? _pendingSub;
  StreamSubscription<List<ActivityLog>>? _actSub;

  ApprovalsNotifier(this._ref, this._repo)
      : super(ApprovalsState(
          pendingChanges: _repo.currentPending,
          activities: _repo.currentActivities,
        )) {
    _listenToStreams();
  }

  void _listenToStreams() {
    _pendingSub = _repo.watchPendingChanges().listen((changes) {
      state = state.copyWith(pendingChanges: changes);
    });

    _actSub = _repo.watchActivities().listen((acts) {
      state = state.copyWith(activities: acts);
    });
  }

  Future<void> queuePendingChange(PendingChange pending) async {
    await _repo.submitPendingChange(pending);

    await addActivity(
      ActivityLog(
        id: 'act_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Price / Name Edit submitted',
        description: '${pending.productName} • Pending Admin Review',
        actorRole: 'shopkeeper',
        type: 'edit_submitted',
        icon: CupertinoIcons.pencil,
        iconColor: AppColors.yellow,
        timestamp: DateTime.now(),
      ),
    );
  }

  Future<bool> approvePendingChange(String pendingId) async {
    final index = state.pendingChanges.indexWhere((p) => p.id == pendingId);
    if (index == -1) return false;

    final pending = state.pendingChanges[index];
    final proposed = pending.proposedProduct;

    await _ref.read(catalogNotifierProvider.notifier).applyApprovedProduct(
          proposed,
          isNew: pending.type == 'new_product' || pending.productId == null,
          existingId: pending.productId,
        );

    await _repo.updatePendingStatus(pendingId, 'approved', reviewedBy: 'admin');

    await addActivity(
      ActivityLog(
        id: 'act_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Change approved',
        description: '${pending.productName} • Live catalog updated',
        actorRole: 'admin',
        type: 'approved',
        icon: CupertinoIcons.checkmark_seal_fill,
        iconColor: AppColors.green,
        timestamp: DateTime.now(),
      ),
    );

    return true;
  }

  Future<bool> rejectPendingChange(String pendingId, {String? reason}) async {
    final index = state.pendingChanges.indexWhere((p) => p.id == pendingId);
    if (index == -1) return false;

    final pending = state.pendingChanges[index];
    await _repo.updatePendingStatus(
      pendingId,
      'rejected',
      reviewedBy: 'admin',
      rejectReason: reason ?? 'Rejected by Admin',
    );

    await addActivity(
      ActivityLog(
        id: 'act_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Change rejected',
        description: '${pending.productName} • ${reason ?? 'Price not approved'}',
        actorRole: 'admin',
        type: 'rejected',
        icon: CupertinoIcons.xmark_seal_fill,
        iconColor: AppColors.red,
        timestamp: DateTime.now(),
      ),
    );

    return true;
  }

  Future<int> approveAllPending() async {
    int count = 0;
    final activeList = _repo.currentPending.where((p) => p.status == 'pending').toList();

    for (final pending in activeList) {
      final proposed = pending.proposedProduct;
      await _ref.read(catalogNotifierProvider.notifier).applyApprovedProduct(
            proposed,
            isNew: pending.type == 'new_product' || pending.productId == null,
            existingId: pending.productId,
          );
      await _repo.updatePendingStatus(pending.id, 'approved', reviewedBy: 'admin');
      count++;
    }

    if (count > 0) {
      await addActivity(
        ActivityLog(
          id: 'act_${DateTime.now().millisecondsSinceEpoch}',
          title: 'Batch approved all',
          description: '$count pending changes applied to catalog',
          actorRole: 'admin',
          type: 'approved',
          icon: CupertinoIcons.checkmark_seal_fill,
          iconColor: AppColors.green,
          timestamp: DateTime.now(),
        ),
      );
    }

    return count;
  }

  Future<void> addActivity(ActivityLog activity) async {
    await _repo.addActivity(activity);
  }

  @override
  void dispose() {
    _pendingSub?.cancel();
    _actSub?.cancel();
    super.dispose();
  }
}

final approvalsNotifierProvider =
    StateNotifierProvider<ApprovalsNotifier, ApprovalsState>((ref) {
  final repo = ref.watch(approvalsRepositoryProvider);
  return ApprovalsNotifier(ref, repo);
});

final activePendingChangesProvider = Provider<List<PendingChange>>((ref) {
  return ref.watch(approvalsNotifierProvider).activePendingChanges;
});

final pendingCountProvider = Provider<int>((ref) {
  return ref.watch(approvalsNotifierProvider).pendingCount;
});

final activitiesProvider = Provider<List<ActivityLog>>((ref) {
  return ref.watch(approvalsNotifierProvider).activities;
});
