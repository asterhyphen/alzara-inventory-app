import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class DockItem {
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final int badgeCount;
  final bool isCenterAction;

  const DockItem({
    required this.icon,
    this.activeIcon,
    required this.label,
    this.badgeCount = 0,
    this.isCenterAction = false,
  });
}

class AlZaraDock extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTabSelected;
  final List<DockItem> items;
  final VoidCallback? onCenterActionTap;

  const AlZaraDock({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    required this.items,
    this.onCenterActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      left: false,
      right: false,
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.dockBackground,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: AppColors.borderGold.withValues(alpha: 0.3),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 28,
                        offset: const Offset(0, 10),
                      ),
                      BoxShadow(
                        color: AppColors.primaryGlow.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(items.length, (index) {
                      final item = items[index];
                      final isSelected = index == currentIndex;

                      if (item.isCenterAction) {
                        return _CenterActionButton(
                          item: item,
                          onTap: onCenterActionTap,
                        );
                      }

                      return _DockTabButton(
                        index: index,
                        item: item,
                        isSelected: isSelected,
                        onTap: () => onTabSelected(index),
                      );
                    }),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DockTabButton extends StatefulWidget {
  final int index;
  final DockItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _DockTabButton({
    required this.index,
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_DockTabButton> createState() => _DockTabButtonState();
}

class _DockTabButtonState extends State<_DockTabButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) {
          _controller.reverse();
          widget.onTap();
        },
        onTapCancel: () => _controller.reverse(),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: widget.isSelected ? AppColors.goldBeigeSubtle : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
            border: widget.isSelected
                ? Border.all(color: AppColors.borderGold, width: 1)
                : null,
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primaryGlow,
                      blurRadius: 12,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedScale(
                scale: widget.isSelected ? 1.15 : 1.0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutBack,
                child: Icon(
                  widget.isSelected ? (widget.item.activeIcon ?? widget.item.icon) : widget.item.icon,
                  size: 22,
                  color: widget.isSelected ? AppColors.primaryLight : AppColors.textSecondary,
                ),
              ),
              if (widget.item.badgeCount > 0)
                Positioned(
                  top: -6,
                  right: -10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.redBadge,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.red.withValues(alpha: 0.5),
                          blurRadius: 6,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Text(
                      '${widget.item.badgeCount}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CenterActionButton extends StatefulWidget {
  final DockItem item;
  final VoidCallback? onTap;

  const _CenterActionButton({
    required this.item,
    this.onTap,
  });

  @override
  State<_CenterActionButton> createState() => _CenterActionButtonState();
}

class _CenterActionButtonState extends State<_CenterActionButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) {
          _controller.reverse();
          widget.onTap?.call();
        },
        onTapCancel: () => _controller.reverse(),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 6),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primaryLight, AppColors.primary, AppColors.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryGlow,
                blurRadius: 18,
                spreadRadius: 2,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            widget.item.icon,
            size: 22,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}
