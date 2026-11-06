import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class FocusMagnifyCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool isFocused;
  final double scaleFactor;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BoxDecoration? decoration;
  final BorderRadius? borderRadius;

  const FocusMagnifyCard({
    super.key,
    required this.child,
    this.onTap,
    this.isFocused = false,
    this.scaleFactor = 1.02,
    this.padding,
    this.margin,
    this.decoration,
    this.borderRadius,
  });

  @override
  State<FocusMagnifyCard> createState() => _FocusMagnifyCardState();
}

class _FocusMagnifyCardState extends State<FocusMagnifyCard> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 160),
    );
    // Apple-like subtle bounce
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    _animController.forward();
  }

  void _onTapUp(TapUpDetails _) {
    _animController.reverse();
  }

  void _onTapCancel() {
    _animController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final defaultRadius = widget.borderRadius ?? BorderRadius.circular(16);

    return GestureDetector(
      onTapDown: widget.onTap != null ? _onTapDown : null,
      onTapUp: widget.onTap != null ? _onTapUp : null,
      onTapCancel: widget.onTap != null ? _onTapCancel : null,
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _animController,
        builder: (context, child) {
          final isHighlighted = widget.isFocused || _glowAnimation.value > 0;
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              margin: widget.margin,
              decoration: widget.decoration ??
                  BoxDecoration(
                    color: AppColors.card,
                    borderRadius: defaultRadius,
                    border: Border.all(
                      color: isHighlighted ? AppColors.borderFocus : AppColors.border,
                      width: isHighlighted ? 1.4 : 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                      if (isHighlighted)
                        BoxShadow(
                          color: AppColors.primaryGlow,
                          blurRadius: 14,
                          spreadRadius: 1,
                        ),
                    ],
                  ),
              child: Padding(
                padding: widget.padding ?? EdgeInsets.zero,
                child: widget.child,
              ),
            ),
          );
        },
      ),
    );
  }
}
