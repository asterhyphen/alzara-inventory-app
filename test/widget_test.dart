import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:al_zara_app/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('AlZaraApp boots first time with RolePicker screen and no default PIN hints',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      const ProviderScope(
        child: AlZaraApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('AL ZARA GROUP'), findsOneWidget);
    expect(find.text('Inventory & Pricing Suite'), findsOneWidget);
    expect(find.text('Admin'), findsOneWidget);
    expect(find.text('Staff'), findsOneWidget);

    // Verify Default PIN hints are completely removed
    expect(find.textContaining('Default PIN'), findsNothing);
  });

  testWidgets('AlZaraApp with saved role boots directly to dashboard without asking again',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'alzara_user_role': 'admin'});

    await tester.pumpWidget(
      const ProviderScope(
        child: AlZaraApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Role picker is bypassed
    expect(find.text('Select your operating profile'), findsNothing);
    // Main dashboard is loaded directly
    expect(find.text('Welcome Back'), findsOneWidget);
  });
}
