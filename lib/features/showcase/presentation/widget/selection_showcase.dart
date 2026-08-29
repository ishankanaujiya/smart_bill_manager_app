import 'package:flutter/material.dart';

/// Demonstrates switch, checkbox, radio, and chip selection controls.
class SelectionShowcase extends StatefulWidget {
  const SelectionShowcase({super.key});

  @override
  State<SelectionShowcase> createState() => _SelectionShowcaseState();
}

class _SelectionShowcaseState extends State<SelectionShowcase> {
  bool _switchValue = true;
  bool _checkboxValue = false;
  String? _radioValue = 'Option A';
  bool _chipSelected = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Switch ─────────────────────────────────────────────────────────
        _LabelRow(
          label: 'Switch',
          child: Switch(
            value: _switchValue,
            onChanged: (v) => setState(() => _switchValue = v),
          ),
        ),
        const SizedBox(height: 12),

        // ── Checkbox ───────────────────────────────────────────────────────
        _LabelRow(
          label: 'Checkbox',
          child: Checkbox(
            value: _checkboxValue,
            onChanged: (v) => setState(() => _checkboxValue = v ?? false),
          ),
        ),
        const SizedBox(height: 12),

        // ── Radio ──────────────────────────────────────────────────────────
        RadioGroup<String>(
          groupValue: _radioValue,
          onChanged: (v) => setState(() => _radioValue = v),
          child: Column(
            children: [
              _LabelRow(
                label: 'Radio A',
                child: const Radio<String>(value: 'Option A'),
              ),
              _LabelRow(
                label: 'Radio B',
                child: const Radio<String>(value: 'Option B'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Chips ──────────────────────────────────────────────────────────
        Text(
          'Chips',
          style: theme.textTheme.labelLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            const Chip(label: Text('Action Chip')),
            const Chip(
              avatar: Icon(Icons.person_rounded, size: 18),
              label: Text('Avatar chip'),
            ),
            FilterChip(
              label: const Text('Filter chip'),
              selected: _chipSelected,
              onSelected: (v) => setState(() => _chipSelected = v),
            ),
            const ActionChip(
              label: Text('Action chip'),
              avatar: Icon(Icons.settings_rounded, size: 18),
            ),
          ],
        ),
      ],
    );
  }
}

class _LabelRow extends StatelessWidget {
  const _LabelRow({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Text(label, style: theme.textTheme.bodyMedium),
        ),
        child,
      ],
    );
  }
}
