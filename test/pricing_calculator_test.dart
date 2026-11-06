import 'package:flutter_test/flutter_test.dart';
import 'package:al_zara_app/features/settings/domain/app_settings.dart';
import 'package:al_zara_app/features/pricing/domain/pricing_calculator.dart';

void main() {
  group('PricingCalculator Tests', () {
    test('Calculates selling price correctly from CP and margin %', () {
      // CP = 400, Margin = 21.25% => SP = 400 * 1.2125 = 485
      final sp = PricingCalculator.calculateSellingPrice(
        costPrice: 400.0,
        marginPercent: 21.25,
      );
      expect(sp, 485.0);
    });

    test('Calculates margin percentage correctly from CP and SP', () {
      final margin = PricingCalculator.calculateMarginPercent(
        costPrice: 400.0,
        sellingPrice: 485.0,
      );
      expect(margin, 21.25);
    });

    test('Al Zara discount price respects floor guardrail', () {
      const settings = AppSettings(alZaraMinMarginPercent: 10.0);

      // Raw discount margin is 5% which is BELOW the 10% floor
      // CP = 100, Floor price = 100 * 1.10 = 110
      final result = PricingCalculator.calculate(
        costPrice: 100.0,
        mrp: 150.0,
        marginPercent: 20.0,
        alZaraDiscountPercent: 5.0, // below 10% floor
        settings: settings,
      );

      expect(result.isFloorClamped, true);
      expect(result.alZaraDiscountPrice, 110.0);
      expect(result.minFloorPrice, 110.0);
    });

    test('Al Zara discount price uses higher margin when above floor', () {
      const settings = AppSettings(alZaraMinMarginPercent: 10.0);

      // Raw discount margin is 15% which is ABOVE the 10% floor
      // CP = 100 => AZP = 100 * 1.15 = 115
      final result = PricingCalculator.calculate(
        costPrice: 100.0,
        mrp: 150.0,
        marginPercent: 20.0,
        alZaraDiscountPercent: 15.0,
        settings: settings,
      );

      expect(result.isFloorClamped, false);
      expect(result.alZaraDiscountPrice, 115.0);
    });

    test('Detects when selling price exceeds MRP', () {
      const settings = AppSettings();

      // CP = 100, Margin = 60% => SP = 160, MRP = 150
      final result = PricingCalculator.calculate(
        costPrice: 100.0,
        mrp: 150.0,
        marginPercent: 60.0,
        alZaraDiscountPercent: 10.0,
        settings: settings,
      );

      expect(result.sellingPrice, 160.0);
      expect(result.exceedsMrp, true);
    });

    test('Rounds prices correctly when rounding is enabled', () {
      const settings = AppSettings(
        enableRounding: true,
        roundingStep: 5,
      );

      // CP = 100, Margin = 23% => Raw SP = 123 => Rounded to nearest 5 = 125
      final sp = PricingCalculator.calculateSellingPrice(
        costPrice: 100.0,
        marginPercent: 23.0,
        settings: settings,
      );

      expect(sp, 125.0);
    });

    test('Al Zara discounted trade price NEVER exceeds selling price', () {
      const settings = AppSettings(alZaraMinMarginPercent: 5.0);

      // CP = 100, Margin = 10% => SP = 110
      // User entered AZ discount % = 25% (which would be CP * 1.25 = 125)
      // AZ price must be strictly capped at SP (110)
      final result = PricingCalculator.calculate(
        costPrice: 100.0,
        mrp: 200.0,
        marginPercent: 10.0,
        alZaraDiscountPercent: 25.0,
        settings: settings,
      );

      expect(result.sellingPrice, 110.0);
      expect(result.alZaraDiscountPrice <= result.sellingPrice, true);
      expect(result.alZaraDiscountPrice, 110.0);
    });

    test('Prices round to 3 decimal places accurately', () {
      const settings = AppSettings();

      // CP = 100, Margin = 12.3456% => SP = 112.346
      final sp = PricingCalculator.calculateSellingPrice(
        costPrice: 100.0,
        marginPercent: 12.3456,
        settings: settings,
      );

      expect(sp, 112.346);
    });
  });
}
