import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';
import '../domain/category.dart';

class SupabaseCategoryRepository {
  static const String tableName = 'categories';
  final List<Category> _localCache = [];
  final _controller = StreamController<List<Category>>.broadcast();
  RealtimeChannel? _subscription;

  SupabaseCategoryRepository() {
    _initListener();
  }

  void _initListener() {
    final client = SupabaseService.client;
    if (client != null) {
      _fetchInitial(client);

      // Realtime stream
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
      _localCache.add(
        const Category(
          id: 'general',
          name: 'General',
          icon: CupertinoIcons.cube_box_fill,
          productCount: 0,
          sortOrder: 1,
        ),
      );
      _controller.add(List.unmodifiable(_localCache));
    }
  }

  Future<void> _fetchInitial(SupabaseClient client) async {
    try {
      final data = await client.from(tableName).select().order('sortOrder', ascending: true);
      final categories = (data as List<dynamic>).map((row) {
        return Category.fromMap(Map<String, dynamic>.from(row as Map), row['id'] as String?);
      }).toList();

      _localCache
        ..clear()
        ..addAll(categories);
      _controller.add(List.unmodifiable(_localCache));
    } catch (e) {
      debugPrint('[SupabaseCategoryRepository] Error fetching categories: $e');
      _controller.add(List.unmodifiable(_localCache));
    }
  }

  Stream<List<Category>> watchCategories() => _controller.stream;

  List<Category> get currentCategories => List.unmodifiable(_localCache);

  Future<void> saveCategory(Category category) async {
    final client = SupabaseService.client;
    final id = category.id.isEmpty ? 'cat_${DateTime.now().millisecondsSinceEpoch}' : category.id;
    final toSave = category.copyWith(id: id);

    if (client != null) {
      try {
        await client.from(tableName).upsert(toSave.toMap());
      } catch (e) {
        debugPrint('[SupabaseCategoryRepository] Error saving category: $e');
      }
    }

    final index = _localCache.indexWhere((c) => c.id == id);
    if (index >= 0) {
      _localCache[index] = toSave;
    } else {
      _localCache.add(toSave);
    }
    _controller.add(List.unmodifiable(_localCache));
  }

  Future<void> deleteCategory(String categoryId) async {
    final client = SupabaseService.client;
    if (client != null) {
      try {
        await client.from(tableName).delete().eq('id', categoryId);
      } catch (e) {
        debugPrint('[SupabaseCategoryRepository] Error deleting category: $e');
      }
    }
    _localCache.removeWhere((c) => c.id == categoryId);
    _controller.add(List.unmodifiable(_localCache));
  }

  void dispose() {
    _subscription?.unsubscribe();
    _controller.close();
  }
}
