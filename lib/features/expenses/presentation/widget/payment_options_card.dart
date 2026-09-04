import 'dart:io' as io;
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/theme/design_system.dart';
import '../../../../core/constants/bank_names.dart';
import '../../domain/entities/bill.dart';
import '../state/create_bill_provider.dart';

// ═════════════════════════════════════════════════════════════════════════════
// Payment Options Card
// ═════════════════════════════════════════════════════════════════════════════

/// A card-style widget that lets the user pick one payment method
/// (eSewa, Khalti, or Bank) and upload the corresponding QR code image.
///
/// Only one method may be selected at a time — selecting a new method
/// replaces the previous one.
///
/// All state is managed externally via the callbacks below so the parent
/// (the create-bill screen) remains the single source of truth.
class PaymentOptionsCard extends StatefulWidget {
  const PaymentOptionsCard({
    super.key,
    required this.paymentEntries,
    required this.colorScheme,
    required this.isDark,
    required this.onAddMethod,
    required this.onRemoveMethod,
    required this.onPickQr,
    required this.onBankNameChanged,
    this.uploadingQrMethod,
    this.paymentMethodError,
  });

  final List<PaymentMethodEntry> paymentEntries;
  final ColorScheme colorScheme;
  final bool isDark;

  /// Called when the user taps a method chip to add it.
  final void Function(BillPaymentMethod) onAddMethod;

  /// Called when the user removes a payment method.
  final void Function(BillPaymentMethod) onRemoveMethod;

  /// Called when the user wants to pick a QR code image for a method.
  /// The callback is responsible for updating state with the picked path.
  final Future<void> Function(BillPaymentMethod) onPickQr;

  /// Called when the user selects a bank name.
  final void Function(String?) onBankNameChanged;

  /// The payment method currently being uploaded (null = none).
  /// Only the matching entry shows a loading spinner.
  final BillPaymentMethod? uploadingQrMethod;

  /// Validation error message for the payment method selection.
  /// When non-null, a red error hint is shown below the selector chips.
  final String? paymentMethodError;

  @override
  State<PaymentOptionsCard> createState() => _PaymentOptionsCardState();
}

