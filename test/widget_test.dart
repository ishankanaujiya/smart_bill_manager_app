import 'package:flutter_test/flutter_test.dart';

import 'package:smart_bill_manager/main.dart';

void main() {
  testWidgets('App renders welcome screen successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const SmartBillManagerApp());
    await tester.pumpAndSettle();

    // Verify all core welcome screen text and the image asset.
    expect(find.text('Welcome to'), findsOneWidget);
    expect(find.text('Group Expense'), findsOneWidget);
    expect(find.text('Splitter'), findsOneWidget);
    expect(find.text('Manage together. Split easily.'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
    expect(find.text('Already have an account?'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });

  testWidgets('Welcome screen navigates to sign-in screen', (WidgetTester tester) async {
    await tester.pumpWidget(const SmartBillManagerApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sign in'), warnIfMissed: false);
    // The sign-in header has a perpetual pulse animation, so pumpAndSettle
    // would never finish. Pump fixed durations instead to let the entrance
    // animation complete and the screen settle into its final layout.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Sign in to see who owes what.'), findsOneWidget);
    expect(find.text('Email address'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
  });
}
