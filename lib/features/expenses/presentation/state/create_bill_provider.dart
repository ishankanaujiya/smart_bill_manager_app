import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_constants.dart';
import '../../../groups/domain/entities/group.dart';
import '../../domain/entities/bill.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Create-bill state
// ─────────────────────────────────────────────────────────────────────────────

/// State produced by the create-bill operation.
sealed class CreateBillState {
  const CreateBillState();
}

class CreateBillIdle extends CreateBillState {
  const CreateBillIdle();
}

class CreateBillLoading extends CreateBillState {
  const CreateBillLoading();
}

/// Returned when a [Bill] has been successfully built from the form data.
class CreateBillSuccess extends CreateBillState {
  const CreateBillSuccess(this.bill);
  final Bill bill;
}

class CreateBillError extends CreateBillState {
  const CreateBillError(this.message);
  final String message;
}

// ─────────────────────────────────────────────────────────────────────────────
// Immutable form model held by the notifier
// ─────────────────────────────────────────────────────────────────────────────

/// Holds the local state for a single payment method entry on the form.
class PaymentMethodEntry {
  const PaymentMethodEntry({
    required this.method,
    this.qrPhotoPath,
    this.bankName,
  });

  final BillPaymentMethod method;

  /// Local file path of the picked QR code image (before upload).
  final String? qrPhotoPath;

  /// Selected bank name (only relevant for [BillPaymentMethod.bank]).
  final String? bankName;

  PaymentMethodEntry copyWith({
    BillPaymentMethod? method,
    Object? qrPhotoPath = _kPaySentinel,
    Object? bankName = _kPaySentinel,
  }) {
    return PaymentMethodEntry(
      method: method ?? this.method,
      qrPhotoPath: qrPhotoPath == _kPaySentinel
          ? this.qrPhotoPath
          : qrPhotoPath as String?,
      bankName: bankName == _kPaySentinel
          ? this.bankName
          : bankName as String?,
    );
  }
}

const Object _kPaySentinel = Object();

class CreateBillFormState {
  const CreateBillFormState({
    this.amount = 0.0,
    this.rawAmountText = '',
    this.title = '',
    this.note = '',
    this.date,
    this.receiptPhotoPath,
    this.splitMode = BillSplitMode.equal,
    this.participants = const [],
    this.amountError,
    this.participantsError,
    this.customSplitError,
    this.paymentEntries = const [],
    this.uploadingQrMethod,
    this.titleError,
    this.noteError,
    this.dateError,
    this.paymentMethodError,
  });

  final double amount;

  /// The raw text the user typed, used to drive the display field without
  /// double-converting from double → String → double.
  final String rawAmountText;

  final String title;
  final String note;
  final DateTime? date;
  final String? receiptPhotoPath;
  final BillSplitMode splitMode;
  final List<BillParticipant> participants;

  // Inline validation messages.
  final String? amountError;
  final String? participantsError;
  final String? customSplitError;
  final String? titleError;
  final String? noteError;
  final String? dateError;
  final String? paymentMethodError;

  /// Payment method entries chosen by the user.
  final List<PaymentMethodEntry> paymentEntries;

  /// The payment method currently being uploaded (null = none).
  /// This is per-method so only the relevant entry shows a loading state.
  final BillPaymentMethod? uploadingQrMethod;

  // ── Computed ────────────────────────────────────────────────────────────

  List<BillParticipant> get includedParticipants =>
      participants.where((p) => p.isIncluded).toList();

  int get includedCount => includedParticipants.length;

  double get perPersonAmount =>
      includedCount > 0 ? amount / includedCount : 0.0;

  /// The custom-split sum total (only used when splitMode == custom).
  double get customSharesTotal =>
      participants.fold(0.0, (sum, p) => sum + (p.isIncluded ? p.customShare : 0.0));

