import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';
import '../domain/user_role.dart';

class AuthRepository {
  static const String _roleKey = 'alzara_user_role';
  static const String _pinKey = 'alzara_authenticated_pin';
  static const String securityTable = 'security';
  static const String pinsDocId = 'pins';

  String _adminPin = '1234';
  String _shopkeeperPin = '0000';
  final _pinChangedController = StreamController<void>.broadcast();
  RealtimeChannel? _subscription;

  String get adminPin => _adminPin;
  String get shopkeeperPin => _shopkeeperPin;
  Stream<void> get onPinChanged => _pinChangedController.stream;

  AuthRepository() {
    _initPinListener();
  }

  void _initPinListener() {
    final client = SupabaseService.client;
    if (client != null) {
      _fetchPins(client);

      _subscription = client
          .channel('public:$securityTable')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: securityTable,
            callback: (payload) {
              _fetchPins(client);
            },
          )
          .subscribe();
    }
  }

  Future<void> _fetchPins(SupabaseClient client) async {
    try {
      final data = await client.from(securityTable).select().eq('id', pinsDocId).maybeSingle();
      if (data != null) {
        final newAdmin = data['adminPin'] as String? ?? '1234';
        final newShop = data['shopkeeperPin'] as String? ?? '0000';

        final currentSavedRole = await getSavedRole();
        final currentSavedPin = await getSavedPin();

        // Detect remote PIN change for active session
        if (currentSavedRole != null && currentSavedPin != null) {
          final expectedPin = currentSavedRole == UserRole.admin ? newAdmin : newShop;
          if (currentSavedPin != expectedPin) {
            _pinChangedController.add(null);
          }
        }

        _adminPin = newAdmin;
        _shopkeeperPin = newShop;
      } else {
        // Seed default PINs row
        await client.from(securityTable).insert({
          'id': pinsDocId,
          'adminPin': _adminPin,
          'shopkeeperPin': _shopkeeperPin,
          'updatedAt': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      debugPrint('[AuthRepository] Error fetching security PINs: $e');
    }
  }

  Future<UserRole?> getSavedRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_roleKey);
      if (saved == 'shopkeeper') return UserRole.shopkeeper;
      if (saved == 'admin') return UserRole.admin;
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> saveRole(UserRole role) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_roleKey, role.name);
    } catch (_) {}
  }

  Future<String?> getSavedPin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_pinKey);
    } catch (_) {
      return null;
    }
  }

  Future<void> savePin(String pin) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_pinKey, pin);
    } catch (_) {}
  }

  Future<void> clearSavedRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_roleKey);
      await prefs.remove(_pinKey);
    } catch (_) {}
  }

  bool verifyPin(UserRole role, String pin) {
    if (role == UserRole.admin) {
      return pin == _adminPin;
    } else {
      return pin == _shopkeeperPin;
    }
  }

  Future<void> updatePin(UserRole role, String newPin) async {
    if (role == UserRole.admin) {
      _adminPin = newPin;
    } else {
      _shopkeeperPin = newPin;
    }

    await savePin(newPin);

    final client = SupabaseService.client;
    if (client != null) {
      try {
        await client.from(securityTable).upsert({
          'id': pinsDocId,
          'adminPin': _adminPin,
          'shopkeeperPin': _shopkeeperPin,
          'updatedAt': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        debugPrint('[AuthRepository] Error updating security PINs in Supabase: $e');
      }
    }
  }

  void dispose() {
    _subscription?.unsubscribe();
    _pinChangedController.close();
  }
}
