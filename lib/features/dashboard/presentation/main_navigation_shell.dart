import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/al_zara_dock.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../products/presentation/add_edit_product_screen.dart';
import '../../products/presentation/search_browse_screen.dart';
import '../../approvals/presentation/approvals_providers.dart';
import '../../approvals/presentation/pending_approvals_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import 'admin_home_screen.dart';
import 'shopkeeper_dashboard.dart';

class MainNavigationShell extends ConsumerStatefulWidget {
  const MainNavigationShell({super.key});

  @override
  ConsumerState<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends ConsumerState<MainNavigationShell> {
  int _currentIndex = 0;

  void _navigateTab(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = ref.watch(isAdminProvider);
    final pendingCount = ref.watch(pendingCountProvider);

    final List<DockItem> dockItems = isAdmin
        ? [
            const DockItem(
              icon: CupertinoIcons.house,
              activeIcon: CupertinoIcons.house_fill,
              label: 'Home',
            ),
            const DockItem(
              icon: CupertinoIcons.cube_box,
              activeIcon: CupertinoIcons.cube_box_fill,
              label: 'Products',
            ),
            const DockItem(
              icon: CupertinoIcons.plus_circle_fill,
              label: 'Add',
              isCenterAction: true,
            ),
            DockItem(
              icon: CupertinoIcons.clock,
              activeIcon: CupertinoIcons.clock_fill,
              label: 'Approvals',
              badgeCount: pendingCount,
            ),
            const DockItem(
              icon: CupertinoIcons.gear,
              activeIcon: CupertinoIcons.gear_solid,
              label: 'Settings',
            ),
          ]
        : [
            const DockItem(
              icon: CupertinoIcons.cube_box,
              activeIcon: CupertinoIcons.cube_box_fill,
              label: 'Catalog',
            ),
            const DockItem(
              icon: CupertinoIcons.plus_circle_fill,
              label: 'Add',
              isCenterAction: true,
            ),
            const DockItem(
              icon: CupertinoIcons.gear,
              activeIcon: CupertinoIcons.gear_solid,
              label: 'Settings',
            ),
          ];

    Widget body;
    if (isAdmin) {
      switch (_currentIndex) {
        case 0:
          body = AdminHomeScreen(onNavigateTab: _navigateTab);
          break;
        case 1:
          body = const SearchBrowseScreen();
          break;
        case 3:
          body = const PendingApprovalsScreen();
          break;
        case 4:
          body = const SettingsScreen();
          break;
        default:
          body = AdminHomeScreen(onNavigateTab: _navigateTab);
      }
    } else {
      switch (_currentIndex) {
        case 0:
          body = ShopkeeperDashboard(onNavigateTab: _navigateTab);
          break;
        case 2:
          body = const SettingsScreen();
          break;
        default:
          body = ShopkeeperDashboard(onNavigateTab: _navigateTab);
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        transitionBuilder: (child, animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: KeyedSubtree(
          key: ValueKey<int>(_currentIndex + (isAdmin ? 0 : 100)),
          child: body,
        ),
      ),
      extendBody: true,
      bottomNavigationBar: AlZaraDock(
        currentIndex: _currentIndex,
        items: dockItems,
        onTabSelected: (index) {
          if (dockItems[index].isCenterAction) return;
          setState(() => _currentIndex = index);
        },
        onCenterActionTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEditProductScreen()),
          );
        },
      ),
    );
  }
}