  /// Whether the form may proceed to the review sheet.
  bool get canReview {
    if (amount <= 0) return false;
    if (includedCount == 0) return false;
    if (splitMode == BillSplitMode.custom) {
      final diff = (customSharesTotal - amount).abs();
      if (diff > AppConstants.splitRoundingTolerance) return false;
    }
    // Quick Info required fields (except Add Photo).
    if (title.trim().isEmpty) return false;
    if (note.trim().isEmpty) return false;
    if (date == null) return false;
    // At least one payment option is required.
    if (paymentEntries.isEmpty) return false;
    return true;
  }

  CreateBillFormState copyWith({
    double? amount,
    String? rawAmountText,
    String? title,
    String? note,
    Object? date = _kSentinel,
    Object? receiptPhotoPath = _kSentinel,
    BillSplitMode? splitMode,
    List<BillParticipant>? participants,
    Object? amountError = _kSentinel,
    Object? participantsError = _kSentinel,
    Object? customSplitError = _kSentinel,
    List<PaymentMethodEntry>? paymentEntries,
    Object? uploadingQrMethod = _kSentinel,
    Object? titleError = _kSentinel,
    Object? noteError = _kSentinel,
    Object? dateError = _kSentinel,
    Object? paymentMethodError = _kSentinel,
  }) {
    return CreateBillFormState(
      amount: amount ?? this.amount,
      rawAmountText: rawAmountText ?? this.rawAmountText,
      title: title ?? this.title,
      note: note ?? this.note,
      date: date == _kSentinel ? this.date : date as DateTime?,
      receiptPhotoPath: receiptPhotoPath == _kSentinel
          ? this.receiptPhotoPath
          : receiptPhotoPath as String?,
      splitMode: splitMode ?? this.splitMode,
      participants: participants ?? this.participants,
      amountError: amountError == _kSentinel
          ? this.amountError
          : amountError as String?,
      participantsError: participantsError == _kSentinel
          ? this.participantsError
          : participantsError as String?,
      customSplitError: customSplitError == _kSentinel
          ? this.customSplitError
          : customSplitError as String?,
      paymentEntries: paymentEntries ?? this.paymentEntries,
      uploadingQrMethod: uploadingQrMethod == _kSentinel
          ? this.uploadingQrMethod
          : uploadingQrMethod as BillPaymentMethod?,
      titleError: titleError == _kSentinel
          ? this.titleError
          : titleError as String?,
      noteError: noteError == _kSentinel
          ? this.noteError
          : noteError as String?,
      dateError: dateError == _kSentinel
          ? this.dateError
          : dateError as String?,
      paymentMethodError: paymentMethodError == _kSentinel
          ? this.paymentMethodError
          : paymentMethodError as String?,
    );
  }
}

const Object _kSentinel = Object();

// ─────────────────────────────────────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────────────────────────────────────

/// Manages the form state for the "Create Bill" screen.
///
/// Accepts the [Group] on construction so the participant list can be
/// pre-populated from the group's members.
class CreateBillNotifier extends StateNotifier<CreateBillFormState> {
  CreateBillNotifier({
    required Group group,
    required String currentUserId,
  }) : super(const CreateBillFormState()) {
    _initParticipants(group, currentUserId);
  }

  void _initParticipants(Group group, String currentUserId) {
    final participants = group.members
        .map(
          (m) => BillParticipant(
            id: m.id,
            fullName: m.fullName,
            email: m.email,
            displayName: m.displayName,
            profilePicture: m.profilePicture,
            isCurrentUser: m.id == currentUserId,
            isIncluded: true,
          ),
        )
        .toList();

    // Ensure current user is always first.
    participants.sort((a, b) {
      if (a.isCurrentUser) return -1;
      if (b.isCurrentUser) return 1;
      return 0;
    });

    state = state.copyWith(participants: participants);
  }

  // ── Setters ──────────────────────────────────────────────────────────────

