import 'package:flutter_test/flutter_test.dart';

import 'package:smart_bill_manager/main.dart';

void main() {
  testWidgets('App renders showcase screen successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const SmartBillManagerApp());
    await tester.pumpAndSettle();

    // App bar title and subtitle
    expect(find.text('Design System'), findsOneWidget);
    expect(find.text('Showcase — Light Mode'), findsOneWidget);

    // First showcase section is always rendered at the top
    expect(find.text('Color Palette'), findsOneWidget);
  });

  testWidgets('Theme toggle switches between light and dark mode',
      (WidgetTester tester) async {
    await tester.pumpWidget(const SmartBillManagerApp());
    await tester.pumpAndSettle();

    // Starts in light mode
    expect(find.text('Showcase — Light Mode'), findsOneWidget);

    // Tap the theme-toggle icon button in the app bar
    final toggle = find.byTooltip('Switch to dark mode');
    expect(toggle, findsOneWidget);
    await tester.tap(toggle);
    await tester.pumpAndSettle();

    // Now in dark mode
    expect(find.text('Showcase — Dark Mode'), findsOneWidget);
  });
}
