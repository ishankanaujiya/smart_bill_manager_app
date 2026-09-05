import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../groups/data/service/cloudinary_service.dart';
import '../../../groups/presentation/state/group_providers.dart';
import '../../data/repositories/bill_repository_impl.dart';
import '../../domain/entities/bill.dart';
import '../../domain/repositories/bill_repository.dart';
import 'create_bill_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Repository & service providers
// ─────────────────────────────────────────────────────────────────────────────

/// Provides the singleton [BillRepository] instance.
final billRepositoryProvider = Provider<BillRepository>((ref) {
  return BillRepositoryImpl();
});

// CloudinaryService is already provided by group_providers.dart as
// `cloudinaryServiceProvider`. We re-use it for bill receipt uploads.

// ─────────────────────────────────────────────────────────────────────────────
// Save-bill state
// ─────────────────────────────────────────────────────────────────────────────

/// State for the save-bill operation.
sealed class SaveBillState {
  const SaveBillState();
}

class SaveBillIdle extends SaveBillState {
  const SaveBillIdle();
}

class SaveBillLoading extends SaveBillState {
  const SaveBillLoading();
}

class SaveBillSuccess extends SaveBillState {
  const SaveBillSuccess(this.bill);
  final Bill bill;
}

class SaveBillError extends SaveBillState {
  const SaveBillError(this.message);
  final String message;
}

// ─────────────────────────────────────────────────────────────────────────────
// Save-bill notifier
// ─────────────────────────────────────────────────────────────────────────────

/// Notifier that orchestrates the full "save bill to Firestore" flow:
///
/// 1. Upload the optional receipt photo to Cloudinary (if a local file
///    path was provided).
/// 2. Build a [Bill] entity with the Cloudinary URL (if any).
/// 3. Persist the bill to the `groups/{groupId}/bills` subcollection.
///
/// Exposes loading/success/error state to the UI so the confirm button can
/// show a spinner and the screen can react to the result.
class SaveBillNotifier extends StateNotifier<SaveBillState> {
  SaveBillNotifier(this._billRepo, this._cloudinary)
      : super(const SaveBillIdle());

  final BillRepository _billRepo;
  final CloudinaryService _cloudinary;

  /// Persists a [Bill] to Firestore.
  ///
  /// [bill] should have all fields populated except `receiptPhotoUrl`
  /// (which is derived from [receiptPhotoPath] via Cloudinary upload).
  /// [receiptPhotoPath] is the optional local file path of the picked
  /// receipt photo.
  /// [paymentEntries] are the payment method entries whose QR codes need
  /// to be uploaded to Cloudinary before saving.
  Future<bool> saveBill({
    required Bill bill,
    String? receiptPhotoPath,
    List<PaymentMethodEntry> paymentEntries = const [],
  }) async {
    state = const SaveBillLoading();

    try {
      // 1. Upload the receipt photo to Cloudinary (if one was picked).
      String? receiptUrl;
      if (receiptPhotoPath != null) {
        final file = File(receiptPhotoPath);
        if (await file.exists()) {
          receiptUrl = await _cloudinary.uploadFile(file);
          // A failed upload is non-fatal — the bill is still created
          // without a receipt photo.
        }
      }

      // 2. Upload QR code images for each payment method (if provided).
      //    Build a method-name-keyed map: {esewa: url, khalti: url, bank: url}
      final qrUrlMap = <String, String>{};
      for (final entry in paymentEntries) {
        final path = entry.qrPhotoPath;
        final key = _methodKey(entry.method);
        if (path != null) {
          final file = File(path);
          if (await file.exists()) {
            final url = await _cloudinary.uploadFile(file);
            qrUrlMap[key] = url ?? '';
          } else {
            qrUrlMap[key] = '';
          }
        } else {
          qrUrlMap[key] = '';
        }
      }

      // 3. Build the final bill entity with the Cloudinary URLs.
      final billToSave = bill.copyWith(
        receiptPhotoUrl: receiptUrl ?? bill.receiptPhotoUrl,
        excludedMemberIds: bill.participants
            .where((p) => !p.isIncluded)
            .map((p) => p.id)
            .toList(),
        paymentQrUrls: qrUrlMap,
      );

      // Debug: log what's being written to Firestore.
      debugPrint('[SaveBillNotifier] bill.paymentMethods=${billToSave.paymentMethods}');
      debugPrint('[SaveBillNotifier] bill.paymentIds=${billToSave.paymentIds}');
      debugPrint('[SaveBillNotifier] bill.paymentQrUrls=${billToSave.paymentQrUrls}');

      // 4. Persist to Firestore.
      final saved = await _billRepo.createBill(billToSave);

      state = SaveBillSuccess(saved);
      return true;
    } on FirebaseException catch (e) {
      final message = switch (e.code) {
        'permission-denied' =>
          'You don\'t have permission to create a bill in this group.',
        'unavailable' =>
          'Firestore is temporarily unavailable. Please try again.',
        'network-request-failed' =>
          'Network error. Please check your internet connection.',
        _ => 'Could not create the bill. Please try again.',
      };
      state = SaveBillError(message);
      return false;
    } catch (_) {
      state = const SaveBillError(
        'Could not create the bill. Please try again.',
      );
      return false;
    }
  }

  /// Resets the state back to idle (e.g. to clear an error).
  void reset() {
    state = const SaveBillIdle();
  }
}

/// Provider for [SaveBillNotifier].
final saveBillProvider =
    StateNotifierProvider<SaveBillNotifier, SaveBillState>((ref) {
  return SaveBillNotifier(
    ref.read(billRepositoryProvider),
    ref.read(cloudinaryServiceProvider),
  );
});