  void setAmount(double amount, String rawText) {
    state = state.copyWith(
      amount: amount,
      rawAmountText: rawText,
      amountError: amount <= 0 && rawText.isNotEmpty
          ? 'Please enter a valid amount greater than zero.'
          : null,
    );
  }

  void setTitle(String title) =>
      state = state.copyWith(title: title, titleError: null);

  void setNote(String note) =>
      state = state.copyWith(note: note, noteError: null);

  void setDate(DateTime date) =>
      state = state.copyWith(date: date, dateError: null);

  void clearDate() => state = state.copyWith(date: null);

  void setReceiptPhoto(String? path) =>
      state = state.copyWith(receiptPhotoPath: path);

  // ── Payment methods ──────────────────────────────────────────────────────

  /// Switches the active payment method to [method].
  ///
  /// If the method was previously selected (and has a QR photo or bank
  /// name), its existing entry is preserved and moved to the front so the
  /// user doesn't lose uploaded data when switching back and forth.
  /// Other entries are kept in the list for data retention but only the
  /// first (active) one is shown in the UI.
  void addPaymentMethod(BillPaymentMethod method) {
    final existing = state.paymentEntries
        .where((e) => e.method == method)
        .toList();
    final entry = existing.isNotEmpty
        ? existing.first
        : PaymentMethodEntry(method: method);
    final rest = state.paymentEntries
        .where((e) => e.method != method)
        .toList();
    state = state.copyWith(
      paymentEntries: [entry, ...rest],
      paymentMethodError: null,
    );
  }

  /// Removes a payment method entry.
  void removePaymentMethod(BillPaymentMethod method) {
    state = state.copyWith(
      paymentEntries:
          state.paymentEntries.where((e) => e.method != method).toList(),
    );
  }

  /// Updates the QR code local file path for the given payment method.
  void setQrPhotoPath(BillPaymentMethod method, String? path) {
    state = state.copyWith(
      paymentEntries: state.paymentEntries.map((e) {
        if (e.method == method) return e.copyWith(qrPhotoPath: path);
        return e;
      }).toList(),
    );
  }

  /// Updates the selected bank name for a bank payment method entry.
  void setBankName(String? bankName) {
    state = state.copyWith(
      paymentEntries: state.paymentEntries.map((e) {
        if (e.method == BillPaymentMethod.bank) {
          return e.copyWith(bankName: bankName);
        }
        return e;
      }).toList(),
    );
  }

  void setUploadingQr(BillPaymentMethod? method) =>
      state = state.copyWith(uploadingQrMethod: method);

  void setSplitMode(BillSplitMode mode) {
    state = state.copyWith(splitMode: mode, customSplitError: null);
    _validateCustomSplit();
  }

  void toggleParticipant(String participantId) {
    final updated = state.participants.map((p) {
      if (p.id == participantId) return p.copyWith(isIncluded: !p.isIncluded);
      return p;
    }).toList();

    state = state.copyWith(
      participants: updated,
      participantsError: null,
    );
    _validateCustomSplit();
  }

  void setCustomShare(String participantId, double share) {
    final updated = state.participants.map((p) {
      if (p.id == participantId) return p.copyWith(customShare: share);
      return p;
    }).toList();
    state = state.copyWith(participants: updated);
    _validateCustomSplit();
  }

  // ── Validation ────────────────────────────────────────────────────────────

  void _validateCustomSplit() {
    if (state.splitMode != BillSplitMode.custom) return;
    if (state.amount <= 0) return;

    final diff = (state.customSharesTotal - state.amount).abs();
    if (diff > AppConstants.splitRoundingTolerance) {
      final remaining = state.amount - state.customSharesTotal;
      state = state.copyWith(
        customSplitError:
            '${remaining > 0 ? "Remaining" : "Over by"} '
            '${AppConstants.formatCurrency(remaining.abs(), withSymbol: true)}',
      );
    } else {
      state = state.copyWith(customSplitError: null);
    }
  }

