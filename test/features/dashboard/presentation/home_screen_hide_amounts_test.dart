import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smart_bill_manager/features/auth/presentation/state/auth_providers.dart';
import 'package:smart_bill_manager/features/dashboard/presentation/view/home_screen.dart';
import 'package:smart_bill_manager/features/expenses/presentation/state/bill_providers.dart';
import 'package:smart_bill_manager/features/groups/domain/entities/group.dart';
import 'package:smart_bill_manager/features/groups/presentation/state/group_providers.dart';
import 'package:smart_bill_manager/features/notifications/presentation/state/notification_providers.dart';

void main() {
  Widget wrap() {
    return ProviderScope(
      overrides: [
        currentAppUserProvider.overrideWith((ref) async => null),
        currentUidProvider.overrideWithValue('test-uid'),
        groupsForCurrentUserProvider.overrideWith(
          (ref) => Stream.value(<Group>[]),
        ),
        userBalanceProvider.overrideWithValue(
          const AsyncValue.data(
            UserBalance(
              youAreOwed: 1250,
              youOwe: 500,
              youAreOwedGroupCount: 2,
              youOweGroupCount: 1,
            ),
          ),
        ),
        unreadNotificationCountProvider.overrideWithValue(0),
      ],
      child: const MaterialApp(home: Scaffold(body: HomeScreen())),
    );
  }

  /// The screen runs perpetual `repeat()` animations, so `pumpAndSettle`
  /// would never complete — fixed-duration pumps are used instead.
  Future<void> settle(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 1200));
  }

  testWidgets('amounts are visible by default', (tester) async {
    await tester.pumpWidget(wrap());
    await settle(tester);

    expect(find.text('Rs. 1,250'), findsOneWidget); // You're Owed
    expect(find.text('Rs. 500'), findsOneWidget); // You Owe
    expect(find.text('Rs. 750'), findsNWidgets(2)); // hero card + stat card
    expect(find.byIcon(Icons.remove_red_eye_outlined), findsOneWidget);
  });

  testWidgets('eye button hides, then re-shows, all four amounts',
      (tester) async {
    await tester.pumpWidget(wrap());
    await settle(tester);

    // Hide.
    await tester.tap(find.byIcon(Icons.remove_red_eye_outlined));
    await tester.pump();

    expect(find.textContaining('••'), findsNWidgets(4));
    expect(find.text('Rs. 1,250'), findsNothing);
    expect(find.text('Rs. 500'), findsNothing);
    expect(find.text('Rs. 750'), findsNothing);
    expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);

    // Show again.
    await tester.tap(find.byIcon(Icons.visibility_off_outlined));
    await tester.pump();

    expect(find.textContaining('••'), findsNothing);
    expect(find.text('Rs. 1,250'), findsOneWidget);
    expect(find.text('Rs. 500'), findsOneWidget);
    expect(find.text('Rs. 750'), findsNWidgets(2));
    expect(find.byIcon(Icons.remove_red_eye_outlined), findsOneWidget);
  });
}
