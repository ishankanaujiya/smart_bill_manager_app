import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/theme/design_system.dart';
import '../../../../core/widgets/animated_entrance.dart';

/// Help & Support screen.
///
/// Provides quick contact actions, an expandable FAQ section, and
/// app/legal links — all with staggered entrance animations.
class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;

  // Track which FAQ item is expanded (-1 = none).
  int _expandedFaq = -1;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
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

  /// Opens the device's default mail app with a pre-filled email
  /// addressed to the support inbox.
  ///
  /// We intentionally skip `canLaunchUrl` — on Android 11+ it requires a
  /// `<queries>` declaration *and* is prone to throwing a
  /// `PlatformException(channel-error, …)` when the pigeon platform channel
  /// isn't ready (common after a hot restart). Calling `launchUrl` directly
  /// and reacting to its result is far more reliable.
  Future<void> _launchEmail() async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'taboracustomersuppoart@gmail.com',
      query: 'subject=Support Request — Smart Bill Manager',
    );

    final messenger = ScaffoldMessenger.maybeOf(context);

    try {
      final launched = await launchUrl(uri);
      if (!launched && mounted) {
        messenger?.showSnackBar(
          SnackBar(
            content: const Text('No email app found. Please install one.'),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Copy',
              onPressed: () async {
                // Fallback: copy the address so the user can paste it
                // into any mail client manually.
                await Clipboard.setData(
                  const ClipboardData(
                    text: 'taboracustomersuppoart@gmail.com',
                  ),
                );
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Email address copied to clipboard'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          ),
        );
      }
    } catch (_) {
      // Platform channel errors, missing mail client, etc.
      if (mounted) {
        messenger?.showSnackBar(
          const SnackBar(
            content: Text('Could not open email. Please try again.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
      ),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            // ── Intro ───────────────────────────────────────────────────────
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
                    'We\'re here to help. Reach out or browse the answers '
                    'below.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ),

            // ── Quick contact card ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: StaggeredEntrance(
                animation: _entranceController,
                interval: const Interval(0.05, 0.5, curve: Curves.easeOut),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenHorizontal,
                  ),
                  child: _ContactCard(
                    icon: Icons.mail_outline_rounded,
                    label: 'Email Us',
                    email: 'taboracustomersuppoart@gmail.com',
                    gradientStart: const Color(0xFF60A5FA),
                    gradientEnd: const Color(0xFF2563EB),
                    onTap: _launchEmail,
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),

            // ── FAQ section ─────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: StaggeredEntrance(
                animation: _entranceController,
                interval: const Interval(0.15, 0.6, curve: Curves.easeOut),
                child: _SectionLabel(label: 'Frequently Asked Questions'),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final faq = _faqs[index];
                  final isExpanded = _expandedFaq == index;
                  return StaggeredEntrance(
                    animation: _entranceController,
                    interval: Interval(
                      0.18 + (index * 0.06),
                      0.6 + (index * 0.06),
                      curve: Curves.easeOut,
                    ),
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: AppSpacing.screenHorizontal,
                        right: AppSpacing.screenHorizontal,
                        bottom: AppSpacing.sm,
                      ),
                      child: _FaqTile(
                        question: faq.question,
                        answer: faq.answer,
                        isExpanded: isExpanded,
                        isDark: isDark,
                        colorScheme: colorScheme,
                        onTap: () {
                          setState(() {
                            _expandedFaq = isExpanded ? -1 : index;
                          });
                        },
                      ),
                    ),
                  );
                },
                childCount: _faqs.length,
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),

            // ── App info card ───────────────────────────────────────────────
            SliverToBoxAdapter(
              child: StaggeredEntrance(
                animation: _entranceController,
                interval: const Interval(0.35, 0.75, curve: Curves.easeOut),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenHorizontal,
                  ),
                  child: _AppInfoCard(
                    isDark: isDark,
                    colorScheme: colorScheme,
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 60)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FAQ data
// ─────────────────────────────────────────────────────────────────────────────

class _FaqData {
  const _FaqData({required this.question, required this.answer});
  final String question;
  final String answer;
}

final List<_FaqData> _faqs = [
  _FaqData(
    question: 'How do I create a group?',
    answer:
        'Tap the "+" button on the dashboard, select "Create Group", fill '
        'in the group name and add members by searching their email or '
        'phone number. Once created, all members will receive a '
        'notification.',
  ),
  _FaqData(
    question: 'How are bills split?',
    answer:
        'When you create a bill inside a group, you can choose which '
        'participants are included. The total amount is divided equally '
        'among all included participants. You can also exclude specific '
        'people if needed.',
  ),
  _FaqData(
    question: 'How do I mark a payment as paid?',
    answer:
        'Open the bill, tap "Mark as Paid", and optionally attach a '
        'payment screenshot. The bill creator will be notified and can '
        'approve or reject your payment request.',
  ),
  _FaqData(
    question: 'Can I use the app on multiple devices?',
    answer:
        'Yes. Sign in with the same account on any device. Your groups, '
        'bills, and payment history sync automatically. Push '
        'notifications are delivered to every device where you\'re '
        'signed in.',
  ),
  _FaqData(
    question: 'Is my data secure?',
    answer:
        'All data is stored securely using Firebase with end-to-end '
        'encryption. Your payment information is never shared with other '
        'group members without your consent.',
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// Contact card
// ─────────────────────────────────────────────────────────────────────────────

class _ContactCard extends StatelessWidget {
  const _ContactCard({
    required this.icon,
    required this.label,
    required this.gradientStart,
    required this.gradientEnd,
    required this.onTap,
    this.email,
  });

  final IconData icon;
  final String label;
  final Color gradientStart;
  final Color gradientEnd;
  final VoidCallback onTap;
  final String? email;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.radiusXl,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [gradientStart, gradientEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: AppRadius.radiusXl,
            boxShadow: [
              BoxShadow(
                color: gradientEnd.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xl,
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.22),
                  borderRadius: AppRadius.radiusMd,
                  border: Border.all(
                    color: AppColors.white.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppTextStyles.titleSmall.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (email != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        email!,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.white.withValues(alpha: 0.85),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 24,
                color: AppColors.white.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section label
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.screenHorizontal,
        right: AppSpacing.screenHorizontal,
        bottom: AppSpacing.sm,
      ),
      child: Text(
        label.toUpperCase(),
        style: AppTextStyles.labelSmall.copyWith(
          color: colorScheme.onSurfaceVariant,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FAQ tile (expandable)
// ─────────────────────────────────────────────────────────────────────────────

class _FaqTile extends StatelessWidget {
  const _FaqTile({
    required this.question,
    required this.answer,
    required this.isExpanded,
    required this.isDark,
    required this.colorScheme,
    required this.onTap,
  });

  final String question;
  final String answer;
  final bool isExpanded;
  final bool isDark;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colorScheme.surface,
      borderRadius: AppRadius.radiusLg,
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: AppRadius.radiusLg,
          border: Border.all(
            color: isExpanded
                ? colorScheme.primary.withValues(alpha: 0.4)
                : colorScheme.outlineVariant.withValues(
                    alpha: isDark ? 0.35 : 0.6,
                  ),
          ),
        ),
        child: Column(
          children: [
            InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        question,
                        style: AppTextStyles.titleSmall.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: isExpanded ? 0.25 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        size: 22,
                        color: isExpanded
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Animated expand/collapse
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 200),
              sizeCurve: Curves.easeInOut,
              crossFadeState: isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: const SizedBox(width: double.infinity, height: 0),
              secondChild: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.md,
                ),
                child: Text(
                  answer,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.5,
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

// ─────────────────────────────────────────────────────────────────────────────
// App info card
// ─────────────────────────────────────────────────────────────────────────────

class _AppInfoCard extends StatelessWidget {
  const _AppInfoCard({required this.isDark, required this.colorScheme});
  final bool isDark;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: AppRadius.radiusLg,
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(
            alpha: isDark ? 0.35 : 0.6,
          ),
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          // App icon
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: isDark
                  ? AppColors.darkPrimaryGradient
                  : AppColors.lightPrimaryGradient,
              borderRadius: AppRadius.radiusLg,
            ),
            child: Icon(
              Icons.receipt_long_rounded,
              size: 28,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Smart Bill Manager',
            style: AppTextStyles.titleSmall.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Version 1.0.0',
            style: AppTextStyles.bodySmall.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          // Divider
          Container(
            height: 1,
            color: colorScheme.outlineVariant.withValues(
              alpha: isDark ? 0.3 : 0.5,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          // Made with love
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.favorite_rounded,
                size: 14,
                color: colorScheme.error.withValues(alpha: 0.7),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Made in Nepal',
                style: AppTextStyles.caption.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