/// Returns the Firestore string key for a payment method — used as the key
/// in the `payment_id` and `payment_qr_urls` maps.
String _methodKey(BillPaymentMethod method) {
  return switch (method) {
    BillPaymentMethod.esewa => 'esewa',
    BillPaymentMethod.khalti => 'khalti',
    BillPaymentMethod.bank => 'bank',
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// Bills list for a group (real-time stream)
// ─────────────────────────────────────────────────────────────────────────────

/// Streams the list of bills for the given [groupId].
///
/// Emits a new list whenever any bill in the subcollection changes.
final billsForGroupProvider =
    StreamProvider.family<List<Bill>, String>((ref, groupId) {
  return ref.read(billRepositoryProvider).watchBillsForGroup(groupId);
});

// ─────────────────────────────────────────────────────────────────────────────
// Single-bill real-time stream
// ─────────────────────────────────────────────────────────────────────────────

/// Streams a single bill document in real time.
///
/// Used by [BillDetailsScreen] so that payment requests and verifications
/// made by other members appear live without needing to reload the screen.
final billStreamProvider =
    StreamProvider.family<Bill?, ({String groupId, String billId})>(
  (ref, params) {
    return ref
        .read(billRepositoryProvider)
        .watchBill(params.groupId, params.billId);
  },
);

// ─────────────────────────────────────────────────────────────────────────────
// Participant payment request / verification
// ─────────────────────────────────────────────────────────────────────────────

/// State for participant payment operations (request & verify).
sealed class PaymentActionState {
  const PaymentActionState();
}

class PaymentActionIdle extends PaymentActionState {
  const PaymentActionIdle();
}

class PaymentActionLoading extends PaymentActionState {
  const PaymentActionLoading();
}

class PaymentActionSuccess extends PaymentActionState {
  const PaymentActionSuccess(this.message);
  final String message;
}

class PaymentActionError extends PaymentActionState {
  const PaymentActionError(this.message);
  final String message;
}

/// Notifier that handles a participant submitting a payment request and the
/// bill creator verifying (approving / rejecting) a request.
///
/// Both flows write to the bill's `participant_payments` map via
/// [BillRepository]. The real-time [billStreamProvider] picks up the change
/// and the UI updates automatically.
class PaymentActionNotifier extends StateNotifier<PaymentActionState> {
  PaymentActionNotifier(this._billRepo) : super(const PaymentActionIdle());

  final BillRepository _billRepo;

  /// A participant submits a payment request for their own share.
  ///
  /// [requestType] is `paid` (full share) or `partially` (partial amount).
  /// [requestedAmount] should equal the share for a full request, or be
  /// less than the share for a partial request.
  Future<bool> requestPayment({
    required String groupId,
    required String billId,
    required String memberId,
    required PaymentRequestType requestType,
    required double requestedAmount,
  }) async {
    state = const PaymentActionLoading();
    try {
      await _billRepo.requestParticipantPayment(
        groupId: groupId,
        billId: billId,
        memberId: memberId,
        requestType: requestType,
        requestedAmount: requestedAmount,
      );
      state = PaymentActionSuccess(
        requestType == PaymentRequestType.paid
            ? 'Payment request submitted. Waiting for verification.'
            : 'Partial payment request submitted. Waiting for verification.',
      );
      return true;
    } on FirebaseException catch (e) {
      state = PaymentActionError(
        switch (e.code) {
          'permission-denied' =>
            'You don\'t have permission to update this bill.',
          'unavailable' => 'Firestore is temporarily unavailable. Try again.',
          'network-request-failed' =>
            'Network error. Check your internet connection.',
          _ => 'Could not submit the request. Please try again.',
        },
      );
      return false;
    } catch (_) {
      state = const PaymentActionError(
        'Could not submit the request. Please try again.',
      );
      return false;
    }
  }

  /// The bill creator verifies a participant's payment request.
  ///
  /// When [approved] is true, [receivedAmount] is the amount the creator
  /// confirms receiving; the participant's status becomes `paid` if it
  /// matches their share, otherwise `partially_paid`. When [approved] is
  /// false, the request is rejected.
  Future<bool> verifyPayment({
    required String groupId,
    required String billId,
    required String memberId,
    required bool approved,
    required double receivedAmount,
    required String verifiedBy,
  }) async {
    state = const PaymentActionLoading();
    try {
      await _billRepo.verifyParticipantPayment(
        groupId: groupId,
        billId: billId,
        memberId: memberId,
        approved: approved,
        receivedAmount: receivedAmount,
        verifiedBy: verifiedBy,
      );
      state = PaymentActionSuccess(
        approved
            ? receivedAmount > 0
                ? 'Payment verified successfully.'
                : 'Payment approved.'
            : 'Payment request rejected.',
      );
      return true;
    } on FirebaseException catch (e) {
      state = PaymentActionError(
        switch (e.code) {
          'permission-denied' =>
            'You don\'t have permission to verify this payment.',
          'unavailable' => 'Firestore is temporarily unavailable. Try again.',
          'network-request-failed' =>
            'Network error. Check your internet connection.',
          _ => 'Could not verify the payment. Please try again.',
        },
      );
      return false;
    } catch (_) {
      state = const PaymentActionError(
        'Could not verify the payment. Please try again.',
      );
      return false;
    }
  }

  /// Resets the state back to idle (e.g. to clear a snackbar).
  void reset() => state = const PaymentActionIdle();
}

/// Provider for [PaymentActionNotifier].
final paymentActionProvider =
    StateNotifierProvider<PaymentActionNotifier, PaymentActionState>((ref) {
  return PaymentActionNotifier(ref.read(billRepositoryProvider));
});
