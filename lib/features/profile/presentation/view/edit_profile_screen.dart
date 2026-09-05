import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/theme/design_system.dart';
import '../../../../core/widgets/animated_entrance.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../auth/presentation/state/auth_providers.dart';
import '../../../auth/presentation/widget/profile_photo_bottom_sheet.dart';
import '../../../groups/presentation/state/group_providers.dart' as group;
import '../../../users/domain/entities/app_user.dart';

/// Validates a Nepali mobile number while the user is typing.
///
/// The error message is only shown for the first two digits:
///  - First digit must be `9`.
///  - Second digit must be `7` or `8` (i.e. `98XXXXXXXX` or `97XXXXXXXX`).
///
/// Length and digit-only checks are still enforced by the input formatters
/// and the save guard, but they do not surface an inline error message.
///
/// Returns `null` when the current input is valid (or empty), otherwise
/// returns a single, generic error string suitable for
/// [InputDecoration.errorText].
String? _validateNepaliPhone(String value) {
  final trimmed = value.trim();

  // Empty is valid — phone number is optional.
  if (trimmed.isEmpty) return null;

  // First digit must be 9.
  if (trimmed[0] != '9') {
    return 'Enter a valid mobile number';
  }

  // Second digit (once present) must be 7 or 8.
  if (trimmed.length >= 2) {
    final second = trimmed[1];
    if (second != '7' && second != '8') {
      return 'Enter a valid mobile number';
    }
  }

  return null;
}

