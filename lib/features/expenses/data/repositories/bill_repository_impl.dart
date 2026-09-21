import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/bill.dart';
import '../../domain/repositories/bill_repository.dart';
import '../model/bill_model.dart';

/// Firestore implementation of [BillRepository].
///
/// Bills are stored as documents inside the subcollection
/// `groups/{groupId}/bills`. This class manages all reads and writes
/// against that subcollection.
class BillRepositoryImpl implements BillRepository {
  BillRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Returns the `bills` subcollection reference for the given [groupId].
  CollectionReference<Map<String, dynamic>> _billsCollection(String groupId) =>
      _firestore
          .collection('groups')
          .doc(groupId)
          .collection(BillModel.collectionName);

  @override
  Future<Bill> createBill(Bill bill) async {
    final model = BillModel.fromEntity(bill);
    final docRef =
        await _billsCollection(bill.groupId).add(model.toMap(isNew: true));

    // Read the document back so the server-set timestamps and the
    // generated document ID are reflected in the returned entity.
    final snapshot = await docRef.get();
    return BillModel.fromDocument(snapshot, groupId: bill.groupId).toEntity();
  }

  @override
  Future<Bill?> getBill(String groupId, String billId) async {
    final doc = await _billsCollection(groupId).doc(billId).get();
    if (!doc.exists) return null;
    return BillModel.fromDocument(doc, groupId: groupId).toEntity();
  }

  @override
  Future<List<Bill>> getBillsForGroup(String groupId) async {
    final snapshot = await _billsCollection(groupId)
        .orderBy('created_at', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => BillModel.fromDocument(doc, groupId: groupId).toEntity())
        .toList();
  }

  @override
  Stream<List<Bill>> watchBillsForGroup(String groupId) {
    return _billsCollection(groupId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                BillModel.fromDocument(doc, groupId: groupId).toEntity())
            .toList());
  }

  @override
  Future<void> updateBill(Bill bill) async {
    final model = BillModel.fromEntity(bill);
    // Only write the mutable fields; keep created_at untouched.
    await _billsCollection(bill.groupId).doc(bill.id).set({
      'updated_at': FieldValue.serverTimestamp(),
      'title': model.title,
      'note': model.note,
      'total_bill_amount': model.totalBillAmount,
      'bill_picture': model.billPicture,
      'date': model.date != null
          ? Timestamp.fromDate(model.date!)
          : FieldValue.serverTimestamp(),
      'split_mode': model.splitMode,
      'members': model.members,
      'splitted_amount': model.splittedAmount,
      'excluded_members': model.excludedMembers,
      'payment_status': model.paymentStatus,
      'real_expense_made_by': model.realExpenseMadeBy,
    }, SetOptions(merge: true));
  }

  @override
  Future<void> updatePaymentStatus(
    String groupId,
    String billId,
    BillPaymentStatus status,
  ) async {
    final statusStr = switch (status) {
      BillPaymentStatus.unpaid => 'unpaid',
      BillPaymentStatus.partiallyPaid => 'partially_paid',
      BillPaymentStatus.paid => 'paid',
    };

    await _billsCollection(groupId).doc(billId).set({
      'payment_status': statusStr,
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Stream<Bill?> watchBill(String groupId, String billId) {
    return _billsCollection(groupId)
        .doc(billId)
        .snapshots()
        .map((doc) => doc.exists
            ? BillModel.fromDocument(doc, groupId: groupId).toEntity()
            : null);
  }

  @override
  Future<void> requestParticipantPayment({
    required String groupId,
    required String billId,
    required String memberId,
    required PaymentRequestType requestType,
    required double requestedAmount,
  }) async {
    final paymentMap = <String, dynamic>{
      'status': 'requested',
      'request_type': requestType == PaymentRequestType.paid
          ? 'paid'
          : 'partially',
      'requested_amount': requestedAmount,
      'amount_paid': 0.0,
      'requested_at': FieldValue.serverTimestamp(),
    };

    await _billsCollection(groupId).doc(billId).set({
      'participant_payments': {memberId: paymentMap},
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> verifyParticipantPayment({
    required String groupId,
    required String billId,
    required String memberId,
    required bool approved,
    required double receivedAmount,
    required String verifiedBy,
  }) async {
    // Read the current bill so we can recompute the aggregate payment
    // status from every participant's state after this verification.
    final doc = await _billsCollection(groupId).doc(billId).get();
    if (!doc.exists) return;
    final bill =
        BillModel.fromDocument(doc, groupId: groupId).toEntity();

    final share = bill.shareFor(memberId);
    final String newStatusStr;
    if (!approved) {
      newStatusStr = 'rejected';
    } else {
      newStatusStr = receivedAmount >= share - 0.005 ? 'paid' : 'partially_paid';
    }

    final paymentMap = <String, dynamic>{
      'status': newStatusStr,
      'amount_paid': approved ? receivedAmount : 0.0,
      'verified_at': FieldValue.serverTimestamp(),
      'verified_by': verifiedBy,
    };

    // Build the merged participant payments map (existing + this update)
    // so we can recompute the bill-level payment_status.
    final updatedPayments = Map<String, ParticipantPayment>.from(
      bill.participantPayments,
    );
    final existing = bill.paymentFor(memberId);
    updatedPayments[memberId] = existing.copyWith(
      status: newStatusStr == 'paid'
          ? ParticipantPaymentStatus.paid
          : newStatusStr == 'partially_paid'
              ? ParticipantPaymentStatus.partiallyPaid
              : ParticipantPaymentStatus.rejected,
      amountPaid: approved ? receivedAmount : 0.0,
      verifiedAt: DateTime.now(),
      verifiedBy: verifiedBy,
    );

    final recomputedBill = bill.copyWith(
      participantPayments: updatedPayments,
    );
    final aggregateStatus =
        _billPaymentStatusToString(recomputedBill.computedPaymentStatus);

    await _billsCollection(groupId).doc(billId).set({
      'participant_payments': {memberId: paymentMap},
      'payment_status': aggregateStatus,
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Maps a [BillPaymentStatus] to its Firestore string.
  static String _billPaymentStatusToString(BillPaymentStatus status) {
    return switch (status) {
      BillPaymentStatus.unpaid => 'unpaid',
      BillPaymentStatus.partiallyPaid => 'partially_paid',
      BillPaymentStatus.paid => 'paid',
    };
  }

  @override
  Future<void> deleteBill(String groupId, String billId) async {
    await _billsCollection(groupId).doc(billId).delete();
  }
}