class _PaymentOptionsCardState extends State<PaymentOptionsCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  bool _isActiveMethod(BillPaymentMethod m) =>
      widget.paymentEntries.isNotEmpty &&
      widget.paymentEntries.first.method == m;

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = widget.colorScheme;
    final isDark = widget.isDark;

    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: AppRadius.radiusXxl,
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: isDark ? 0.3 : 0.5),
        ),
        boxShadow: AppShadows.cardShadow(
          isDark ? Brightness.dark : Brightness.light,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ───────────────────────────────────────────────────
          _CardHeader(
            colorScheme: cs,
            hasAnyMethod: widget.paymentEntries.isNotEmpty,
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── Method selector chips ─────────────────────────────────────
          _MethodSelectorRow(
            colorScheme: cs,
            isDark: isDark,
            hasEsewa: _isActiveMethod(BillPaymentMethod.esewa),
            hasKhalti: _isActiveMethod(BillPaymentMethod.khalti),
            hasBank: _isActiveMethod(BillPaymentMethod.bank),
            onToggle: (method) {
              final isActive = widget.paymentEntries.isNotEmpty &&
                  widget.paymentEntries.first.method == method;
              if (isActive) {
                // Tapping the active method deselects it.
                widget.onRemoveMethod(method);
              } else {
                // Tapping any other method activates it (preserving
                // any previously uploaded QR photo or bank name).
                widget.onAddMethod(method);
              }
            },
          ),

          // ── Payment method validation error ────────────────────────
          if (widget.paymentMethodError != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 13,
                  color: cs.error,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    widget.paymentMethodError!,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: cs.error,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],

          // ── Expanded entry for the selected method (animated transition) ──
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 380),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              final offset = Tween<Offset>(
                begin: const Offset(0, 0.12),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ));
              final fade = Tween<double>(
                begin: 0.0,
                end: 1.0,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
              ));
              return FadeTransition(
                opacity: fade,
                child: SlideTransition(
                  position: offset,
                  child: child,
                ),
              );
            },
            layoutBuilder: (currentChild, previousChildren) {
              return Stack(
                alignment: Alignment.topLeft,
                children: <Widget>[
                  ...previousChildren,
                  if (currentChild != null) currentChild,
                ],
              );
            },
            child: widget.paymentEntries.isEmpty
                ? const SizedBox.shrink()
                : Column(
                    key: ValueKey(
                      widget.paymentEntries.first.method,
                    ),
                    children: [
                      const SizedBox(height: AppSpacing.lg),
                      _PaymentEntry(
                        key: ValueKey(widget.paymentEntries.first.method),
                        entry: widget.paymentEntries.first,
                        colorScheme: cs,
                        isDark: isDark,
                        isUploadingQr:
                            widget.uploadingQrMethod == widget.paymentEntries.first.method,
                        pulseController: _pulseController,
                        onPickQr: () => widget.onPickQr(widget.paymentEntries.first.method),
                        onRemove: () => widget.onRemoveMethod(widget.paymentEntries.first.method),
                        onBankNameChanged: widget.onBankNameChanged,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Card header
// ═════════════════════════════════════════════════════════════════════════════

class _CardHeader extends StatelessWidget {
  const _CardHeader({
    required this.colorScheme,
    required this.hasAnyMethod,
  });

  final ColorScheme colorScheme;
  final bool hasAnyMethod;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: _paymentAccent.withValues(alpha: 0.12),
            borderRadius: AppRadius.radiusSm,
          ),
          child: Icon(
            Icons.payment_rounded,
            size: 16,
            color: _paymentAccent,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Payment Options',
                style: AppTextStyles.labelLarge.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.1,
                ),
              ),
              Text(
                hasAnyMethod
                    ? 'Add your QR code for the selected method'
                    : 'Choose how payers can send money',
                style: AppTextStyles.labelSmall.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Method selector chip row
// ═════════════════════════════════════════════════════════════════════════════

class _MethodSelectorRow extends StatelessWidget {
  const _MethodSelectorRow({
    required this.colorScheme,
    required this.isDark,
    required this.hasEsewa,
    required this.hasKhalti,
    required this.hasBank,
    required this.onToggle,
  });

  final ColorScheme colorScheme;
  final bool isDark;
  final bool hasEsewa;
  final bool hasKhalti;
  final bool hasBank;
  final void Function(BillPaymentMethod) onToggle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _MethodChip(
          label: 'eSewa',
          icon: 'assets/images/esewa.png',
          color: const Color(0xFF60BB46),
          isSelected: hasEsewa,
          isDark: isDark,
          colorScheme: colorScheme,
          onTap: () => onToggle(BillPaymentMethod.esewa),
        ),
        const SizedBox(width: AppSpacing.sm),
        _MethodChip(
          label: 'Khalti',
          icon: 'assets/images/khalti.png',
          color: const Color(0xFF5C2D91),
          isSelected: hasKhalti,
          isDark: isDark,
          colorScheme: colorScheme,
          onTap: () => onToggle(BillPaymentMethod.khalti),
        ),
        const SizedBox(width: AppSpacing.sm),
        _MethodChip(
          label: 'Banks',
          iconWidget: const Icon(Icons.account_balance_rounded, size: 14),
          color: AppColors.chartBlue,
          isSelected: hasBank,
          isDark: isDark,
          colorScheme: colorScheme,
          onTap: () => onToggle(BillPaymentMethod.bank),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Individual method chip
// ═════════════════════════════════════════════════════════════════════════════

class _MethodChip extends StatefulWidget {
  const _MethodChip({
    required this.label,
    required this.color,
    required this.isSelected,
    required this.isDark,
    required this.colorScheme,
    required this.onTap,
    this.icon,
    this.iconWidget,
  });

  final String label;
  final Color color;
  final bool isSelected;
  final bool isDark;
  final ColorScheme colorScheme;
  final VoidCallback onTap;
  final String? icon;
  final Widget? iconWidget;

  @override
  State<_MethodChip> createState() => _MethodChipState();
}

class _MethodChipState extends State<_MethodChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scale;

  @override
  void initState() {
    super.initState();
    _scale = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.93,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _scale.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = widget.colorScheme;
    final selected = widget.isSelected;

    return Expanded(
      child: ScaleTransition(
        scale: _scale,
        child: GestureDetector(
          onTapDown: (_) => _scale.reverse(),
          onTapUp: (_) {
            _scale.forward();
            widget.onTap();
          },
          onTapCancel: () => _scale.forward(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            height: 80,
            decoration: BoxDecoration(
              color: selected
                  ? widget.color.withValues(alpha: widget.isDark ? 0.25 : 0.12)
                  : cs.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: AppRadius.radiusMd,
              border: Border.all(
                color: selected
                    ? widget.color
                    : cs.outlineVariant.withValues(
                        alpha: widget.isDark ? 0.25 : 0.4,
                      ),
                width: selected ? 1.5 : 1.0,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildIcon(selected, cs),
                const SizedBox(height: 7),
                Text(
                  widget.label,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: selected ? widget.color : cs.onSurfaceVariant,
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 12.5,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(bool selected, ColorScheme cs) {
    if (widget.iconWidget != null) {
      return IconTheme(
        data: IconThemeData(
          color: selected ? widget.color : cs.onSurfaceVariant,
          size: 26,
        ),
        child: widget.iconWidget!,
      );
    }
    if (widget.icon != null) {
      return Image.asset(
        widget.icon!,
        width: 36,
        height: 36,
        errorBuilder: (_, __, ___) => Icon(
          Icons.payment_rounded,
          size: 26,
          color: selected ? widget.color : cs.onSurfaceVariant,
        ),
      );
    }
    return Icon(
      Icons.payment_rounded,
      size: 26,
      color: selected ? widget.color : cs.onSurfaceVariant,
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Individual payment entry (expanded panel per method)
// ═════════════════════════════════════════════════════════════════════════════

class _PaymentEntry extends StatefulWidget {
  const _PaymentEntry({
    super.key,
    required this.entry,
    required this.colorScheme,
    required this.isDark,
    required this.isUploadingQr,
    required this.pulseController,
    required this.onPickQr,
    required this.onRemove,
    required this.onBankNameChanged,
  });

  final PaymentMethodEntry entry;
  final ColorScheme colorScheme;
  final bool isDark;
  final bool isUploadingQr;
  final AnimationController pulseController;
  final VoidCallback onPickQr;
  final VoidCallback onRemove;
  final void Function(String?) onBankNameChanged;

  @override
  State<_PaymentEntry> createState() => _PaymentEntryState();
}

class _PaymentEntryState extends State<_PaymentEntry>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnim = Tween<double>(begin: 0.96, end: 1.0).animate(
      CurvedAnimation(
        parent: _entrance,
        curve: Curves.easeOutBack,
      ),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entrance,
        curve: const Interval(0.1, 1.0, curve: Curves.easeOut),
      ),
    );
    _entrance.forward();
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  PaymentMethodEntry get entry => widget.entry;
  ColorScheme get colorScheme => widget.colorScheme;
  bool get isDark => widget.isDark;

  Color get _accentColor {
    return switch (entry.method) {
      BillPaymentMethod.esewa => const Color(0xFF60BB46),
      BillPaymentMethod.khalti => const Color(0xFF5C2D91),
      BillPaymentMethod.bank => AppColors.chartBlue,
    };
  }

  String get _methodLabel {
    return switch (entry.method) {
      BillPaymentMethod.esewa => 'eSewa',
      BillPaymentMethod.khalti => 'Khalti',
      BillPaymentMethod.bank => 'Bank Transfer',
    };
  }

  String? get _logoPath {
    return switch (entry.method) {
      BillPaymentMethod.esewa => 'assets/images/esewa.png',
      BillPaymentMethod.khalti => 'assets/images/khalti.png',
      BillPaymentMethod.bank => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: FadeTransition(
        opacity: _fadeAnim,
        child: ScaleTransition(
          scale: _scaleAnim,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: _accentColor.withValues(alpha: isDark ? 0.07 : 0.04),
              borderRadius: AppRadius.radiusLg,
              border: Border.all(
                color: _accentColor.withValues(alpha: 0.3),
                width: 1.0,
              ),
            ),
            child: Column(
              children: [
                // ── Entry header ──────────────────────────────────────────
                _EntryHeader(
                  method: entry.method,
                  label: _methodLabel,
                  logoPath: _logoPath,
                  accentColor: _accentColor,
                  colorScheme: colorScheme,
                  isDark: isDark,
                  onRemove: widget.onRemove,
                ),
                Divider(
                  height: 1,
                  color: _accentColor.withValues(alpha: 0.15),
                ),
                // ── Bank selector (only for bank method) ──────────────────
                if (entry.method == BillPaymentMethod.bank) ...[
                  _BankSelector(
                    selectedBank: entry.bankName,
                    accentColor: _accentColor,
                    colorScheme: colorScheme,
                    isDark: isDark,
                    onChanged: widget.onBankNameChanged,
                  ),
                  Divider(
                    height: 1,
                    color: _accentColor.withValues(alpha: 0.15),
                  ),
                ],
                // ── QR code upload zone ────────────────────────────────────
                _QrUploadZone(
                  qrPhotoPath: entry.qrPhotoPath,
                  accentColor: _accentColor,
                  colorScheme: colorScheme,
                  isDark: isDark,
                  isUploading: widget.isUploadingQr,
                  pulseController: widget.pulseController,
                  onTap: widget.onPickQr,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Entry header row
// ═════════════════════════════════════════════════════════════════════════════

class _EntryHeader extends StatelessWidget {
  const _EntryHeader({
    required this.method,
    required this.label,
    required this.logoPath,
    required this.accentColor,
    required this.colorScheme,
    required this.isDark,
    required this.onRemove,
  });

  final BillPaymentMethod method;
  final String label;
  final String? logoPath;
  final Color accentColor;
  final ColorScheme colorScheme;
  final bool isDark;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      child: Row(
        children: [
          // Logo or icon
          if (logoPath != null)
            Image.asset(
              logoPath!,
              width: 22,
              height: 22,
              errorBuilder: (_, __, ___) => Icon(
                Icons.payment_rounded,
                size: 20,
                color: accentColor,
              ),
            )
          else
            Icon(
              Icons.account_balance_rounded,
              size: 20,
              color: accentColor,
            ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            label,
            style: AppTextStyles.labelMedium.copyWith(
              color: accentColor,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
            ),
          ),
          const Spacer(),
          // Remove button
          GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withValues(alpha: 0.06),
                borderRadius: AppRadius.radiusFull,
              ),
              child: Icon(
                Icons.close_rounded,
                size: 14,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Bank selector dropdown
// ═════════════════════════════════════════════════════════════════════════════

class _BankSelector extends StatelessWidget {
  const _BankSelector({
    required this.selectedBank,
    required this.accentColor,
    required this.colorScheme,
    required this.isDark,
    required this.onChanged,
  });

  final String? selectedBank;
  final Color accentColor;
  final ColorScheme colorScheme;
  final bool isDark;
  final void Function(String?) onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_balance_wallet_rounded,
                size: 13,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 5),
              Text(
                'Select Bank',
                style: AppTextStyles.labelSmall.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 5,
                  vertical: 1,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.error.withValues(alpha: 0.1),
                  borderRadius: AppRadius.radiusFull,
                ),
                child: Text(
                  'Required',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: colorScheme.error,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs + 2),
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: AppRadius.radiusMd,
              border: Border.all(
                color: selectedBank != null
                    ? accentColor.withValues(alpha: 0.5)
                    : colorScheme.outlineVariant.withValues(
                        alpha: isDark ? 0.35 : 0.55,
                      ),
                width: selectedBank != null ? 1.5 : 1.0,
              ),
            ),
            child: DropdownButtonFormField<String>(
              initialValue: selectedBank,
              isExpanded: true,
              icon: Icon(
                Icons.expand_more_rounded,
                size: 18,
                color: colorScheme.onSurfaceVariant,
              ),
              style: AppTextStyles.bodySmall.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm + 2,
                ),
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                hintText: 'Choose your bank…',
                hintStyle: AppTextStyles.bodySmall.copyWith(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
              ),
              dropdownColor: colorScheme.surface,
              borderRadius: AppRadius.radiusMd,
              items: nepalBankNames.map((bank) {
                return DropdownMenuItem(
                  value: bank,
                  child: Text(
                    bank,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: colorScheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// QR Upload zone
// ═════════════════════════════════════════════════════════════════════════════

class _QrUploadZone extends StatefulWidget {
  const _QrUploadZone({
    required this.qrPhotoPath,
    required this.accentColor,
    required this.colorScheme,
    required this.isDark,
    required this.isUploading,
    required this.pulseController,
    required this.onTap,
  });

  final String? qrPhotoPath;
  final Color accentColor;
  final ColorScheme colorScheme;
  final bool isDark;
  final bool isUploading;
  final AnimationController pulseController;
  final VoidCallback onTap;

  @override
  State<_QrUploadZone> createState() => _QrUploadZoneState();
}

class _QrUploadZoneState extends State<_QrUploadZone>
    with SingleTickerProviderStateMixin {
  late final AnimationController _tap;

  @override
  void initState() {
    super.initState();
    _tap = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.97,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _tap.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasQr = widget.qrPhotoPath != null;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.qr_code_2_rounded,
                size: 13,
                color: widget.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 5),
              Text(
                'QR Code',
                style: AppTextStyles.labelSmall.copyWith(
                  color: widget.colorScheme.onSurfaceVariant,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 5,
                  vertical: 1,
                ),
                decoration: BoxDecoration(
                  color: widget.colorScheme.error.withValues(alpha: 0.1),
                  borderRadius: AppRadius.radiusFull,
                ),
                child: Text(
                  'Required',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: widget.colorScheme.error,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ScaleTransition(
            scale: _tap,
            child: GestureDetector(
              onTapDown: (_) => _tap.reverse(),
              onTapUp: (_) {
                _tap.forward();
                if (!widget.isUploading) widget.onTap();
              },
              onTapCancel: () => _tap.forward(),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                height: hasQr ? 120 : 90,
                decoration: BoxDecoration(
                  color: hasQr
                      ? Colors.transparent
                      : widget.accentColor.withValues(
                          alpha: widget.isDark ? 0.06 : 0.04,
                        ),
                  borderRadius: AppRadius.radiusMd,
                  border: Border.all(
                    color: hasQr
                        ? widget.accentColor.withValues(alpha: 0.4)
                        : widget.accentColor.withValues(alpha: 0.25),
                    width: hasQr ? 1.5 : 1.0,
                    style: hasQr ? BorderStyle.solid : BorderStyle.solid,
                  ),
                ),
                child: widget.isUploading
                    ? _LoadingOverlay(
                        accentColor: widget.accentColor,
                        pulseController: widget.pulseController,
                      )
                    : hasQr
                        ? _QrPreview(
                            path: widget.qrPhotoPath!,
                            accentColor: widget.accentColor,
                            colorScheme: widget.colorScheme,
                          )
                        : _UploadPrompt(
                            accentColor: widget.accentColor,
                            colorScheme: widget.colorScheme,
                          ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Upload prompt (empty state)
// ═════════════════════════════════════════════════════════════════════════════

class _UploadPrompt extends StatelessWidget {
  const _UploadPrompt({
    required this.accentColor,
    required this.colorScheme,
  });

  final Color accentColor;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate_outlined,
            size: 24,
            color: accentColor.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 5),
          Text(
            'Tap to upload QR Code',
            style: AppTextStyles.labelSmall.copyWith(
              color: accentColor,
              fontWeight: FontWeight.w600,
              fontSize: 11,
              letterSpacing: 0.1,
            ),
          ),
          Text(
            'from your gallery',
            style: AppTextStyles.labelSmall.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// QR preview (when image is picked)
// ═════════════════════════════════════════════════════════════════════════════

class _QrPreview extends StatelessWidget {
  const _QrPreview({
    required this.path,
    required this.accentColor,
    required this.colorScheme,
  });

  final String path;
  final Color accentColor;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Image — wrapped in Positioned.fill so it always gets bounded
        // constraints from the Stack, even during AnimatedContainer height
        // transitions.  Without this, Image.file's intrinsic size can cause
        // "Stack requires bounded constraints" errors.
        Positioned.fill(
          child: ClipRRect(
            borderRadius: AppRadius.radiusMd,
            child: Image.file(
              io.File(path),
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Center(
                child: Icon(
                  Icons.broken_image_outlined,
                  size: 28,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
        // Change overlay badge
        Positioned(
          bottom: 6,
          right: 6,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 3,
            ),
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: AppRadius.radiusFull,
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.4),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.edit_rounded, size: 9, color: Colors.white),
                const SizedBox(width: 3),
                Text(
                  'Change',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
        // ✓ badge top-left
        Positioned(
          top: 6,
          left: 6,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.success.withValues(alpha: 0.4),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 10,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Loading overlay while picking/uploading
// ═════════════════════════════════════════════════════════════════════════════

class _LoadingOverlay extends StatelessWidget {
  const _LoadingOverlay({
    required this.accentColor,
    required this.pulseController,
  });

  final Color accentColor;
  final AnimationController pulseController;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: pulseController,
        builder: (_, child) {
          final t = pulseController.value;
          final scale = 0.90 + 0.10 * math.sin(math.pi * t);
          final alpha = 0.5 + 0.5 * math.sin(math.pi * t);
          return Transform.scale(
            scale: scale,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation(
                      accentColor.withValues(alpha: alpha),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Uploading…',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: accentColor.withValues(alpha: alpha),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Color constant for the payment card accent
// ═════════════════════════════════════════════════════════════════════════════

const Color _paymentAccent = Color(0xFF10B981); // matches app teal
