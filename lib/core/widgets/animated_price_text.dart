import 'package:flutter/material.dart';
import '../utils/currency_formatter.dart';

class AnimatedPriceText extends StatelessWidget {
  final double value;
  final TextStyle? style;
  final String? prefix;
  final String? suffix;
  final bool showDecimals;

  const AnimatedPriceText({
    super.key,
    required this.value,
    this.style,
    this.prefix,
    this.suffix,
    this.showDecimals = false,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: value, end: value),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      builder: (context, val, child) {
        String formattedNumber;
        if (prefix == '₹' || prefix == null && suffix == null) {
          formattedNumber = CurrencyFormatter.format(val, showDecimals: showDecimals);
        } else if (suffix == '%') {
          formattedNumber = '${val.toStringAsFixed(showDecimals ? 1 : 0)}%';
        } else {
          final p = prefix ?? '';
          final s = suffix ?? '';
          formattedNumber = '$p${showDecimals ? val.toStringAsFixed(2) : val.toStringAsFixed(0)}$s';
        }

        return Text(
          formattedNumber,
          style: style,
        );
      },
    );
  }
}