/// Edit Profile screen — allows the user to change their profile picture
/// and phone number only. All other fields (full name, email, display name)
/// are shown as read-only.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() =>
      _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen>
    with TickerProviderStateMixin {
  // ── Controllers ──
  final _phoneController = TextEditingController();
  final _phoneFocus = FocusNode();

  // ── State ──
  String? _profilePhotoPath; // local file path (before upload)
  String? _profilePhotoUrl; // existing / uploaded URL
  bool _isPicking = false;
  bool _isSaving = false;
  bool _hasChanges = false;
  String? _initialPhone;

  // ── Animation ──
  late final AnimationController _entranceController;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _phoneController.addListener(_onPhoneChanged);
    _startEntrance();
  }

  void _onPhoneChanged() {
    final changed = _phoneController.text.trim() != (_initialPhone ?? '');
    if (changed != _hasChanges) setState(() => _hasChanges = changed);
  }

  Future<void> _startEntrance() async {
    await Future.delayed(const Duration(milliseconds: 80));
    if (!mounted) return;
    _entranceController.forward();
  }

  /// Pre-fill the form once the user data is available.
  void _hydrateFromUser(AppUser? user) {
    if (user == null || _initialPhone != null) return;
    _initialPhone = user.phoneNumber ?? '';
    _phoneController.text = _initialPhone!;
    _profilePhotoUrl = user.profilePicture;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _phoneController.removeListener(_onPhoneChanged);
    _phoneController.dispose();
    _phoneFocus.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  // ── Helpers ──

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    if (parts.isNotEmpty && parts.first.isNotEmpty) {
      return parts.first[0].toUpperCase();
    }
    return '?';
  }

  // ── Photo picking ──

  Future<void> _onPickPhoto() async {
    if (_isPicking) return;
    final option = await ProfilePhotoBottomSheet.show(
      context,
      showRemoveOption:
          _profilePhotoPath != null || _profilePhotoUrl != null,
    );
    if (option == null || !mounted) return;

    switch (option) {
      case ProfilePhotoOption.remove:
        setState(() {
          _profilePhotoPath = null;
          _profilePhotoUrl = null;
          _hasChanges = true;
        });
      case ProfilePhotoOption.camera:
      case ProfilePhotoOption.gallery:
        await _pickImage(option);
    }
  }

  Future<void> _pickImage(ProfilePhotoOption option) async {
    _isPicking = true;
    try {
      final source = option == ProfilePhotoOption.camera
          ? ImageSource.camera
          : ImageSource.gallery;

      final xFile = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (!mounted) return;
      if (xFile != null) {
        setState(() {
          _profilePhotoPath = xFile.path;
          _hasChanges = true;
        });
      }
    } finally {
      _isPicking = false;
    }
  }

  // ── Save ──

  Future<void> _onSave() async {
    if (_isSaving) return;

    final phone = _phoneController.text.trim();

    // Validate Nepali phone number if provided.
    if (phone.isNotEmpty && !RegExp(r'^9[78]\d{8}$').hasMatch(phone)) {
      AppSnackBar.show(
        context,
        title: 'Invalid phone number',
        message: 'Enter a valid mobile number',
        type: AppSnackBarType.error,
      );
      _phoneFocus.requestFocus();
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = await ref.read(currentAppUserProvider.future);
      if (user == null || !mounted) return;

      // Upload the new photo (if a local file was picked).
      String? finalPhotoUrl = _profilePhotoUrl;
      if (_profilePhotoPath != null) {
        final file = File(_profilePhotoPath!);
        if (await file.exists()) {
          final cloudinary = ref.read(group.cloudinaryServiceProvider);
          finalPhotoUrl = await cloudinary.uploadFile(file);
        }
      }

      final updated = user.copyWith(
        phoneNumber: phone.isEmpty ? null : phone,
        profilePicture: finalPhotoUrl,
        updatedAt: DateTime.now(),
      );

      await ref.read(userRepositoryProvider).updateUser(updated);

      // Invalidate so other screens see the fresh data.
      ref.invalidate(currentAppUserProvider);

      if (!mounted) return;
      AppSnackBar.show(
        context,
        title: 'Profile updated',
        type: AppSnackBarType.success,
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.show(
        context,
        title: 'Update failed',
        message: 'Please check your connection and try again.',
        type: AppSnackBarType.error,
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentAppUserProvider);
    // Hydrate the form as soon as data arrives.
    userAsync.whenData(_hydrateFromUser);

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final firebaseUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          _SaveButton(
            enabled: _hasChanges && !_isSaving,
            isLoading: _isSaving,
            onPressed: _onSave,
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            // ── Avatar section ──────────────────────────────────────────────
            SliverToBoxAdapter(
              child: StaggeredEntrance(
                animation: _entranceController,
                interval: const Interval(0.0, 0.5, curve: Curves.easeOut),
                child: Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xxl),
                  child: Center(
                    child: _EditableAvatar(
                      initials: _initials(
                        userAsync.maybeWhen(
                          data: (u) => u?.fullName ?? '',
                          orElse: () => '',
                        ),
                      ),
                      photoPath: _profilePhotoPath,
                      photoUrl: _profilePhotoUrl,
                      isDark: isDark,
                      colorScheme: colorScheme,
                      onTap: _onPickPhoto,
                    ),
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: StaggeredEntrance(
                animation: _entranceController,
                interval: const Interval(0.08, 0.55, curve: Curves.easeOut),
                child: Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: Center(
                    child: Text(
                      'Tap the camera icon to change your photo',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),

            // ── Read-only fields ────────────────────────────────────────────
            SliverToBoxAdapter(
              child: StaggeredEntrance(
                animation: _entranceController,
                interval: const Interval(0.15, 0.6, curve: Curves.easeOut),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenHorizontal,
                  ),
                  child: _SectionLabel(label: 'Personal Info'),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: StaggeredEntrance(
                animation: _entranceController,
                interval: const Interval(0.18, 0.63, curve: Curves.easeOut),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenHorizontal,
                  ),
                  child: _ReadOnlyGroup(
                    isDark: isDark,
                    colorScheme: colorScheme,
                    fields: [
                      _ReadOnlyField(
                        icon: Icons.person_outline_rounded,
                        label: 'Full Name',
                        value: userAsync.maybeWhen(
                          data: (u) => u?.fullName ?? '—',
                          orElse: () => '—',
                        ),
                      ),
                      _ReadOnlyField(
                        icon: Icons.alternate_email_rounded,
                        label: 'Display Name',
                        value: userAsync.maybeWhen(
                          data: (u) => u?.displayName ?? '—',
                          orElse: () => '—',
                        ),
                      ),
                      _ReadOnlyField(
                        icon: Icons.mail_outline_rounded,
                        label: 'Email',
                        value: userAsync.maybeWhen(
                          data: (u) => u?.email ?? firebaseUser?.email ?? '—',
                          orElse: () => firebaseUser?.email ?? '—',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),

            // ── Editable phone number ───────────────────────────────────────
            SliverToBoxAdapter(
              child: StaggeredEntrance(
                animation: _entranceController,
                interval: const Interval(0.25, 0.7, curve: Curves.easeOut),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenHorizontal,
                  ),
                  child: _SectionLabel(label: 'Editable'),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: StaggeredEntrance(
                animation: _entranceController,
                interval: const Interval(0.28, 0.73, curve: Curves.easeOut),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenHorizontal,
                  ),
                  child: _PhoneField(
                    controller: _phoneController,
                    focusNode: _phoneFocus,
                    isDark: isDark,
                    colorScheme: colorScheme,
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Save button
// ─────────────────────────────────────────────────────────────────────────────

class _SaveButton extends StatelessWidget {
  const _SaveButton({
    required this.enabled,
    required this.isLoading,
    required this.onPressed,
  });

  final bool enabled;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.sm),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    return TextButton(
      onPressed: enabled ? onPressed : null,
      child: Text(
        'Save',
        style: AppTextStyles.button.copyWith(
          color: enabled ? null : Theme.of(context).disabledColor,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Editable avatar
// ─────────────────────────────────────────────────────────────────────────────

class _EditableAvatar extends StatelessWidget {
  const _EditableAvatar({
    required this.initials,
    required this.isDark,
    required this.colorScheme,
    required this.onTap,
    this.photoPath,
    this.photoUrl,
  });

  final String initials;
  final String? photoPath;
  final String? photoUrl;
  final bool isDark;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const size = 120.0;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.primaryContainer,
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.3),
                width: 3,
              ),
              boxShadow: AppShadows.cardShadow(
                isDark ? Brightness.dark : Brightness.light,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: _buildAvatarContent(),
          ),
          // Camera badge
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: colorScheme.primary,
                shape: BoxShape.circle,
                border: Border.all(
                  color: colorScheme.surface,
                  width: 3,
                ),
              ),
              child: Icon(
                Icons.camera_alt_rounded,
                size: 18,
                color: colorScheme.onPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarContent() {
    // Prefer the local file (just picked) over the remote URL.
    if (photoPath != null) {
      return Image.file(
        File(photoPath!),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _Initials(initials: initials),
      );
    }
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return Image.network(
        photoUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _Initials(initials: initials),
      );
    }
    return _Initials(initials: initials);
  }
}

class _Initials extends StatelessWidget {
  const _Initials({required this.initials});
  final String initials;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Text(
        initials,
        style: AppTextStyles.displaySmall.copyWith(
          color: colorScheme.primary,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section label
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        label.toUpperCase(),
        style: AppTextStyles.labelSmall.copyWith(
          color: colorScheme.onSurfaceVariant,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Read-only fields group
// ─────────────────────────────────────────────────────────────────────────────

class _ReadOnlyField {
  const _ReadOnlyField({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;
}

class _ReadOnlyGroup extends StatelessWidget {
  const _ReadOnlyGroup({
    required this.fields,
    required this.isDark,
    required this.colorScheme,
  });

  final List<_ReadOnlyField> fields;
  final bool isDark;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: AppRadius.radiusLg,
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(
            alpha: isDark ? 0.35 : 0.6,
          ),
        ),
      ),
      child: Column(
        children: [
          for (var i = 0; i < fields.length; i++) ...[
            _ReadOnlyRow(field: fields[i], colorScheme: colorScheme),
            if (i < fields.length - 1)
              Divider(
                height: 1,
                thickness: 1,
                indent: AppSpacing.lg + 38 + AppSpacing.md,
                color: colorScheme.outlineVariant.withValues(
                  alpha: isDark ? 0.3 : 0.5,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _ReadOnlyRow extends StatelessWidget {
  const _ReadOnlyRow({required this.field, required this.colorScheme});
  final _ReadOnlyField field;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.5,
              ),
              borderRadius: AppRadius.radiusSm,
            ),
            child: Icon(
              field.icon,
              size: 20,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  field.label,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  field.value,
                  style: AppTextStyles.titleSmall.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Lock icon — indicates the field is not editable
          Icon(
            Icons.lock_outline,
            size: 16,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Phone field
// ─────────────────────────────────────────────────────────────────────────────

class _PhoneField extends StatelessWidget {
  const _PhoneField({
    required this.controller,
    required this.focusNode,
    required this.isDark,
    required this.colorScheme,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isDark;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: AppRadius.radiusLg,
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(
            alpha: isDark ? 0.35 : 0.6,
          ),
        ),
      ),
      child: Padding(
        // Same padding as _ReadOnlyRow so both groups look identical.
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icon container — same 38×38 as the read-only rows.
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: AppRadius.radiusSm,
              ),
              child: Icon(
                Icons.phone_outlined,
                size: 20,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Label + field — vertically stacked, mirrors _ReadOnlyRow.
            // ValueListenableBuilder rebuilds the field on every keystroke so
            // the error text updates in real time as the user types.
            Expanded(
              child: ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller,
                builder: (context, value, _) {
                  final error = _validateNepaliPhone(value.text);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Phone Number',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          letterSpacing: 0.3,
                        ),
                      ),
                      // The TextField renders the phone number exactly like
                      // the static value text in _ReadOnlyRow. We:
                      //  • override filled:false so the global input theme
                      //    does not paint a dark fill behind the number
                      //  • keep isDense:true so the field stays compact
                      //  • use a small top-only contentPadding so the text
                      //    baseline sits 2 dp below the label
                      //  • restrict input to digits only and cap at 10 digits
                      TextField(
                        controller: controller,
                        focusNode: focusNode,
                        keyboardType: TextInputType.phone,
                        style: AppTextStyles.titleSmall.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        decoration: InputDecoration(
                          filled: false,
                          hintText: '98XXXXXXXX',
                          hintStyle: AppTextStyles.titleSmall.copyWith(
                            color: colorScheme.onSurfaceVariant.withValues(
                              alpha: 0.5,
                            ),
                          ),
                          errorText: error,
                          errorStyle: AppTextStyles.bodySmall.copyWith(
                            color: colorScheme.error,
                            height: 1.3,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          focusedErrorBorder: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.only(top: 2),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
