class AppSettings {
  final double priceIncrementAmount;
  final String priceIncrementType; // 'flat' or 'percent'
  final double alZaraMinMarginPercent; // Global floor guardrail (e.g. 10.0%)
  final bool enableRounding;
  final int roundingStep; // 1, 5, 10

  const AppSettings({
    this.priceIncrementAmount = 5.0,
    this.priceIncrementType = 'flat',
    this.alZaraMinMarginPercent = 10.0,
    this.enableRounding = false,
    this.roundingStep = 5,
  });

  AppSettings copyWith({
    double? priceIncrementAmount,
    String? priceIncrementType,
    double? alZaraMinMarginPercent,
    bool? enableRounding,
    int? roundingStep,
  }) {
    return AppSettings(
      priceIncrementAmount: priceIncrementAmount ?? this.priceIncrementAmount,
      priceIncrementType: priceIncrementType ?? this.priceIncrementType,
      alZaraMinMarginPercent: alZaraMinMarginPercent ?? this.alZaraMinMarginPercent,
      enableRounding: enableRounding ?? this.enableRounding,
      roundingStep: roundingStep ?? this.roundingStep,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'priceIncrementAmount': priceIncrementAmount,
      'priceIncrementType': priceIncrementType,
      'alZaraMinMarginPercent': alZaraMinMarginPercent,
      'enableRounding': enableRounding,
      'roundingStep': roundingStep,
    };
  }
}
