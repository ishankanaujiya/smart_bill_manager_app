import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:smart_bill_manager/features/expenses/domain/entities/bill.dart';
import 'package:smart_bill_manager/features/expenses/domain/repositories/bill_repository.dart';
import 'package:smart_bill_manager/features/expenses/presentation/state/bill_providers.dart';
import 'package:smart_bill_manager/features/expenses/presentation/view/bill_details_screen.dart';

class _MockBillRepository extends Mock implements BillRepository {}

void main() {
  const creator = 'creator';
  const alice = 'alice';
  const bob = 'bob';

  Bill buildBill(Map<String, ParticipantPayment> payments) => Bill(
        id: 'bill-1',
        groupId: 'group-1',
        groupName: 'Trip to Pokhara',
        title: 'Dinner',
        totalAmount: 300,
        splitMode: BillSplitMode.equal,
        participants: [
          for (final id in [creator, alice, bob])
            BillParticipant(
              id: id,
              fullName: 'Member $id',
              email: '$id@example.com',
            ),
        ],
        createdBy: creator,
        createdAt: DateTime(2026, 1, 1),
        participantPayments: payments,
      );

  Map<String, ParticipantPayment> allPaid({
    Map<String, ParticipantPayment> overrides = const {},
  }) =>
      {
        for (final id in [creator, alice, bob])
          id: const ParticipantPayment(
            status: ParticipantPaymentStatus.paid,
            amountPaid: 100,
          ),
        ...overrides,
      };

  /// Pumps the bill details screen past its skeleton shimmer.
  ///
  /// The screen (and the payment progress bar) run perpetual `repeat()`
  /// animations, so `pumpAndSettle` would never complete — fixed-duration
  /// pumps are used instead.
  Future<void> pumpScreen(
    WidgetTester tester, {
    required Bill bill,
    required String currentUserId,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          billRepositoryProvider.overrideWithValue(_MockBillRepository()),
          billStreamProvider((groupId: bill.groupId, billId: bill.id))
              .overrideWith((ref) => Stream<Bill?>.value(bill)),
        ],
        child: MaterialApp(
          // The test environment has no Inter font, so text is measured with
          // the wider default test font — enough to overflow two pre-existing
          // fixed-width boxes in the participant table (the 72px Status column
          // and the status badge). Shrinking the text scale keeps the layout
          // under test identical without masking any real exception.
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(0.7)),
            child: child!,
          ),
          home: BillDetailsScreen(bill: bill, currentUserId: currentUserId),
        ),
      ),
    );

    // Skip past the skeleton (400ms) and the AnimatedSwitcher (300ms).
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 400));
  }

  group('BillDetailsScreen reminder button', () {
    testWidgets('creator sees the button when members still owe their share',
        (tester) async {
      await pumpScreen(
        tester,
        bill: buildBill(allPaid(overrides: <String, ParticipantPayment>{
          alice: const ParticipantPayment(
            status: ParticipantPaymentStatus.unpaid,
          ),
          bob: const ParticipantPayment(
            status: ParticipantPaymentStatus.partiallyPaid,
            amountPaid: 20,
          ),
        })),
        currentUserId: creator,
      );

      expect(find.text('Remind 2 members'), findsOneWidget);
    });

    testWidgets('creator does not see the button when everyone has paid',
        (tester) async {
      await pumpScreen(
        tester,
        bill: buildBill(allPaid()),
        currentUserId: creator,
      );

      expect(find.textContaining('Remind'), findsNothing);
    });

    testWidgets('non-creator members never see the button', (tester) async {
      await pumpScreen(
        tester,
        bill: buildBill(allPaid(overrides: <String, ParticipantPayment>{
          alice: const ParticipantPayment(
            status: ParticipantPaymentStatus.unpaid,
          ),
        })),
        currentUserId: alice,
      );

      expect(find.textContaining('Remind'), findsNothing);
    });

    testWidgets('tapping the button opens the confirmation dialog',
        (tester) async {
      await pumpScreen(
        tester,
        bill: buildBill(allPaid(overrides: <String, ParticipantPayment>{
          alice: const ParticipantPayment(
            status: ParticipantPaymentStatus.unpaid,
          ),
        })),
        currentUserId: creator,
      );

      await tester.tap(find.text('Remind 1 member'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final dialog = find.byType(AlertDialog);
      expect(find.text('Send Reminder'), findsOneWidget);
      expect(find.text('Send a payment reminder to 1 member?'), findsOneWidget);
      expect(
        find.descendant(of: dialog, matching: find.text('Member alice')),
        findsOneWidget,
      );
      expect(find.text('Send'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });
  });
}
