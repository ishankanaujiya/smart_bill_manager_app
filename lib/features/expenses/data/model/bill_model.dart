import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/bill.dart';

/// Firestore data model for bills.
///
/// Bills are stored as documents inside the **subcollection**
/// `groups/{groupId}/bills`. This keeps every group's bills isolated
/// and queryable without scanning a global collection.
///
/// Document shape (snake_case, matching the security rules):
/// - `title`              : String
/// - `note`               : String?
/// - `total_bill_amount`  : double
/// - `bill_picture`       : String?  (Cloudinary secure_url)
/// - `date`               : Timestamp
/// - `split_mode`         : String   ('equal' | 'custom')
/// - `members`            : List<Map>  (participant snapshots)
/// - `splitted_amount`    : List<Map>  ({member_id, member_name, amount})
/// - `excluded_members`   : List of String  (UIDs)
/// - `payment_status`     : String   ('unpaid' | 'partially_paid' | 'paid')
/// - `real_expense_made_by`: Map?     (profile snapshot of who paid)
/// - `created_by`         : Map      (profile snapshot of the bill creator)
/// - `created_at`         : Timestamp (server)
/// - `updated_at`         : Timestamp (server)
/// - `group_name`         : String   (snapshot)
/// - `payment_methods`    : List of String  ('esewa' | 'khalti' | 'bank')
/// - `payment_qr_urls`    : `Map<String,String>`  (keyed by method name → Cloudinary URL)
/// - `selected_bank_name` : String?  (bank name when method includes 'bank')
/// - `payment_id`         : `Map<String,String>`  (keyed by method name → eSewa ID / Khalti ID / bank account number)
class BillModel {
  const BillModel._({
    required this.id,
    required this.groupId,
    required this.groupName,
    required this.title,
    required this.totalBillAmount,
    required this.splitMode,
    required this.members,
    required this.splittedAmount,
    required this.excludedMembers,
    required this.paymentStatus,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    required this.paymentMethods,
    required this.paymentQrUrls,
    this.note,
    this.billPicture,
    this.date,
    this.realExpenseMadeBy,
    this.selectedBankName,
    this.paymentIds = const {},
  });

  /// Firestore subcollection name — `bills` inside each group document.
  static const String collectionName = 'bills';

  final String id;
  final String groupId;
  final String groupName;
  final String title;
  final String? note;
  final double totalBillAmount;
  final String? billPicture;
  final DateTime? date;
  final String splitMode; // 'equal' | 'custom'
  final List<Map<String, dynamic>> members;
  final List<Map<String, dynamic>> splittedAmount;
  final List<String> excludedMembers;
  final String paymentStatus; // 'unpaid' | 'partially_paid' | 'paid'
  final Map<String, dynamic> createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? realExpenseMadeBy;
  final List<String> paymentMethods; // ['esewa', 'khalti', 'bank']
  final Map<String, String> paymentQrUrls; // method name → Cloudinary URL
  final String? selectedBankName;
  final Map<String, String> paymentIds; // method name → ID / account number

