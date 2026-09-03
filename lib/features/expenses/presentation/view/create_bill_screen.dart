import 'dart:io' as io;
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/theme/design_system.dart';
import '../../../../core/widgets/animated_entrance.dart';
import '../../../groups/domain/entities/group.dart';
import '../../domain/entities/bill.dart';
import '../state/create_bill_provider.dart';

// ═════════════════════════════════════════════════════════════════════════════
// Screen
// ═════════════════════════════════════════════════════════════════════════════

/// Full-screen bill-creation form pushed on top of the app shell when the
/// user taps a group card.
///
/// Orchestrates:
/// - Staggered entrance animation (master controller).
/// - Ambient floating animation for the hero image and button pulse.
/// - In-memory form state via [createBillProvider].
/// - Image picker for a receipt photo.
/// - "Review & Create Bill" bottom sheet.
class CreateBillScreen extends ConsumerStatefulWidget {
  const CreateBillScreen({
    super.key,
    required this.group,
    required this.currentUserId,
  });

  final Group group;
  final String currentUserId;

  @override
  ConsumerState<CreateBillScreen> createState() => _CreateBillScreenState();
}

class _CreateBillScreenState extends ConsumerState<CreateBillScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entrance;
  late final AnimationController _ambient;

  /// Key used to scope the provider to this screen instance.
  late final CreateBillKey _providerKey;

  /// Whether a receipt photo is currently being picked.
  bool _isPickingPhoto = false;

  @override
  void initState() {
    super.initState();
    _providerKey = (group: widget.group, currentUserId: widget.currentUserId);

    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();

    _startEntrance();
  }

  Future<void> _startEntrance() async {
    await Future.delayed(const Duration(milliseconds: 80));
    if (mounted) _entrance.forward();
  }

  @override
  void dispose() {
    _entrance.dispose();
    _ambient.dispose();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _stagger(Widget child, double start, double end, {double slide = 28}) {
    return StaggeredEntrance(
      animation: _entrance,
      interval: Interval(start, end, curve: Curves.easeOutCubic),
      slideOffset: slide,
      child: child,
    );
  }

  CreateBillFormState get _form => ref.watch(createBillProvider(_providerKey));
  CreateBillNotifier get _notifier =>
      ref.read(createBillProvider(_providerKey).notifier);

  // ── Amount entry ───────────────────────────────────────────────────────────

  Future<void> _openAmountDialog(ColorScheme colorScheme, bool isDark) async {
    final controller = TextEditingController(
      text: _form.amount > 0 ? _form.amount.toStringAsFixed(2) : '',
    );
    await showDialog<void>(
      context: context,
      builder: (ctx) => _AmountDialog(
        controller: controller,
        colorScheme: colorScheme,
        isDark: isDark,
        onConfirm: (text) {
          final parsed = double.tryParse(text) ?? 0.0;
          _notifier.setAmount(parsed, text);
        },
      ),
    );
  }

  // ── Receipt photo ──────────────────────────────────────────────────────────

  Future<void> _pickReceiptPhoto() async {
    if (_isPickingPhoto) return;
    setState(() => _isPickingPhoto = true);
    try {
      final xFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (xFile == null) return;
      _notifier.setReceiptPhoto(xFile.path);
    } on Exception {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not open the gallery. Please try again.',
              style: AppTextStyles.bodySmall.copyWith(
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPickingPhoto = false);
    }
  }

  // ── Title / Note dialogs ───────────────────────────────────────────────────

  Future<void> _openTitleDialog(ColorScheme colorScheme, bool isDark) async {
    final controller = TextEditingController(text: _form.title);
    await showDialog<void>(
      context: context,
      builder: (ctx) => _TextFieldDialog(
        controller: controller,
        colorScheme: colorScheme,
        isDark: isDark,
        title: 'Add Title',
        hint: 'e.g. Dinner, Hotel, Taxi',
        maxLength: AppConstants.billTitleMaxLength,
        onConfirm: _notifier.setTitle,
      ),
    );
  }

  Future<void> _openNoteDialog(ColorScheme colorScheme, bool isDark) async {
    final controller = TextEditingController(text: _form.note);
    await showDialog<void>(
      context: context,
      builder: (ctx) => _TextFieldDialog(
        controller: controller,
        colorScheme: colorScheme,
        isDark: isDark,
        title: 'Add Note',
        hint: 'Any additional details…',
        maxLength: AppConstants.billNoteMaxLength,
        maxLines: 4,
        onConfirm: _notifier.setNote,
      ),
    );
  }

  // ── Date picker ────────────────────────────────────────────────────────────

  Future<void> _openDatePicker() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _form.date ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) _notifier.setDate(picked);
  }

  // ── Exclude picker sheet ───────────────────────────────────────────────────

  void _openExcludePicker(ColorScheme colorScheme, bool isDark) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ExcludePickerSheet(
        participants: _form.participants,
        colorScheme: colorScheme,
        isDark: isDark,
        onToggle: _notifier.toggleParticipant,
      ),
    );
  }

  // ── Review sheet ───────────────────────────────────────────────────────────

  void _openReviewSheet(ColorScheme colorScheme, bool isDark) {
    final error = _notifier.validate();
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error,
            style: AppTextStyles.bodySmall.copyWith(
              color: colorScheme.onPrimary,
            ),
          ),
          backgroundColor: colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReviewSheet(
        form: _form,
        group: widget.group,
        currentUserId: widget.currentUserId,
        colorScheme: colorScheme,
        isDark: isDark,
        onConfirm: () {
          final ok = _notifier.createBill(
            createdBy: widget.currentUserId,
            groupId: widget.group.id,
            groupName: widget.group.groupName,
          );
          if (ok && mounted) {
            Navigator.of(context).pop(); // close sheet
            Navigator.of(context).pop(); // close screen
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Bill created successfully!',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: colorScheme.onPrimary,
                  ),
                ),
                backgroundColor: colorScheme.primary,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenHorizontal,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.md),
                    // ── App bar ──────────────────────────────────────────
                    _stagger(
                      _AppBar(
                        group: widget.group,
                        colorScheme: colorScheme,
                        isDark: isDark,
                        onBack: () => Navigator.of(context).maybePop(),
                      ),
                      0.0, 0.14,
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    // ── Hero header ──────────────────────────────────────
                    _stagger(
                      _HeroHeader(
                        ambient: _ambient,
                        colorScheme: colorScheme,
                      ),
                      0.04, 0.22,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    // ── Total amount card ────────────────────────────────
                    _stagger(
                      _TotalAmountCard(
                        amount: _form.amount,
                        rawText: _form.rawAmountText,
                        amountError: _form.amountError,
                        ambient: _ambient,
                        colorScheme: colorScheme,
                        isDark: isDark,
                        onTap: () => _openAmountDialog(colorScheme, isDark),
                      ),
                      0.10, 0.28,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    // ── Quick info row ───────────────────────────────────
                    _stagger(
                      _QuickInfoRow(
                        form: _form,
                        colorScheme: colorScheme,
                        isDark: isDark,
                        isPickingPhoto: _isPickingPhoto,
                        onAddPhoto: _pickReceiptPhoto,
                        onAddTitle: () => _openTitleDialog(colorScheme, isDark),
                        onAddNote: () => _openNoteDialog(colorScheme, isDark),
                        onSelectDate: _openDatePicker,
                      ),
                      0.18, 0.36,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    // ── Split mode selector ──────────────────────────────
                    _stagger(
                      _SplitSectionHeader(colorScheme: colorScheme),
                      0.26, 0.42,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _stagger(
                      _SplitSelector(
                        splitMode: _form.splitMode,
                        colorScheme: colorScheme,
                        isDark: isDark,
                        onChanged: _notifier.setSplitMode,
                      ),
                      0.30, 0.46,
                    ),
                    // Custom split error
                    if (_form.customSplitError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.sm),
                        child: _InlineError(
                          message: _form.customSplitError!,
                          colorScheme: colorScheme,
                        ),
                      ),
                    const SizedBox(height: AppSpacing.xl),
                    // ── Custom amounts (when custom split selected) ──────
                    if (_form.splitMode == BillSplitMode.custom) ...[
                      _stagger(
                        _CustomSplitSection(
                          participants: _form.participants,
                          colorScheme: colorScheme,
                          isDark: isDark,
                          onSetShare: _notifier.setCustomShare,
                        ),
                        0.32, 0.50,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                    ],
                    // ── Add members ──────────────────────────────────────
                    _stagger(
                      _MembersSection(
                        participants: _form.participants,
                        colorScheme: colorScheme,
                        isDark: isDark,
                        participantsError: _form.participantsError,
                        onToggle: _notifier.toggleParticipant,
                      ),
                      0.38, 0.54,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    // ── Exclude from bill row ────────────────────────────
                    _stagger(
                      _ExcludeTile(
                        excludedCount: _form.participants
                            .where((p) => !p.isIncluded)
                            .length,
                        colorScheme: colorScheme,
                        isDark: isDark,
                        onTap: () => _openExcludePicker(colorScheme, isDark),
                      ),
                      0.44, 0.60,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    // ── Summary strip ────────────────────────────────────
                    _stagger(
                      _SummaryCard(
                        form: _form,
                        currentUserId: widget.currentUserId,
                        colorScheme: colorScheme,
                        isDark: isDark,
                      ),
                      0.50, 0.66,
                    ),
                    const SizedBox(height: AppSpacing.xxxl),
                  ],
                ),
              ),
            ),
            // ── Sticky CTA ──────────────────────────────────────────────
            SliverFillRemaining(
              hasScrollBody: false,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: _stagger(
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screenHorizontal,
                      AppSpacing.lg,
                      AppSpacing.screenHorizontal,
                      AppSpacing.xl,
                    ),
                    child: _ReviewButton(
                      canReview: _form.canReview,
                      ambient: _ambient,
                      colorScheme: colorScheme,
                      onTap: () => _openReviewSheet(colorScheme, isDark),
                    ),
                  ),
                  0.58, 0.76,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// App bar
// ═════════════════════════════════════════════════════════════════════════════

class _AppBar extends StatelessWidget {
  const _AppBar({
    required this.group,
    required this.colorScheme,
    required this.isDark,
    required this.onBack,
  });

  final Group group;
  final ColorScheme colorScheme;
  final bool isDark;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _AnimatedTapScale(
          onTap: onBack,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colorScheme.surface,
              shape: BoxShape.circle,
              border: Border.all(color: colorScheme.outlineVariant),
              boxShadow: isDark ? AppShadows.xsDark : AppShadows.xsLight,
            ),
            child: Icon(
              Icons.close,
              color: colorScheme.onSurface,
              size: 20,
            ),
          ),
        ),
        const Spacer(),
        // Group member count chip.
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: AppRadius.radiusFull,
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.6),
            ),
            boxShadow: isDark ? AppShadows.xsDark : AppShadows.xsLight,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.people_alt_rounded,
                size: 16,
                color: colorScheme.primary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '${group.memberCount}',
                style: AppTextStyles.labelMedium.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
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
// Hero header — title + floating bill_and_coins.png
// ═════════════════════════════════════════════════════════════════════════════

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({
    required this.ambient,
    required this.colorScheme,
  });

  final AnimationController ambient;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ── Left: title block ──────────────────────────────────────────
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'New Bill',
                  style: AppTextStyles.headlineMedium.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                RichText(
                  text: TextSpan(
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    children: [
                      const TextSpan(text: 'Split expenses. '),
                      TextSpan(
                        text: 'Settle stories.',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                          decorationColor: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                // Decorative pill — group name.
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                    borderRadius: AppRadius.radiusFull,
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Text(
                    context
                            .findAncestorWidgetOfExactType<CreateBillScreen>()
                            ?.group
                            .groupName ??
                        '',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          // ── Right: floating illustration ───────────────────────────────
          Positioned(
            right: -AppSpacing.screenHorizontal,
            top: -24,
            child: AnimatedBuilder(
              animation: ambient,
              builder: (context, child) {
                final t = ambient.value;
                final floatY = math.sin(t * 2 * math.pi) * 6;
                final floatX = math.sin(t * 2 * math.pi + 1.0) * 2;
                return Transform.translate(
                  offset: Offset(floatX, floatY),
                  child: child,
                );
              },
              child: Image.asset(
                'assets/images/bill_and_coins.png',
                width: 160,
                height: 160,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Total amount card
// ═════════════════════════════════════════════════════════════════════════════

class _TotalAmountCard extends StatelessWidget {
  const _TotalAmountCard({
    required this.amount,
    required this.rawText,
    required this.amountError,
    required this.ambient,
    required this.colorScheme,
    required this.isDark,
    required this.onTap,
  });

  final double amount;
  final String rawText;
  final String? amountError;
  final AnimationController ambient;
  final ColorScheme colorScheme;
  final bool isDark;
  final VoidCallback onTap;

  String get _displayAmount {
    if (amount <= 0 && rawText.isEmpty) return '0';
    if (amount <= 0) return rawText;
    // Show up to 2 decimals, strip trailing zeros.
    final formatted = amount.toStringAsFixed(2);
    return formatted.endsWith('.00')
        ? formatted.substring(0, formatted.length - 3)
        : formatted;
  }

  @override
  Widget build(BuildContext context) {
    final gradient = isDark
        ? AppColors.darkPrimaryGradient
        : AppColors.lightPrimaryGradient;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedBuilder(
          animation: ambient,
          builder: (context, child) {
            final t = ambient.value;
            final sweepX = -0.3 + 1.6 * t;
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                borderRadius: AppRadius.radiusXxl,
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: gradient.colors,
                ),
                boxShadow: isDark
                    ? AppShadows.primaryGlowDark
                    : AppShadows.primaryGlowLight,
              ),
              child: Stack(
                children: [
                  // Ambient sheen sweep.
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: AppRadius.radiusXxl,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment(sweepX, -0.8),
                            end: Alignment(sweepX + 0.4, 0.8),
                            colors: [
                              Colors.white.withValues(alpha: 0.0),
                              Colors.white.withValues(alpha: isDark ? 0.06 : 0.10),
                              Colors.white.withValues(alpha: 0.0),
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),
                  child!,
                ],
              ),
            );
          },
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Amount',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: colorScheme.onPrimary.withValues(alpha: 0.8),
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '${AppConstants.currencySymbol} ',
                          style: AppTextStyles.titleLarge.copyWith(
                            color: colorScheme.onPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (child, anim) => FadeTransition(
                            opacity: anim,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 0.3),
                                end: Offset.zero,
                              ).animate(anim),
                              child: child,
                            ),
                          ),
                          child: Text(
                            _displayAmount,
                            key: ValueKey(_displayAmount),
                            style: AppTextStyles.amountLarge.copyWith(
                              color: colorScheme.onPrimary,
                              height: 1.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Edit button.
              _AnimatedTapScale(
                onTap: onTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.onPrimary.withValues(alpha: 0.2),
                    borderRadius: AppRadius.radiusFull,
                    border: Border.all(
                      color: colorScheme.onPrimary.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Enter amount',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Icon(
                        Icons.edit_rounded,
                        size: 16,
                        color: colorScheme.onPrimary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (amountError != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm, left: AppSpacing.xs),
            child: _InlineError(
              message: amountError!,
              colorScheme: colorScheme,
            ),
          ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Quick info row — Photo / Title / Note / Date
// ═════════════════════════════════════════════════════════════════════════════

class _QuickInfoRow extends StatelessWidget {
  const _QuickInfoRow({
    required this.form,
    required this.colorScheme,
    required this.isDark,
    required this.isPickingPhoto,
    required this.onAddPhoto,
    required this.onAddTitle,
    required this.onAddNote,
    required this.onSelectDate,
  });

  final CreateBillFormState form;
  final ColorScheme colorScheme;
  final bool isDark;
  final bool isPickingPhoto;
  final VoidCallback onAddPhoto;
  final VoidCallback onAddTitle;
  final VoidCallback onAddNote;
  final VoidCallback onSelectDate;

  @override
  Widget build(BuildContext context) {
    final date = form.date;
    final dateLabel = date != null ? _formatDate(date) : 'Select Date';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: AppRadius.radiusXxl,
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: isDark ? 0.3 : 0.5),
        ),
        boxShadow: isDark ? AppShadows.smDark : AppShadows.smLight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Info',
            style: AppTextStyles.labelLarge.copyWith(
              color: colorScheme.onSurfaceVariant,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _QuickInfoChip(
                icon: isPickingPhoto
                    ? Icons.hourglass_top_rounded
                    : (form.receiptPhotoPath != null
                        ? Icons.check_circle_rounded
                        : Icons.camera_alt_outlined),
                label: 'Add Photo',
                sublabel: form.receiptPhotoPath != null
                    ? 'Attached'
                    : 'Upload bill image',
                color: AppColors.chartOrange,
                isDone: form.receiptPhotoPath != null,
                colorScheme: colorScheme,
                isDark: isDark,
                onTap: onAddPhoto,
              ),
              _QuickInfoChip(
                icon: form.title.isNotEmpty
                    ? Icons.title_rounded
                    : Icons.title_outlined,
                label: 'Add Title',
                sublabel: form.title.isNotEmpty ? form.title : "What's this for?",
                color: AppColors.chartBlue,
                isDone: form.title.isNotEmpty,
                colorScheme: colorScheme,
                isDark: isDark,
                onTap: onAddTitle,
              ),
              _QuickInfoChip(
                icon: form.note.isNotEmpty
                    ? Icons.sticky_note_2_rounded
                    : Icons.sticky_note_2_outlined,
                label: 'Add Note',
                sublabel: form.note.isNotEmpty ? 'Added' : 'Any details?',
                color: AppColors.chartPurple,
                isDone: form.note.isNotEmpty,
                colorScheme: colorScheme,
                isDark: isDark,
                onTap: onAddNote,
              ),
              _QuickInfoChip(
                icon: form.date != null
                    ? Icons.event_available_rounded
                    : Icons.calendar_today_outlined,
                label: dateLabel,
                sublabel: form.date != null ? 'Set' : 'When was this?',
                color: AppColors.chartPurple.withValues(alpha: 0.7),
                isDone: form.date != null,
                colorScheme: colorScheme,
                isDark: isDark,
                onTap: onSelectDate,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}';
  }
}

class _QuickInfoChip extends StatelessWidget {
  const _QuickInfoChip({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.color,
    required this.isDone,
    required this.colorScheme,
    required this.isDark,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String sublabel;
  final Color color;
  final bool isDone;
  final ColorScheme colorScheme;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _AnimatedTapScale(
      onTap: onTap,
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            // Circle icon.
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: isDone
                    ? color.withValues(alpha: 0.18)
                    : colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDone
                      ? color.withValues(alpha: 0.4)
                      : colorScheme.outlineVariant.withValues(alpha: 0.5),
                  width: isDone ? 1.5 : 1.0,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    icon,
                    color: isDone ? color : colorScheme.onSurfaceVariant,
                    size: 24,
                  ),
                  if (isDone)
                    Positioned(
                      right: 6,
                      bottom: 6,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 8,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              sublabel,
              style: AppTextStyles.caption.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Split section header
// ═════════════════════════════════════════════════════════════════════════════

class _SplitSectionHeader extends StatelessWidget {
  const _SplitSectionHeader({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'How do you want to split?',
          style: AppTextStyles.titleSmall.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Icon(
          Icons.arrow_forward_rounded,
          size: 18,
          color: colorScheme.primary,
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Split selector
// ═════════════════════════════════════════════════════════════════════════════

class _SplitSelector extends StatelessWidget {
  const _SplitSelector({
    required this.splitMode,
    required this.colorScheme,
    required this.isDark,
    required this.onChanged,
  });

  final BillSplitMode splitMode;
  final ColorScheme colorScheme;
  final bool isDark;
  final ValueChanged<BillSplitMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SplitCard(
            mode: BillSplitMode.equal,
            icon: Icons.people_alt_rounded,
            iconColor: colorScheme.primary,
            title: 'Equal Split',
            subtitle: 'Everyone pays\nthe same amount',
            isSelected: splitMode == BillSplitMode.equal,
            colorScheme: colorScheme,
            isDark: isDark,
            onTap: () => onChanged(BillSplitMode.equal),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _SplitCard(
            mode: BillSplitMode.custom,
            icon: Icons.tune_rounded,
            iconColor: AppColors.chartBlue,
            title: 'Custom Split',
            subtitle: 'Set custom amounts\nfor each member',
            isSelected: splitMode == BillSplitMode.custom,
            colorScheme: colorScheme,
            isDark: isDark,
            onTap: () => onChanged(BillSplitMode.custom),
          ),
        ),
      ],
    );
  }
}

class _SplitCard extends StatelessWidget {
  const _SplitCard({
    required this.mode,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.colorScheme,
    required this.isDark,
    required this.onTap,
  });

  final BillSplitMode mode;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool isSelected;
  final ColorScheme colorScheme;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _AnimatedTapScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer.withValues(alpha: isDark ? 0.25 : 0.55)
              : colorScheme.surface,
          borderRadius: AppRadius.radiusXxl,
          border: Border.all(
            color: isSelected
                ? colorScheme.primary.withValues(alpha: 0.6)
                : colorScheme.outlineVariant.withValues(alpha: isDark ? 0.3 : 0.5),
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? (isDark ? AppShadows.primaryGlowDark : AppShadows.primaryGlowLight)
              : (isDark ? AppShadows.xsDark : AppShadows.xsLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const Spacer(),
                AnimatedScale(
                  scale: isSelected ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutBack,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              style: AppTextStyles.titleSmall.copyWith(
                color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle,
              style: AppTextStyles.caption.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Custom split section — per-member amount fields
// ═════════════════════════════════════════════════════════════════════════════

class _CustomSplitSection extends StatelessWidget {
  const _CustomSplitSection({
    required this.participants,
    required this.colorScheme,
    required this.isDark,
    required this.onSetShare,
  });

  final List<BillParticipant> participants;
  final ColorScheme colorScheme;
  final bool isDark;
  final void Function(String id, double share) onSetShare;

  @override
  Widget build(BuildContext context) {
    final included = participants.where((p) => p.isIncluded).toList();
    if (included.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: AppRadius.radiusXxl,
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: isDark ? 0.3 : 0.5),
        ),
        boxShadow: isDark ? AppShadows.smDark : AppShadows.smLight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune_rounded, size: 18, color: AppColors.chartBlue),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Custom Amounts',
                style: AppTextStyles.labelLarge.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          for (final p in included) ...[
            _CustomShareRow(
              participant: p,
              colorScheme: colorScheme,
              isDark: isDark,
              onChanged: (v) => onSetShare(p.id, v),
            ),
            if (p != included.last)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Divider(
                  height: 1,
                  color: colorScheme.outlineVariant.withValues(
                    alpha: isDark ? 0.3 : 0.4,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _CustomShareRow extends StatefulWidget {
  const _CustomShareRow({
    required this.participant,
    required this.colorScheme,
    required this.isDark,
    required this.onChanged,
  });

  final BillParticipant participant;
  final ColorScheme colorScheme;
  final bool isDark;
  final ValueChanged<double> onChanged;

  @override
  State<_CustomShareRow> createState() => _CustomShareRowState();
}

class _CustomShareRowState extends State<_CustomShareRow> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    final initial = widget.participant.customShare;
    _ctrl = TextEditingController(
      text: initial > 0 ? initial.toStringAsFixed(2) : '',
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = widget.colorScheme;
    return Row(
      children: [
        _SmallAvatar(participant: widget.participant, colorScheme: cs),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            widget.participant.bestDisplayName,
            style: AppTextStyles.titleSmall.copyWith(
              color: cs.onSurface,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        SizedBox(
          width: 110,
          child: TextField(
            controller: _ctrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            textAlign: TextAlign.end,
            style: AppTextStyles.titleSmall.copyWith(color: cs.onSurface),
            decoration: InputDecoration(
              hintText: '0.00',
              prefixText: '${AppConstants.currencySymbol} ',
              prefixStyle: AppTextStyles.labelSmall.copyWith(
                color: cs.onSurfaceVariant,
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.sm,
              ),
            ),
            onChanged: (v) {
              final parsed = double.tryParse(v) ?? 0.0;
              widget.onChanged(parsed);
            },
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Members section
// ═════════════════════════════════════════════════════════════════════════════

class _MembersSection extends StatelessWidget {
  const _MembersSection({
    required this.participants,
    required this.colorScheme,
    required this.isDark,
    required this.participantsError,
    required this.onToggle,
  });

  final List<BillParticipant> participants;
  final ColorScheme colorScheme;
  final bool isDark;
  final String? participantsError;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Add Members',
              style: AppTextStyles.titleSmall.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: AppRadius.radiusFull,
              ),
              child: Text(
                '${participants.where((p) => p.isIncluded).length}/${participants.length}',
                style: AppTextStyles.labelSmall.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        // Horizontal scroll of participant avatars.
        SizedBox(
          height: 90,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
            itemCount: participants.length,
            separatorBuilder: (_, __) =>
                const SizedBox(width: AppSpacing.md),
            itemBuilder: (_, i) {
              final p = participants[i];
              return _ParticipantAvatar(
                participant: p,
                colorScheme: colorScheme,
                isDark: isDark,
                onRemove: () => onToggle(p.id),
              );
            },
          ),
        ),
        if (participantsError != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: _InlineError(
              message: participantsError!,
              colorScheme: colorScheme,
            ),
          ),
      ],
    );
  }
}

class _ParticipantAvatar extends StatelessWidget {
  const _ParticipantAvatar({
    required this.participant,
    required this.colorScheme,
    required this.isDark,
    required this.onRemove,
  });

  final BillParticipant participant;
  final ColorScheme colorScheme;
  final bool isDark;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final included = participant.isIncluded;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedOpacity(
              duration: const Duration(milliseconds: 250),
              opacity: included ? 1.0 : 0.4,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: included
                        ? colorScheme.primary.withValues(alpha: 0.5)
                        : colorScheme.outlineVariant,
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: participant.profilePicture != null &&
                          participant.profilePicture!.isNotEmpty
                      ? Image.network(
                          participant.profilePicture!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _AvatarFallback(participant: participant, colorScheme: colorScheme),
                        )
                      : _AvatarFallback(
                          participant: participant,
                          colorScheme: colorScheme,
                        ),
                ),
              ),
            ),
            // Remove / restore button.
            Positioned(
              top: -4,
              right: -4,
              child: _AnimatedTapScale(
                onTap: onRemove,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: included
                          ? colorScheme.outlineVariant
                          : colorScheme.primary.withValues(alpha: 0.4),
                      width: 1,
                    ),
                    boxShadow: AppShadows.xsLight,
                  ),
                  child: Icon(
                    included ? Icons.close : Icons.add,
                    size: 12,
                    color: included
                        ? colorScheme.onSurfaceVariant
                        : colorScheme.primary,
                  ),
                ),
              ),
            ),
            // "You" badge.
            if (participant.isCurrentUser)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: AppRadius.radiusFull,
                    ),
                    child: Text(
                      'You',
                      style: AppTextStyles.caption.copyWith(
                        color: colorScheme.onPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 9,
                        height: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          participant.isCurrentUser
              ? 'You'
              : participant.bestDisplayName.split(' ').first,
          style: AppTextStyles.caption.copyWith(
            color: included ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback({
    required this.participant,
    required this.colorScheme,
  });

  final BillParticipant participant;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: colorScheme.primaryContainer,
      alignment: Alignment.center,
      child: Text(
        participant.initials,
        style: AppTextStyles.labelMedium.copyWith(
          color: colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Exclude from this bill tile
// ═════════════════════════════════════════════════════════════════════════════

class _ExcludeTile extends StatelessWidget {
  const _ExcludeTile({
    required this.excludedCount,
    required this.colorScheme,
    required this.isDark,
    required this.onTap,
  });

  final int excludedCount;
  final ColorScheme colorScheme;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _AnimatedTapScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(
            alpha: isDark ? 0.4 : 0.6,
          ),
          borderRadius: AppRadius.radiusLg,
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: isDark ? 0.3 : 0.5),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shield_outlined,
                size: 20,
                color: AppColors.warning,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Exclude from this bill',
                    style: AppTextStyles.titleSmall.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    excludedCount > 0
                        ? '$excludedCount person${excludedCount > 1 ? 's' : ''} excluded'
                        : "Choose people who shouldn't pay",
                    style: AppTextStyles.caption.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (excludedCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.15),
                  borderRadius: AppRadius.radiusFull,
                ),
                child: Text(
                  '$excludedCount',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            const SizedBox(width: AppSpacing.sm),
            Icon(
              Icons.chevron_right_rounded,
              color: colorScheme.onSurfaceVariant,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Summary card — You pay / Per person
// ═════════════════════════════════════════════════════════════════════════════

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.form,
    required this.currentUserId,
    required this.colorScheme,
    required this.isDark,
  });

  final CreateBillFormState form;
  final String currentUserId;
  final ColorScheme colorScheme;
  final bool isDark;

  double get _currentUserShare {
    final me = form.participants.cast<BillParticipant?>().firstWhere(
          (p) => p?.isCurrentUser == true,
          orElse: () => null,
        );
    if (me == null || !me.isIncluded) return 0.0;
    return form.splitMode == BillSplitMode.equal
        ? form.perPersonAmount
        : me.customShare;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: AppRadius.radiusXxl,
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: isDark ? 0.3 : 0.5),
        ),
        boxShadow: isDark ? AppShadows.smDark : AppShadows.smLight,
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // You pay.
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: _SummaryPill(
                  icon: Icons.person_rounded,
                  iconColor: colorScheme.primary,
                  label: 'You pay',
                  amount: _currentUserShare,
                  colorScheme: colorScheme,
                ),
              ),
            ),
            VerticalDivider(
              width: 1,
              color: colorScheme.outlineVariant.withValues(
                alpha: isDark ? 0.3 : 0.5,
              ),
            ),
            // Per person.
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: _SummaryPill(
                  icon: Icons.people_alt_rounded,
                  iconColor: AppColors.chartBlue,
                  label: 'Per person',
                  amount: form.perPersonAmount,
                  colorScheme: colorScheme,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.amount,
    required this.colorScheme,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final double amount;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final formatted = amount > 0
        ? '${AppConstants.currencySymbol} ${amount.toStringAsFixed(2)}'
        : '${AppConstants.currencySymbol} 0';

    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.3),
                      end: Offset.zero,
                    ).animate(anim),
                    child: child,
                  ),
                ),
                child: Text(
                  formatted,
                  key: ValueKey(formatted),
                  style: AppTextStyles.amountMedium.copyWith(
                    color: colorScheme.onSurface,
                    fontSize: 18,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
// Review & Create Bill button
// ═════════════════════════════════════════════════════════════════════════════

class _ReviewButton extends StatelessWidget {
  const _ReviewButton({
    required this.canReview,
    required this.ambient,
    required this.colorScheme,
    required this.onTap,
  });

  final bool canReview;
  final AnimationController ambient;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _AnimatedTapScale(
      onTap: canReview ? onTap : null,
      child: AnimatedBuilder(
        animation: ambient,
        builder: (context, child) {
          final pulse = canReview
              ? (1 - math.cos(math.pi * 2 * ambient.value)) * 0.5
              : 0.0;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            width: double.infinity,
            height: 62,
            decoration: BoxDecoration(
              color: canReview
                  ? colorScheme.primary
                  : colorScheme.onSurface.withValues(alpha: 0.12),
              borderRadius: AppRadius.radiusXxl,
              boxShadow: canReview
                  ? [
                      BoxShadow(
                        color: colorScheme.primary.withValues(
                          alpha: 0.20 + 0.30 * pulse,
                        ),
                        blurRadius: 12 + 16 * pulse,
                        spreadRadius: 1 + 2 * pulse,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
            child: child,
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: canReview
                      ? colorScheme.onPrimary.withValues(alpha: 0.15)
                      : colorScheme.onSurface.withValues(alpha: 0.08),
                  borderRadius: AppRadius.radiusMd,
                ),
                child: Icon(
                  Icons.receipt_long_rounded,
                  color: canReview
                      ? colorScheme.onPrimary
                      : colorScheme.onSurface.withValues(alpha: 0.38),
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Review & Create Bill',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: canReview
                            ? colorScheme.onPrimary
                            : colorScheme.onSurface.withValues(alpha: 0.38),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      canReview
                          ? 'Preview and confirm details'
                          : 'Enter amount to continue',
                      style: AppTextStyles.caption.copyWith(
                        color: canReview
                            ? colorScheme.onPrimary.withValues(alpha: 0.75)
                            : colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: canReview
                      ? colorScheme.onPrimary.withValues(alpha: 0.18)
                      : colorScheme.onSurface.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: canReview
                      ? colorScheme.onPrimary
                      : colorScheme.onSurface.withValues(alpha: 0.38),
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Exclude picker bottom sheet
// ═════════════════════════════════════════════════════════════════════════════

class _ExcludePickerSheet extends StatelessWidget {
  const _ExcludePickerSheet({
    required this.participants,
    required this.colorScheme,
    required this.isDark,
    required this.onToggle,
  });

  final List<BillParticipant> participants;
  final ColorScheme colorScheme;
  final bool isDark;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.4,
      maxChildSize: 0.85,
      expand: false,
      builder: (_, scrollController) => Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: AppRadius.topXxl,
        ),
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.sm),
            // Drag handle.
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: AppRadius.radiusFull,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenHorizontal,
              ),
              child: Row(
                children: [
                  Icon(Icons.shield_outlined,
                      color: AppColors.warning, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Exclude from bill',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Done'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenHorizontal,
              ),
              child: Text(
                'Excluded members will not be part of the split.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenHorizontal,
                  vertical: AppSpacing.sm,
                ),
                itemCount: participants.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (_, i) {
                  final p = participants[i];
                  return _ExcludeParticipantTile(
                    participant: p,
                    colorScheme: colorScheme,
                    isDark: isDark,
                    onToggle: () => onToggle(p.id),
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

class _ExcludeParticipantTile extends StatelessWidget {
  const _ExcludeParticipantTile({
    required this.participant,
    required this.colorScheme,
    required this.isDark,
    required this.onToggle,
  });

  final BillParticipant participant;
  final ColorScheme colorScheme;
  final bool isDark;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final isExcluded = !participant.isIncluded;

    return _AnimatedTapScale(
      onTap: participant.isCurrentUser ? null : onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: AppSpacing.cardPaddingSymmetric,
        decoration: BoxDecoration(
          color: isExcluded
              ? colorScheme.errorContainer.withValues(alpha: isDark ? 0.3 : 0.15)
              : colorScheme.surface,
          borderRadius: AppRadius.radiusLg,
          border: Border.all(
            color: isExcluded
                ? colorScheme.error.withValues(alpha: 0.3)
                : colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          children: [
            _SmallAvatar(participant: participant, colorScheme: colorScheme),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        participant.bestDisplayName,
                        style: AppTextStyles.titleSmall.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (participant.isCurrentUser) ...[
                        const SizedBox(width: AppSpacing.xs),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: AppRadius.radiusFull,
                          ),
                          child: Text(
                            'You',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 9,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    participant.email,
                    style: AppTextStyles.caption.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (participant.isCurrentUser)
              Text(
                'Always included',
                style: AppTextStyles.caption.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              )
            else
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: isExcluded
                    ? Icon(
                        Icons.remove_circle_rounded,
                        key: const ValueKey('excluded'),
                        color: colorScheme.error,
                        size: 22,
                      )
                    : Icon(
                        Icons.check_circle_rounded,
                        key: const ValueKey('included'),
                        color: colorScheme.primary,
                        size: 22,
                      ),
              ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Review bottom sheet
// ═════════════════════════════════════════════════════════════════════════════

class _ReviewSheet extends StatelessWidget {
  const _ReviewSheet({
    required this.form,
    required this.group,
    required this.currentUserId,
    required this.colorScheme,
    required this.isDark,
    required this.onConfirm,
  });

  final CreateBillFormState form;
  final Group group;
  final String currentUserId;
  final ColorScheme colorScheme;
  final bool isDark;
  final VoidCallback onConfirm;

  String _formatDate(DateTime d) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final included = form.includedParticipants;
    final date = form.date ?? DateTime.now();
    final title = form.title.trim().isEmpty ? 'Untitled Bill' : form.title.trim();

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) => Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: AppRadius.topXxl,
        ),
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.sm),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: AppRadius.radiusFull,
                ),
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.xl,
                  AppSpacing.xl,
                  AppSpacing.pageBottom,
                ),
                children: [
                  // Header.
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer.withValues(
                              alpha: 0.5),
                          borderRadius: AppRadius.radiusMd,
                        ),
                        child: Icon(
                          Icons.receipt_long_rounded,
                          color: colorScheme.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Review Bill',
                              style: AppTextStyles.headlineSmall.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              'Confirm details before creating',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  // Bill summary card.
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                            ? AppColors.darkPrimaryGradient.colors
                            : AppColors.lightPrimaryGradient.colors,
                      ),
                      borderRadius: AppRadius.radiusXxl,
                      boxShadow: isDark
                          ? AppShadows.primaryGlowDark
                          : AppShadows.primaryGlowLight,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppTextStyles.titleLarge.copyWith(
                            color: colorScheme.onPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          group.groupName,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: colorScheme.onPrimary.withValues(alpha: 0.75),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: colorScheme.onPrimary
                                        .withValues(alpha: 0.7),
                                  ),
                                ),
                                Text(
                                  '${AppConstants.currencySymbol} ${form.amount.toStringAsFixed(2)}',
                                  style: AppTextStyles.amountMedium.copyWith(
                                    color: colorScheme.onPrimary,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Date',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: colorScheme.onPrimary
                                        .withValues(alpha: 0.7),
                                  ),
                                ),
                                Text(
                                  _formatDate(date),
                                  style: AppTextStyles.labelLarge.copyWith(
                                    color: colorScheme.onPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (form.note.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.md),
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: colorScheme.onPrimary.withValues(alpha: 0.12),
                              borderRadius: AppRadius.radiusMd,
                            ),
                            child: Text(
                              form.note,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: colorScheme.onPrimary.withValues(alpha: 0.85),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Receipt thumbnail if present.
                  if (form.receiptPhotoPath != null) ...[
                    Row(
                      children: [
                        Icon(Icons.photo_library_outlined,
                            size: 18, color: colorScheme.primary),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'Receipt',
                          style: AppTextStyles.labelLarge.copyWith(
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ClipRRect(
                      borderRadius: AppRadius.radiusLg,
                      child: Image.file(
                        io.File(form.receiptPhotoPath!),
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],

                  // Split mode chip.
                  Row(
                    children: [
                      Icon(
                        form.splitMode == BillSplitMode.equal
                            ? Icons.people_alt_rounded
                            : Icons.tune_rounded,
                        size: 18,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        form.splitMode == BillSplitMode.equal
                            ? 'Equal Split'
                            : 'Custom Split',
                        style: AppTextStyles.labelLarge.copyWith(
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Participant breakdown.
                  Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest
                          .withValues(alpha: isDark ? 0.4 : 0.5),
                      borderRadius: AppRadius.radiusXxl,
                      border: Border.all(
                        color: colorScheme.outlineVariant.withValues(
                          alpha: isDark ? 0.3 : 0.5,
                        ),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Header row.
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg,
                            AppSpacing.md,
                            AppSpacing.lg,
                            AppSpacing.sm,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  'Participant',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              Text(
                                'Share',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Divider(
                          height: 1,
                          color: colorScheme.outlineVariant.withValues(
                            alpha: isDark ? 0.3 : 0.4,
                          ),
                        ),
                        for (int i = 0; i < included.length; i++) ...[
                          _ReviewParticipantRow(
                            participant: included[i],
                            share: form.splitMode == BillSplitMode.equal
                                ? form.perPersonAmount
                                : included[i].customShare,
                            colorScheme: colorScheme,
                          ),
                          if (i < included.length - 1)
                            Divider(
                              height: 1,
                              indent: AppSpacing.xl + 36,
                              color: colorScheme.outlineVariant.withValues(
                                alpha: isDark ? 0.2 : 0.3,
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxxl),

                  // Confirm button.
                  _AnimatedTapScale(
                    onTap: onConfirm,
                    child: Container(
                      width: double.infinity,
                      height: 58,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: AppRadius.radiusXxl,
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.primary.withValues(alpha: 0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle_outline_rounded,
                            color: colorScheme.onPrimary,
                            size: 22,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            'Create Bill',
                            style: AppTextStyles.labelLarge.copyWith(
                              color: colorScheme.onPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewParticipantRow extends StatelessWidget {
  const _ReviewParticipantRow({
    required this.participant,
    required this.share,
    required this.colorScheme,
  });

  final BillParticipant participant;
  final double share;
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
          _SmallAvatar(participant: participant, colorScheme: colorScheme),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  participant.bestDisplayName,
                  style: AppTextStyles.titleSmall.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (participant.isCurrentUser)
                  Text(
                    'You',
                    style: AppTextStyles.caption.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            '${AppConstants.currencySymbol} ${share.toStringAsFixed(2)}',
            style: AppTextStyles.amountSmall.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Amount dialog
// ═════════════════════════════════════════════════════════════════════════════

class _AmountDialog extends StatelessWidget {
  const _AmountDialog({
    required this.controller,
    required this.colorScheme,
    required this.isDark,
    required this.onConfirm,
  });

  final TextEditingController controller;
  final ColorScheme colorScheme;
  final bool isDark;
  final ValueChanged<String> onConfirm;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.calculate_outlined, color: colorScheme.primary, size: 22),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'Enter Amount',
            style: AppTextStyles.headlineSmall.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w700,
              fontSize: 20,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enter the total bill amount',
            style: AppTextStyles.bodySmall.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            style: AppTextStyles.amountMedium.copyWith(
              color: colorScheme.onSurface,
            ),
            decoration: InputDecoration(
              prefixText: '${AppConstants.currencySymbol} ',
              prefixStyle: AppTextStyles.titleMedium.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              hintText: '0.00',
              hintStyle: AppTextStyles.amountMedium.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              ),
            ),
            onSubmitted: (v) {
              onConfirm(v);
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            onConfirm(controller.text);
            Navigator.of(context).pop();
          },
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Text field dialog (Title / Note)
// ═════════════════════════════════════════════════════════════════════════════

class _TextFieldDialog extends StatelessWidget {
  const _TextFieldDialog({
    required this.controller,
    required this.colorScheme,
    required this.isDark,
    required this.title,
    required this.hint,
    required this.maxLength,
    required this.onConfirm,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final ColorScheme colorScheme;
  final bool isDark;
  final String title;
  final String hint;
  final int maxLength;
  final int maxLines;
  final ValueChanged<String> onConfirm;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        title,
        style: AppTextStyles.headlineSmall.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w700,
          fontSize: 20,
        ),
      ),
      content: TextField(
        controller: controller,
        autofocus: true,
        maxLines: maxLines,
        maxLength: maxLength,
        textInputAction:
            maxLines > 1 ? TextInputAction.newline : TextInputAction.done,
        decoration: InputDecoration(
          hintText: hint,
          counterStyle: AppTextStyles.caption.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        onSubmitted: maxLines == 1
            ? (v) {
                onConfirm(v);
                Navigator.of(context).pop();
              }
            : null,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            onConfirm(controller.text);
            Navigator.of(context).pop();
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Shared small helpers
// ═════════════════════════════════════════════════════════════════════════════

/// 36×36 avatar used in table rows and exclude picker.
class _SmallAvatar extends StatelessWidget {
  const _SmallAvatar({
    required this.participant,
    required this.colorScheme,
  });

  final BillParticipant participant;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final url = participant.profilePicture;
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colorScheme.primary,
        border: Border.all(
          color: colorScheme.primaryContainer,
          width: 2,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: url != null && url.isNotEmpty
          ? Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _AvatarFallback(
                participant: participant,
                colorScheme: colorScheme,
              ),
            )
          : _AvatarFallback(
              participant: participant,
              colorScheme: colorScheme,
            ),
    );
  }
}

/// Inline validation error message row.
class _InlineError extends StatelessWidget {
  const _InlineError({
    required this.message,
    required this.colorScheme,
  });

  final String message;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.error_outline_rounded,
            size: 16, color: colorScheme.error),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            message,
            style: AppTextStyles.caption.copyWith(
              color: colorScheme.error,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

/// Scales its child slightly on tap — consistent with `CreateGroupScreen`.
class _AnimatedTapScale extends StatefulWidget {
  const _AnimatedTapScale({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  State<_AnimatedTapScale> createState() => _AnimatedTapScaleState();
}

class _AnimatedTapScaleState extends State<_AnimatedTapScale> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _scale,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutCubic,
      child: GestureDetector(
        onTapDown: widget.onTap != null
            ? (_) => setState(() => _scale = 0.96)
            : null,
        onTapUp: widget.onTap != null
            ? (_) {
                setState(() => _scale = 1.0);
                widget.onTap?.call();
              }
            : null,
        onTapCancel: widget.onTap != null
            ? () => setState(() => _scale = 1.0)
            : null,
        child: widget.child,
      ),
    );
  }
}
