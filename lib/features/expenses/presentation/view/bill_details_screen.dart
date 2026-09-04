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
