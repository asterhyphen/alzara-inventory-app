import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';
import '../domain/brand.dart';

class SupabaseBrandRepository {
  static const String tableName = 'brands';
  final List<Brand> _localCache = [];
  final _controller = StreamController<List<Brand>>.broadcast();
  RealtimeChannel? _subscription;

  SupabaseBrandRepository() {
    _initListener();
  }

  void _initListener() {
    final client = SupabaseService.client;
    if (client != null) {
      _fetchInitial(client);

      _subscription = client
          .channel('public:$tableName')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: tableName,
            callback: (payload) {
              _fetchInitial(client);
            },
          )
          .subscribe();
    } else {
      _controller.add(List.unmodifiable(_localCache));
    }
  }

  Future<void> _fetchInitial(SupabaseClient client) async {
    try {
      final data = await client.from(tableName).select().order('sortOrder', ascending: true);
      final brands = (data as List<dynamic>).map((row) {
        return Brand.fromMap(Map<String, dynamic>.from(row as Map), row['id'] as String?);
      }).toList();

      _localCache
        ..clear()
        ..addAll(brands);
      _controller.add(List.unmodifiable(_localCache));
    } catch (e) {
      debugPrint('[SupabaseBrandRepository] Error fetching brands: $e');
      _controller.add(List.unmodifiable(_localCache));
    }
  }

  Stream<List<Brand>> watchBrands() => _controller.stream;
  List<Brand> get currentBrands => List.unmodifiable(_localCache);
  List<Brand> brandsForCategory(String categoryId) =>
      _localCache.where((b) => b.categoryId == categoryId).toList();

  Future<Brand> saveBrand(Brand brand) async {
    final client = SupabaseService.client;
    final id = brand.id.isEmpty ? 'brand_${DateTime.now().microsecondsSinceEpoch}' : brand.id;
    final toSave = brand.copyWith(id: id);

    if (client != null) {
      try {
        await client.from(tableName).upsert(toSave.toMap());
      } catch (e) {
        debugPrint('[SupabaseBrandRepository] Error saving brand: $e');
      }
    }

    final index = _localCache.indexWhere((b) => b.id == id);
    if (index >= 0) {
      _localCache[index] = toSave;
    } else {
      _localCache.add(toSave);
    }
    _controller.add(List.unmodifiable(_localCache));
    return toSave;
  }

  Future<void> deleteBrand(String brandId) async {
    final client = SupabaseService.client;
    if (client != null) {
      try {
        await client.from(tableName).delete().eq('id', brandId);
      } catch (e) {
        debugPrint('[SupabaseBrandRepository] Error deleting brand: $e');
      }
    }
    _localCache.removeWhere((b) => b.id == brandId);
    _controller.add(List.unmodifiable(_localCache));
  }

  void dispose() {
    _subscription?.unsubscribe();
    _controller.close();
  }
}
