import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/services/supabase_service.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/auth_providers.dart';
import 'features/auth/presentation/role_picker_screen.dart';
import 'features/dashboard/presentation/main_navigation_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('[FlutterError] ${details.exceptionAsString()}');
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('[PlatformDispatcher] Unhandled error: $error\n$stack');
    return true;
  };

  try {
    await SupabaseService.initialize();
  } catch (e) {
    debugPrint('[main] SupabaseService init exception: $e');
  }
  runApp(const ProviderScope(child: AlZaraApp()));
}

class AlZaraApp extends StatelessWidget {
  const AlZaraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Al Zara Inventory & Pricing',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const AppGate(),
    );
  }
}

/// Determines whether to show role picker or the main shell.
class AppGate extends ConsumerWidget {
  const AppGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);

    if (!authState.isInitialized) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CupertinoActivityIndicator(radius: 14)),
      );
    }

    if (!authState.hasSelectedRole) {
      return const RolePickerScreen();
    }

    return const MainNavigationShell();
  }
}
