import 'package:flutter/material.dart';

import '../../../../app/theme/design_system.dart';
import '../../domain/entities/bill.dart';

/// Full-screen bill details view.
///
/// Mirrors the layout of the review bottom sheet in [CreateBillScreen] but
/// as a standalone screen — showing the gradient summary card, receipt
/// photo (if any), split mode, and the full participant breakdown.
///
/// Shows a brief skeleton loading shimmer on entry before revealing the
/// content, giving a smooth transition when navigating from the group
/// details bill list.
class BillDetailsScreen extends StatefulWidget {
  const BillDetailsScreen({
    super.key,
    required this.bill,
    required this.currentUserId,
  });

  final Bill bill;
  final String currentUserId;

  @override
  State<BillDetailsScreen> createState() => _BillDetailsScreenState();
}

class _BillDetailsScreenState extends State<BillDetailsScreen>
    with TickerProviderStateMixin {
  late final AnimationController _shimmerController;
  bool _isLoading = true;

  static const _loadingDuration = Duration(milliseconds: 400);

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

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
                  child: _buildContent(context, colorScheme, isDark),
                ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    final bill = widget.bill;
    final included = bill.includedParticipants;
    final date = bill.date ?? bill.createdAt;

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
            child: Row(
              children: [
                Material(
                  color: colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.6),
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    customBorder: const CircleBorder(),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      child: Icon(
                        Icons.arrow_back_rounded,
                        color: colorScheme.onSurface,
                        size: 22,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  'Bill Details',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
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
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

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

class _ParticipantRow extends StatelessWidget {
  const _ParticipantRow({
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
          _ParticipantAvatar(
            participant: participant,
            colorScheme: colorScheme,
          ),
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

String? _methodLogo(BillPaymentMethod m) {
  return switch (m) {
    BillPaymentMethod.esewa => 'assets/images/esewa.png',
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

/// Renders the "Payment Method" header and one tappable card per method the
/// bill creator selected. [Bill.paymentMethods] and [Bill.paymentQrUrls] are
/// parallel arrays — we zip them, treating a missing/empty URL as "no QR
/// uploaded" for that method.
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
    final qrUrls = bill.paymentQrUrls;
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
              qrUrl: (i < qrUrls.length) ? qrUrls[i] : null,
              bankName: bill.selectedBankName,
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
    required this.colorScheme,
    required this.isDark,
  });

  final String billId;
  final int index;
  final BillPaymentMethod method;
  final String? qrUrl;
  final String? bankName;
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
    final logo = _methodLogo(widget.method);

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

              // Label + subtitle.
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
