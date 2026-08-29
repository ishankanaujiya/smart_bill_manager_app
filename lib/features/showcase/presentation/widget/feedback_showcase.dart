import 'package:flutter/material.dart';

/// Demonstrates progress indicators, snackbars, dialogs, and bottom sheets.
class FeedbackShowcase extends StatelessWidget {
  const FeedbackShowcase({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Progress indicators ────────────────────────────────────────────
        Text(
          'Progress Indicators',
          style: theme.textTheme.labelLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        const LinearProgressIndicator(),
        const SizedBox(height: 12),
        const SizedBox(
          width: 48,
          child: CircularProgressIndicator(strokeWidth: 4),
        ),
        const SizedBox(height: 24),

        // ── Trigger buttons ────────────────────────────────────────────────
        Text(
          'Feedback Triggers',
          style: theme.textTheme.labelLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            OutlinedButton.icon(
              onPressed: () => _showSnackBar(context),
              icon: const Icon(Icons.info_outline, size: 18),
              label: const Text('Snackbar'),
            ),
            OutlinedButton.icon(
              onPressed: () => _showDialog(context),
              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
              label: const Text('Dialog'),
            ),
            OutlinedButton.icon(
              onPressed: () => _showBottomSheet(context),
              icon: const Icon(Icons.vertical_align_bottom_rounded, size: 18),
              label: const Text('Bottom Sheet'),
            ),
          ],
        ),
      ],
    );
  }

  void _showSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('This is a snackbar from the design system.'),
        action: SnackBarAction(label: 'Undo', onPressed: () {}),
      ),
    );
  }

  void _showDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dialog Title'),
        content: const Text(
          'This dialog uses the dialogTheme from AppTheme — '
          '24dp radius, zero elevation, surface tint transparent.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _showBottomSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bottom Sheet',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            const Text(
              'This sheet uses the bottomSheetTheme — '
              'top-24dp radius, drag handle, surface background.',
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
