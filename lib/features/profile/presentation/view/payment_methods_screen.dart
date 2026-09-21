import 'package:flutter/material.dart';

import '../../../../app/theme/design_system.dart';
import '../../../../core/widgets/animated_entrance.dart';

/// Payment Methods screen — showcases the three supported payment options
/// (eSewa, Khalti, Bank Transfer) with animated entrance and a unique,
/// professional card design.
///
/// Each payment card has:
///  - A branded gradient header with the payment logo/icon
///  - A description of the service
///  - A "Coming soon" / status badge
///
/// The cards animate in with a staggered vertical slide + fade.
class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _startEntrance();
  }

  Future<void> _startEntrance() async {
    await Future.delayed(const Duration(milliseconds: 80));
    if (!mounted) return;
    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Methods'),
      ),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            // ── Intro text ───────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: StaggeredEntrance(
                animation: _entranceController,
                interval: const Interval(0.0, 0.4, curve: Curves.easeOut),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenHorizontal,
                    AppSpacing.lg,
                    AppSpacing.screenHorizontal,
                    AppSpacing.xl,
                  ),
                  child: Text(
                    'Choose how you want to send and receive payments. '
                    'All transactions are secure and instant.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ),

            // ── Payment cards ────────────────────────────────────────────────
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final method = _paymentMethods[index];
                  return StaggeredEntrance(
                    animation: _entranceController,
                    interval: Interval(
                      0.1 + (index * 0.12),
                      0.55 + (index * 0.12),
                      curve: Curves.easeOut,
                    ),
                    slideOffset: 32,
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: AppSpacing.screenHorizontal,
                        right: AppSpacing.screenHorizontal,
                        bottom: AppSpacing.lg,
                      ),
                      child: _PaymentCard(method: method),
                    ),
                  );
                },
                childCount: _paymentMethods.length,
              ),
            ),

            // ── Footer note ──────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: StaggeredEntrance(
                animation: _entranceController,
                interval: const Interval(0.5, 0.9, curve: Curves.easeOut),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenHorizontal,
                    vertical: AppSpacing.lg,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.lock_rounded,
                        size: 14,
                        color: colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.6,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        'Payments are encrypted & secure',
                        style: AppTextStyles.caption.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Payment method data model
// ─────────────────────────────────────────────────────────────────────────────

class _PaymentMethodData {
  const _PaymentMethodData({
    required this.name,
    required this.tagline,
    required this.gradientStart,
    required this.gradientEnd,
    required this.icon,
    required this.status,
  });

  final String name;
  final String tagline;
  final Color gradientStart;
  final Color gradientEnd;
  final IconData icon;
  final _PaymentStatus status;
}

enum _PaymentStatus { available, comingSoon }

final List<_PaymentMethodData> _paymentMethods = [
  _PaymentMethodData(
    name: 'eSewa',
    tagline: 'Nepal\'s #1 Digital Wallet',
    gradientStart: const Color(0xFF60A5FA),
    gradientEnd: const Color(0xFF2563EB),
    icon: Icons.account_balance_wallet_rounded,
    status: _PaymentStatus.available,
  ),
  _PaymentMethodData(
    name: 'Khalti',
    tagline: 'Smart Digital Payments',
    gradientStart: const Color(0xFF8B5CF6),
    gradientEnd: const Color(0xFF6D28D9),
    icon: Icons.bolt_rounded,
    status: _PaymentStatus.available,
  ),
  _PaymentMethodData(
    name: 'Bank',
    tagline: 'Direct to your bank account',
    gradientStart: const Color(0xFF14B8A6),
    gradientEnd: const Color(0xFF0D9488),
    icon: Icons.account_balance_rounded,
    status: _PaymentStatus.available,
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// Payment card
// ─────────────────────────────────────────────────────────────────────────────

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({required this.method});
  final _PaymentMethodData method;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: AppRadius.radiusXxl,
        boxShadow: AppShadows.cardShadow(
          isDark ? Brightness.dark : Brightness.light,
        ),
      ),
      child: ClipRRect(
        borderRadius: AppRadius.radiusXxl,
        child: Column(
          children: [
            // ── Gradient header ─────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.xl,
                AppSpacing.xl,
                AppSpacing.lg,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [method.gradientStart, method.gradientEnd],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  // Icon badge
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.22),
                      borderRadius: AppRadius.radiusLg,
                      border: Border.all(
                        color: AppColors.white.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      method.icon,
                      size: 28,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          method.name,
                          style: AppTextStyles.titleLarge.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.w700,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          method.tagline,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Status badge
                  _StatusBadge(status: method.status),
                ],
              ),
            ),

            // ── Body ────────────────────────────────────────────────────────
            Container(
              color: colorScheme.surface,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.md,
                AppSpacing.xl,
                AppSpacing.lg,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.shield_outlined,
                    size: 16,
                    color: colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.6,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'Secured by 256-bit encryption',
                    style: AppTextStyles.caption.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 20,
                    color: method.status == _PaymentStatus.available
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.4,
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

// ─────────────────────────────────────────────────────────────────────────────
// Status badge
// ─────────────────────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final _PaymentStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      _PaymentStatus.available => ('Available', AppColors.success),
      _PaymentStatus.comingSoon => ('Soon', AppColors.warning),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.22),
        borderRadius: AppRadius.radiusFull,
        border: Border.all(
          color: AppColors.white.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
