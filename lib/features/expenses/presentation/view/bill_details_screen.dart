import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/design_system.dart';
import '../../domain/entities/bill.dart';
import '../../presentation/state/bill_providers.dart';

/// Full-screen bill details view.
///
/// Mirrors the layout of the review bottom sheet in [CreateBillScreen] but
/// as a standalone screen — showing the gradient summary card, receipt
/// photo (if any), split mode, and the full participant breakdown.
///
/// Each included participant can mark their own share as "Paid" or
/// "Partially paid". The request is sent to the bill creator (identified
/// by the bill's `created_by` field), who must verify it before the
/// participant's [ParticipantPaymentStatus] is finalized. The screen
/// watches the bill document in real time so requests and verifications
/// made by other members appear live.
///
/// Shows a brief skeleton loading shimmer on entry before revealing the
/// content, giving a smooth transition when navigating from the group
/// details bill list.
class BillDetailsScreen extends ConsumerStatefulWidget {
  const BillDetailsScreen({
    super.key,
    required this.bill,
    required this.currentUserId,
  });

  final Bill bill;
  final String currentUserId;

  @override
  ConsumerState<BillDetailsScreen> createState() =>
      _BillDetailsScreenState();
}

class _BillDetailsScreenState extends ConsumerState<BillDetailsScreen>
    with TickerProviderStateMixin {
  late final AnimationController _shimmerController;
  late final AnimationController _hintController;
  bool _isLoading = true;

  static const _loadingDuration = Duration(milliseconds: 400);

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    // Gentle, repeating nudge animation for the "tap to update" hint
    // pointer next to the Status column header. Loops with a pause between
    // each nudge so it feels alive without being distracting.
    _hintController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _startLoading();
  }

  Future<void> _startLoading() async {
    await Future.delayed(_loadingDuration);
    if (!mounted) return;
    _shimmerController.stop();
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _hintController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime d) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Watch the live bill stream so payment requests and verifications
    // made by other members appear in real time. Fall back to the bill
    // passed into the widget until the stream emits its first value.
    final billAsync = ref.watch(billStreamProvider(
      (groupId: widget.bill.groupId, billId: widget.bill.id),
    ));
    final bill = billAsync.valueOrNull ?? widget.bill;

    // Surface payment action outcomes (success / error) as snackbars.
    ref.listen<PaymentActionState>(paymentActionProvider, (_, next) {
      if (next is PaymentActionSuccess) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text(next.message),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ));
        ref.read(paymentActionProvider.notifier).reset();
      } else if (next is PaymentActionError) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text(next.message),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ));
        ref.read(paymentActionProvider.notifier).reset();
      }
    });

    return Scaffold(
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: _isLoading
              ? _BillDetailsSkeleton(
                  key: const ValueKey('skeleton'),
                  shimmerController: _shimmerController,
                  colorScheme: colorScheme,
                  isDark: isDark,
                )
              : KeyedSubtree(
                  key: const ValueKey('content'),
                  child: _buildContent(context, colorScheme, isDark, bill),
                ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ColorScheme colorScheme,
    bool isDark,
    Bill bill,
  ) {
    final included = bill.includedParticipants;
    final date = bill.date ?? bill.createdAt;
    final isCreator = widget.currentUserId == bill.createdBy;
    // Participants the creator can still nudge about an outstanding share.
    final remindable = bill.remindableParticipants;
    // Whether at least one row offers a tappable status (the current user
    // has an unpaid/rejected share). Drives the animated "tap to update"
    // hint pointer next to the Status column header.
    final hasTappableStatus = included.any((p) {
      if (p.id != widget.currentUserId) return false;
      final s = bill.paymentFor(p.id).status;
      return s == ParticipantPaymentStatus.unpaid ||
          s == ParticipantPaymentStatus.rejected;
    });

    return CustomScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        // ── Top bar ─────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.sm,
              AppSpacing.sm,
              AppSpacing.screenHorizontal,
              AppSpacing.sm,
            ),
            child: Text(
              'Bill Details',
              style: AppTextStyles.titleMedium.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenHorizontal,
          ),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: AppSpacing.lg),

              // ── Bill summary card (same style as review sheet) ───────
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
                    // Title + payment status.
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            bill.title,
                            style: AppTextStyles.titleLarge.copyWith(
                              color: colorScheme.onPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        _PaymentStatusPill(
                          status: bill.paymentStatus,
                          onPrimary: colorScheme.onPrimary,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      bill.groupName,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: colorScheme.onPrimary
                            .withValues(alpha: 0.75),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    // Total + Date row.
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
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
                              AppConstants.formatCurrency(
                                bill.totalAmount,
                                withSymbol: true,
                              ),
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
                    // Note (if present).
                    if (bill.note != null && bill.note!.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.md),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: colorScheme.onPrimary
                              .withValues(alpha: 0.12),
                          borderRadius: AppRadius.radiusMd,
                        ),
                        child: Text(
                          bill.note!,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: colorScheme.onPrimary
                                .withValues(alpha: 0.85),
                          ),
                        ),
                      ),
                    ],
                    // Payment progress bar — reflects how many included
                    // participants have been verified as fully paid.
                    const SizedBox(height: AppSpacing.lg),
                    _PaymentProgressBar(
                      bill: bill,
                      onPrimary: colorScheme.onPrimary,
                    ),
                    // Reminder action — creator only, and only while at
                    // least one member still owes their share.
                    if (isCreator && remindable.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.lg),
                      _RemindMembersButton(
                        count: remindable.length,
                        onPrimary: colorScheme.onPrimary,
                        onTap: () => _showRemindDialog(
                          bill: bill,
                          recipients: remindable,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // ── Verification requests (creator only) ──────────────────
              // Placed right below the main summary card so the bill
              // creator sees pending approvals prominently, before the
              // receipt photo, payment methods, and split breakdown.
              if (isCreator &&
                  bill.pendingVerificationParticipants.isNotEmpty) ...[
                _StaggeredFadeIn(
                  delay: const Duration(milliseconds: 80),
                  child: _VerificationSection(
                    bill: bill,
                    currentUserId: widget.currentUserId,
                    colorScheme: colorScheme,
                    isDark: isDark,
                    onVerify: ({
                      required participantId,
                      required approved,
                      required receivedAmount,
                    }) =>
                        _verifyRequest(
                      bill: bill,
                      participantId: participantId,
                      approved: approved,
                      receivedAmount: receivedAmount,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],

              // ── Receipt photo (if present) ────────────────────────────
              if (bill.receiptPhotoUrl != null &&
                  bill.receiptPhotoUrl!.isNotEmpty) ...[
                _StaggeredFadeIn(
                  delay: const Duration(milliseconds: 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                        child: Image.network(
                          bill.receiptPhotoUrl!,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const SizedBox.shrink(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],

              // ── Payment method(s) with QR code ───────────────────────
              // Shows the payment option(s) chosen at creation time as
              // tappable cards. Tapping a card opens the uploaded QR photo
              // in a full-screen Hero-driven viewer with a dimming
              // backdrop, instead of showing the photo inline.
              if (bill.paymentMethods.isNotEmpty) ...[
                _StaggeredFadeIn(
                  delay: const Duration(milliseconds: 220),
                  child: _PaymentMethodSection(
                    bill: bill,
                    colorScheme: colorScheme,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],

              // ── Split mode chip ───────────────────────────────────────
              Row(
                children: [
                  Icon(
                    bill.splitMode == BillSplitMode.equal
                        ? Icons.people_alt_rounded
                        : Icons.tune_rounded,
                    size: 18,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    bill.splitMode == BillSplitMode.equal
                        ? 'Equal Split'
                        : 'Custom Split',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // ── Participant breakdown ─────────────────────────────────
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
                          const SizedBox(width: AppSpacing.sm),
                          SizedBox(
                            width: 72,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (hasTappableStatus)
                                  _StatusHintPointer(
                                    controller: _hintController,
                                    color: colorScheme.primary,
                                  )
                                else
                                  const SizedBox(width: 14),
                                const SizedBox(width: 2),
                                Text(
                                  'Status',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  textAlign: TextAlign.end,
                                ),
                              ],
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
                      _ParticipantRow(
                        participant: included[i],
                        share: bill.splitMode == BillSplitMode.equal
                            ? bill.perPersonShare
                            : included[i].customShare,
                        payment: bill.paymentFor(included[i].id),
                        isCurrentUserRow:
                            included[i].id == widget.currentUserId,
                        colorScheme: colorScheme,
                        onMarkPayment: () => _showPaymentActionSheet(
                          bill: bill,
                          participant: included[i],
                        ),
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

              // ── Excluded members (if any) ─────────────────────────────
              if (bill.excludedMemberIds.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xl),
                Row(
                  children: [
                    Icon(
                      Icons.person_remove_outlined,
                      size: 18,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Excluded',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: bill.excludedMemberIds.map((id) {
                    final p = bill.participants
                        .cast<BillParticipant?>()
                        .firstWhere(
                          (p) => p?.id == id,
                          orElse: () => null,
                        );
                    final name = p?.bestDisplayName ?? 'Unknown';
                    return Chip(
                      label: Text(name),
                      avatar: Icon(
                        Icons.person_outline_rounded,
                        size: 18,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.radiusFull,
                      ),
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: AppSpacing.xxxl),
              const SizedBox(height: 80),
            ]),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // Payment action helpers
  // ─────────────────────────────────────────────────────────────────────

  /// Opens a bottom sheet letting the current user mark their own share as
  /// "Paid in full" or "Partially paid".
  ///
  /// Every member — including the bill creator — submits a verification
  /// request. The request appears in the bill creator's "Payment
  /// Verifications" section, where the creator approves or rejects it
  /// (their own request included), keeping the flow uniform for all.
  void _showPaymentActionSheet({
    required Bill bill,
    required BillParticipant participant,
  }) {
    final share = bill.splitMode == BillSplitMode.equal
        ? bill.perPersonShare
        : participant.customShare;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (context) => _PaymentActionSheet(
        participantName: participant.bestDisplayName,
        share: share,
        onPaid: () {
          Navigator.of(context).pop();
          _submitPaidRequest(bill, participant, share);
        },
        onPartially: () {
          Navigator.of(context).pop();
          _showPartialAmountDialog(
            bill: bill,
            participant: participant,
            share: share,
          );
        },
      ),
    );
  }

  /// Submits a "paid in full" request for [participant]'s share.
  ///
  /// Every participant — including the bill creator — submits a request
  /// that lands in the bill creator's "Payment Verifications" section.
  /// The creator then approves/rejects it (their own request included),
  /// keeping the verification flow uniform for all members.
  Future<void> _submitPaidRequest(
    Bill bill,
    BillParticipant participant,
    double share,
  ) async {
    await ref.read(paymentActionProvider.notifier).requestPayment(
          groupId: bill.groupId,
          billId: bill.id,
          memberId: participant.id,
          requestType: PaymentRequestType.paid,
          requestedAmount: share,
        );
  }

  /// Opens a dialog where the user enters the partial amount they have paid.
  ///
  /// Validators enforce:
  /// - The amount must be greater than zero.
  /// - The amount must not exceed the assigned share.
  /// - The amount must not equal the assigned share (since the user chose
  ///   the "partially paid" option, they cannot enter the full amount).
  void _showPartialAmountDialog({
    required Bill bill,
    required BillParticipant participant,
    required double share,
  }) {
    showDialog<void>(
      context: context,
      builder: (context) => _PartialPaymentDialog(
        participantName: participant.bestDisplayName,
        share: share,
        onSubmit: (amount) {
          Navigator.of(context).pop();
          _submitPartialRequest(bill, participant, amount);
        },
      ),
    );
  }

  /// Submits a "partially paid" request for [participant] with the entered
  /// [amount]. Like [_submitPaidRequest], this always creates a
  /// verification request — even when the current user is the bill creator.
  Future<void> _submitPartialRequest(
    Bill bill,
    BillParticipant participant,
    double amount,
  ) async {
    await ref.read(paymentActionProvider.notifier).requestPayment(
          groupId: bill.groupId,
          billId: bill.id,
          memberId: participant.id,
          requestType: PaymentRequestType.partially,
          requestedAmount: amount,
        );
  }

  /// The bill creator verifies (approves or rejects) a participant's
  /// pending payment request. Approval opens a dialog to confirm the
  /// amount actually received.
  Future<void> _verifyRequest({
    required Bill bill,
    required String participantId,
    required bool approved,
    required double receivedAmount,
  }) async {
    await ref.read(paymentActionProvider.notifier).verifyPayment(
          groupId: bill.groupId,
          billId: bill.id,
          memberId: participantId,
          approved: approved,
          receivedAmount: receivedAmount,
          verifiedBy: widget.currentUserId,
        );
  }

  /// Opens a confirmation dialog listing the members who will be reminded
  /// before dispatching the notification.
  void _showRemindDialog({
    required Bill bill,
    required List<BillParticipant> recipients,
  }) {
    showDialog<void>(
      context: context,
      builder: (context) => _RemindConfirmDialog(
        bill: bill,
        recipients: recipients,
        onSend: () {
          Navigator.of(context).pop();
          _sendReminder(bill);
        },
      ),
    );
  }

  /// Sends a payment reminder to the bill's outstanding participants.
  ///
  /// The resulting success/error snackbar is surfaced by the
  /// [paymentActionProvider] listener in [build].
  Future<void> _sendReminder(Bill bill) async {
    await ref.read(paymentActionProvider.notifier).remindOutstandingParticipants(
          groupId: bill.groupId,
          billId: bill.id,
        );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Skeleton loading for bill details
// ═════════════════════════════════════════════════════════════════════════════

class _BillDetailsSkeleton extends StatelessWidget {
  const _BillDetailsSkeleton({
    super.key,
    required this.shimmerController,
    required this.colorScheme,
    required this.isDark,
  });

  final AnimationController shimmerController;
  final ColorScheme colorScheme;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final base = colorScheme.surfaceContainerHighest.withValues(alpha: 0.5);
    final highlight = colorScheme.surfaceContainerHighest
        .withValues(alpha: 0.9);

    return AnimatedBuilder(
      animation: shimmerController,
      builder: (context, _) {
        final t = shimmerController.value;
        return Stack(
          children: [
            SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenHorizontal,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top bar skeleton.
                  Padding(
                    padding: const EdgeInsets.only(
                      top: AppSpacing.sm,
                      bottom: AppSpacing.sm,
                    ),
                    child: Row(
                      children: [
                        _SkeletonCircle(size: 40, color: base),
                        const SizedBox(width: AppSpacing.md),
                        _SkeletonBox(
                            width: 120, height: 16, color: base),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  // Summary card skeleton.
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: base,
                      borderRadius: AppRadius.radiusXxl,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  // Payment method card skeleton.
                  Row(
                    children: [
                      _SkeletonCircle(size: 18, color: base),
                      const SizedBox(width: AppSpacing.sm),
                      _SkeletonBox(width: 120, height: 16, color: base),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    height: 72,
                    decoration: BoxDecoration(
                      color: base,
                      borderRadius: AppRadius.radiusLg,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  // Split mode label skeleton.
                  Row(
                    children: [
                      _SkeletonCircle(size: 18, color: base),
                      const SizedBox(width: AppSpacing.sm),
                      _SkeletonBox(width: 100, height: 16, color: base),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // Participant breakdown skeleton.
                  Container(
                    decoration: BoxDecoration(
                      color: base,
                      borderRadius: AppRadius.radiusXxl,
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Row(
                            children: [
                              _SkeletonCircle(size: 36, color: base),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: _SkeletonBox(
                                    width: double.infinity,
                                    height: 14,
                                    color: base),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              _SkeletonBox(width: 60, height: 14, color: base),
                            ],
                          ),
                        ),
                        for (var i = 0; i < 4; i++)
                          Padding(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: Row(
                              children: [
                                _SkeletonCircle(size: 36, color: base),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: _SkeletonBox(
                                      width: double.infinity,
                                      height: 14,
                                      color: base),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                _SkeletonBox(
                                    width: 60, height: 14, color: base),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Shimmer overlay.
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment(-1 + 2 * t, 0),
                      end: Alignment(-1 + 2 * t + 0.5, 0),
                      colors: [
                        Colors.transparent,
                        highlight.withValues(alpha: 0.25),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SkeletonCircle extends StatelessWidget {
  const _SkeletonCircle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({
    this.width,
    this.height,
    required this.color,
  });

  final double? width;
  final double? height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Payment progress bar (inside the gradient summary card)
// ═════════════════════════════════════════════════════════════════════════════

/// A highly-animated progress bar shown inside the gradient bill summary
/// card. It reflects the share of included participants whose payment has
/// been verified as fully paid.
///
/// Visual behavior by state:
/// - **0%**: the track is always visible with a shimmering placeholder
///   sweep and a gentle pulse, so the user knows a progress bar exists
///   even before anyone has paid.
/// - **1%–99%**: the fill animates from its previous value to the new
///   target (easeOutCubic), with a continuous shimmer sweep travelling
///   across the filled portion and a soft leading-edge glow.
/// - **100%**: the fill brightens to full opacity, gains a celebratory
///   glow, and the label switches to "All paid" with a check icon.
///
/// The track and fill are tinted with `onPrimary` so they sit naturally on
/// the gradient. A label row above the bar shows "X of Y paid" on the left
/// and the percentage on the right.
class _PaymentProgressBar extends StatefulWidget {
  const _PaymentProgressBar({
    required this.bill,
    required this.onPrimary,
  });

  final Bill bill;
  final Color onPrimary;

  @override
  State<_PaymentProgressBar> createState() => _PaymentProgressBarState();
}

class _PaymentProgressBarState extends State<_PaymentProgressBar>
    with TickerProviderStateMixin {
  late final AnimationController _fillController;
  late final AnimationController _shimmerController;
  late Animation<double> _fill;

  int get _paidCount {
    final included = widget.bill.includedParticipants;
    return included
        .where((p) =>
            widget.bill.paymentFor(p.id).status ==
            ParticipantPaymentStatus.paid)
        .length;
  }

  int get _totalCount => widget.bill.includedCount;

  double get _progress {
    if (_totalCount == 0) return 0.0;
    return (_paidCount / _totalCount).clamp(0.0, 1.0);
  }

  @override
  void initState() {
    super.initState();
    // Drives the fill animation from 0 → 1. The actual fill width is
    // computed as `_fill.value * _progress`, so the eased curve never
    // distorts the final target value. (Animating directly to
    // `_progress` through a CurvedAnimation would apply the easing
    // curve to the target — e.g. easeOutCubic(0.5) ≈ 0.9, making a
    // 50% bar look ~90% full.)
    _fillController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
      value: 0.0,
    );
    _fill = CurvedAnimation(
      parent: _fillController,
      curve: Curves.easeOutCubic,
    )..addListener(() {
        if (mounted) setState(() {});
      });

    // Drives the shimmer sweep across the fill (loops forever).
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    // Animate from 0 → 1 after the first frame. The width factor is
    // `_fill.value * _progress`, so the bar eases up to the correct
    // target width.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _fillController.animateTo(1.0);
    });
  }

  @override
  void didUpdateWidget(covariant _PaymentProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-animate whenever the target progress changes (e.g. a
    // verification lands via the real-time bill stream).
    final oldTotal = oldWidget.bill.includedCount;
    final oldPaid = oldWidget.bill.includedParticipants
        .where((p) =>
            oldWidget.bill.paymentFor(p.id).status ==
            ParticipantPaymentStatus.paid)
        .length;
    final oldProgress = oldTotal == 0
        ? 0.0
        : (oldPaid / oldTotal).clamp(0.0, 1.0);
    if ((oldProgress - _progress).abs() > 0.001) {
      // Reset to 0 and re-animate to 1 so the new target is reached
      // with the easing curve applied correctly.
      _fillController
        ..value = 0.0
        ..animateTo(1.0);
    }
  }

  @override
  void dispose() {
    _fillController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onPrimary = widget.onPrimary;
    final paid = _paidCount;
    final total = _totalCount;
    final progress = _progress;
    final percent = (progress * 100).round();
    final allPaid = paid > 0 && paid == total;
    final isZero = progress <= 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label row: "X of Y paid" + percentage.
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  allPaid
                      ? Icons.check_circle_rounded
                      : Icons.groups_2_rounded,
                  size: 13,
                  color: onPrimary.withValues(alpha: 0.85),
                ),
                const SizedBox(width: 5),
                Text(
                  allPaid ? 'All paid' : '$paid of $total paid',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: onPrimary.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            Text(
              '$percent%',
              style: AppTextStyles.labelSmall.copyWith(
                color: onPrimary.withValues(alpha: 0.95),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        // Track + animated fill.
        AnimatedBuilder(
          animation: _shimmerController,
          builder: (context, _) {
            return Container(
              height: 10,
              decoration: BoxDecoration(
                color: onPrimary.withValues(alpha: 0.16),
                borderRadius: AppRadius.radiusFull,
              ),
              child: ClipRRect(
                borderRadius: AppRadius.radiusFull,
                child: Stack(
                  children: [
                    // At 0%, render a full-width (100%) low-opacity fill
                    // so the bar is clearly visible as a complete shape —
                    // just dimmed to communicate "no progress yet". A
                    // shimmer sweep travels across it to keep it feeling
                    // alive. Once progress > 0%, this is hidden and the
                    // real animated fill takes over.
                    if (isZero)
                      Positioned.fill(
                        child: _ProgressFill(
                          onPrimary: onPrimary,
                          allPaid: false,
                          shimmerValue: _shimmerController.value,
                          dimmed: true,
                        ),
                      ),
                    // Real fill (animated width). The width factor is
                    // the eased animation value (0 → 1) multiplied by the
                    // actual progress, so the bar fills to exactly the
                    // right percentage with a smooth easing curve.
                    if (!isZero)
                      FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: _fill.value * _progress,
                        child: _ProgressFill(
                          onPrimary: onPrimary,
                          allPaid: allPaid,
                          shimmerValue: _shimmerController.value,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// The filled portion of the progress bar.
///
/// Renders a rounded fill with a continuous shimmer sweep travelling left
/// → right across it, plus a soft glow at the leading edge. When [allPaid]
/// is true, the fill brightens and gains a celebratory glow.
///
/// When [dimmed] is true (used at 0% progress), the fill renders at full
/// width with a low opacity so the bar is clearly visible as a complete
/// shape — just dimmed to communicate "no progress yet" — while still
/// carrying the shimmer sweep so it feels alive.
class _ProgressFill extends StatelessWidget {
  const _ProgressFill({
    required this.onPrimary,
    required this.allPaid,
    required this.shimmerValue,
    this.dimmed = false,
  });

  final Color onPrimary;
  final bool allPaid;
  final double shimmerValue;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    // Shimmer sweep position (0 → 1, wraps around).
    final sweep = (shimmerValue * 2.0) % 1.0;

    // Base fill alpha: full when complete, strong when in progress, low
    // when dimmed (0% placeholder).
    final fillAlpha = dimmed
        ? 0.35
        : allPaid
            ? 1.0
            : 0.9;

    return Container(
      decoration: BoxDecoration(
        borderRadius: AppRadius.radiusFull,
        boxShadow: dimmed
            ? null
            : allPaid
                ? [
                    BoxShadow(
                      color: onPrimary.withValues(alpha: 0.55),
                      blurRadius: 10,
                      spreadRadius: 0.5,
                    ),
                  ]
                : [
                    // Soft glow at the leading edge of the fill.
                    BoxShadow(
                      color: onPrimary.withValues(alpha: 0.35),
                      blurRadius: 6,
                      spreadRadius: 0.5,
                    ),
                  ],
      ),
      child: Stack(
        children: [
          // Base fill.
          Container(
            decoration: BoxDecoration(
              color: onPrimary.withValues(alpha: fillAlpha),
              borderRadius: AppRadius.radiusFull,
            ),
          ),
          // Shimmer sweep overlay.
          Positioned.fill(
            child: ClipRRect(
              borderRadius: AppRadius.radiusFull,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(sweep * 2 - 1, 0),
                    end: Alignment(sweep * 2 - 0.4, 0),
                    colors: [
                      Colors.transparent,
                      Colors.white.withValues(
                          alpha: dimmed ? 0.20 : 0.35),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
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
// Reminder button (inside the gradient summary card)
// ═════════════════════════════════════════════════════════════════════════════

/// Creator-only action shown at the bottom of the gradient bill summary card.
///
/// Displays how many members still owe their share and, when tapped, opens
/// [_RemindConfirmDialog] before dispatching the push reminders. Styled as a
/// translucent `onPrimary`-tinted pill so it reads as part of the card, with
/// the same press-scale feedback used by [_ParticipantRow].
class _RemindMembersButton extends StatefulWidget {
  const _RemindMembersButton({
    required this.count,
    required this.onPrimary,
    required this.onTap,
  });

  final int count;
  final Color onPrimary;
  final VoidCallback onTap;

  @override
  State<_RemindMembersButton> createState() => _RemindMembersButtonState();
}

class _RemindMembersButtonState extends State<_RemindMembersButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.96,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onPrimary = widget.onPrimary;
    final label = widget.count == 1
        ? 'Remind 1 member'
        : 'Remind ${widget.count} members';

    return ScaleTransition(
      scale: _press,
      child: GestureDetector(
        onTapDown: (_) => _press.reverse(),
        onTapUp: (_) {
          _press.forward();
          widget.onTap();
        },
        onTapCancel: () => _press.forward(),
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: onPrimary.withValues(alpha: 0.18),
            borderRadius: AppRadius.radiusLg,
            border: Border.all(
              color: onPrimary.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.notifications_active_rounded,
                size: 18,
                color: onPrimary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: AppTextStyles.labelLarge.copyWith(
                  color: onPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: AppSpacing.xxs),
              Icon(
                Icons.arrow_forward_rounded,
                size: 16,
                color: onPrimary.withValues(alpha: 0.85),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Confirmation dialog shown before a reminder is dispatched.
///
/// A gradient hero header sets the intent, then the members who will receive
/// the notification are listed as cards — each with their avatar and the
/// outstanding amount — so the creator knows exactly who is about to be
/// nudged. A reassurance strip notes that members who have already paid are
/// skipped.
class _RemindConfirmDialog extends StatelessWidget {
  const _RemindConfirmDialog({
    required this.bill,
    required this.recipients,
    required this.onSend,
  });

  final Bill bill;
  final List<BillParticipant> recipients;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final gradient = isDark
        ? AppColors.darkPrimaryGradient
        : AppColors.lightPrimaryGradient;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.xxl,
      ),
      backgroundColor: cs.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusXxl),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.94, end: 1.0),
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutBack,
        builder: (context, scale, child) => Transform.scale(
          scale: scale,
          child: child,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(gradient, recipients.length),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    AppSpacing.lg,
                    AppSpacing.xl,
                    AppSpacing.lg,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'WHO GETS REMINDED',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      for (final participant in recipients)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: _buildRecipientTile(cs, isDark, participant),
                        ),
                      const SizedBox(height: AppSpacing.xs),
                      _buildReassurance(cs, isDark),
                    ],
                  ),
                ),
              ),
              _buildActions(context, cs, gradient),
            ],
          ),
        ),
      ),
    );
  }

  // ── Gradient hero header ───────────────────────────────────────────────────

  Widget _buildHeader(LinearGradient gradient, int count) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(gradient: gradient),
      child: Stack(
        children: [
          // Decorative translucent circles for depth.
          Positioned(
            right: -34,
            top: -40,
            child: _decorBlob(130, 0.12),
          ),
          Positioned(
            left: -30,
            bottom: -50,
            child: _decorBlob(100, 0.08),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.22),
                    borderRadius: AppRadius.radiusLg,
                    border: Border.all(
                      color: AppColors.white.withValues(alpha: 0.35),
                    ),
                  ),
                  child: const Icon(
                    Icons.notifications_active_rounded,
                    color: AppColors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Send Payment Reminder',
                  style: AppTextStyles.titleLarge.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  count == 1
                      ? '1 member will be notified right away'
                      : '$count members will be notified right away',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.white.withValues(alpha: 0.92),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _decorBlob(double size, double alpha) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.white.withValues(alpha: alpha),
      ),
    );
  }

  // ── Recipient card ─────────────────────────────────────────────────────────

  Widget _buildRecipientTile(
    ColorScheme cs,
    bool isDark,
    BillParticipant participant,
  ) {
    final share = bill.shareFor(participant.id);
    final paid = bill.paymentFor(participant.id).amountPaid;
    final outstanding = (share - paid).clamp(0.0, double.infinity);
    final accent = _accentFor(participant.id, isDark);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: isDark ? 0.35 : 0.5),
        borderRadius: AppRadius.radiusLg,
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          _buildAvatar(participant, accent),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  participant.bestDisplayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleSmall.copyWith(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Payment pending',
                  style: AppTextStyles.caption.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                AppConstants.formatCurrency(outstanding, withSymbol: true),
                style: AppTextStyles.labelLarge.copyWith(
                  color: cs.error,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'due',
                style: AppTextStyles.caption.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(BillParticipant participant, Color accent) {
    final picture = participant.profilePicture;
    final hasPicture = picture != null && picture.isNotEmpty;

    return Container(
      width: 44,
      height: 44,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: accent.withValues(alpha: 0.16),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: hasPicture
          ? Image.network(
              picture,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildInitials(participant, accent),
            )
          : _buildInitials(participant, accent),
    );
  }

  Widget _buildInitials(BillParticipant participant, Color accent) {
    return Center(
      child: Text(
        participant.initials.isEmpty ? '?' : participant.initials,
        style: AppTextStyles.labelLarge.copyWith(
          color: accent,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  /// Deterministic accent colour per participant, so a member keeps the same
  /// avatar tint across the dialog.
  Color _accentFor(String id, bool isDark) {
    final palette =
        isDark ? AppColors.chartColorsDark : AppColors.chartColorsLight;
    final hash = id.codeUnits.fold<int>(0, (sum, unit) => sum + unit);
    return palette[hash % palette.length];
  }

  // ── Reassurance strip ──────────────────────────────────────────────────────

  Widget _buildReassurance(ColorScheme cs, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: isDark ? 0.16 : 0.35),
        borderRadius: AppRadius.radiusLg,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.verified_rounded, size: 18, color: cs.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Members who have already paid will not be notified.',
              style: AppTextStyles.caption.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Widget _buildActions(
    BuildContext context,
    ColorScheme cs,
    LinearGradient gradient,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        0,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                foregroundColor: cs.onSurface,
                side: BorderSide(color: cs.outlineVariant),
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.radiusLg,
                ),
              ),
              child: Text(
                'Cancel',
                style: AppTextStyles.labelLarge.copyWith(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            flex: 2,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: AppRadius.radiusLg,
                boxShadow: [
                  BoxShadow(
                    color: cs.primary.withValues(alpha: 0.32),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: AppColors.transparent,
                child: InkWell(
                  onTap: onSend,
                  borderRadius: AppRadius.radiusLg,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.send_rounded,
                          size: 18,
                          color: AppColors.white,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'Send Reminder',
                          style: AppTextStyles.labelLarge.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
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
// Payment status pill (for gradient cards)
// ═════════════════════════════════════════════════════════════════════════════

class _PaymentStatusPill extends StatelessWidget {
  const _PaymentStatusPill({
    required this.status,
    required this.onPrimary,
  });

  final BillPaymentStatus status;
  final Color onPrimary;

  @override
  Widget build(BuildContext context) {
    final (label, alpha) = switch (status) {
      BillPaymentStatus.paid => ('Paid', 0.95),
      BillPaymentStatus.partiallyPaid => ('Partial', 0.9),
      BillPaymentStatus.unpaid => ('Unpaid', 0.85),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: onPrimary.withValues(alpha: 0.2),
        borderRadius: AppRadius.radiusFull,
        border: Border.all(
          color: onPrimary.withValues(alpha: 0.25),
          width: 0.5,
        ),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          color: onPrimary.withValues(alpha: alpha),
          fontWeight: FontWeight.w700,
          fontSize: 10,
          height: 1.2,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Participant row
// ═════════════════════════════════════════════════════════════════════════════

class _ParticipantRow extends StatefulWidget {
  const _ParticipantRow({
    required this.participant,
    required this.share,
    required this.payment,
    required this.isCurrentUserRow,
    required this.colorScheme,
    required this.onMarkPayment,
  });

  final BillParticipant participant;
  final double share;
  final ParticipantPayment payment;
  final bool isCurrentUserRow;
  final ColorScheme colorScheme;
  final VoidCallback onMarkPayment;

  @override
  State<_ParticipantRow> createState() => _ParticipantRowState();
}

class _ParticipantRowState extends State<_ParticipantRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.94,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  bool get _canMark =>
      widget.isCurrentUserRow &&
      (widget.payment.status == ParticipantPaymentStatus.unpaid ||
          widget.payment.status == ParticipantPaymentStatus.rejected);

  @override
  Widget build(BuildContext context) {
    final colorScheme = widget.colorScheme;
    final payment = widget.payment;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _ParticipantAvatar(
                participant: widget.participant,
                colorScheme: colorScheme,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.participant.bestDisplayName,
                      style: AppTextStyles.titleSmall.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.participant.isCurrentUser)
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
                AppConstants.formatCurrency(widget.share, withSymbol: true),
                style: AppTextStyles.amountSmall.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              SizedBox(
                width: 72,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _canMark
                      ? ScaleTransition(
                          scale: _press,
                          child: GestureDetector(
                            onTapDown: (_) => _press.reverse(),
                            onTapUp: (_) {
                              _press.forward();
                              widget.onMarkPayment();
                            },
                            onTapCancel: () => _press.forward(),
                            child: _PaymentStatusBadge(
                              status: payment.status,
                              colorScheme: colorScheme,
                              tappable: true,
                            ),
                          ),
                        )
                      : _PaymentStatusBadge(
                          status: payment.status,
                          colorScheme: colorScheme,
                          tappable: false,
                        ),
                ),
              ),
            ],
          ),
          // If partially paid, show the verified amount below the row.
          if (payment.status == ParticipantPaymentStatus.partiallyPaid) ...[
            const SizedBox(height: 2),
            Padding(
              padding: const EdgeInsets.only(left: AppSpacing.xl + 36),
              child: Text(
                'Paid: ${AppConstants.formatCurrency(payment.amountPaid, withSymbol: true)}'
                ' • Remaining: ${AppConstants.formatCurrency(widget.share - payment.amountPaid, withSymbol: true)}',
                style: AppTextStyles.caption.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
          // Hint for the current user's own unpaid/rejected row.
          if (_canMark) ...[
            const SizedBox(height: 2),
            Padding(
              padding: const EdgeInsets.only(left: AppSpacing.xl + 36),
              child: Text(
                'Tap the status to mark your payment',
                style: AppTextStyles.caption.copyWith(
                  color: colorScheme.primary.withValues(alpha: 0.7),
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ParticipantAvatar extends StatelessWidget {
  const _ParticipantAvatar({
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
      child: Center(
        child: Text(
          participant.initials,
          style: AppTextStyles.labelSmall.copyWith(
            color: colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.w700,
            height: 1.0,
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Staggered fade-in helper for section entrance animations
// ═════════════════════════════════════════════════════════════════════════════

/// A small wrapper that fades + slides its child in on first build, after an
/// optional [delay]. Used to give each section of the bill details screen a
/// subtle, professional staggered entrance once the shimmer clears.
class _StaggeredFadeIn extends StatefulWidget {
  const _StaggeredFadeIn({
    required this.child,
    this.delay = Duration.zero,
  });

  final Widget child;
  final Duration delay;

  @override
  State<_StaggeredFadeIn> createState() => _StaggeredFadeInState();
}

class _StaggeredFadeInState extends State<_StaggeredFadeIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _fade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 1.0, curve: Curves.easeOut),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: widget.child,
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Payment method section + cards
// ═════════════════════════════════════════════════════════════════════════════

/// Brand accent colors + logos for each payment method.
/// Mirrors the values used in [PaymentOptionsCard] so the bill details screen
/// feels like a continuation of the creation flow.
Color _methodAccent(BillPaymentMethod m) {
  return switch (m) {
    BillPaymentMethod.esewa => const Color(0xFF60BB46),
    BillPaymentMethod.khalti => const Color(0xFF5C2D91),
    BillPaymentMethod.bank => AppColors.chartBlue,
  };
}

/// Brand logo asset for a payment method, resolved for the current theme.
///
/// eSewa ships a light-mode mark (dark artwork that reads on light surfaces)
/// alongside the original, which is used on dark surfaces.
String? _methodLogo(BillPaymentMethod m, {required bool isDark}) {
  return switch (m) {
    BillPaymentMethod.esewa => isDark
        ? 'assets/images/esewa.png'
        : 'assets/images/esewa_light_mode.png',
    BillPaymentMethod.khalti => 'assets/images/khalti.png',
    BillPaymentMethod.bank => null,
  };
}

String _methodLabel(BillPaymentMethod m) {
  return switch (m) {
    BillPaymentMethod.esewa => 'eSewa',
    BillPaymentMethod.khalti => 'Khalti',
    BillPaymentMethod.bank => 'Bank Transfer',
  };
}

/// Returns the Firestore string key for a payment method — used to look up
/// values in [Bill.paymentQrUrls] and [Bill.paymentIds].
String _methodKey(BillPaymentMethod method) {
  return switch (method) {
    BillPaymentMethod.esewa => 'esewa',
    BillPaymentMethod.khalti => 'khalti',
    BillPaymentMethod.bank => 'bank',
  };
}

/// Renders the "Payment Method" header and one tappable card per method the
/// bill creator selected. QR URLs and account IDs are looked up by method
/// name key from [Bill.paymentQrUrls] and [Bill.paymentIds] respectively.
class _PaymentMethodSection extends StatelessWidget {
  const _PaymentMethodSection({
    required this.bill,
    required this.colorScheme,
    required this.isDark,
  });

  final Bill bill;
  final ColorScheme colorScheme;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final methods = bill.paymentMethods;
    final count = methods.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header.
        Row(
          children: [
            Icon(
              Icons.account_balance_wallet_rounded,
              size: 18,
              color: colorScheme.primary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Payment Method',
              style: AppTextStyles.labelLarge.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Tap a method to view its QR code',
          style: AppTextStyles.labelSmall.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        for (int i = 0; i < count; i++)
          Padding(
            padding: EdgeInsets.only(bottom: i < count - 1 ? AppSpacing.sm : 0),
            child: _PaymentMethodCard(
              billId: bill.id,
              index: i,
              method: methods[i],
              qrUrl: bill.paymentQrUrls[_methodKey(methods[i])],
              bankName: bill.selectedBankName,
              accountId: bill.paymentIds[_methodKey(methods[i])],
              colorScheme: colorScheme,
              isDark: isDark,
            ),
          ),
      ],
    );
  }
}

/// A single tappable payment-method card. Mirrors the visual language of the
/// `_PaymentEntry` panel in [PaymentOptionsCard]: accent-tinted fill, accent
/// border, brand logo on the left, label + subtitle in the middle, and a
/// chevron / QR hint on the right.
///
/// Tapping the card (when a QR photo exists) opens [_PaymentQrViewer] via a
/// Hero transition so the photo appears to grow out of the card.
class _PaymentMethodCard extends StatefulWidget {
  const _PaymentMethodCard({
    required this.billId,
    required this.index,
    required this.method,
    required this.qrUrl,
    required this.bankName,
    required this.accountId,
    required this.colorScheme,
    required this.isDark,
  });

  final String billId;
  final int index;
  final BillPaymentMethod method;
  final String? qrUrl;
  final String? bankName;
  final String? accountId;
  final ColorScheme colorScheme;
  final bool isDark;

  @override
  State<_PaymentMethodCard> createState() => _PaymentMethodCardState();
}

class _PaymentMethodCardState extends State<_PaymentMethodCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.97,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  bool get _hasQr =>
      widget.qrUrl != null && widget.qrUrl!.isNotEmpty;

  String get _heroTag => 'payment-qr-${widget.billId}-${widget.index}';

  String get _accountIdLabel {
    return switch (widget.method) {
      BillPaymentMethod.esewa => 'eSewa ID',
      BillPaymentMethod.khalti => 'Khalti ID',
      BillPaymentMethod.bank => 'Account No.',
    };
  }

  String get _subtitle {
    if (widget.method == BillPaymentMethod.bank) {
      final name = widget.bankName;
      return (name != null && name.isNotEmpty)
          ? name
          : 'Tap to view QR code';
    }
    return _hasQr ? 'Tap to view QR code' : 'No QR code uploaded';
  }

  void _openViewer() {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.transparent,
        transitionDuration: const Duration(milliseconds: 320),
        reverseTransitionDuration: const Duration(milliseconds: 260),
        pageBuilder: (context, animation, secondaryAnimation) =>
            _PaymentQrViewer(
          heroTag: _heroTag,
          qrUrl: widget.qrUrl!,
          method: widget.method,
          colorScheme: widget.colorScheme,
          isDark: widget.isDark,
          animation: animation,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = widget.colorScheme;
    final accent = _methodAccent(widget.method);
    final logo = _methodLogo(widget.method, isDark: widget.isDark);

    return ScaleTransition(
      scale: _press,
      child: GestureDetector(
        onTapDown: (_) {
          if (_hasQr) _press.reverse();
        },
        onTapUp: (_) {
          _press.forward();
          if (_hasQr) _openViewer();
        },
        onTapCancel: () => _press.forward(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: widget.isDark ? 0.08 : 0.05),
            borderRadius: AppRadius.radiusLg,
            border: Border.all(
              color: accent.withValues(alpha: _hasQr ? 0.35 : 0.18),
              width: 1.0,
            ),
          ),
          child: Row(
            children: [
              // Brand logo / icon.
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: cs.surface.withValues(alpha: 0.85),
                  borderRadius: AppRadius.radiusMd,
                  border: Border.all(
                    color: accent.withValues(alpha: 0.25),
                    width: 0.8,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: Center(
                  child: logo != null
                      ? Image.asset(
                          logo,
                          width: 28,
                          height: 28,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.payment_rounded,
                            size: 24,
                            color: accent,
                          ),
                        )
                      : Icon(
                          Icons.account_balance_rounded,
                          size: 24,
                          color: accent,
                        ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),

              // Label + subtitle + account ID.
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _methodLabel(widget.method),
                      style: AppTextStyles.titleSmall.copyWith(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _subtitle,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: _hasQr
                            ? cs.onSurfaceVariant
                            : cs.onSurfaceVariant.withValues(alpha: 0.6),
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.accountId != null &&
                        widget.accountId!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.1),
                          borderRadius: AppRadius.radiusSm,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$_accountIdLabel: ',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: accent.withValues(alpha: 0.8),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Flexible(
                              child: Text(
                                widget.accountId!,
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: cs.onSurface,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Trailing QR hint / chevron.
              if (_hasQr)
                Hero(
                  tag: _heroTag,
                  flightShuttleBuilder: _qrFlightShuttleBuilder,
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: AppRadius.radiusSm,
                    ),
                    child: Icon(
                      Icons.qr_code_2_rounded,
                      size: 20,
                      color: accent,
                    ),
                  ),
                )
              else
                Icon(
                  Icons.qr_code_2_outlined,
                  size: 20,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Full-screen QR viewer (Hero-driven, dimming backdrop)
// ═════════════════════════════════════════════════════════════════════════════

/// Full-screen viewer for a payment QR photo.
///
/// The image flies in from the card's trailing QR chip via a [Hero] transition
/// (tag = [heroTag]). On top of the Hero flight, the backdrop fades from
/// transparent to a dimmed black and the image scales up slightly, giving a
/// polished "grow out of the card" feel. Dismiss by tapping the backdrop or
/// swiping down.
class _PaymentQrViewer extends StatefulWidget {
  const _PaymentQrViewer({
    required this.heroTag,
    required this.qrUrl,
    required this.method,
    required this.colorScheme,
    required this.isDark,
    required this.animation,
  });

  final String heroTag;
  final String qrUrl;
  final BillPaymentMethod method;
  final ColorScheme colorScheme;
  final bool isDark;
  final Animation<double> animation;

  @override
  State<_PaymentQrViewer> createState() => _PaymentQrViewerState();
}

class _PaymentQrViewerState extends State<_PaymentQrViewer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _dismissController;

  @override
  void initState() {
    super.initState();
    _dismissController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
      value: 1.0, // 1.0 = fully visible
    );
  }

  @override
  void dispose() {
    _dismissController.dispose();
    super.dispose();
  }

  Color get _accent => _methodAccent(widget.method);
  String get _label => _methodLabel(widget.method);

  Future<void> _close() async {
    await _dismissController.reverse();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    // Backdrop fades with the route animation; image scales in on top.
    final backdropFade = Tween<double>(begin: 0.0, end: 0.6).animate(
      CurvedAnimation(
        parent: widget.animation,
        curve: Curves.easeOut,
      ),
    );
    final imageScale = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(
        parent: widget.animation,
        curve: Curves.easeOutCubic,
      ),
    );
    final contentFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: widget.animation,
        curve: const Interval(0.25, 1.0, curve: Curves.easeOut),
      ),
    );

    return AnimatedBuilder(
      animation: Listenable.merge([widget.animation, _dismissController]),
      builder: (context, _) {
        // Combine route animation with the manual dismiss controller so a
        // swipe-down dismiss dims the backdrop smoothly.
        final dismissValue = _dismissController.value;
        final backdropOpacity = backdropFade.value * dismissValue;
        final scale = imageScale.value * dismissValue;
        final contentOpacity = contentFade.value * dismissValue;

        return Material(
          color: Colors.transparent,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _close,
            onVerticalDragEnd: (details) {
              if (details.primaryVelocity != null &&
                  details.primaryVelocity! > 220) {
                _close();
              }
            },
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Dimming backdrop.
                IgnorePointer(
                  child: ColoredBox(
                    color: Colors.black.withValues(alpha: backdropOpacity),
                  ),
                ),

                // Centered QR image with Hero.
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Method label chip.
                        Opacity(
                          opacity: contentOpacity,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color: _accent.withValues(alpha: 0.16),
                              borderRadius: AppRadius.radiusFull,
                              border: Border.all(
                                color: _accent.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.qr_code_2_rounded,
                                  size: 14,
                                  color: _accent,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '$_label QR Code',
                                  style: AppTextStyles.labelMedium.copyWith(
                                    color: _accent,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // Hero image.
                        Hero(
                          tag: widget.heroTag,
                          flightShuttleBuilder: _qrFlightShuttleBuilder,
                          child: Material(
                            color: Colors.transparent,
                            child: Transform.scale(
                              scale: scale,
                              child: ClipRRect(
                                borderRadius: AppRadius.radiusXxl,
                                child: Container(
                                  constraints: BoxConstraints(
                                    maxWidth:
                                        MediaQuery.of(context).size.width * 0.82,
                                    maxHeight:
                                        MediaQuery.of(context).size.height * 0.6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: AppRadius.radiusXxl,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.35),
                                        blurRadius: 40,
                                        spreadRadius: 2,
                                        offset: const Offset(0, 12),
                                      ),
                                    ],
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: Image.network(
                                    widget.qrUrl,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => Container(
                                      padding: const EdgeInsets.all(
                                        AppSpacing.xxl,
                                      ),
                                      color: Colors.white,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.broken_image_outlined,
                                            size: 48,
                                            color: Colors.grey.shade400,
                                          ),
                                          const SizedBox(height: AppSpacing.sm),
                                          Text(
                                            'Could not load QR code',
                                            style: AppTextStyles.labelMedium
                                                .copyWith(
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // Dismiss hint.
                        Opacity(
                          opacity: contentOpacity,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 16,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Tap or swipe down to close',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Shared Hero flight shuttle builder so the QR chip morphs cleanly into the
/// full-screen image (and back) regardless of the route's own transition.
Widget _qrFlightShuttleBuilder(
  BuildContext flightContext,
  Animation<double> animation,
  HeroFlightDirection flightDirection,
  BuildContext fromHeroContext,
  BuildContext toHeroContext,
) {
  return FadeTransition(
    opacity: animation,
    child: flightDirection == HeroFlightDirection.push
        ? toHeroContext.widget
        : fromHeroContext.widget,
  );
}

// ═════════════════════════════════════════════════════════════════════════════
// Animated "tap to update" hint pointer (Status column header)
// ═════════════════════════════════════════════════════════════════════════════

/// A small, gently bouncing pointer icon placed next to the "Status" column
/// header. Its repeating nudge animation hints to the user that the status
/// badges in that column are tappable.
class _StatusHintPointer extends StatelessWidget {
  const _StatusHintPointer({
    required this.controller,
    required this.color,
  });

  final AnimationController controller;
  final Color color;

  @override
  Widget build(BuildContext context) {
    // The pointer slides left ↔ right and fades slightly, like a finger
    // nudging toward the status badges.
    final nudge = Tween<double>(begin: -3.0, end: 3.0).animate(
      CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOutSine,
      ),
    );
    final fade = Tween<double>(begin: 0.45, end: 1.0).animate(
      CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOutSine,
      ),
    );

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Opacity(
          opacity: fade.value,
          child: Transform.translate(
            offset: Offset(nudge.value, 0),
            child: Icon(
              Icons.touch_app_rounded,
              size: 13,
              color: color,
            ),
          ),
        );
      },
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Per-participant payment status badge
// ═════════════════════════════════════════════════════════════════════════════

/// A compact pill showing a participant's [ParticipantPaymentStatus].
///
/// When [tappable] is true, the badge is rendered with a slightly stronger
/// fill, a small leading dot, and a dashed outline to communicate that it
/// is an interactive affordance (tapping it opens the mark-payment sheet).
class _PaymentStatusBadge extends StatelessWidget {
  const _PaymentStatusBadge({
    required this.status,
    required this.colorScheme,
    this.tappable = false,
  });

  final ParticipantPaymentStatus status;
  final ColorScheme colorScheme;
  final bool tappable;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      ParticipantPaymentStatus.paid =>
        ('Paid', colorScheme.primary),
      ParticipantPaymentStatus.partiallyPaid =>
        ('Partial', const Color(0xFFE0A800)),
      ParticipantPaymentStatus.requested =>
        ('Pending', colorScheme.tertiary),
      ParticipantPaymentStatus.rejected =>
        ('Rejected', colorScheme.error),
      ParticipantPaymentStatus.unpaid =>
        ('Unpaid', colorScheme.onSurfaceVariant),
    };

    final fillAlpha = tappable ? 0.18 : 0.12;
    final borderAlpha = tappable ? 0.55 : 0.3;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: fillAlpha),
        borderRadius: AppRadius.radiusFull,
        border: Border.all(
          color: color.withValues(alpha: borderAlpha),
          width: tappable ? 0.8 : 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (tappable) ...[
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 9,
              height: 1.2,
            ),
            textAlign: TextAlign.end,
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Payment action bottom sheet (Paid / Partially)
// ═════════════════════════════════════════════════════════════════════════════

/// Bottom sheet shown when a participant taps their status badge. Offers
/// two options: pay in full, or pay a partial amount.
///
/// The sheet is laid out with a gradient header card summarizing the share,
/// followed by two tappable option rows with leading icons, titles, and
/// descriptive subtitles. A footer note explains that the bill creator
/// will verify the request.
class _PaymentActionSheet extends StatelessWidget {
  const _PaymentActionSheet({
    required this.participantName,
    required this.share,
    required this.onPaid,
    required this.onPartially,
  });

  final String participantName;
  final double share;
  final VoidCallback onPaid;
  final VoidCallback onPartially;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return SafeArea(
      minimum: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.md,
            AppSpacing.xl,
            AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            // Drag handle.
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                decoration: BoxDecoration(
                  color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: AppRadius.radiusFull,
                ),
              ),
            ),

            // Header: icon + title.
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.12),
                    borderRadius: AppRadius.radiusMd,
                  ),
                  child: Icon(
                    Icons.payments_outlined,
                    size: 20,
                    color: cs.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mark Your Payment',
                        style: AppTextStyles.titleMedium.copyWith(
                          color: cs.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Tell the bill creator what you paid',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Share summary card.
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? AppColors.darkPrimaryGradient.colors
                      : AppColors.lightPrimaryGradient.colors,
                ),
                borderRadius: AppRadius.radiusLg,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Share',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: cs.onPrimary.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        AppConstants.formatCurrency(share, withSymbol: true),
                        style: AppTextStyles.amountMedium.copyWith(
                          color: cs.onPrimary,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    Icons.account_balance_wallet_rounded,
                    color: cs.onPrimary.withValues(alpha: 0.85),
                    size: 28,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Option: Paid in full.
            _PaymentOptionTile(
              icon: Icons.check_circle_rounded,
              iconColor: cs.primary,
              tint: cs.primary,
              title: 'Paid in full',
              subtitle:
                  'I have paid ${AppConstants.formatCurrency(share, withSymbol: true)}',
              onTap: onPaid,
              isDark: isDark,
            ),
            const SizedBox(height: AppSpacing.sm),

            // Option: Partially paid.
            _PaymentOptionTile(
              icon: Icons.pie_chart_rounded,
              iconColor: const Color(0xFFE0A800),
              tint: const Color(0xFFE0A800),
              title: 'Partially paid',
              subtitle: 'I have paid part of my share',
              onTap: onPartially,
              isDark: isDark,
            ),
            const SizedBox(height: AppSpacing.lg),

            // Footer note.
            Row(
              children: [
                Icon(
                  Icons.verified_user_outlined,
                  size: 13,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'The bill creator will verify your payment before it is '
                    'confirmed.',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: cs.onSurfaceVariant.withValues(alpha: 0.8),
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }
}

/// A single tappable option row inside [_PaymentActionSheet].
class _PaymentOptionTile extends StatefulWidget {
  const _PaymentOptionTile({
    required this.icon,
    required this.iconColor,
    required this.tint,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.isDark,
  });

  final IconData icon;
  final Color iconColor;
  final Color tint;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDark;

  @override
  State<_PaymentOptionTile> createState() => _PaymentOptionTileState();
}

class _PaymentOptionTileState extends State<_PaymentOptionTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.97,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ScaleTransition(
      scale: _press,
      child: GestureDetector(
        onTapDown: (_) => _press.reverse(),
        onTapUp: (_) {
          _press.forward();
          widget.onTap();
        },
        onTapCancel: () => _press.forward(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: widget.tint.withValues(alpha: widget.isDark ? 0.08 : 0.06),
            borderRadius: AppRadius.radiusLg,
            border: Border.all(
              color: widget.tint.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: cs.surface.withValues(alpha: 0.85),
                  borderRadius: AppRadius.radiusMd,
                  border: Border.all(
                    color: widget.tint.withValues(alpha: 0.25),
                    width: 0.8,
                  ),
                ),
                child: Icon(widget.icon, size: 20, color: widget.iconColor),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: AppTextStyles.titleSmall.copyWith(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: cs.onSurfaceVariant,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: cs.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Partial amount dialog (with validators)
// ═════════════════════════════════════════════════════════════════════════════

/// Dialog where the user enters the partial amount they have paid.
///
/// Validators enforce:
/// - The amount must be greater than zero.
/// - The amount must not exceed the assigned share.
/// - The amount must not equal the assigned share (since the user chose the
///   "partially paid" option, they cannot enter the full amount).
class _PartialPaymentDialog extends StatefulWidget {
  const _PartialPaymentDialog({
    required this.participantName,
    required this.share,
    required this.onSubmit,
  });

  final String participantName;
  final double share;
  final ValueChanged<double> onSubmit;

  @override
  State<_PartialPaymentDialog> createState() => _PartialPaymentDialogState();
}

class _PartialPaymentDialogState extends State<_PartialPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String? _validate(String? value) {
    final raw = (value ?? '').trim();
    if (raw.isEmpty) return 'Please enter an amount.';
    final amount = double.tryParse(raw);
    if (amount == null) return 'Please enter a valid number.';
    if (amount <= 0) return 'Amount must be greater than zero.';
    final share = widget.share;
    if (amount > share + 0.005) {
      return 'Amount cannot exceed your share of '
          '${AppConstants.formatCurrency(share, withSymbol: true)}.';
    }
    // The user explicitly chose "partially paid", so the amount must not
    // equal the full share.
    if ((share - amount).abs() <= 0.005) {
      return 'You selected "Partially paid". The amount cannot equal your '
          'full share. Use "Paid in full" instead.';
    }
    return null;
  }

  void _submit() {
    final error = _validate(_controller.text);
    if (error != null) {
      setState(() => _errorText = error);
      return;
    }
    final amount = double.parse(_controller.text.trim());
    widget.onSubmit(amount);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusXl),
      title: const Text('Partial Payment'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.participantName} owes '
              '${AppConstants.formatCurrency(widget.share, withSymbol: true)}',
              style: AppTextStyles.bodySmall.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Enter the amount you have paid:',
              style: AppTextStyles.labelMedium.copyWith(
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                  RegExp(r'^\d*\.?\d{0,2}$'),
                ),
              ],
              decoration: InputDecoration(
                prefixText: '${AppConstants.currencySymbol} ',
                errorText: _errorText,
                border: const OutlineInputBorder(),
                hintText: '0.00',
              ),
              autofocus: true,
              onChanged: (_) {
                if (_errorText != null) {
                  setState(() => _errorText = null);
                }
              },
              onFieldSubmitted: (_) => _submit(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Submit'),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Verification section (bill creator only)
// ═════════════════════════════════════════════════════════════════════════════

/// Section shown only to the bill creator. Lists every participant whose
/// payment request is pending verification, with Approve / Reject actions.
///
/// Approving opens a confirmation dialog where the creator enters the
/// amount they actually received (defaulting to the requested amount).
/// The participant's status becomes `paid` if the received amount equals
/// their share, otherwise `partially_paid`.
class _VerificationSection extends StatelessWidget {
  const _VerificationSection({
    required this.bill,
    required this.currentUserId,
    required this.colorScheme,
    required this.isDark,
    required this.onVerify,
  });

  final Bill bill;
  final String currentUserId;
  final ColorScheme colorScheme;
  final bool isDark;
  final void Function({
    required String participantId,
    required bool approved,
    required double receivedAmount,
  }) onVerify;

  @override
  Widget build(BuildContext context) {
    final pending = bill.pendingVerificationParticipants;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer.withValues(alpha: isDark ? 0.18 : 0.25),
        borderRadius: AppRadius.radiusXxl,
        border: Border.all(
          color: colorScheme.tertiary.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.verified_user_rounded,
                  size: 18,
                  color: colorScheme.tertiary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Payment Verifications',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.tertiary.withValues(alpha: 0.15),
                    borderRadius: AppRadius.radiusFull,
                  ),
                  child: Text(
                    '${pending.length}',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: colorScheme.tertiary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
          for (int i = 0; i < pending.length; i++) ...[
            _VerificationRow(
              bill: bill,
              participant: pending[i],
              colorScheme: colorScheme,
              onApprove: () => _confirmApprove(context, pending[i].id),
              onReject: () => onVerify(
                participantId: pending[i].id,
                approved: false,
                receivedAmount: 0.0,
              ),
            ),
            if (i < pending.length - 1)
              Divider(
                height: 1,
                indent: AppSpacing.xl + 36,
                color: colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
          ],
        ],
      ),
    );
  }

  /// Opens a dialog where the creator confirms the amount they received
  /// before approving the participant's request.
  void _confirmApprove(BuildContext context, String participantId) {
    final participant = bill.participants
        .cast<BillParticipant?>()
        .firstWhere((p) => p?.id == participantId, orElse: () => null);
    if (participant == null) return;
    final share = bill.splitMode == BillSplitMode.equal
        ? bill.perPersonShare
        : participant.customShare;
    final requested = bill.paymentFor(participantId).requestedAmount;

    showDialog<void>(
      context: context,
      builder: (context) => _ConfirmReceiptDialog(
        participantName: participant.bestDisplayName,
        share: share,
        requestedAmount: requested,
        onConfirm: (received) => onVerify(
          participantId: participantId,
          approved: true,
          receivedAmount: received,
        ),
      ),
    );
  }
}

/// A single pending-verification row with Approve / Reject buttons.
class _VerificationRow extends StatelessWidget {
  const _VerificationRow({
    required this.bill,
    required this.participant,
    required this.colorScheme,
    required this.onApprove,
    required this.onReject,
  });

  final Bill bill;
  final BillParticipant participant;
  final ColorScheme colorScheme;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final payment = bill.paymentFor(participant.id);
    final share = bill.splitMode == BillSplitMode.equal
        ? bill.perPersonShare
        : participant.customShare;
    final isPartialRequest =
        payment.requestType == PaymentRequestType.partially;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _ParticipantAvatar(
                participant: participant,
                colorScheme: colorScheme,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
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
                    Text(
                      isPartialRequest
                          ? 'Requests partial payment of '
                              '${AppConstants.formatCurrency(payment.requestedAmount, withSymbol: true)} '
                              '(share: ${AppConstants.formatCurrency(share, withSymbol: true)})'
                          : 'Requests full payment of '
                              '${AppConstants.formatCurrency(share, withSymbol: true)}',
                      style: AppTextStyles.caption.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: onReject,
                style: TextButton.styleFrom(
                  foregroundColor: colorScheme.error,
                ),
                child: const Text('Reject'),
              ),
              const SizedBox(width: AppSpacing.sm),
              FilledButton.icon(
                onPressed: onApprove,
                icon: const Icon(Icons.check_rounded, size: 16),
                label: const Text('Approve'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  minimumSize: const Size(0, 36),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Confirm receipt dialog (creator enters the amount they received)
// ═════════════════════════════════════════════════════════════════════════════

/// Dialog where the bill creator confirms the amount they actually received
/// from a participant before approving the request.
///
/// Defaults to the participant's requested amount. The creator can adjust
/// it (e.g. if the participant claimed more than they sent). The
/// participant's final status is computed from the received amount:
/// `paid` if it equals their share, otherwise `partially_paid`.
class _ConfirmReceiptDialog extends StatefulWidget {
  const _ConfirmReceiptDialog({
    required this.participantName,
    required this.share,
    required this.requestedAmount,
    required this.onConfirm,
  });

  final String participantName;
  final double share;
  final double requestedAmount;
  final ValueChanged<double> onConfirm;

  @override
  State<_ConfirmReceiptDialog> createState() => _ConfirmReceiptDialogState();
}

class _ConfirmReceiptDialogState extends State<_ConfirmReceiptDialog> {
  late final TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.requestedAmount.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String? _validate(String? value) {
    final raw = (value ?? '').trim();
    if (raw.isEmpty) return 'Please enter an amount.';
    final amount = double.tryParse(raw);
    if (amount == null) return 'Please enter a valid number.';
    if (amount < 0) return 'Amount cannot be negative.';
    if (amount > widget.share + 0.005) {
      return 'Amount cannot exceed their share of '
          '${AppConstants.formatCurrency(widget.share, withSymbol: true)}.';
    }
    return null;
  }

  void _confirm() {
    final error = _validate(_controller.text);
    if (error != null) {
      setState(() => _errorText = error);
      return;
    }
    final amount = double.parse(_controller.text.trim());
    widget.onConfirm(amount);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusXl),
      title: const Text('Confirm Receipt'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${widget.participantName} requested '
            '${AppConstants.formatCurrency(widget.requestedAmount, withSymbol: true)} '
            '(share: ${AppConstants.formatCurrency(widget.share, withSymbol: true)})',
            style: AppTextStyles.bodySmall.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Enter the amount you received:',
            style: AppTextStyles.labelMedium.copyWith(
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _controller,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                RegExp(r'^\d*\.?\d{0,2}$'),
              ),
            ],
            decoration: InputDecoration(
              prefixText: '${AppConstants.currencySymbol} ',
              errorText: _errorText,
              border: const OutlineInputBorder(),
            ),
            onChanged: (_) {
              if (_errorText != null) {
                setState(() => _errorText = null);
              }
            },
            onSubmitted: (_) => _confirm(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _confirm,
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}
