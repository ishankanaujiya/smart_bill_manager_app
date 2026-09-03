import 'dart:io' as io;
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/theme/design_system.dart';
import '../../../../core/widgets/animated_entrance.dart';
import '../../../groups/domain/entities/group.dart';
import '../../domain/entities/bill.dart';
import '../state/bill_providers.dart';
import '../state/create_bill_provider.dart';

// ═════════════════════════════════════════════════════════════════════════════
// Quick Info inline editing field
// ═════════════════════════════════════════════════════════════════════════════

/// Which Quick Info field is currently being edited inline (null = none).
enum _QuickInfoField { title, note }

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

  // ── Inline amount editing ────────────────────────────────────────────────
  bool _isEditingAmount = false;
  late final TextEditingController _amountEditController =
      TextEditingController();
  late final FocusNode _amountEditFocus = FocusNode();

  // ── Inline Quick Info editing ────────────────────────────────────────────
  _QuickInfoField? _editingField;
  late final TextEditingController _titleEditController = TextEditingController();
  late final TextEditingController _noteEditController = TextEditingController();
  late final FocusNode _titleEditFocus = FocusNode();
  late final FocusNode _noteEditFocus = FocusNode();

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

    // Commit inline amount edit when focus is lost.
    _amountEditFocus.addListener(() {
      if (!_amountEditFocus.hasFocus && _isEditingAmount) {
        _commitAmountEdit();
      }
    });

    // Commit inline edit when focus is lost.
    _titleEditFocus.addListener(() {
      if (!_titleEditFocus.hasFocus && _editingField == _QuickInfoField.title) {
        _commitQuickInfoEdit();
      }
    });
    _noteEditFocus.addListener(() {
      if (!_noteEditFocus.hasFocus && _editingField == _QuickInfoField.note) {
        _commitQuickInfoEdit();
      }
    });

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
    _amountEditController.dispose();
    _amountEditFocus.dispose();
    _titleEditController.dispose();
    _noteEditController.dispose();
    _titleEditFocus.dispose();
    _noteEditFocus.dispose();
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

  // ── Inline amount editing ──────────────────────────────────────────────────

  void _startEditingAmount() {
    setState(() {
      _isEditingAmount = true;
      _amountEditController.text =
          _form.amount > 0 ? AppConstants.formatCurrency(_form.amount) : '';
      _amountEditController.selection = TextSelection(
        baseOffset: _amountEditController.text.length,
        extentOffset: _amountEditController.text.length,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _amountEditFocus.requestFocus();
      });
    });
  }

  void _commitAmountEdit() {
    final text = _amountEditController.text.trim().replaceAll(',', '');
    final parsed = double.tryParse(text) ?? 0.0;
    _notifier.setAmount(parsed, text);
    setState(() => _isEditingAmount = false);
  }

  void _cancelAmountEdit() {
    setState(() => _isEditingAmount = false);
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

  // ── Inline Quick Info editing ──────────────────────────────────────────────

  void _startEditingQuickInfo(_QuickInfoField field) {
    setState(() {
      _editingField = field;
      switch (field) {
        case _QuickInfoField.title:
          _titleEditController.text = _form.title;
          _titleEditController.selection = TextSelection(
            baseOffset: _form.title.length,
            extentOffset: _form.title.length,
          );
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _titleEditFocus.requestFocus();
          });
        case _QuickInfoField.note:
          _noteEditController.text = _form.note;
          _noteEditController.selection = TextSelection(
            baseOffset: _form.note.length,
            extentOffset: _form.note.length,
          );
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _noteEditFocus.requestFocus();
          });
      }
    });
  }

  void _commitQuickInfoEdit() {
    if (_editingField == null) return;
    final field = _editingField!;
    setState(() => _editingField = null);
    switch (field) {
      case _QuickInfoField.title:
        _notifier.setTitle(_titleEditController.text.trim());
      case _QuickInfoField.note:
        _notifier.setNote(_noteEditController.text.trim());
    }
  }

  void _cancelQuickInfoEdit() {
    setState(() => _editingField = null);
  }

  // ── Exclude picker sheet ───────────────────────────────────────────────────

  void _openExcludePicker(ColorScheme colorScheme, bool isDark) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: colorScheme.scrim.withValues(alpha: 0.4),
      showDragHandle: false,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.topXxl,
      ),
      builder: (_) => _ExcludePickerSheet(
        providerKey: _providerKey,
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
        onConfirm: () => _confirmBillCreation(colorScheme),
      ),
    );
  }

  /// Builds the [Bill] entity from the form and persists it to Firestore
  /// via [SaveBillNotifier].
  Future<void> _confirmBillCreation(ColorScheme colorScheme) async {
    final bill = _notifier.buildBill(
      createdBy: widget.currentUserId,
      groupId: widget.group.id,
      groupName: widget.group.groupName,
    );
    if (bill == null) return;

    final saveNotifier = ref.read(saveBillProvider.notifier);
    final ok = await saveNotifier.saveBill(
      bill: bill,
      receiptPhotoPath: _form.receiptPhotoPath,
    );

    if (!mounted) return;

    if (ok) {
      Navigator.of(context).pop(); // close review sheet
      Navigator.of(context).pop(); // close create bill screen
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
    } else {
      final saveState = ref.read(saveBillProvider);
      final message = saveState is SaveBillError
          ? saveState.message
          : 'Could not create the bill. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: AppTextStyles.bodySmall.copyWith(
              color: colorScheme.onPrimary,
            ),
          ),
          backgroundColor: colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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
                    const SizedBox(height: AppSpacing.xxl),
                    // ── Hero section (title outside + amount card) ────────
                    _stagger(
                      _HeroSection(
                        group: widget.group,
                        amount: _form.amount,
                        rawText: _form.rawAmountText,
                        amountError: _form.amountError,
                        ambient: _ambient,
                        colorScheme: colorScheme,
                        isDark: isDark,
                        isEditingAmount: _isEditingAmount,
                        amountController: _amountEditController,
                        amountFocus: _amountEditFocus,
                        onTapAmount: _startEditingAmount,
                        onCommitAmount: _commitAmountEdit,
                        onCancelAmount: _cancelAmountEdit,
                      ),
                      0.04, 0.28,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    // ── Quick info row ───────────────────────────────────
                    _stagger(
                      _QuickInfoRow(
                        form: _form,
                        colorScheme: colorScheme,
                        isDark: isDark,
                        isPickingPhoto: _isPickingPhoto,
                        editingField: _editingField,
                        titleController: _titleEditController,
                        noteController: _noteEditController,
                        titleFocus: _titleEditFocus,
                        noteFocus: _noteEditFocus,
                        onAddPhoto: _pickReceiptPhoto,
                        onAddTitle: () =>
                            _startEditingQuickInfo(_QuickInfoField.title),
                        onAddNote: () =>
                            _startEditingQuickInfo(_QuickInfoField.note),
                        onSelectDate: _openDatePicker,
                        onCommitEdit: _commitQuickInfoEdit,
                        onCancelEdit: _cancelQuickInfoEdit,
                      ),
                      0.18, 0.36,
                    ),
                    // ── Filled info showcase (below Quick Info) ──────────
                    if (_form.title.isNotEmpty ||
                        _form.note.isNotEmpty ||
                        _form.date != null ||
                        _form.receiptPhotoPath != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      _stagger(
                        _FilledInfoShowcase(
                          form: _form,
                          colorScheme: colorScheme,
                          isDark: isDark,
                          onEditTitle: () =>
                              _startEditingQuickInfo(_QuickInfoField.title),
                          onEditNote: () =>
                              _startEditingQuickInfo(_QuickInfoField.note),
                          onEditDate: _openDatePicker,
                          onEditPhoto: _pickReceiptPhoto,
                          onRemoveTitle: () => _notifier.setTitle(''),
                          onRemoveNote: () => _notifier.setNote(''),
                          onRemoveDate: () => _notifier.clearDate(),
                          onRemovePhoto: () => _notifier.setReceiptPhoto(null),
                        ),
                        0.20, 0.38,
                      ),
                    ],
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
                        amount: _form.amount,
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

// ═════════════════════════════════════════════════════════════════════════════
// Hero section — title/subtitle outside, image + amount inside the card
// ═════════════════════════════════════════════════════════════════════════════

// ═════════════════════════════════════════════════════════════════════════════
// Hero section — title/subtitle outside, image + amount in a single card
// ═════════════════════════════════════════════════════════════════════════════

class _HeroSection extends StatelessWidget {
  const _HeroSection({
    required this.group,
    required this.amount,
    required this.rawText,
    required this.amountError,
    required this.ambient,
    required this.colorScheme,
    required this.isDark,
    required this.isEditingAmount,
    required this.amountController,
    required this.amountFocus,
    required this.onTapAmount,
    required this.onCommitAmount,
    required this.onCancelAmount,
  });

  final Group group;
  final double amount;
  final String rawText;
  final String? amountError;
  final AnimationController ambient;
  final ColorScheme colorScheme;
  final bool isDark;
  final bool isEditingAmount;
  final TextEditingController amountController;
  final FocusNode amountFocus;
  final VoidCallback onTapAmount;
  final VoidCallback onCommitAmount;
  final VoidCallback onCancelAmount;

  String get _display {
    if (amount <= 0 && rawText.isEmpty) return '0';
    if (amount <= 0) return rawText;
    return AppConstants.formatCurrency(amount);
  }

  @override
  Widget build(BuildContext context) {
    // Use the design-system gradient endpoints, enriched with intermediate
    // stops for extra depth. Tokens come from AppColors, not raw hex.
    final gradientStart = isDark
        ? AppColors.darkPrimaryGradientStart
        : AppColors.lightPrimaryGradientStart;
    final gradientEnd = isDark
        ? AppColors.darkPrimaryGradientEnd
        : AppColors.lightPrimaryGradientEnd;
    final cardGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        gradientEnd,
        gradientStart,
        gradientEnd,
        gradientEnd.withValues(alpha: 0.85),
      ],
      stops: const [0.0, 0.35, 0.7, 1.0],
    );
    final onPrimary = colorScheme.onPrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Title + subtitle (OUTSIDE the card) ──────────────────────
        Text(
          'New Bill',
          style: AppTextStyles.headlineLarge.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
            height: 1.1,
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
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        // ── Single card with amount left + image top-right ───────────
        SizedBox(
            height: 140,
          child: AnimatedBuilder(
            animation: ambient,
            builder: (_, child) {
              final t = ambient.value;
              // Pulsing glow shadow — breathes like the home screen card.
              final pulse = (1 - math.cos(math.pi * 2 * t)) * 0.5;
              final glowAlpha = isDark
                  ? (0.12 + 0.15 * pulse)
                  : (0.15 + 0.30 * pulse);
              final glowBlur = isDark ? (20 + 16 * pulse) : (16 + 12 * pulse);
              final glowSpread = isDark ? (1 + pulse) : (2 + 2 * pulse);
              // Shimmer sweep position.
              final shimmer = (t * 1.6 - 0.3).clamp(-0.5, 1.5);
              // Pulsing blob scale.
              final blobScale = 0.85 + 0.15 * ((1 - math.cos(math.pi * 2 * t)) * 0.5);

              return Container(
                height: double.infinity,
                decoration: BoxDecoration(
                  gradient: cardGradient,
                  borderRadius: AppRadius.radiusXxl,
                  border: Border.all(
                    color: onPrimary.withValues(alpha: 0.15),
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: glowAlpha),
                      blurRadius: glowBlur,
                      spreadRadius: glowSpread,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // ── Clipped overlay layer (blob + shimmer) ───────
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: AppRadius.radiusXxl,
                        child: Stack(
                          clipBehavior: Clip.hardEdge,
                          children: [
                            // Pulsing glow blob (top-right).
                            Positioned(
                              right: -34,
                              top: -34,
                              child: Transform.scale(
                                scale: blobScale,
                                child: Container(
                                  width: 180,
                                  height: 180,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: onPrimary.withValues(
                                      alpha: isDark ? 0.07 : 0.18,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // Top inner highlight for glass-like depth.
                            Positioned(
                              top: 0,
                              left: 0,
                              right: 0,
                              height: 1,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      onPrimary.withValues(alpha: 0.0),
                                      onPrimary.withValues(alpha: 0.35),
                                      onPrimary.withValues(alpha: 0.0),
                                    ],
                                    stops: const [0.0, 0.5, 1.0],
                                  ),
                                ),
                              ),
                            ),
                            // Shimmer sweep (diagonal light band).
                            Positioned.fill(
                              child: CustomPaint(
                                painter: _HeroShimmerPainter(
                                  progress: shimmer,
                                  color: onPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    child!,
                  ],
                ),
              );
            },
            child: Stack(
              clipBehavior: Clip.none,
              fit: StackFit.expand,
              children: [
                // ── Amount content + Enter amount pill ─────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xxl, AppSpacing.lg, 160, AppSpacing.lg,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // "Total Amount" label with icon.
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.account_balance_wallet_rounded,
                            size: 13,
                            color: onPrimary.withValues(alpha: 0.70),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Total Amount',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: onPrimary.withValues(alpha: 0.70),
                              fontSize: 12,
                              letterSpacing: 0.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      // Amount display — becomes editable in place when tapped.
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '${AppConstants.currencySymbol} ',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: onPrimary.withValues(alpha: 0.90),
                              fontWeight: FontWeight.w600,
                              height: 1.1,
                            ),
                          ),
                          // When editing, show a borderless TextField that
                          // looks identical to the static text — only the
                          // cursor appears. Otherwise show the animated text.
                          isEditingAmount
                              ? Flexible(
                                  child: TextField(
                                    controller: amountController,
                                    focusNode: amountFocus,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                    inputFormatters: [
                                      SouthAsianCurrencyInputFormatter(),
                                    ],
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: onPrimary,
                                      fontWeight: FontWeight.w700,
                                      height: 1.0,
                                    ),
                                    cursorColor: onPrimary,
                                    textInputAction: TextInputAction.done,
                                    maxLines: 1,
                                    decoration: const InputDecoration(
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                      isCollapsed: true,
                                      border: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      disabledBorder: InputBorder.none,
                                      errorBorder: InputBorder.none,
                                      focusedErrorBorder: InputBorder.none,
                                      filled: false,
                                      fillColor: Colors.transparent,
                                    ),
                                    onSubmitted: (_) => onCommitAmount(),
                                  ),
                                )
                              : AnimatedSwitcher(
                                  duration:
                                      const Duration(milliseconds: 360),
                                  transitionBuilder: (child, anim) =>
                                      FadeTransition(
                                    opacity: anim,
                                    child: SlideTransition(
                                      position: Tween<Offset>(
                                        begin: const Offset(0, 0.35),
                                        end: Offset.zero,
                                      ).animate(
                                        CurvedAnimation(
                                          parent: anim,
                                          curve: Curves.easeOutCubic,
                                        ),
                                      ),
                                      child: child,
                                    ),
                                  ),
                                  child: Text(
                                    _display,
                                    key: ValueKey(_display),
                                    style:
                                        AppTextStyles.bodyMedium.copyWith(
                                      color: onPrimary,
                                      fontWeight: FontWeight.w700,
                                      height: 1.0,
                                    ),
                                  ),
                                ),
                        ],
                      ),
                      if (!isEditingAmount) ...[
                        const SizedBox(height: AppSpacing.xs + 2),
                        // Enter amount pill button.
                        _AnimatedTapScale(
                          onTap: onTapAmount,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm + 2,
                              vertical: AppSpacing.xs,
                            ),
                            decoration: BoxDecoration(
                              color: onPrimary.withValues(alpha: 0.15),
                              borderRadius: AppRadius.radiusFull,
                              border: Border.all(
                                color: onPrimary.withValues(alpha: 0.30),
                                width: 1.0,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  amount > 0
                                      ? 'Change amount'
                                      : 'Enter amount',
                                  style: AppTextStyles.labelMedium.copyWith(
                                    color: onPrimary,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.1,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.xs + 1),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 13,
                                  color: onPrimary,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // ── Large illustration, top-right, overlapping ──
                const Positioned(
                  top: -110,
                  right: -35,
                  child: _HeroIllustration(),
                ),
              ],
            ),
          ),
        ),

        // ── Amount validation error ───────────────────────────────────
        if (amountError != null)
          Padding(
            padding: const EdgeInsets.only(
              top: AppSpacing.sm,
              left: AppSpacing.xs,
            ),
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
// Hero shimmer painter — paints a soft diagonal light band that sweeps across
// the amount card.  Same technique as the home screen financial summary card.
// ═════════════════════════════════════════════════════════════════════════════

class _HeroShimmerPainter extends CustomPainter {
  _HeroShimmerPainter({required this.progress, required this.color});

  /// 0 = far left, 1 = far right.  Values outside [0, 1] keep the band
  /// off-card so the sweep fades in/out naturally.
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // The band is ~25% of the card width.
    final bandWidth = width * 0.25;
    final centerX = progress * width;

    final rect = Rect.fromCenter(
      center: Offset(centerX, height / 2),
      width: bandWidth,
      height: height * 1.5,
    );

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          color.withValues(alpha: 0.0),
          color.withValues(alpha: 0.12),
          color.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(rect);

    canvas.save();
    canvas.rotate(0.15); // slight diagonal tilt
    canvas.drawRect(rect, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_HeroShimmerPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// ═════════════════════════════════════════════════════════════════════════════
// ═════════════════════════════════════════════════════════════════════════════
// Hero illustration — bigger, top-right positioned, with pulsing glow disc.
// ═════════════════════════════════════════════════════════════════════════════

class _HeroIllustration extends StatefulWidget {
  const _HeroIllustration();

  @override
  State<_HeroIllustration> createState() => _HeroIllustrationState();
}

class _HeroIllustrationState extends State<_HeroIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glow;

  @override
  void initState() {
    super.initState();
    _glow = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final glowColor = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

    return SizedBox(
      width: 250,
      height: 250,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // ── Pulsing glow disc behind the image ────────────────
          // Scales 0.85 → 1.05 and varies alpha + blur for a
          // breathing effect that makes the illustration feel alive.
          AnimatedBuilder(
            animation: _glow,
            builder: (_, child) {
              final t = _glow.value;
              final scale = 0.85 + 0.20 * t;
              final alpha = 0.18 + 0.22 * t;
              final blur = 40 + 30 * t;
              final spread = 6 + 12 * t;
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: glowColor.withValues(alpha: alpha),
                        blurRadius: blur,
                        spreadRadius: spread,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          // The illustration itself — completely static.
          Image.asset(
            'assets/images/bill_and_coins.png',
            width: 240,
            height: 240,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
          // Static decorative sparkle dots (scaled up).
          const _StaticSparkle(right: 20, top: 38, size: 9),
          const _StaticSparkle(left: 14, top: 88, size: 7),
          const _StaticSparkle(right: 22, bottom: 48, size: 8),
          const _StaticSparkle(left: 30, bottom: 32, size: 6),
          const _StaticSparkle(right: 52, bottom: 78, size: 6.5),
          const _StaticSparkle(left: 50, top: 28, size: 5),
        ],
      ),
    );
  }
}

/// A static cross-shaped sparkle at a fixed opacity — no animation.
class _StaticSparkle extends StatelessWidget {
  const _StaticSparkle({
    this.right,
    this.left,
    this.top,
    this.bottom,
    required this.size,
  });

  final double? right;
  final double? left;
  final double? top;
  final double? bottom;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: right,
      left: left,
      top: top,
      bottom: bottom,
      child: Opacity(
        opacity: 0.55,
        child: CustomPaint(
          size: Size(size, size),
          painter: _CrossPainter(
            color: Colors.white,
            strokeWidth: size * 0.28,
          ),
        ),
      ),
    );
  }
}

class _CrossPainter extends CustomPainter {
  const _CrossPainter({required this.color, required this.strokeWidth});
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      paint,
    );
  }

  @override
  bool shouldRepaint(_CrossPainter old) =>
      old.color != color || old.strokeWidth != strokeWidth;
}

// ═════════════════════════════════════════════════════════════════════════════
// Quick info row — Photo / Title / Note / Date
// Supports inline editing: tapping Title or Note hides all chips and shows
// an animated TextField inside the same card.
// ═════════════════════════════════════════════════════════════════════════════

class _QuickInfoRow extends StatelessWidget {
  const _QuickInfoRow({
    required this.form,
    required this.colorScheme,
    required this.isDark,
    required this.isPickingPhoto,
    required this.editingField,
    required this.titleController,
    required this.noteController,
    required this.titleFocus,
    required this.noteFocus,
    required this.onAddPhoto,
    required this.onAddTitle,
    required this.onAddNote,
    required this.onSelectDate,
    required this.onCommitEdit,
    required this.onCancelEdit,
  });

  final CreateBillFormState form;
  final ColorScheme colorScheme;
  final bool isDark;
  final bool isPickingPhoto;
  final _QuickInfoField? editingField;
  final TextEditingController titleController;
  final TextEditingController noteController;
  final FocusNode titleFocus;
  final FocusNode noteFocus;
  final VoidCallback onAddPhoto;
  final VoidCallback onAddTitle;
  final VoidCallback onAddNote;
  final VoidCallback onSelectDate;
  final VoidCallback onCommitEdit;
  final VoidCallback onCancelEdit;

  @override
  Widget build(BuildContext context) {
    final isEditing = editingField != null;

    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: AppRadius.radiusXxl,
        border: Border.all(
          color: colorScheme.outlineVariant
              .withValues(alpha: isDark ? 0.3 : 0.5),
        ),
        boxShadow: AppShadows.cardShadow(
          isDark ? Brightness.dark : Brightness.light,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Quick Info',
                style: AppTextStyles.labelLarge.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  letterSpacing: 0.2,
                ),
              ),
              const Spacer(),
              if (isEditing)
                _AnimatedTapScale(
                  onTap: onCancelEdit,
                  child: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          // ── Animated switch between chips and inline editor ──
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            reverseDuration: const Duration(milliseconds: 250),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, anim) {
              return FadeTransition(
                opacity: anim,
                child: SizeTransition(
                  sizeFactor: anim,
                  axisAlignment: 0.0,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.15),
                      end: Offset.zero,
                    ).animate(anim),
                    child: child,
                  ),
                ),
              );
            },
            child: isEditing
                ? _InlineEditor(
                    key: const ValueKey('inline-editor'),
                    field: editingField!,
                    colorScheme: colorScheme,
                    isDark: isDark,
                    titleController: titleController,
                    noteController: noteController,
                    titleFocus: titleFocus,
                    noteFocus: noteFocus,
                    onDone: onCommitEdit,
                  )
                : _QuickInfoChips(
                    key: const ValueKey('chips'),
                    form: form,
                    colorScheme: colorScheme,
                    isDark: isDark,
                    isPickingPhoto: isPickingPhoto,
                    onAddPhoto: onAddPhoto,
                    onAddTitle: onAddTitle,
                    onAddNote: onAddNote,
                    onSelectDate: onSelectDate,
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Chips row (4 options) ────────────────────────────────────────────────────

class _QuickInfoChips extends StatelessWidget {
  const _QuickInfoChips({
    super.key,
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

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _QuickInfoChip(
          icon: isPickingPhoto
              ? Icons.hourglass_top_rounded
              : (form.receiptPhotoPath != null
                  ? Icons.check_circle_rounded
                  : Icons.camera_alt_outlined),
          label: 'Add Photo',
          sublabel: form.receiptPhotoPath != null ? 'Attached' : 'Upload bill',
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
          sublabel: form.title.isNotEmpty ? 'Added' : "What's this for?",
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

// ── Inline editor (shown when a field is being edited) ──────────────────────

class _InlineEditor extends StatelessWidget {
  const _InlineEditor({
    super.key,
    required this.field,
    required this.colorScheme,
    required this.isDark,
    required this.titleController,
    required this.noteController,
    required this.titleFocus,
    required this.noteFocus,
    required this.onDone,
  });

  final _QuickInfoField field;
  final ColorScheme colorScheme;
  final bool isDark;
  final TextEditingController titleController;
  final TextEditingController noteController;
  final FocusNode titleFocus;
  final FocusNode noteFocus;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final isTitle = field == _QuickInfoField.title;
    final controller = isTitle ? titleController : noteController;
    final focus = isTitle ? titleFocus : noteFocus;
    final icon = isTitle ? Icons.title_rounded : Icons.sticky_note_2_rounded;
    final label = isTitle ? 'Bill Title' : 'Note';
    final hint = isTitle ? 'e.g. Dinner, Hotel, Taxi' : 'Any additional details…';
    final color = isTitle ? AppColors.chartBlue : AppColors.chartPurple;
    final maxLines = isTitle ? 1 : 3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Label row with icon ──────────────────────────────
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: AppRadius.radiusSm,
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              label,
              style: AppTextStyles.labelLarge.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        // ── Text field ───────────────────────────────────────
        TextField(
          controller: controller,
          focusNode: focus,
          maxLines: maxLines,
          minLines: 1,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: isTitle ? TextInputAction.done : TextInputAction.newline,
          maxLength: isTitle
              ? AppConstants.billTitleMaxLength
              : AppConstants.billNoteMaxLength,
          onSubmitted: isTitle ? (_) => onDone() : null,
          style: AppTextStyles.bodyMedium.copyWith(
            color: colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.bodyMedium.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
            counterText: '',
            filled: true,
            fillColor: colorScheme.surfaceContainerHighest
                .withValues(alpha: 0.5),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            border: OutlineInputBorder(
              borderRadius: AppRadius.input,
              borderSide: BorderSide(
                color: color.withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppRadius.input,
              borderSide: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppRadius.input,
              borderSide: BorderSide(
                color: color,
                width: 2.0,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // ── Done button ──────────────────────────────────────
        Align(
          alignment: Alignment.centerRight,
          child: _AnimatedTapScale(
            onTap: onDone,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: AppRadius.radiusFull,
                boxShadow: isDark
                    ? AppShadows.primaryGlowDark
                    : AppShadows.primaryGlowLight,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_rounded,
                    size: 16,
                    color: colorScheme.onPrimary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'Done',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
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
// Filled info showcase — appears below the Quick Info card
// Shows each filled field in a professional row with an edit button.
// Uses colorScheme semantic container tokens for mode-aware styling.
// ═════════════════════════════════════════════════════════════════════════════

/// Semantic accent role for a filled-info row. Maps to the matching
/// `colorScheme` container / on-container pair so colours adapt to both
/// light and dark themes automatically.
enum _InfoAccent { primary, secondary }

class _FilledInfoShowcase extends StatelessWidget {
  const _FilledInfoShowcase({
    required this.form,
    required this.colorScheme,
    required this.isDark,
    required this.onEditTitle,
    required this.onEditNote,
    required this.onEditDate,
    required this.onEditPhoto,
    required this.onRemoveTitle,
    required this.onRemoveNote,
    required this.onRemoveDate,
    required this.onRemovePhoto,
  });

  final CreateBillFormState form;
  final ColorScheme colorScheme;
  final bool isDark;
  final VoidCallback onEditTitle;
  final VoidCallback onEditNote;
  final VoidCallback onEditDate;
  final VoidCallback onEditPhoto;
  final VoidCallback onRemoveTitle;
  final VoidCallback onRemoveNote;
  final VoidCallback onRemoveDate;
  final VoidCallback onRemovePhoto;

  @override
  Widget build(BuildContext context) {
    final items = <_FilledInfoItem>[];
    if (form.receiptPhotoPath != null) {
      items.add(_FilledInfoItem(
        icon: Icons.check_circle_rounded,
        accent: _InfoAccent.primary,
        label: 'Receipt Photo',
        value: 'Attached',
        onEdit: onEditPhoto,
        onRemove: onRemovePhoto,
      ));
    }
    if (form.title.isNotEmpty) {
      items.add(_FilledInfoItem(
        icon: Icons.title_rounded,
        accent: _InfoAccent.secondary,
        label: 'Title',
        value: form.title,
        onEdit: onEditTitle,
        onRemove: onRemoveTitle,
      ));
    }
    if (form.note.isNotEmpty) {
      items.add(_FilledInfoItem(
        icon: Icons.sticky_note_2_rounded,
        accent: _InfoAccent.primary,
        label: 'Note',
        value: form.note,
        onEdit: onEditNote,
        onRemove: onRemoveNote,
      ));
    }
    if (form.date != null) {
      items.add(_FilledInfoItem(
        icon: Icons.event_available_rounded,
        accent: _InfoAccent.secondary,
        label: 'Date',
        value: _formatDate(form.date!),
        onEdit: onEditDate,
        onRemove: onRemoveDate,
      ));
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: AppRadius.radiusXxl,
        border: Border.all(
          color: colorScheme.outlineVariant
              .withValues(alpha: isDark ? 0.25 : 0.4),
        ),
        boxShadow: AppShadows.cardShadow(
          isDark ? Brightness.dark : Brightness.light,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.task_alt_rounded,
                size: 16,
                color: colorScheme.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Added Details',
                style: AppTextStyles.labelLarge.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  letterSpacing: 0.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _FilledInfoRow(
                  item: item,
                  colorScheme: colorScheme,
                  isDark: isDark,
                ),
              )),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}

/// Data model for one filled field row.
class _FilledInfoItem {
  const _FilledInfoItem({
    required this.icon,
    required this.accent,
    required this.label,
    required this.value,
    required this.onEdit,
    required this.onRemove,
  });

  final IconData icon;
  final _InfoAccent accent;
  final String label;
  final String value;
  final VoidCallback onEdit;
  final VoidCallback onRemove;
}

/// Animated "tap to edit" hint icon — gently pulses with a bounce + opacity
/// cycle to draw the user's attention to the tappable card.
class _TapHintIcon extends StatefulWidget {
  const _TapHintIcon();

  @override
  State<_TapHintIcon> createState() => _TapHintIconState();
}

class _TapHintIconState extends State<_TapHintIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    // Scale: 1.0 → 1.25 → 1.0 (gentle bounce).
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutCubicEmphasized,
      ),
    );
    // Opacity: 0.35 → 0.75 → 0.35 (pulsing visibility).
    _opacityAnim = Tween<double>(begin: 0.35, end: 0.75).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutCubicEmphasized,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, child) {
        return Opacity(
          opacity: _opacityAnim.value,
          child: Transform.scale(
            scale: _scaleAnim.value,
            child: child,
          ),
        );
      },
      child: Icon(
        Icons.touch_app_rounded,
        size: 16,
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }
}

/// A single filled field row with icon, label, value.
/// Tap to flip-and-edit; swipe right to delete.
/// Uses [ColorScheme] container tokens for mode-aware, professional styling.
class _FilledInfoRow extends StatefulWidget {
  const _FilledInfoRow({
    required this.item,
    required this.colorScheme,
    required this.isDark,
  });

  final _FilledInfoItem item;
  final ColorScheme colorScheme;
  final bool isDark;

  @override
  State<_FilledInfoRow> createState() => _FilledInfoRowState();
}

class _FilledInfoRowState extends State<_FilledInfoRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _scaleAnim;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    // Smooth fade — delayed start so the row is visible as it begins moving.
    _fadeAnim = CurvedAnimation(
      parent: _anim,
      curve: const Interval(0.15, 1.0, curve: Curves.easeOutCubic),
    );
    // Smooth slide up toward the Quick Info card above.
    _slideAnim = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -1.8),
    ).animate(CurvedAnimation(
      parent: _anim,
      curve: Curves.easeInOutCubicEmphasized,
    ));
    // Gentle scale-down for a "merging" feel.
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(
        parent: _anim,
        curve: Curves.easeInOutCubicEmphasized,
      ),
    );
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  Color get _containerColor {
    switch (widget.item.accent) {
      case _InfoAccent.primary:
        return widget.colorScheme.primaryContainer;
      case _InfoAccent.secondary:
        return widget.colorScheme.secondaryContainer;
    }
  }

  Color get _onContainerColor {
    switch (widget.item.accent) {
      case _InfoAccent.primary:
        return widget.colorScheme.onPrimaryContainer;
      case _InfoAccent.secondary:
        return widget.colorScheme.onSecondaryContainer;
    }
  }

  Future<void> _handleTap() async {
    if (_navigated) return;
    _navigated = true;
    // Animate the row sliding up + fading out toward the editor.
    await _anim.forward();
    widget.item.onEdit();
    // Reset for next time.
    if (mounted) {
      _anim.reset();
      _navigated = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final container = _containerColor;
    final onContainer = _onContainerColor;

    return Dismissible(
      key: ValueKey('${widget.item.label}-${widget.item.value}'),
      direction: DismissDirection.startToEnd,
      confirmDismiss: (direction) async {
        widget.item.onRemove();
        return false; // Don't remove from tree; the parent rebuilds.
      },
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: AppSpacing.xl),
        decoration: BoxDecoration(
          // Subtle error-tinted surface — not a flat harsh red.
          // Uses error at low alpha over the card's own surface colour
          // so it blends naturally in both light and dark modes.
          color: widget.isDark
              ? widget.colorScheme.error.withValues(alpha: 0.12)
              : widget.colorScheme.error.withValues(alpha: 0.08),
          borderRadius: AppRadius.card,
          border: Border.all(
            color: widget.colorScheme.error.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: widget.colorScheme.error.withValues(alpha: 0.15),
                borderRadius: AppRadius.radiusMd,
              ),
              child: Icon(
                Icons.delete_sweep_rounded,
                color: widget.colorScheme.error,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Delete',
              style: AppTextStyles.labelLarge.copyWith(
                color: widget.colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      child: GestureDetector(
        onTap: _handleTap,
        child: AnimatedBuilder(
          animation: _anim,
          builder: (_, child) {
            return Opacity(
              opacity: 1 - _fadeAnim.value,
              child: SlideTransition(
                position: _slideAnim,
                child: ScaleTransition(
                  scale: _scaleAnim,
                  child: child,
                ),
              ),
            );
          },
          child: Container(
            padding: AppSpacing.cardPaddingSymmetric,
            decoration: BoxDecoration(
              color: container.withValues(alpha: widget.isDark ? 0.25 : 0.45),
              borderRadius: AppRadius.card,
              border: Border.all(
                color: onContainer
                    .withValues(alpha: widget.isDark ? 0.20 : 0.12),
              ),
            ),
            child: Row(
              children: [
                // Icon badge.
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color:
                        onContainer.withValues(alpha: widget.isDark ? 0.18 : 0.12),
                    borderRadius: AppRadius.radiusMd,
                  ),
                  child: Icon(widget.item.icon, size: 18, color: onContainer),
                ),
                const SizedBox(width: AppSpacing.md),
                // Label + value.
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.item.label,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: widget.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        widget.item.value,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: widget.colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Tap-to-edit hint icon — animated pulse to draw attention.
                const _TapHintIcon(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Split section header
// ═════════════════════════════════════════════════════════════════════════════

class _SplitSectionHeader extends StatefulWidget {
  const _SplitSectionHeader({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  State<_SplitSectionHeader> createState() => _SplitSectionHeaderState();
}

class _SplitSectionHeaderState extends State<_SplitSectionHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _arrow;

  @override
  void initState() {
    super.initState();
    _arrow = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _arrow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'How do you want to split?',
          style: AppTextStyles.titleSmall.copyWith(
            color: widget.colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        AnimatedBuilder(
          animation: _arrow,
          builder: (_, child) {
            final offset = (_arrow.value - 0.5) * 8.0;
            return Transform.translate(
              offset: Offset(offset, 0),
              child: child,
            );
          },
          child: Icon(
            Icons.arrow_forward_rounded,
            size: 18,
            color: widget.colorScheme.primary,
          ),
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
    required this.amount,
    required this.colorScheme,
    required this.isDark,
    required this.onChanged,
  });

  final BillSplitMode splitMode;
  final double amount;
  final ColorScheme colorScheme;
  final bool isDark;
  final ValueChanged<BillSplitMode> onChanged;

  @override
  Widget build(BuildContext context) {
    // Custom split requires an amount to be set first.
    final customEnabled = amount > 0;

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
            isEnabled: true,
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
            subtitle: customEnabled
                ? 'Set custom amounts\nfor each member'
                : 'Enter amount first\nto enable custom',
            isSelected: splitMode == BillSplitMode.custom,
            isEnabled: customEnabled,
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
    required this.isEnabled,
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
  final bool isEnabled;
  final ColorScheme colorScheme;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isEnabled ? 1.0 : 0.5,
      child: _AnimatedTapScale(
        onTap: isEnabled ? onTap : null,
        child: AnimatedScale(
          scale: isSelected ? 1.03 : 1.0,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutBack,
          child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primaryContainer
                    .withValues(alpha: isDark ? 0.25 : 0.55)
                : colorScheme.surface,
            borderRadius: AppRadius.radiusXxl,
            border: Border.all(
              color: isSelected
                  ? colorScheme.primary.withValues(alpha: 0.6)
                  : colorScheme.outlineVariant
                      .withValues(alpha: isDark ? 0.3 : 0.5),
              width: isSelected ? 1.5 : 1.0,
            ),
            boxShadow: isSelected
                ? (isDark
                    ? AppShadows.primaryGlowDark
                    : AppShadows.primaryGlowLight)
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
                  if (!isEnabled)
                    Icon(
                      Icons.lock_outline,
                      size: 18,
                      color: colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.5),
                    )
                  else
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
                        child: Icon(
                          Icons.check,
                          size: 14,
                          color: colorScheme.onPrimary,
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
      text: initial > 0 ? AppConstants.formatCurrency(initial) : '',
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
              SouthAsianCurrencyInputFormatter(),
            ],
            textAlign: TextAlign.end,
            style: AppTextStyles.titleSmall.copyWith(color: cs.onSurface),
            decoration: InputDecoration(
              hintText: '0',
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
              final parsed =
                  double.tryParse(v.replaceAll(',', '')) ?? 0.0;
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
                index: i,
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

class _ParticipantAvatar extends StatefulWidget {
  const _ParticipantAvatar({
    required this.participant,
    required this.colorScheme,
    required this.isDark,
    required this.onRemove,
    required this.index,
  });

  final BillParticipant participant;
  final ColorScheme colorScheme;
  final bool isDark;
  final VoidCallback onRemove;
  final int index;

  @override
  State<_ParticipantAvatar> createState() => _ParticipantAvatarState();
}

class _ParticipantAvatarState extends State<_ParticipantAvatar>
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
    // Stagger each avatar by its index.
    final start = (widget.index * 0.06).clamp(0.0, 0.4);
    _scaleAnim = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _entrance,
        curve: Interval(start, start + 0.6, curve: Curves.easeOutBack),
      ),
    );
    _fadeAnim = CurvedAnimation(
      parent: _entrance,
      curve: Interval(start, start + 0.4, curve: Curves.easeOutCubic),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _entrance.forward();
    });
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final included = widget.participant.isIncluded;

    return AnimatedBuilder(
      animation: _entrance,
      builder: (_, child) {
        return Opacity(
          opacity: _fadeAnim.value,
          child: Transform.scale(
            scale: _scaleAnim.value,
            child: child,
          ),
        );
      },
      child: Column(
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
                        ? widget.colorScheme.primary.withValues(alpha: 0.5)
                        : widget.colorScheme.outlineVariant,
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: widget.participant.profilePicture != null &&
                          widget.participant.profilePicture!.isNotEmpty
                      ? Image.network(
                          widget.participant.profilePicture!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _AvatarFallback(participant: widget.participant, colorScheme: widget.colorScheme),
                        )
                      : _AvatarFallback(
                          participant: widget.participant,
                          colorScheme: widget.colorScheme,
                        ),
                ),
              ),
            ),
            // Remove / restore button.
            Positioned(
              top: -4,
              right: -4,
              child: _AnimatedTapScale(
                onTap: widget.onRemove,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: widget.colorScheme.surface,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: included
                          ? widget.colorScheme.outlineVariant
                          : widget.colorScheme.primary.withValues(alpha: 0.4),
                      width: 1,
                    ),
                    boxShadow: AppShadows.xsLight,
                  ),
                  child: Icon(
                    included ? Icons.close : Icons.add,
                    size: 12,
                    color: included
                        ? widget.colorScheme.onSurfaceVariant
                        : widget.colorScheme.primary,
                  ),
                ),
              ),
            ),
            // "You" badge.
            if (widget.participant.isCurrentUser)
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
                      color: widget.colorScheme.primary,
                      borderRadius: AppRadius.radiusFull,
                    ),
                    child: Text(
                      'You',
                      style: AppTextStyles.caption.copyWith(
                        color: widget.colorScheme.onPrimary,
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
          widget.participant.isCurrentUser
              ? 'You'
              : widget.participant.bestDisplayName.split(' ').first,
          style: AppTextStyles.caption.copyWith(
            color: included ? widget.colorScheme.onSurface : widget.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    ),
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

class _ExcludeTile extends StatefulWidget {
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
  State<_ExcludeTile> createState() => _ExcludeTileState();
}

class _ExcludeTileState extends State<_ExcludeTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final excludedCount = widget.excludedCount;
    final colorScheme = widget.colorScheme;
    final isDark = widget.isDark;

    return _AnimatedTapScale(
      onTap: widget.onTap,
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
              AnimatedBuilder(
                animation: _pulse,
                builder: (_, child) {
                  final scale = 1.0 + 0.08 * _pulse.value;
                  return Transform.scale(
                    scale: scale,
                    child: child,
                  );
                },
                child: Container(
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

class _SummaryCard extends StatefulWidget {
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

  @override
  State<_SummaryCard> createState() => _SummaryCardState();
}

class _SummaryCardState extends State<_SummaryCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmer;

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  double get _currentUserShare {
    final me = widget.form.participants.cast<BillParticipant?>().firstWhere(
          (p) => p?.isCurrentUser == true,
          orElse: () => null,
        );
    if (me == null || !me.isIncluded) return 0.0;
    return widget.form.splitMode == BillSplitMode.equal
        ? widget.form.perPersonAmount
        : me.customShare;
  }

  @override
  Widget build(BuildContext context) {
    final cs = widget.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: AppRadius.radiusXxl,
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: widget.isDark ? 0.3 : 0.5),
        ),
        boxShadow: widget.isDark ? AppShadows.smDark : AppShadows.smLight,
      ),
      child: ClipRRect(
        borderRadius: AppRadius.radiusXxl,
        child: Stack(
          children: [
            IntrinsicHeight(
              child: Row(
                children: [
                  // You pay.
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: _SummaryPill(
                        icon: Icons.person_rounded,
                        iconColor: cs.primary,
                        label: 'You pay',
                        amount: _currentUserShare,
                        colorScheme: cs,
                      ),
                    ),
                  ),
                  VerticalDivider(
                    width: 1,
                    color: cs.outlineVariant.withValues(
                      alpha: widget.isDark ? 0.3 : 0.5,
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
                        amount: widget.form.perPersonAmount,
                        colorScheme: cs,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Subtle shimmer sweep across the card.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(_shimmer.value * 2.5 - 1.0, -1.0),
                    end: Alignment(_shimmer.value * 2.5 - 0.5, 1.0),
                    colors: [
                      cs.primary.withValues(alpha: 0.0),
                      cs.primary.withValues(alpha: 0.04),
                      cs.primary.withValues(alpha: 0.0),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
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
        ? AppConstants.formatCurrency(amount, withSymbol: true)
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
          // Shimmer sweep position — travels left to right when enabled.
          final shimmer = canReview ? ambient.value : 0.0;

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
            child: ClipRRect(
              borderRadius: AppRadius.radiusXxl,
              child: Stack(
                children: [
                  child!,
                  // Shimmer sweep — a diagonal light band that travels across.
                  if (canReview)
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment(shimmer * 2.5 - 1.0, -1.0),
                            end: Alignment(shimmer * 2.5 - 0.5, 1.0),
                            colors: [
                              colorScheme.onPrimary.withValues(alpha: 0.0),
                              colorScheme.onPrimary.withValues(alpha: 0.12),
                              colorScheme.onPrimary.withValues(alpha: 0.0),
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
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

class _ExcludePickerSheet extends ConsumerStatefulWidget {
  const _ExcludePickerSheet({
    required this.providerKey,
    required this.colorScheme,
    required this.isDark,
    required this.onToggle,
  });

  final CreateBillKey providerKey;
  final ColorScheme colorScheme;
  final bool isDark;
  final ValueChanged<String> onToggle;

  @override
  ConsumerState<_ExcludePickerSheet> createState() =>
      _ExcludePickerSheetState();
}

class _ExcludePickerSheetState extends ConsumerState<_ExcludePickerSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _entrance.forward();
    });
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  /// Build a staggered fade + slide entrance for a child widget.
  Widget _stagger(Widget child, double start, double end) {
    return AnimatedBuilder(
      animation: _entrance,
      builder: (_, c) {
        final curve = CurvedAnimation(
          parent: _entrance,
          curve: Interval(start, end, curve: Curves.easeOutCubic),
        );
        return Opacity(
          opacity: curve.value,
          child: Transform.translate(
            offset: Offset(0, 16 * (1 - curve.value)),
            child: c,
          ),
        );
      },
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final participants =
        ref.watch(createBillProvider(widget.providerKey)).participants;
    final excludedCount =
        participants.where((p) => !p.isIncluded).length;
    final cs = widget.colorScheme;
    final dark = widget.isDark;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, scrollController) => Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: AppRadius.topXxl,
          border: Border(
            top: BorderSide(
              color: cs.outlineVariant.withValues(alpha: dark ? 0.3 : 0.5),
              width: 1,
            ),
          ),
          boxShadow: AppShadows.modalShadow(
            dark ? Brightness.dark : Brightness.light,
          ),
        ),
        child: Column(
          children: [
            // ── Drag handle ──────────────────────────────────────
            const SizedBox(height: AppSpacing.md),
            _stagger(
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cs.outlineVariant
                        .withValues(alpha: dark ? 0.5 : 0.7),
                    borderRadius: AppRadius.radiusFull,
                  ),
                ),
              ),
              0.0, 0.15,
            ),
            const SizedBox(height: AppSpacing.lg),
            // ── Header ───────────────────────────────────────────
            _stagger(
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenHorizontal,
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
                            color: cs.secondaryContainer
                                .withValues(alpha: dark ? 0.3 : 0.6),
                            borderRadius: AppRadius.radiusMd,
                          ),
                          child: Icon(
                            Icons.person_remove_rounded,
                            color: cs.onSecondaryContainer,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            'Exclude from bill',
                            style: AppTextStyles.titleLarge.copyWith(
                              color: cs.onSurface,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                        // Done button — pill style.
                        _AnimatedTapScale(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg,
                              vertical: AppSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color: cs.primary,
                              borderRadius: AppRadius.radiusFull,
                              boxShadow: dark
                                  ? AppShadows.primaryGlowDark
                                  : AppShadows.primaryGlowLight,
                            ),
                            child: Text(
                              'Done',
                              style: AppTextStyles.labelLarge.copyWith(
                                color: cs.onPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Tap a member to include or exclude them from the split.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    // ── Excluded count badge — animated ───────────
                    AnimatedSize(
                      duration: const Duration(milliseconds: 320),
                      curve: Curves.easeInOutCubicEmphasized,
                      alignment: Alignment.topLeft,
                      child: AnimatedOpacity(
                        opacity: excludedCount > 0 ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOutCubic,
                        child: excludedCount > 0
                            ? Padding(
                                padding: const EdgeInsets.only(
                                  top: AppSpacing.xs,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.sm,
                                    vertical: AppSpacing.xs,
                                  ),
                                  decoration: BoxDecoration(
                                    color: cs.errorContainer
                                        .withValues(alpha: dark ? 0.25 : 0.5),
                                    borderRadius: AppRadius.radiusFull,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.info_outline_rounded,
                                        size: 13,
                                        color: cs.error,
                                      ),
                                      const SizedBox(width: AppSpacing.xs),
                                      AnimatedSwitcher(
                                        duration: const Duration(
                                          milliseconds: 250,
                                        ),
                                        transitionBuilder: (child, anim) =>
                                            FadeTransition(
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
                                          '$excludedCount '
                                          '${excludedCount == 1 ? "person" : "people"} excluded',
                                          key: ValueKey(excludedCount),
                                          style: AppTextStyles.labelSmall
                                              .copyWith(
                                            color: cs.error,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                  ],
                ),
              ),
              0.10, 0.30,
            ),
            const SizedBox(height: AppSpacing.lg),
            // ── Divider ──────────────────────────────────────────
            _stagger(
              Divider(
                height: 1,
                thickness: 1,
                color: cs.outlineVariant
                    .withValues(alpha: dark ? 0.2 : 0.4),
              ),
              0.20, 0.35,
            ),
            // ── Participant list ─────────────────────────────────
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenHorizontal,
                  vertical: AppSpacing.md,
                ),
                itemCount: participants.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (_, i) {
                  final p = participants[i];
                  // Stagger each tile with a slight delay based on index.
                  final start = 0.25 + (i * 0.04).clamp(0.0, 0.35);
                  final end = start + 0.20;
                  return _stagger(
                    _ExcludeParticipantTile(
                      participant: p,
                      colorScheme: cs,
                      isDark: dark,
                      onToggle: () => widget.onToggle(p.id),
                    ),
                    start, end,
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
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: AppSpacing.cardPaddingSymmetric,
        decoration: BoxDecoration(
          color: isExcluded
              ? colorScheme.errorContainer
                  .withValues(alpha: isDark ? 0.25 : 0.4)
              : colorScheme.surfaceContainerHighest
                  .withValues(alpha: isDark ? 0.3 : 0.5),
          borderRadius: AppRadius.radiusLg,
          border: Border.all(
            color: isExcluded
                ? colorScheme.error.withValues(alpha: 0.3)
                : colorScheme.outlineVariant
                    .withValues(alpha: isDark ? 0.2 : 0.4),
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
                      Flexible(
                        child: Text(
                          participant.bestDisplayName,
                          style: AppTextStyles.titleSmall.copyWith(
                            color: isExcluded
                                ? colorScheme.onSurfaceVariant
                                : colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    isExcluded ? 'Excluded' : 'Included',
                    style: AppTextStyles.caption.copyWith(
                      color: isExcluded
                          ? colorScheme.error
                          : colorScheme.onSurfaceVariant,
                      fontWeight: isExcluded ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            // Status toggle.
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: isExcluded
                  ? Container(
                      key: const ValueKey('excluded'),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: colorScheme.error.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.remove_rounded,
                        color: colorScheme.error,
                        size: 18,
                      ),
                    )
                  : Container(
                      key: const ValueKey('included'),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        color: colorScheme.primary,
                        size: 18,
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
                                  AppConstants.formatCurrency(form.amount, withSymbol: true),
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
            AppConstants.formatCurrency(share, withSymbol: true),
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
