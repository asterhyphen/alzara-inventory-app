import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class SupabaseService {
  static bool _initialized = false;
  static bool get isInitialized => _initialized;

  static Future<void> initialize() async {
    if (_initialized) return;
    try {
      final url = SupabaseConfig.url.trim();
      final anonKey = SupabaseConfig.anonKey.trim();

      if (url.isNotEmpty &&
          anonKey.isNotEmpty &&
          url != 'YOUR_SUPABASE_URL' &&
          anonKey != 'YOUR_SUPABASE_ANON_KEY') {
        await Supabase.initialize(
          url: url,
          anonKey: anonKey,
          debug: kDebugMode,
        );
        _initialized = true;
        debugPrint('[SupabaseService] Initialized successfully.');
      } else {
        debugPrint('[SupabaseService] Config credentials not set yet; running offline fallback mode.');
      }
    } catch (e) {
      _initialized = false;
      debugPrint('[SupabaseService] Initialization error: $e');
    }
  }

  static SupabaseClient? get client {
    try {
      if (_initialized) {
        return Supabase.instance.client;
      }
    } catch (_) {}
    return null;
  }
}