  /// Validates the full form and returns the first blocking error message,
  /// or `null` if the form is valid.
  String? validate() {
    // Clear previous errors.
    state = state.copyWith(
      titleError: null,
      noteError: null,
      dateError: null,
      paymentMethodError: null,
    );

    if (state.amount <= 0) {
      state = state.copyWith(
        amountError: 'Please enter a bill amount greater than zero.',
      );
      return state.amountError;
    }
    // Quick Info required fields (except Add Photo).
    if (state.title.trim().isEmpty) {
      state = state.copyWith(
        titleError: 'Please add a bill title.',
      );
      return state.titleError;
    }
    if (state.note.trim().isEmpty) {
      state = state.copyWith(
        noteError: 'Please add a note.',
      );
      return state.noteError;
    }
    if (state.date == null) {
      state = state.copyWith(
        dateError: 'Please select a date.',
      );
      return state.dateError;
    }
    // At least one payment option is required.
    if (state.paymentEntries.isEmpty) {
      state = state.copyWith(
        paymentMethodError: 'Please select a payment option.',
      );
      return state.paymentMethodError;
    }
    if (state.includedCount == 0) {
      state = state.copyWith(
        participantsError: 'At least one participant must be included.',
      );
      return state.participantsError;
    }
    if (state.splitMode == BillSplitMode.custom) {
      final diff = (state.customSharesTotal - state.amount).abs();
      if (diff > AppConstants.splitRoundingTolerance) {
        _validateCustomSplit();
        return state.customSplitError;
      }
    }
    return null;
  }

  // ── Bill creation ─────────────────────────────────────────────────────────

  /// Validates the form data and, if valid, produces a [Bill] entity.
  ///
  /// Returns the [Bill] on success, or `null` on validation failure.
  Bill? buildBill({required String createdBy, required String groupId, required String groupName}) {
    final error = validate();
    if (error != null) return null;

    final now = DateTime.now();

    // Extract payment data — only the active (first) entry is used.
    // QR URLs are uploaded later in SaveBillNotifier.
    final activeEntry = state.paymentEntries.first;
    final methods = [activeEntry.method];
    final bankEntry = activeEntry.method == BillPaymentMethod.bank
        ? activeEntry
        : null;

    return Bill(
      id: '',
      groupId: groupId,
      groupName: groupName,
      title: state.title.trim().isNotEmpty ? state.title.trim() : 'Untitled Bill',
      note: state.note.trim().isEmpty ? null : state.note.trim(),
      totalAmount: state.amount,
      receiptPhotoUrl: null, // Set after Cloudinary upload in SaveBillNotifier
      date: state.date ?? now,
      splitMode: state.splitMode,
      participants: state.participants,
      createdBy: createdBy,
      createdAt: now,
      excludedMemberIds: state.participants
          .where((p) => !p.isIncluded)
          .map((p) => p.id)
          .toList(),
      paymentMethods: methods,
      paymentQrUrls: const [], // Set after Cloudinary upload in SaveBillNotifier
      selectedBankName: bankEntry?.bankName,
    );
  }

  void reset() => state = const CreateBillFormState();
}

// ─────────────────────────────────────────────────────────────────────────────
// Provider family
// ─────────────────────────────────────────────────────────────────────────────

/// A [ProviderFamily] that creates a fresh [CreateBillNotifier] per group.
///
/// The family key is a `(Group, String)` record: the group and the current
/// user's UID. Scoped inside the screen with an [AutoDisposeStateNotifierProvider]
/// so it is cleaned up when the screen is popped.
typedef CreateBillKey = ({Group group, String currentUserId});

final createBillProvider = StateNotifierProvider.autoDispose
    .family<CreateBillNotifier, CreateBillFormState, CreateBillKey>(
  (ref, key) => CreateBillNotifier(
    group: key.group,
    currentUserId: key.currentUserId,
  ),
);
