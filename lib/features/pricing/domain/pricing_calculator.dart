import '../../settings/domain/app_settings.dart';

class PricingCalculationResult {
  final double costPrice;
  final double mrp;
  final double marginPercent;
  final double sellingPrice;
  final double alZaraDiscountPercent;
  final double alZaraDiscountPrice;
  final double minFloorPrice;
  final bool isFloorClamped;
  final bool exceedsMrp;

  const PricingCalculationResult({
    required this.costPrice,
    required this.mrp,
    required this.marginPercent,
    required this.sellingPrice,
    required this.alZaraDiscountPercent,
    required this.alZaraDiscountPrice,
    required this.minFloorPrice,
    required this.isFloorClamped,
    required this.exceedsMrp,
  });
}

class PricingCalculator {
  /// Calculate selling price from cost price and margin percentage (rounded to 3 decimal places)
  static double calculateSellingPrice({
    required double costPrice,
    required double marginPercent,
    AppSettings settings = const AppSettings(),
  }) {
    if (costPrice <= 0) return 0.0;
    double sp = costPrice * (1.0 + (marginPercent / 100.0));
    if (settings.enableRounding && settings.roundingStep > 0) {
      sp = (sp / settings.roundingStep).round() * settings.roundingStep.toDouble();
    }
    return double.parse(sp.toStringAsFixed(3));
  }

  /// Calculate margin percentage from cost price and selling price (rounded to 3 decimal places)
  static double calculateMarginPercent({
    required double costPrice,
    required double sellingPrice,
  }) {
    if (costPrice <= 0) return 0.0;
    double margin = ((sellingPrice - costPrice) / costPrice) * 100.0;
    return double.parse(margin.toStringAsFixed(3));
  }

  /// Calculate Al Zara discount price guarded by minimum profit margin floor and capped by selling price
  static double calculateAlZaraPrice({
    required double costPrice,
    required double sellingPrice,
    required double discountMarginPercent,
    required double minMarginPercent,
    AppSettings settings = const AppSettings(),
  }) {
    if (costPrice <= 0) return 0.0;
    double rawPrice = costPrice * (1.0 + (discountMarginPercent / 100.0));
    double floorPrice = costPrice * (1.0 + (minMarginPercent / 100.0));
    double finalPrice = rawPrice < floorPrice ? floorPrice : rawPrice;

    // Hard cap: AZ discounted trade price can NEVER exceed the selling price
    if (sellingPrice > 0 && finalPrice > sellingPrice) {
      finalPrice = sellingPrice;
    }

    if (settings.enableRounding && settings.roundingStep > 0) {
      finalPrice = (finalPrice / settings.roundingStep).round() * settings.roundingStep.toDouble();
      if (sellingPrice > 0 && finalPrice > sellingPrice) {
        finalPrice = sellingPrice;
      }
    }
    return double.parse(finalPrice.toStringAsFixed(3));
  }

  /// Complete pricing calculation bundle with flags
  static PricingCalculationResult calculate({
    required double costPrice,
    required double mrp,
    required double marginPercent,
    required double alZaraDiscountPercent,
    required AppSettings settings,
  }) {
    final sp = calculateSellingPrice(
      costPrice: costPrice,
      marginPercent: marginPercent,
      settings: settings,
    );

    final floorPrice = costPrice * (1.0 + (settings.alZaraMinMarginPercent / 100.0));
    final rawAzp = costPrice * (1.0 + (alZaraDiscountPercent / 100.0));
    final isFloorClamped = rawAzp < floorPrice;

    final azp = calculateAlZaraPrice(
      costPrice: costPrice,
      sellingPrice: sp,
      discountMarginPercent: alZaraDiscountPercent,
      minMarginPercent: settings.alZaraMinMarginPercent,
      settings: settings,
    );

    final exceedsMrp = mrp > 0 && sp > mrp;

    return PricingCalculationResult(
      costPrice: double.parse(costPrice.toStringAsFixed(3)),
      mrp: double.parse(mrp.toStringAsFixed(3)),
      marginPercent: double.parse(marginPercent.toStringAsFixed(3)),
      sellingPrice: sp,
      alZaraDiscountPercent: double.parse(alZaraDiscountPercent.toStringAsFixed(3)),
      alZaraDiscountPrice: azp,
      minFloorPrice: double.parse(floorPrice.toStringAsFixed(3)),
      isFloorClamped: isFloorClamped,
      exceedsMrp: exceedsMrp,
    );
  }
}
