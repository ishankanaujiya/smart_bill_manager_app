import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smart_bill_manager/features/expenses/presentation/widget/payment_options_card.dart';

/// eSewa ships two brand marks: a light-mode variant (dark artwork that reads
/// on light surfaces) and the original, which is used on dark surfaces.
void main() {
  /// Every asset path rendered by an [Image] currently in the tree.
  List<String> renderedAssetPaths(WidgetTester tester) => tester
      .widgetList<Image>(find.byType(Image))
      .map((image) => image.image)
      .whereType<AssetImage>()
      .map((provider) => provider.assetName)
      .toList();

  Future<void> pumpCard(WidgetTester tester, {required bool isDark}) async {
    final brightness = isDark ? Brightness.dark : Brightness.light;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(brightness: brightness),
        home: Scaffold(
          body: PaymentOptionsCard(
            paymentEntries: const [],
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF14B8A6),
              brightness: brightness,
            ),
            isDark: isDark,
            onAddMethod: (_) {},
            onRemoveMethod: (_) {},
            onPickQr: (_) async {},
            onBankNameChanged: (_) {},
            onAccountIdChanged: (_, __) {},
          ),
        ),
      ),
    );
    // Entrance animations are finite here, but avoid pumpAndSettle in case
    // the card hosts any perpetual animation.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  group('eSewa payment method logo', () {
    testWidgets('uses the light-mode mark in light mode', (tester) async {
      await pumpCard(tester, isDark: false);

      final assets = renderedAssetPaths(tester);
      expect(assets, contains('assets/images/esewa_light_mode.png'));
      expect(assets, isNot(contains('assets/images/esewa.png')));
    });

    testWidgets('uses the original mark in dark mode', (tester) async {
      await pumpCard(tester, isDark: true);

      final assets = renderedAssetPaths(tester);
      expect(assets, contains('assets/images/esewa.png'));
      expect(assets, isNot(contains('assets/images/esewa_light_mode.png')));
    });

    testWidgets('leaves the Khalti mark unchanged in both themes',
        (tester) async {
      for (final isDark in [false, true]) {
        await pumpCard(tester, isDark: isDark);
        expect(
          renderedAssetPaths(tester),
          contains('assets/images/khalti.png'),
          reason: 'isDark=$isDark',
        );
      }
    });
  });
}
