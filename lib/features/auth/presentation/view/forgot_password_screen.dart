import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/design_system.dart';
import '../../../../core/validators/auth_validator.dart';
import '../../../../core/widgets/app_field_error.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../state/password_reset_provider.dart';
import '../widget/auth_header.dart';
import '../widget/auth_primary_button.dart';
import '../widget/auth_text_field.dart';

/// Forgot-password screen.
///
/// Collects the user's email and asks Firebase to send a password-reset
/// link. The reset itself happens on Firebase's hosted action page — this
/// screen only handles the request and its feedback.
///
/// Two visual states are swapped with an [AnimatedSwitcher]:
///  1. **Request** — email field + "Send reset link" CTA.
///  2. **Success** — animated confirmation with a resend option.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key, this.initialEmail});

  /// Pre-fills the email field (e.g. with whatever the user typed on the
  /// sign-in screen).
  final String? initialEmail;

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen>
    with TickerProviderStateMixin {
  late final TextEditingController _emailController;
  final _emailFocus = FocusNode();
  final _emailFieldKey = GlobalKey<AuthTextFieldState>();

  String? _emailError;

  /// The address the link was last sent to — shown in the success copy.
  String? _sentTo;

  // ── Resend cooldown ──
  Timer? _cooldownTimer;
  int _cooldownSeconds = 0;
  static const int _cooldownDuration = 30;

  // ── Entrance animation ──
  late final AnimationController _entranceController;
  late final Animation<double> _formFade;
  late final Animation<Offset> _formSlide;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail ?? '');

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 560),
    );

    _formFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.15, 0.80, curve: Curves.easeOut),
    );
    _formSlide = Tween<Offset>(
      begin: const Offset(0, 0.14),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.15, 0.80, curve: Curves.easeOut),
      ),
    );

    _startEntrance();
  }

  Future<void> _startEntrance() async {
    await Future.delayed(const Duration(milliseconds: 120));
    if (!mounted) return;
    _entranceController.forward();
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _emailController.dispose();
    _emailFocus.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  // ── Actions ──────────────────────────────────────────────────────────────

  bool _validate() {
    final error = AuthValidator.email(_emailController.text);
    setState(() => _emailError = error);
    if (error != null) _emailFieldKey.currentState?.shake();
    return error == null;
  }

  void _clearError() {
    if (_emailError != null) setState(() => _emailError = null);
  }

  Future<void> _submit() async {
    // Guard against double submissions while a request is in flight.
    if (ref.read(passwordResetProvider) is PasswordResetSending) return;
    if (!_validate()) return;

    final email = _emailController.text.trim();
    final success =
        await ref.read(passwordResetProvider.notifier).send(email);

    if (!mounted) return;

    if (success) {
      setState(() => _sentTo = email);
      _startCooldown();
    }
  }

  Future<void> _resend() async {
    if (_cooldownSeconds > 0) return;
    if (ref.read(passwordResetProvider) is PasswordResetSending) return;

    final email = _sentTo ?? _emailController.text.trim();
    final success =
        await ref.read(passwordResetProvider.notifier).send(email);

    if (!mounted) return;
    if (success) _startCooldown();
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    setState(() => _cooldownSeconds = _cooldownDuration);

    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _cooldownSeconds--;
        if (_cooldownSeconds <= 0) timer.cancel();
      });
    });
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Surface one-shot error feedback as a polished snackbar, then clear
    // the state so it doesn't fire again on rebuild.
    ref.listen<PasswordResetState>(passwordResetProvider, (previous, next) {
      if (next is PasswordResetError) {
        AppSnackBar.show(
          context,
          title: "Couldn't send email",
          message: next.message,
          type: AppSnackBarType.error,
        );
        ref.read(passwordResetProvider.notifier).reset();
      }
    });

    final resetState = ref.watch(passwordResetProvider);
    final isSending = resetState is PasswordResetSending;
    final isSuccess = resetState is PasswordResetSuccess;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              padding: AppSpacing.screenPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.sm),
                  _BackButton(onTap: () => Navigator.of(context).maybePop()),
                  const SizedBox(height: AppSpacing.md),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(
                        scale: Tween<double>(begin: 0.96, end: 1.0)
                            .animate(animation),
                        child: child,
                      ),
                    ),
                    child: isSuccess
                        ? _buildSuccessState(context)
                        : _buildRequestState(context, isSending: isSending),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRequestState(BuildContext context, {required bool isSending}) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      key: const ValueKey('request'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AuthHeader(
          animation: _entranceController,
          title: 'Forgot password',
          subtitle: "Enter the email linked to your account and we'll send "
              'you a reset link.',
        ),
        const SizedBox(height: AppSpacing.xl),
        SlideTransition(
          position: _formSlide,
          child: FadeTransition(
            opacity: _formFade,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Email address',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                AuthTextField(
                  key: _emailFieldKey,
                  controller: _emailController,
                  focusNode: _emailFocus,
                  hint: 'you@example.com',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  onChanged: _clearError,
                  onSubmitted: (_) => _submit(),
                  errorText: _emailError,
                ),
                AppFieldError(errorText: _emailError, isDark: isDark),
                const SizedBox(height: AppSpacing.xl),
                AuthPrimaryButton(
                  label: 'Send reset link',
                  onPressed: _submit,
                  isLoading: isSending,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final email = _sentTo ?? _emailController.text.trim();
    final cooling = _cooldownSeconds > 0;

    return Column(
      key: const ValueKey('success'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.xl),

        // Animated check badge.
        Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutBack,
            builder: (context, value, child) => Transform.scale(
              scale: value.clamp(0.0, 1.2),
              child: child,
            ),
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.primaryContainer,
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.25),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                Icons.mark_email_read_rounded,
                size: 44,
                color: colorScheme.primary,
              ),
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.xxl),

        Text(
          'Check your inbox',
          textAlign: TextAlign.center,
          style: AppTextStyles.headlineSmall.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w800,
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        Text(
          "If an account exists for $email, a reset link is on its way. "
          'The link expires in 1 hour.',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium.copyWith(
            color: colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),

        const SizedBox(height: AppSpacing.xxxl),

        AuthPrimaryButton(
          label: 'Back to sign in',
          onPressed: () => Navigator.of(context).maybePop(),
        ),

        const SizedBox(height: AppSpacing.md),

        // Resend with cooldown.
        Center(
          child: TextButton(
            onPressed: cooling ? null : _resend,
            child: Text(
              cooling ? 'Resend link in ${_cooldownSeconds}s' : 'Resend link',
              style: AppTextStyles.labelLarge.copyWith(
                color: cooling
                    ? colorScheme.onSurfaceVariant
                    : colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Small circular back button matching the app's auth styling.
class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
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
          Icons.arrow_back_ios_new,
          color: colorScheme.onSurface,
          size: 18,
        ),
      ),
    );
  }
}
