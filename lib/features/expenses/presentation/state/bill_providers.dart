import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
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
      final qrUrls = <String>[];
      for (final entry in paymentEntries) {
        final path = entry.qrPhotoPath;
        if (path != null) {
          final file = File(path);
          if (await file.exists()) {
            final url = await _cloudinary.uploadFile(file);
            qrUrls.add(url ?? '');
          } else {
            qrUrls.add('');
          }
        } else {
          qrUrls.add('');
        }
      }

      // 3. Build the final bill entity with the Cloudinary URLs.
      final billToSave = bill.copyWith(
        receiptPhotoUrl: receiptUrl ?? bill.receiptPhotoUrl,
        excludedMemberIds: bill.participants
            .where((p) => !p.isIncluded)
            .map((p) => p.id)
            .toList(),
        paymentQrUrls: qrUrls,
      );

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
