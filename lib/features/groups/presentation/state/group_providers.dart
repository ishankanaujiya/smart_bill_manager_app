import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/group_repository_impl.dart';
import '../../data/service/cloudinary_service.dart';
import '../../domain/entities/group.dart';
import '../../domain/repositories/group_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Repository & service providers
// ─────────────────────────────────────────────────────────────────────────────

/// Provides the singleton [GroupRepository] instance.
final groupRepositoryProvider = Provider<GroupRepository>((ref) {
  return GroupRepositoryImpl();
});

/// Provides the singleton [CloudinaryService] instance.
final cloudinaryServiceProvider = Provider<CloudinaryService>((ref) {
  return CloudinaryService();
});

// ─────────────────────────────────────────────────────────────────────────────
// Create group state
// ─────────────────────────────────────────────────────────────────────────────

/// State for the create-group operation.
sealed class CreateGroupState {
  const CreateGroupState();
}

class CreateGroupIdle extends CreateGroupState {
  const CreateGroupIdle();
}

class CreateGroupLoading extends CreateGroupState {
  const CreateGroupLoading();
}

class CreateGroupSuccess extends CreateGroupState {
  const CreateGroupSuccess(this.group);
  final Group group;
}

class CreateGroupError extends CreateGroupState {
  const CreateGroupError(this.message);
  final String message;
}

// ─────────────────────────────────────────────────────────────────────────────
// Create group notifier
// ─────────────────────────────────────────────────────────────────────────────

/// Notifier that orchestrates the full "create group" flow:
///
/// 1. Upload the optional group photo to Cloudinary (if a local file path
///    was provided).
/// 2. Build a [Group] entity from the form data, embedding the creator's
///    and members' profile snapshots fetched from the "Users" collection.
/// 3. Persist the group to the Firestore "Groups" collection.
///
/// Exposes loading/success/error state to the UI so the create button can
/// show a spinner and the screen can react to the result.
class CreateGroupNotifier extends StateNotifier<CreateGroupState> {
  CreateGroupNotifier(this._groupRepo, this._cloudinary)
      : super(const CreateGroupIdle());

  final GroupRepository _groupRepo;
  final CloudinaryService _cloudinary;

  /// Creates a new group.
  ///
  /// [groupName] is the display name of the group.
  /// [createdByUid] is the Firebase Auth uid of the creator (the current
  /// user). Stored as the `created_by` string field that the security
  /// rules check on create.
  /// [groupAdmin] is the admin's full [GroupMember] profile snapshot —
  /// stored as the `group_admin` field in Firestore.
  /// [members] is the full list of group members (including the creator,
  /// marked as admin). Each member's `id` is collected into the
  /// `member_ids` list that the security rules use for membership checks.
  /// [groupPhotoPath] is the optional local file path of the picked group
  /// photo — when non-null it is uploaded to Cloudinary and the returned
  /// `secure_url` is stored as `group_picture`.
  Future<bool> createGroup({
    required String groupName,
    required String createdByUid,
    required GroupMember groupAdmin,
    required List<GroupMember> members,
    String? groupPhotoPath,
  }) async {
    final trimmedName = groupName.trim();
    if (trimmedName.isEmpty) {
      state = const CreateGroupError('Please enter a group name.');
      return false;
    }
    if (members.isEmpty) {
      state = const CreateGroupError('A group needs at least one member.');
      return false;
    }

    state = const CreateGroupLoading();

    try {
      // 1. Upload the group photo to Cloudinary (if one was picked).
      String? groupPictureUrl;
      if (groupPhotoPath != null) {
        final file = File(groupPhotoPath);
        if (await file.exists()) {
          groupPictureUrl = await _cloudinary.uploadFile(file);
          // A failed upload is non-fatal — the group is still created
          // without a picture. The user can add one later.
        }
      }

      // 2. Build the group entity.
      final now = DateTime.now();
      final group = Group(
        id: '',
        groupName: trimmedName,
        groupPicture: groupPictureUrl,
        createdAt: now,
        updatedAt: now,
        createdBy: createdByUid,
        memberIds: members.map((m) => m.id).toList(),
        groupAdmin: groupAdmin,
        members: members,
        memberCount: members.length,
      );

      // 3. Persist to Firestore.
      final saved = await _groupRepo.createGroup(group);

      state = CreateGroupSuccess(saved);
      return true;
    } on FirebaseException catch (e) {
      final message = switch (e.code) {
        'permission-denied' =>
          'You don\'t have permission to create a group. Please contact support.',
        'unavailable' =>
          'Firestore is temporarily unavailable. Please try again.',
        'network-request-failed' =>
          'Network error. Please check your internet connection.',
        _ => 'Could not create the group. Please try again.',
      };
      state = CreateGroupError(message);
      return false;
    } catch (_) {
      state = const CreateGroupError(
        'Could not create the group. Please try again.',
      );
      return false;
    }
  }

  /// Resets the state back to idle (e.g. to clear an error).
  void reset() {
    state = const CreateGroupIdle();
  }
}

/// Provider for [CreateGroupNotifier].
final createGroupProvider =
    StateNotifierProvider<CreateGroupNotifier, CreateGroupState>((ref) {
  return CreateGroupNotifier(
    ref.read(groupRepositoryProvider),
    ref.read(cloudinaryServiceProvider),
  );
});

// ─────────────────────────────────────────────────────────────────────────────
// Convenience: the currently signed-in user's uid
// ─────────────────────────────────────────────────────────────────────────────

/// Provides the Firebase Auth UID of the currently signed-in user, or
/// `null` when nobody is signed in.
final currentUidProvider = Provider<String?>((ref) {
  return FirebaseAuth.instance.currentUser?.uid;
});
