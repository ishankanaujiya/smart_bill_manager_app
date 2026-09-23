import 'package:flutter_test/flutter_test.dart';

import 'package:smart_bill_manager/features/expenses/domain/entities/bill.dart';

void main() {
  const creator = 'creator';
  const alice = 'alice';
  const bob = 'bob';
  const carol = 'carol';
  const dave = 'dave';
  const erin = 'erin';

  BillParticipant participant(String id, {bool isIncluded = true}) =>
      BillParticipant(
        id: id,
        fullName: 'Member $id',
        email: '$id@example.com',
        isIncluded: isIncluded,
      );

  Bill buildBill(Map<String, ParticipantPayment> payments) => Bill(
        id: 'bill-1',
        groupId: 'group-1',
        groupName: 'Trip to Pokhara',
        title: 'Dinner',
        totalAmount: 500,
        splitMode: BillSplitMode.equal,
        participants: [
          participant(creator),
          participant(alice),
          participant(bob),
          participant(carol),
          participant(dave),
          participant(erin, isIncluded: false),
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
        for (final id in [creator, alice, bob, carol, dave, erin])
          id: const ParticipantPayment(
            status: ParticipantPaymentStatus.paid,
            amountPaid: 100,
          ),
        ...overrides,
      };

  group('Bill.remindableParticipants', () {
    test('includes unpaid and partially paid participants', () {
      final bill = buildBill(allPaid(overrides: {
        alice: const ParticipantPayment(
          status: ParticipantPaymentStatus.unpaid,
        ),
        bob: const ParticipantPayment(
          status: ParticipantPaymentStatus.partiallyPaid,
          amountPaid: 20,
        ),
      }));

      expect(bill.remindableParticipants.map((p) => p.id), [alice, bob]);
    });

    test('excludes participants who have paid in full', () {
      expect(buildBill(allPaid()).remindableParticipants, isEmpty);
    });

    test('excludes participants with a pending or rejected request', () {
      final bill = buildBill(allPaid(overrides: {
        alice: const ParticipantPayment(
          status: ParticipantPaymentStatus.requested,
        ),
        bob: const ParticipantPayment(
          status: ParticipantPaymentStatus.rejected,
        ),
      }));

      expect(bill.remindableParticipants, isEmpty);
    });

    test('excludes the creator even when their own share is unpaid', () {
      final bill = buildBill(allPaid(overrides: {
        creator: const ParticipantPayment(
          status: ParticipantPaymentStatus.unpaid,
        ),
      }));

      expect(bill.remindableParticipants, isEmpty);
    });

    test('excludes participants who are not included in the split', () {
      final bill = buildBill(allPaid(overrides: {
        erin: const ParticipantPayment(
          status: ParticipantPaymentStatus.unpaid,
        ),
      }));

      expect(bill.remindableParticipants, isEmpty);
    });

    test('treats participants with no payment record as unpaid', () {
      expect(
        buildBill(const {}).remindableParticipants.map((p) => p.id),
        [alice, bob, carol, dave],
      );
    });
  });
}
