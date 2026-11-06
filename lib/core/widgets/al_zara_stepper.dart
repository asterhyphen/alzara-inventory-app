import 'package:flutter/cupertino.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'animated_price_text.dart';

class AlZaraStepper extends StatelessWidget {
  final double value;
  final double step;
  final double min;
  final double max;
  final String? prefix;
  final String? suffix;
  final ValueChanged<double> onChanged;
  final bool showDecimals;
  final String? label;

  const AlZaraStepper({
    super.key,
    required this.value,
    this.step = 5.0,
    this.min = 0.0,
    this.max = 100000.0,
    this.prefix,
    this.suffix,
    required this.onChanged,
    this.showDecimals = false,
    this.label,
  });

  void _decrement() {
    final next = (value - step).clamp(min, max);
    if (next != value) {
      onChanged(double.parse(next.toStringAsFixed(showDecimals ? 2 : 0)));
    }
  }

  void _increment() {
    final next = (value + step).clamp(min, max);
    if (next != value) {
      onChanged(double.parse(next.toStringAsFixed(showDecimals ? 2 : 0)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final canDecrement = value > min;
    final canIncrement = value < max;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.cardElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderGold.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (label != null) ...[
            Text(
              label!,
              style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(width: 8),
          ],
          _StepperButton(
            icon: CupertinoIcons.minus,
            isEnabled: canDecrement,
            onTap: _decrement,
          ),
          Container(
            constraints: const BoxConstraints(minWidth: 68),
            padding: const EdgeInsets.symmetric(horizontal: 6),
            alignment: Alignment.center,
            child: AnimatedPriceText(
              value: value,
              prefix: prefix,
              suffix: suffix,
              showDecimals: showDecimals,
              style: AppTypography.priceMedium(color: AppColors.primaryLight),
            ),
          ),
          _StepperButton(
            icon: CupertinoIcons.plus,
            isEnabled: canIncrement,
            onTap: _increment,
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatefulWidget {
  final IconData icon;
  final bool isEnabled;
  final VoidCallback onTap;

  const _StepperButton({
    required this.icon,
    required this.isEnabled,
    required this.onTap,
  });

  @override
  State<_StepperButton> createState() => _StepperButtonState();
}

class _StepperButtonState extends State<_StepperButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.82).animate(
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
        onTapDown: widget.isEnabled ? (_) => _controller.forward() : null,
        onTapUp: widget.isEnabled
            ? (_) {
                _controller.reverse();
                widget.onTap();
              }
            : null,
        onTapCancel: () => _controller.reverse(),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: widget.isEnabled ? AppColors.surfaceDark : AppColors.card,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: widget.isEnabled ? AppColors.borderGold.withValues(alpha: 0.4) : AppColors.borderSubtle,
            ),
          ),
          child: Icon(
            widget.icon,
            size: 14,
            color: widget.isEnabled ? AppColors.primaryLight : AppColors.textDisabled,
          ),
        ),
      ),
    );
  }
}
