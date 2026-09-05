import 'package:flutter/material.dart';

import '../../../../app/theme/design_system.dart';

/// Result of a user action in the profile-photo bottom sheet.
enum ProfilePhotoOption {
  /// Open the device camera to capture a new photo.
  camera,

  /// Open the device gallery to select an existing photo.
  gallery,

  /// Remove the currently selected photo.
  remove,
}

/// Rounded bottom sheet shown when the user taps the avatar camera badge.
///
/// Mirrors the design in the reference image: a drag handle, title,
/// subtitle, and a list of large tappable cards. Each card has a rounded
/// icon container, primary/secondary text, and a chevron on the right.
class ProfilePhotoBottomSheet extends StatelessWidget {
  const ProfilePhotoBottomSheet({
    super.key,
    this.showRemoveOption = false,
  });

  /// Whether to show the "Remove photo" destructive option.
  final bool showRemoveOption;

  static Future<ProfilePhotoOption?> show(
    BuildContext context, {
    bool showRemoveOption = false,
  }) {
    return showModalBottomSheet<ProfilePhotoOption>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      builder: (_) => ProfilePhotoBottomSheet(
        showRemoveOption: showRemoveOption,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppRadius.xxl),
          topRight: Radius.circular(AppRadius.xxl),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle — inside the rounded container so it sits on the
            // sheet surface, not floating above it.
            Center(
              child: Container(
                width: 40,
                height: 5,
                margin: const EdgeInsets.only(top: AppSpacing.md),
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                  borderRadius: AppRadius.radiusFull,
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Title
            Text(
              'Upload profile picture',
              textAlign: TextAlign.center,
              style: AppTextStyles.headlineSmall.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: AppSpacing.xs),

            // Subtitle
            Text(
              'Choose how you want to add a profile photo',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: AppSpacing.xxl),

            // Options
            _OptionTile(
              icon: Icons.camera_alt_outlined,
              title: 'Take a photo',
              subtitle: 'Use your camera to capture a new picture',
              onTap: () => Navigator.of(context).pop(ProfilePhotoOption.camera),
            ),

            const SizedBox(height: AppSpacing.md),

            _OptionTile(
              icon: Icons.photo_library_outlined,
              title: 'Choose from gallery',
              subtitle: 'Select an existing photo from your device',
              onTap: () => Navigator.of(context).pop(ProfilePhotoOption.gallery),
            ),

            if (showRemoveOption) ...[
              const SizedBox(height: AppSpacing.md),
              _OptionTile(
                icon: Icons.delete_outline_rounded,
                title: 'Remove photo',
                subtitle: 'Clear your current profile picture',
                isDestructive: true,
                onTap: () => Navigator.of(context).pop(ProfilePhotoOption.remove),
              ),
            ],

            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}

/// A single large tappable row with an icon, labels, and a chevron.
class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final baseColor = isDestructive ? colorScheme.error : colorScheme.primary;

    return Material(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      borderRadius: AppRadius.radiusLg,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.radiusLg,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              // Icon badge
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: baseColor.withValues(alpha: 0.12),
                  borderRadius: AppRadius.radiusMd,
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: baseColor,
                ),
              ),

              const SizedBox(width: AppSpacing.md),

              // Labels
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.labelLarge.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              // Chevron
              Icon(
                Icons.chevron_right_rounded,
                size: 24,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
