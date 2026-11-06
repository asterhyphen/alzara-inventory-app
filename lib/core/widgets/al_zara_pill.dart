import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

enum PillVariant {
  primary,
  neutral,
  warning,
  success,
  danger,
  gold,
}

class AlZaraPill extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final IconData? icon;
  final int? count;
  final PillVariant variant;
  final bool isSmall;

  const AlZaraPill({
    super.key,
    required this.label,
    this.isSelected = false,
    this.onTap,
    this.icon,
    this.count,
    this.variant = PillVariant.neutral,
    this.isSmall = false,
  });

  @override
  State<AlZaraPill> createState() => _AlZaraPillState();
}

class _AlZaraPillState extends State<AlZaraPill> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Color _getBackgroundColor() {
    if (widget.isSelected) {
      switch (widget.variant) {
        case PillVariant.primary:
        case PillVariant.gold:
          return AppColors.primary.withValues(alpha: 0.22);
        case PillVariant.warning:
          return AppColors.yellow.withValues(alpha: 0.2);
        case PillVariant.success:
          return AppColors.primary.withValues(alpha: 0.22);
        case PillVariant.danger:
          return AppColors.red.withValues(alpha: 0.2);
        default:
          return AppColors.primary.withValues(alpha: 0.2);
      }
    }

    switch (widget.variant) {
      case PillVariant.warning:
        return AppColors.yellow.withValues(alpha: 0.12);
      case PillVariant.success:
        return AppColors.primary.withValues(alpha: 0.12);
      case PillVariant.danger:
        return AppColors.red.withValues(alpha: 0.12);
      case PillVariant.gold:
        return AppColors.primary.withValues(alpha: 0.12);
      default:
        return AppColors.cardElevated;
    }
  }

  Color _getBorderColor() {
    if (widget.isSelected) {
      switch (widget.variant) {
        case PillVariant.gold:
        case PillVariant.primary:
          return AppColors.primary;
        case PillVariant.warning:
          return AppColors.yellow;
        case PillVariant.success:
          return AppColors.primary;
        case PillVariant.danger:
          return AppColors.red;
        default:
          return AppColors.primary;
      }
    }
    return AppColors.border;
  }

  Color _getTextColor() {
    if (widget.isSelected) {
      switch (widget.variant) {
        case PillVariant.gold:
        case PillVariant.primary:
          return AppColors.primaryLight;
        case PillVariant.warning:
          return AppColors.yellow;
        case PillVariant.success:
          return AppColors.primaryLight;
        case PillVariant.danger:
          return AppColors.red;
        default:
          return AppColors.primaryLight;
      }
    }

    switch (widget.variant) {
      case PillVariant.warning:
        return AppColors.yellow;
      case PillVariant.success:
        return AppColors.primaryLight;
      case PillVariant.danger:
        return AppColors.red;
      case PillVariant.gold:
        return AppColors.primaryLight;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = _getTextColor();
    final bgColor = _getBackgroundColor();
    final borderColor = _getBorderColor();

    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: (_) => _animController.forward(),
        onTapUp: (_) => _animController.reverse(),
        onTapCancel: () => _animController.reverse(),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: widget.isSmall ? 10 : 14,
            vertical: widget.isSmall ? 5 : 8,
          ),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: borderColor,
              width: widget.isSelected ? 1.5 : 1.0,
            ),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: borderColor.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(
                  widget.icon,
                  size: widget.isSmall ? 13 : 16,
                  color: textColor,
                ),
                SizedBox(width: widget.isSmall ? 4 : 6),
              ],
              Text(
                widget.label,
                style: (widget.isSmall ? AppTypography.caption : AppTypography.bodyMedium).copyWith(
                  color: textColor,
                  fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
              if (widget.count != null) ...[
                SizedBox(width: widget.isSmall ? 4 : 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: widget.isSelected
                        ? textColor.withValues(alpha: 0.2)
                        : AppColors.surfaceDark,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${widget.count}',
                    style: AppTypography.caption.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
