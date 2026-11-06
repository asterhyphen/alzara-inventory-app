import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';
import '../domain/pending_change.dart';
import '../domain/activity_log.dart';

class SupabaseApprovalsRepository {
  static const String pendingTable = 'pending_changes';
  static const String activityTable = 'activity_logs';

  final List<PendingChange> _pendingCache = [];
  final List<ActivityLog> _activityCache = [];

  final _pendingController = StreamController<List<PendingChange>>.broadcast();
  final _activityController = StreamController<List<ActivityLog>>.broadcast();

  RealtimeChannel? _pendingSub;
  RealtimeChannel? _activitySub;

  SupabaseApprovalsRepository() {
    _initListeners();
  }

  void _initListeners() {
    final client = SupabaseService.client;
    if (client != null) {
      _fetchInitialPending(client);
      _fetchInitialActivities(client);

      _pendingSub = client
          .channel('public:$pendingTable')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: pendingTable,
            callback: (_) => _fetchInitialPending(client),
          )
          .subscribe();

      _activitySub = client
          .channel('public:$activityTable')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: activityTable,
            callback: (_) => _fetchInitialActivities(client),
          )
          .subscribe();
    } else {
      _pendingController.add(List.unmodifiable(_pendingCache));
      _activityController.add(List.unmodifiable(_activityCache));
    }
  }

  Future<void> _fetchInitialPending(SupabaseClient client) async {
    try {
      final data = await client.from(pendingTable).select();
      final changes = (data as List<dynamic>).map((row) {
        return PendingChange.fromMap(Map<String, dynamic>.from(row as Map), row['id'] as String?);
      }).toList();

      _pendingCache
        ..clear()
        ..addAll(changes);
      _pendingController.add(List.unmodifiable(_pendingCache));
    } catch (e) {
      debugPrint('[SupabaseApprovalsRepository] Error fetching pending changes: $e');
      _pendingController.add(List.unmodifiable(_pendingCache));
    }
  }

  Future<void> _fetchInitialActivities(SupabaseClient client) async {
    try {
      final data = await client.from(activityTable).select().order('timestamp', ascending: false).limit(25);
      final logs = (data as List<dynamic>).map((row) {
        return ActivityLog.fromMap(Map<String, dynamic>.from(row as Map), row['id'] as String?);
      }).toList();

      _activityCache
        ..clear()
        ..addAll(logs);
      _activityController.add(List.unmodifiable(_activityCache));
    } catch (e) {
      debugPrint('[SupabaseApprovalsRepository] Error fetching activity logs: $e');
      _activityController.add(List.unmodifiable(_activityCache));
    }
  }

  Stream<List<PendingChange>> watchPendingChanges() => _pendingController.stream;
  Stream<List<ActivityLog>> watchActivities() => _activityController.stream;

  List<PendingChange> get currentPending => List.unmodifiable(_pendingCache);
  List<ActivityLog> get currentActivities => List.unmodifiable(_activityCache);

  Future<void> submitPendingChange(PendingChange change) async {
    final client = SupabaseService.client;
    final id = change.id.isEmpty
        ? 'pend_${DateTime.now().microsecondsSinceEpoch}_${_pendingCache.length}'
        : change.id;
    final toSave = change.copyWith(id: id);

    if (client != null) {
      try {
        await client.from(pendingTable).upsert(toSave.toMap());
      } catch (e) {
        debugPrint('[SupabaseApprovalsRepository] Error saving pending change: $e');
      }
    }

    _pendingCache.insert(0, toSave);
    _pendingController.add(List.unmodifiable(_pendingCache));
  }

  Future<void> updatePendingStatus(String changeId, String status, {String? reviewedBy, String? rejectReason}) async {
    final client = SupabaseService.client;
    final now = DateTime.now();

    if (client != null) {
      try {
        await client.from(pendingTable).update({
          'status': status,
          'reviewedBy': reviewedBy ?? 'admin',
          'reviewedAt': now.toIso8601String(),
          if (rejectReason != null) 'rejectReason': rejectReason,
        }).eq('id', changeId);
      } catch (e) {
        debugPrint('[SupabaseApprovalsRepository] Error updating pending status: $e');
      }
    }

    final index = _pendingCache.indexWhere((p) => p.id == changeId);
    if (index >= 0) {
      _pendingCache[index] = _pendingCache[index].copyWith(
        status: status,
        reviewedBy: reviewedBy ?? 'admin',
        reviewedAt: now,
        rejectReason: rejectReason,
      );
      _pendingController.add(List.unmodifiable(_pendingCache));
    }
  }

  Future<void> addActivity(ActivityLog activity) async {
    final id = activity.id.isEmpty
        ? 'act_${DateTime.now().millisecondsSinceEpoch}_${_activityCache.length}'
        : activity.id;
    final toSave = activity.copyWith(id: id);

    _activityCache.removeWhere((a) => a.id == id);
    _activityCache.insert(0, toSave);
    if (_activityCache.length > 50) _activityCache.removeLast();
    _activityController.add(List.unmodifiable(_activityCache));

    final client = SupabaseService.client;
    if (client != null) {
      try {
        await client.from(activityTable).upsert(toSave.toMap());
      } catch (e) {
        debugPrint('[SupabaseApprovalsRepository] Error saving activity log: $e');
      }
    }
  }

  void dispose() {
    _pendingSub?.unsubscribe();
    _activitySub?.unsubscribe();
    _pendingController.close();
    _activityController.close();
  }
}
