import 'package:flutter_test/flutter_test.dart';

import 'package:smart_bill_manager/main.dart';

void main() {
  testWidgets('App renders welcome screen successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const SmartBillManagerApp());

    expect(find.text('Split expenses.'), findsOneWidget);
    expect(find.text('Stay friends.'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });
}
