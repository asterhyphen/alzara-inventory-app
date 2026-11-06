import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'animated_price_text.dart';

class AlZaraSlider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final double? floorValue; // Minimum guardrail floor
  final String? floorLabel;
  final String? suffix;
  final String? prefix;
  final ValueChanged<double> onChanged;
  final Color activeColor;

  const AlZaraSlider({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    this.divisions,
    this.floorValue,
    this.floorLabel,
    this.suffix = '%',
    this.prefix,
    required this.onChanged,
    this.activeColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    final isAtOrBelowFloor = floorValue != null && value <= floorValue!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAtOrBelowFloor
              ? AppColors.yellow.withValues(alpha: 0.5)
              : AppColors.borderGold.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: AppTypography.titleMedium.copyWith(color: AppColors.textPrimary),
              ),
              AnimatedPriceText(
                value: value,
                prefix: prefix,
                suffix: suffix,
                showDecimals: true,
                style: AppTypography.priceMedium(
                  color: isAtOrBelowFloor ? AppColors.yellow : activeColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: activeColor,
              inactiveTrackColor: AppColors.surfaceDark,
              thumbColor: AppColors.primaryLight,
              overlayColor: activeColor.withValues(alpha: 0.18),
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 10,
                elevation: 4,
              ),
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              divisions: divisions,
              onChanged: (val) {
                onChanged(double.parse(val.toStringAsFixed(1)));
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${prefix ?? ''}${min.toStringAsFixed(0)}${suffix ?? ''}',
                style: AppTypography.caption,
              ),
              if (floorValue != null)
                Row(
                  children: [
                    Icon(
                      isAtOrBelowFloor
                          ? Icons.warning_amber_rounded
                          : Icons.shield_outlined,
                      size: 13,
                      color: isAtOrBelowFloor ? AppColors.yellow : AppColors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Floor: ${floorValue!.toStringAsFixed(0)}${suffix ?? ''}',
                      style: AppTypography.caption.copyWith(
                        color: isAtOrBelowFloor ? AppColors.yellow : AppColors.textMuted,
                        fontWeight: isAtOrBelowFloor ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              Text(
                '${prefix ?? ''}${max.toStringAsFixed(0)}${suffix ?? ''}',
                style: AppTypography.caption,
              ),
            ],
          ),
          if (isAtOrBelowFloor && floorLabel != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.yellow.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.yellow.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 14, color: AppColors.yellow),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      floorLabel!,
                      style: AppTypography.caption.copyWith(color: AppColors.yellow),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
