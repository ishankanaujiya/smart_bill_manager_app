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
}
