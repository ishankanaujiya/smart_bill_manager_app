import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:smart_bill_manager/core/notifications/notification_dispatcher.dart';
import 'package:smart_bill_manager/features/expenses/domain/entities/bill.dart';
import 'package:smart_bill_manager/features/expenses/domain/repositories/bill_repository.dart';
import 'package:smart_bill_manager/features/expenses/presentation/state/bill_providers.dart';

class _MockBillRepository extends Mock implements BillRepository {}

class _MockNotificationDispatcher extends Mock
    implements NotificationDispatcher {}

void main() {
  const creator = 'creator';
  const alice = 'alice';
  const bob = 'bob';
  const carol = 'carol';

  late _MockBillRepository billRepo;
  late _MockNotificationDispatcher dispatcher;
  late PaymentActionNotifier notifier;

  setUpAll(() {
    registerFallbackValue(NotificationType.billCreated);
    registerFallbackValue(<String>[]);
    registerFallbackValue(<String, String>{});
  });

  setUp(() {
    billRepo = _MockBillRepository();
    dispatcher = _MockNotificationDispatcher();
    notifier = PaymentActionNotifier(billRepo, dispatcher);
  });

  Bill buildBill(Map<String, ParticipantPayment> payments) => Bill(
        id: 'bill-1',
        groupId: 'group-1',
        groupName: 'Trip to Pokhara',
        title: 'Dinner',
        totalAmount: 400,
        splitMode: BillSplitMode.equal,
        participants: [
          for (final id in [creator, alice, bob, carol])
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

  /// Baseline where every member has paid in full, so each test can make
  /// only the participant under test outstanding.
  Map<String, ParticipantPayment> allPaid({
    Map<String, ParticipantPayment> overrides = const {},
  }) =>
      {
        for (final id in [creator, alice, bob, carol])
          id: const ParticipantPayment(
            status: ParticipantPaymentStatus.paid,
            amountPaid: 100,
          ),
        ...overrides,
      };

  void stubBill(Map<String, ParticipantPayment> payments) {
    when(() => billRepo.getBill('group-1', 'bill-1'))
        .thenAnswer((_) async => buildBill(payments));
  }

  void stubDispatch({bool delivered = true}) {
    when(() => dispatcher.dispatch(
          type: any(named: 'type'),
          targetUserIds: any(named: 'targetUserIds'),
          params: any(named: 'params'),
        )).thenAnswer((_) async => delivered);
  }

  group('PaymentActionNotifier.remindOutstandingParticipants', () {
    test('starts in the idle state', () {
      expect(notifier.state, isA<PaymentActionIdle>());
    });

    test('reminds only the unpaid and partially paid members', () async {
      stubDispatch();
      stubBill(allPaid(overrides: <String, ParticipantPayment>{
        alice: const ParticipantPayment(
          status: ParticipantPaymentStatus.unpaid,
        ),
        bob: const ParticipantPayment(
          status: ParticipantPaymentStatus.partiallyPaid,
          amountPaid: 50,
        ),
        creator: const ParticipantPayment(
          status: ParticipantPaymentStatus.unpaid,
        ),
      }));

      final result = await notifier.remindOutstandingParticipants(
        groupId: 'group-1',
        billId: 'bill-1',
      );

      expect(result, isTrue);
      expect(notifier.state, isA<PaymentActionSuccess>());
      expect(
        (notifier.state as PaymentActionSuccess).message,
        'Reminder sent to 2 members.',
      );

      final captured = verify(() => dispatcher.dispatch(
            type: captureAny(named: 'type'),
            targetUserIds: captureAny(named: 'targetUserIds'),
            params: captureAny(named: 'params'),
          )).captured;

      expect(captured[0], NotificationType.paymentReminder);
      expect(captured[1], [alice, bob]);
      expect(captured[2], containsPair('billTitle', 'Dinner'));
      expect(captured[2], containsPair('groupId', 'group-1'));
      expect(captured[2], containsPair('billId', 'bill-1'));
    });

    test('uses the singular message when only one member is reminded',
        () async {
      stubDispatch();
      stubBill(allPaid(overrides: <String, ParticipantPayment>{
        alice: const ParticipantPayment(
          status: ParticipantPaymentStatus.unpaid,
        ),
      }));

      await notifier.remindOutstandingParticipants(
        groupId: 'group-1',
        billId: 'bill-1',
      );

      expect(
        (notifier.state as PaymentActionSuccess).message,
        'Reminder sent to 1 member.',
      );
    });

    test('errors out when the proxy rejects the dispatch', () async {
      // e.g. the deployed proxy predates the `paymentReminder` template and
      // answers 400 — the creator must not be told the reminder was sent.
      stubDispatch(delivered: false);
      stubBill(allPaid(overrides: <String, ParticipantPayment>{
        alice: const ParticipantPayment(
          status: ParticipantPaymentStatus.unpaid,
        ),
      }));

      final result = await notifier.remindOutstandingParticipants(
        groupId: 'group-1',
        billId: 'bill-1',
      );

      expect(result, isFalse);
      expect(notifier.state, isA<PaymentActionError>());
      expect(
        (notifier.state as PaymentActionError).message,
        'Could not deliver the reminder. Please try again.',
      );
    });

    test('errors out and dispatches nothing when nobody is outstanding',
        () async {
      stubBill(allPaid(overrides: <String, ParticipantPayment>{
        alice: const ParticipantPayment(
          status: ParticipantPaymentStatus.paid,
          amountPaid: 100,
        ),
        bob: const ParticipantPayment(
          status: ParticipantPaymentStatus.requested,
        ),
      }));

      final result = await notifier.remindOutstandingParticipants(
        groupId: 'group-1',
        billId: 'bill-1',
      );

      expect(result, isFalse);
      expect(notifier.state, isA<PaymentActionError>());
      expect(
        (notifier.state as PaymentActionError).message,
        'Everyone has already paid.',
      );
      verifyNever(() => dispatcher.dispatch(
            type: any(named: 'type'),
            targetUserIds: any(named: 'targetUserIds'),
            params: any(named: 'params'),
          ));
    });

    test('errors out when the bill cannot be loaded', () async {
      when(() => billRepo.getBill('group-1', 'missing'))
          .thenAnswer((_) async => null);

      final result = await notifier.remindOutstandingParticipants(
        groupId: 'group-1',
        billId: 'missing',
      );

      expect(result, isFalse);
      expect(notifier.state, isA<PaymentActionError>());
      expect(
        (notifier.state as PaymentActionError).message,
        'Could not load this bill.',
      );
    });
  });
}
