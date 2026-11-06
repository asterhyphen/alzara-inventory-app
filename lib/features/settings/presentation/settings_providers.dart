import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/app_settings.dart';

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(const AppSettings());

  void updateSettings(AppSettings newSettings) {
    state = newSettings;
  }

  void setIncrementAmount(double amount) {
    state = state.copyWith(priceIncrementAmount: amount, priceIncrementType: 'flat');
  }

  void toggleRounding(bool enabled) {
    state = state.copyWith(enableRounding: enabled);
  }

  void setMinMargin(double percent) {
    state = state.copyWith(alZaraMinMarginPercent: percent);
  }
}

final settingsNotifierProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier();
});
