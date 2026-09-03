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
  Future<void> deleteBill(String groupId, String billId) async {
    await _billsCollection(groupId).doc(billId).delete();
  }
}