  /// Creates a [BillModel] from a Firestore document.
  factory BillModel.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    required String groupId,
  }) {
    final data = doc.data() ?? <String, dynamic>{};

    return BillModel._(
      id: doc.id,
      groupId: groupId,
      groupName: data['group_name'] as String? ?? '',
      title: data['title'] as String? ?? 'Untitled Bill',
      note: data['note'] as String?,
      totalBillAmount: (data['total_bill_amount'] as num?)?.toDouble() ?? 0.0,
      billPicture: data['bill_picture'] as String?,
      date: (data['date'] as Timestamp?)?.toDate(),
      splitMode: (data['split_mode'] as String?) == 'custom'
          ? 'custom'
          : 'equal',
      members: _normalizeMapList(data['members']),
      splittedAmount: _normalizeMapList(data['splitted_amount']),
      excludedMembers: _normalizeStringList(data['excluded_members']),
      paymentStatus: _parsePaymentStatus(data['payment_status']),
      createdBy: _normalizeMap(data['created_by']),
      createdAt:
          (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt:
          (data['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      realExpenseMadeBy: _normalizeNullableMap(data['real_expense_made_by']),
      paymentMethods: _normalizeStringList(data['payment_methods']),
      paymentQrUrls: _parseQrUrlMap(data['payment_qr_urls'], data['payment_methods']),
      selectedBankName: data['selected_bank_name'] as String?,
      paymentIds: _parsePaymentIdMap(data['payment_id'], data['payment_account_id'], data['payment_methods']),
    );
  }

  /// Creates a [BillModel] from a plain map (useful for testing).
  factory BillModel.fromMap(
    Map<String, dynamic> map, {
    required String id,
    required String groupId,
  }) {
    return BillModel._(
      id: id,
      groupId: groupId,
      groupName: map['group_name'] as String? ?? '',
      title: map['title'] as String? ?? 'Untitled Bill',
      note: map['note'] as String?,
      totalBillAmount:
          (map['total_bill_amount'] as num?)?.toDouble() ?? 0.0,
      billPicture: map['bill_picture'] as String?,
      date: (map['date'] as Timestamp?)?.toDate(),
      splitMode: (map['split_mode'] as String?) == 'custom'
          ? 'custom'
          : 'equal',
      members: _normalizeMapList(map['members']),
      splittedAmount: _normalizeMapList(map['splitted_amount']),
      excludedMembers: _normalizeStringList(map['excluded_members']),
      paymentStatus: _parsePaymentStatus(map['payment_status']),
      createdBy: _normalizeMap(map['created_by']),
      createdAt:
          (map['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt:
          (map['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      realExpenseMadeBy: _normalizeNullableMap(map['real_expense_made_by']),
      paymentMethods: _normalizeStringList(map['payment_methods']),
      paymentQrUrls: _parseQrUrlMap(map['payment_qr_urls'], map['payment_methods']),
      selectedBankName: map['selected_bank_name'] as String?,
      paymentIds: _parsePaymentIdMap(map['payment_id'], map['payment_account_id'], map['payment_methods']),
    );
  }

  /// Serializes to a Firestore-compatible map.
  ///
  /// Timestamps use [FieldValue.serverTimestamp] when [isNew] is true so
  /// the server sets them consistently. `updated_at` always uses server
  /// timestamp.
  Map<String, dynamic> toMap({bool isNew = false}) {
    return {
      'title': title,
      'note': note,
      'total_bill_amount': totalBillAmount,
      'bill_picture': billPicture,
      'date': date != null ? Timestamp.fromDate(date!) : FieldValue.serverTimestamp(),
      'split_mode': splitMode,
      'members': members,
      'splitted_amount': splittedAmount,
      'excluded_members': excludedMembers,
      'payment_status': paymentStatus,
      'real_expense_made_by': realExpenseMadeBy,
      'created_by': createdBy,
      'group_name': groupName,
      'created_at': isNew ? FieldValue.serverTimestamp() : createdAt,
      'updated_at': FieldValue.serverTimestamp(),
      'payment_methods': paymentMethods,
      'payment_qr_urls': paymentQrUrls,
      'selected_bank_name': selectedBankName,
      'payment_id': paymentIds,
    };
  }

  /// Converts to the domain entity.
  Bill toEntity() {
    return Bill(
      id: id,
      groupId: groupId,
      groupName: groupName,
      title: title,
      note: note,
      totalAmount: totalBillAmount,
      receiptPhotoUrl: billPicture,
      date: date,
      splitMode: splitMode == 'custom'
          ? BillSplitMode.custom
          : BillSplitMode.equal,
      participants: members.map(_toBillParticipant).toList(),
      createdBy: createdBy['id'] as String? ?? '',
      createdAt: createdAt,
      updatedAt: updatedAt,
      paymentStatus: _paymentStatusFromString(paymentStatus),
      realExpenseMadeBy: realExpenseMadeBy,
      excludedMemberIds: List<String>.of(excludedMembers),
      paymentMethods: paymentMethods
          .map(_paymentMethodFromString)
          .whereType<BillPaymentMethod>()
          .toList(),
      paymentQrUrls: Map<String, String>.of(paymentQrUrls),
      selectedBankName: selectedBankName,
      paymentIds: Map<String, String>.of(paymentIds),
    );
  }

  /// Creates a [BillModel] from a [Bill] entity.
  static BillModel fromEntity(Bill bill) {
    return BillModel._(
      id: bill.id,
      groupId: bill.groupId,
      groupName: bill.groupName,
      title: bill.title,
      note: bill.note,
      totalBillAmount: bill.totalAmount,
      billPicture: bill.receiptPhotoUrl,
      date: bill.date,
      splitMode: bill.splitMode == BillSplitMode.custom ? 'custom' : 'equal',
      members: bill.participants.map(_fromBillParticipant).toList(),
      splittedAmount: bill.splittedAmount,
      excludedMembers: List<String>.of(bill.excludedMemberIds),
      paymentStatus: _paymentStatusToString(bill.paymentStatus),
      createdBy: _creatorSnapshot(bill),
      createdAt: bill.createdAt,
      updatedAt: bill.updatedAt ?? bill.createdAt,
      realExpenseMadeBy: bill.realExpenseMadeBy,
      paymentMethods: bill.paymentMethods
          .map(_paymentMethodToString)
          .toList(),
      paymentQrUrls: Map<String, String>.of(bill.paymentQrUrls),
      selectedBankName: bill.selectedBankName,
      paymentIds: Map<String, String>.of(bill.paymentIds),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────

  /// Coerces a Firestore value into a list of strings.
  static List<String> _normalizeStringList(dynamic value) {
    if (value is! List) return [];
    return value.whereType<String>().toList(growable: false);
  }

  /// Parses `payment_qr_urls` into a method-name-keyed map.
  ///
  /// Supports both the new map format (`{esewa: url, ...}`) and the legacy
  /// list format (`[url1, url2, ...]` parallel to `payment_methods`). When
  /// the value is a list, it's zipped with [methodsRaw] to produce the map.
  static Map<String, String> _parseQrUrlMap(
    dynamic value,
    dynamic methodsRaw,
  ) {
    // New format: map.
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''));
    }
    // Legacy format: list parallel to payment_methods.
    if (value is List) {
      final methods = _normalizeStringList(methodsRaw);
      final urls = value.whereType<String>().toList();
      final map = <String, String>{};
      for (var i = 0; i < methods.length && i < urls.length; i++) {
        map[methods[i]] = urls[i];
      }
      return map;
    }
    return {};
  }

  /// Parses `payment_id` into a method-name-keyed map.
  ///
  /// Supports three scenarios:
  /// 1. New format: `payment_id` is a map (`{esewa: id, ...}`).
  /// 2. Legacy: `payment_id` is absent but `payment_account_id` (String?)
  ///    exists — it's assigned to the first (active) method.
  /// 3. Neither exists — returns an empty map.
  static Map<String, String> _parsePaymentIdMap(
    dynamic paymentIdMap,
    dynamic legacyAccountId,
    dynamic methodsRaw,
  ) {
    // New format: map.
    if (paymentIdMap is Map) {
      return paymentIdMap
          .map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''))
        ..removeWhere((_, v) => v.isEmpty);
    }
    // Legacy: single String? assigned to the active method.
    if (legacyAccountId is String && legacyAccountId.isNotEmpty) {
      final methods = _normalizeStringList(methodsRaw);
      if (methods.isNotEmpty) {
        return {methods.first: legacyAccountId};
      }
    }
    return {};
  }

  /// Coerces a Firestore value into a single map.
  static Map<String, dynamic> _normalizeMap(dynamic value) {
    if (value is! Map<String, dynamic>) return <String, dynamic>{};
    return value;
  }

  /// Coerces a Firestore value into a nullable map.
  static Map<String, dynamic>? _normalizeNullableMap(dynamic value) {
    if (value is! Map<String, dynamic>) return null;
    return value;
  }

  /// Coerces a Firestore value into a list of maps.
  static List<Map<String, dynamic>> _normalizeMapList(dynamic value) {
    if (value is! List) return [];
    return value
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
  }

  /// Converts a stored member map into a [BillParticipant] entity.
  static BillParticipant _toBillParticipant(Map<String, dynamic> map) {
    return BillParticipant(
      id: map['id'] as String? ?? '',
      fullName: map['full_name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      displayName: map['display_name'] as String?,
      profilePicture: map['profile_picture'] as String?,
      customShare: (map['custom_share'] as num?)?.toDouble() ?? 0.0,
      isIncluded: map['is_included'] as bool? ?? true,
    );
  }

  /// Converts a [BillParticipant] entity into a storable member map.
  static Map<String, dynamic> _fromBillParticipant(BillParticipant p) {
    return {
      'id': p.id,
      'full_name': p.fullName,
      'email': p.email,
      'display_name': p.displayName,
      'profile_picture': p.profilePicture,
      'custom_share': p.customShare,
      'is_included': p.isIncluded,
    };
  }

  /// Builds the `created_by` snapshot map from the bill's participants.
  ///
  /// The creator is identified by [Bill.createdBy] (their UID). We find
  /// their participant entry to snapshot their profile.
  static Map<String, dynamic> _creatorSnapshot(Bill bill) {
    final creator = bill.participants
        .cast<BillParticipant?>()
        .firstWhere((p) => p?.id == bill.createdBy, orElse: () => null);
    if (creator == null) {
      return {'id': bill.createdBy};
    }
    return {
      'id': creator.id,
      'full_name': creator.fullName,
      'email': creator.email,
      'display_name': creator.displayName,
      'profile_picture': creator.profilePicture,
    };
  }

  static String _paymentStatusToString(BillPaymentStatus status) {
    return switch (status) {
      BillPaymentStatus.unpaid => 'unpaid',
      BillPaymentStatus.partiallyPaid => 'partially_paid',
      BillPaymentStatus.paid => 'paid',
    };
  }

  static BillPaymentStatus _paymentStatusFromString(String? value) {
    return switch (value) {
      'paid' => BillPaymentStatus.paid,
      'partially_paid' => BillPaymentStatus.partiallyPaid,
      _ => BillPaymentStatus.unpaid,
    };
  }

  static String _parsePaymentStatus(dynamic value) {
    final str = value as String?;
    return switch (str) {
      'paid' => 'paid',
      'partially_paid' => 'partially_paid',
      _ => 'unpaid',
    };
  }

  static String _paymentMethodToString(BillPaymentMethod method) {
    return switch (method) {
      BillPaymentMethod.esewa => 'esewa',
      BillPaymentMethod.khalti => 'khalti',
      BillPaymentMethod.bank => 'bank',
    };
  }

  static BillPaymentMethod? _paymentMethodFromString(String value) {
    return switch (value) {
      'esewa' => BillPaymentMethod.esewa,
      'khalti' => BillPaymentMethod.khalti,
      'bank' => BillPaymentMethod.bank,
      _ => null,
    };
  }
}
