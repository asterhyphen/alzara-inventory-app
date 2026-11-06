import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/user_role.dart';
import '../data/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final repo = AuthRepository();
  ref.onDispose(() => repo.dispose());
  return repo;
});

class AuthState {
  final UserRole role;
  final bool isInitialized;
  final bool hasSelectedRole;

  const AuthState({
    this.role = UserRole.admin,
    this.isInitialized = false,
    this.hasSelectedRole = false,
  });

  AuthState copyWith({
    UserRole? role,
    bool? isInitialized,
    bool? hasSelectedRole,
  }) {
    return AuthState(
      role: role ?? this.role,
      isInitialized: isInitialized ?? this.isInitialized,
      hasSelectedRole: hasSelectedRole ?? this.hasSelectedRole,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  StreamSubscription<void>? _pinSub;

  AuthNotifier(this._repository) : super(const AuthState()) {
    _init();
  }

  Future<void> _init() async {
    final savedRole = await _repository.getSavedRole();
    state = state.copyWith(
      role: savedRole ?? UserRole.admin,
      hasSelectedRole: savedRole != null,
      isInitialized: true,
    );

    // Auto-logout all devices when PIN changes in Firestore
    _pinSub = _repository.onPinChanged.listen((_) {
      logout();
    });
  }

  Future<bool> setRole(UserRole role, {String? pin, bool bypassPin = false}) async {
    if (!bypassPin && pin != null) {
      if (!_repository.verifyPin(role, pin)) {
        return false;
      }
      await _repository.savePin(pin);
    }

    await _repository.saveRole(role);
    state = state.copyWith(
      role: role,
      hasSelectedRole: true,
    );
    return true;
  }

  Future<void> switchRole(UserRole role) async {
    await _repository.saveRole(role);
    state = state.copyWith(role: role, hasSelectedRole: true);
  }

  Future<void> logout() async {
    await _repository.clearSavedRole();
    state = state.copyWith(hasSelectedRole: false);
  }

  @override
  void dispose() {
    _pinSub?.cancel();
    super.dispose();
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return AuthNotifier(repo);
});

final currentRoleProvider = Provider<UserRole>((ref) {
  return ref.watch(authNotifierProvider).role;
});

final isAdminProvider = Provider<bool>((ref) {
  return ref.watch(currentRoleProvider) == UserRole.admin;
});
