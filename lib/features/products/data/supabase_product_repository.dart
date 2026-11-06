import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';
import '../domain/product.dart';

class SupabaseProductRepository {
  static const String tableName = 'products';
  final List<Product> _localCache = [];
  final _controller = StreamController<List<Product>>.broadcast();
  RealtimeChannel? _subscription;

  SupabaseProductRepository() {
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
      final data = await client.from(tableName).select();
      final products = (data as List<dynamic>).map((row) {
        return Product.fromMap(Map<String, dynamic>.from(row as Map), row['id'] as String?);
      }).toList();

      _localCache
        ..clear()
        ..addAll(products);
      _controller.add(List.unmodifiable(_localCache));
    } catch (e) {
      debugPrint('[SupabaseProductRepository] Error fetching products: $e');
      _controller.add(List.unmodifiable(_localCache));
    }
  }

  Stream<List<Product>> watchProducts() => _controller.stream;
  List<Product> get currentProducts => List.unmodifiable(_localCache);

  Future<void> saveProduct(Product product) async {
    final client = SupabaseService.client;
    final id = product.id.isEmpty ? 'prod_${DateTime.now().millisecondsSinceEpoch}' : product.id;
    final toSave = product.copyWith(id: id);

    if (client != null) {
      try {
        await client.from(tableName).upsert(toSave.toMap());
      } catch (e) {
        debugPrint('[SupabaseProductRepository] Error saving product: $e');
      }
    }

    final index = _localCache.indexWhere((p) => p.id == id);
    if (index >= 0) {
      _localCache[index] = toSave;
    } else {
      _localCache.insert(0, toSave);
    }
    _controller.add(List.unmodifiable(_localCache));
  }

  Future<void> deleteProduct(String productId) async {
    final client = SupabaseService.client;
    if (client != null) {
      try {
        await client.from(tableName).delete().eq('id', productId);
      } catch (e) {
        debugPrint('[SupabaseProductRepository] Error deleting product: $e');
      }
    }
    _localCache.removeWhere((p) => p.id == productId);
    _controller.add(List.unmodifiable(_localCache));
  }

  void dispose() {
    _subscription?.unsubscribe();
    _controller.close();
  }
}
