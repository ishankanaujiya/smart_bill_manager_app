import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../app/theme/design_system.dart';
import '../../../../core/presentation/app_shell.dart';
import '../../../../core/validators/auth_validator.dart';
import '../../../../core/widgets/app_field_error.dart';
import '../../../users/domain/entities/app_user.dart';
import '../state/auth_providers.dart';
import '../widget/auth_header.dart';
import 'registration_details_screen.dart';
import 'registration_profile_screen.dart';

/// Sign-in screen for returning users.
///
/// Layout and UX are modelled on the product design spec:
///  - Back button
///  - Header with network-pattern background, app logo, brand and "Welcome back"
///  - Mobile number field with country-code picker and 10-digit limit
///  - Password field with show/hide toggle
///  - Animated field shake + slide/fade error messages
///  - "Forgot password?" link
///  - "Remember me" checkbox
///  - Primary "Sign in" button
///  - "or continue with" divider + Google / Apple social buttons
///  - "Don't have an account? Register" footer
///  - Terms of Service / Privacy Policy legal footer
///
/// Fields are validated on submit. Invalid fields shake horizontally and the
/// error messages slide down with a fade. The screen entrance is also staggered.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen>
    with TickerProviderStateMixin {
  // ── Form state ──
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _emailFieldKey = GlobalKey<_AuthTextFieldState>();
  final _passwordFieldKey = GlobalKey<_AuthTextFieldState>();

  bool _obscurePassword = true;
  bool _rememberMe = false;

  // ── Validation error state ──
  String? _emailError;
  String? _passwordError;

  // ── Entrance animation ──
  late final AnimationController _entranceController;
  late final Animation<double> _formFade;
  late final Animation<Offset> _formSlide;
  late final Animation<double> _footerFade;

  @override
  void initState() {
    super.initState();
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

    _footerFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.55, 1.0, curve: Curves.easeOut),
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
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  bool _validate() {
    final emailErr = AuthValidator.email(_emailController.text);
    final passErr = AuthValidator.password(_passwordController.text);

    setState(() {
      _emailError = emailErr;
      _passwordError = passErr;
    });

    if (emailErr != null) {
      _emailFieldKey.currentState?.shake();
    }
    if (passErr != null) {
      _passwordFieldKey.currentState?.shake();
    }

    return emailErr == null && passErr == null;
  }

  /// Validates the email field live as the user types.
  ///
  /// Only shows an error once the user has typed enough to look like an
  /// email attempt (contains '@'). Before that, no error is shown — the
  /// full validation runs on submit.
  void _onEmailChanged() {
    final input = _emailController.text.trim();
    if (input.isEmpty) {
      if (_emailError != null) setState(() => _emailError = null);
      return;
    }

    // Only validate once the user has typed an '@' — before that they're
    // still entering the local part and we don't want to be intrusive.
    if (!input.contains('@')) {
      if (_emailError != null) setState(() => _emailError = null);
      return;
    }

    final err = AuthValidator.email(input);
    if (err != _emailError) setState(() => _emailError = err);
  }

  void _clearPasswordError() {
    if (_passwordError != null) setState(() => _passwordError = null);
  }

  void _openRegistration(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const RegistrationDetailsScreen(),
      ),
    );
  }

  Future<void> _onSignIn() async {
    if (!_validate()) return;

    final authAction = ref.read(authActionProvider.notifier);
    final success = await authAction.signInWithEmailAndPassword(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      _navigateToHome();
    } else {
      _showAuthError();
    }
  }

  Future<void> _onGoogleSignIn() async {
    final authAction = ref.read(authActionProvider.notifier);
    final result = await authAction.signInWithGoogle();

    if (!mounted) return;

    if (!result.success) {
      _showAuthError();
      return;
    }

    // If the profile is incomplete, redirect to the profile completion flow.
    if (result.partialUser != null) {
      _navigateToProfileCompletion(result.partialUser!);
    } else {
      _navigateToHome();
    }
  }

  void _navigateToHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const AppShell()),
      (route) => false,
    );
  }

  void _navigateToProfileCompletion(AppUser partialUser) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => RegistrationProfileScreen(
          fullName: partialUser.fullName,
          email: partialUser.email,
          phoneNumber: partialUser.phoneNumber ?? '',
          partialUser: partialUser,
        ),
      ),
      (route) => false,
    );
  }

  void _showAuthError() {
    final state = ref.read(authActionProvider);
    final errorMsg = state is AuthActionError
        ? state.message
        : 'Sign-in failed. Please try again.';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorMsg),
        backgroundColor: Theme.of(context).colorScheme.error,
        duration: const Duration(seconds: 3),
      ),
    );
    ref.read(authActionProvider.notifier).reset();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: AppSpacing.screenPadding,
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const SizedBox(height: AppSpacing.sm),

                      // ── Header ──
                      AuthHeader(
                        animation: _entranceController,
                        title: 'Welcome back',
                        subtitle: 'Sign in to see who owes what.',
                      ),

                      const SizedBox(height: AppSpacing.xl),

                      // ── Form ──
                      SlideTransition(
                        position: _formSlide,
                        child: FadeTransition(
                          opacity: _formFade,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Email address
                              Text(
                                'Email address',
                                style: AppTextStyles.labelLarge.copyWith(
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              _EmailField(
                                fieldKey: _emailFieldKey,
                                controller: _emailController,
                                focusNode: _emailFocus,
                                nextFocus: _passwordFocus,
                                errorText: _emailError,
                                onChanged: _onEmailChanged,
                              ),

                              const SizedBox(height: AppSpacing.lg),

                              // Password
                              Text(
                                'Password',
                                style: AppTextStyles.labelLarge.copyWith(
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              _PasswordField(
                                fieldKey: _passwordFieldKey,
                                controller: _passwordController,
                                focusNode: _passwordFocus,
                                obscure: _obscurePassword,
                                onToggleObscure: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                                errorText: _passwordError,
                                onChanged: _clearPasswordError,
                              ),

                              const SizedBox(height: AppSpacing.sm),

                              // Forgot password
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {},
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    'Forgot password?',
                                    style: AppTextStyles.labelLarge.copyWith(
                                      color: colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: AppSpacing.md),

                              // Remember me
                              GestureDetector(
                                onTap: () => setState(
                                  () => _rememberMe = !_rememberMe,
                                ),
                                behavior: HitTestBehavior.opaque,
                                child: Row(
                                  children: [
                                    _BrandCheckbox(
                                      value: _rememberMe,
                                      onChanged: (v) => setState(
                                        () => _rememberMe = v ?? false,
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Text(
                                      'Remember me',
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: colorScheme.onSurface,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: AppSpacing.xl),

                              // Sign in CTA
                              _SignInButton(
                                onPressed: _onSignIn,
                                isLoading: ref.watch(authActionProvider)
                                    is AuthActionLoading,
                              ),

                              const SizedBox(height: AppSpacing.xl),

                              // Divider — or continue with
                              _OrDivider(),

                              const SizedBox(height: AppSpacing.lg),

                              // Social buttons
                              Row(
                                children: [
                                  Expanded(
                                    child: _SocialButton(
                                      label: 'Google',
                                      icon: SvgPicture.asset(
                                        'assets/icons/google.svg',
                                        width: 20,
                                        height: 20,
                                      ),
                                      onTap: _onGoogleSignIn,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: _SocialButton(
                                      label: 'Apple',
                                      icon: SvgPicture.asset(
                                        'assets/icons/apple.svg',
                                        width: 20,
                                        height: 20,
                                        colorFilter: ColorFilter.mode(
                                          colorScheme.onSurface,
                                          BlendMode.srcIn,
                                        ),
                                      ),
                                      onTap: () {
                                        // TODO(auth): Apple sign-in
                                      },
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: AppSpacing.xl),

                              // Register link
                              Center(
                                child: Text.rich(
                                  TextSpan(
                                    text: "Don't have an account? ",
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: 'Register',
                                        style:
                                            AppTextStyles.bodyMedium.copyWith(
                                          color: colorScheme.primary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                        recognizer: TapGestureRecognizer()
                                          ..onTap =
                                              () => _openRegistration(context),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.xl),

                      // ── Legal footer ──
                      FadeTransition(
                        opacity: _footerFade,
                        child: const _LegalFooter(),
                      ),

                      const SizedBox(height: AppSpacing.xl),
                    ]),
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

// ─────────────────────────────────────────────────────────────────────────────
// Sub-components
// ─────────────────────────────────────────────────────────────────────────────

/// Email address field with leading icon and animated error.
class _EmailField extends StatelessWidget {
  const _EmailField({
    this.fieldKey,
    required this.controller,
    required this.focusNode,
    required this.nextFocus,
    this.errorText,
    this.onChanged,
  });

  final GlobalKey<_AuthTextFieldState>? fieldKey;
  final TextEditingController controller;
  final FocusNode focusNode;
  final FocusNode nextFocus;
  final String? errorText;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _AuthTextField(
          key: fieldKey,
          controller: controller,
          focusNode: focusNode,
          hint: 'you@example.com',
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          onChanged: onChanged,
          onSubmitted: (_) => FocusScope.of(context).requestFocus(nextFocus),
          errorText: errorText,
        ),
        AppFieldError(errorText: errorText, isDark: isDark),
      ],
    );
  }
}

/// Password field with show/hide toggle.
class _PasswordField extends StatelessWidget {
  const _PasswordField({
    this.fieldKey,
    required this.controller,
    required this.focusNode,
    required this.obscure,
    required this.onToggleObscure,
    this.errorText,
    this.onChanged,
  });

  final GlobalKey<_AuthTextFieldState>? fieldKey;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool obscure;
  final VoidCallback onToggleObscure;
  final String? errorText;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _AuthTextField(
          key: fieldKey,
          controller: controller,
          focusNode: focusNode,
          obscureText: obscure,
          hint: 'Enter your password',
          keyboardType: TextInputType.visiblePassword,
          textInputAction: TextInputAction.done,
          onChanged: onChanged,
          onSubmitted: (_) => FocusScope.of(context).unfocus(),
          suffix: IconButton(
            icon: Icon(
              obscure
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 20,
              color: colorScheme.onSurfaceVariant,
            ),
            onPressed: onToggleObscure,
            splashRadius: 20,
          ),
          errorText: errorText,
        ),
        AppFieldError(errorText: errorText, isDark: isDark),
      ],
    );
  }
}

/// Reusable input field shell used by [_EmailField] and [_PasswordField].
///
/// Provides the focus-driven animated border, the filled background, and
/// a horizontal shake that is triggered via [shake] when validation fails.
/// All colours are pulled from the active theme.
class _AuthTextField extends StatefulWidget {
  const _AuthTextField({
    super.key,
    required this.controller,
    required this.focusNode,
    this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.suffix,
    this.errorText,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String? hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final VoidCallback? onChanged;
  final ValueChanged<String>? onSubmitted;
  final Widget? suffix;
  final String? errorText;

  @override
  State<_AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<_AuthTextField>
    with TickerProviderStateMixin {
  late final AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  /// Triggers the horizontal shake animation.
  void shake() {
    _shakeController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasError = widget.errorText != null;

    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        final t = _shakeController.value;
        // Damped sine wave shake — same as the original AuthTextField.
        final offset =
            8 * (1 - t) * (t * 4 - t * t * 4 - t * t * t).clamp(-1.0, 1.0);

        return Transform.translate(
          offset: Offset(offset, 0),
          child: child,
        );
      },
      child: Focus(
        child: Builder(
          builder: (ctx) {
            final focused = Focus.of(ctx).hasFocus;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              height: 56,
              decoration: BoxDecoration(
                color: isDark
                    ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
                    : colorScheme.surfaceContainerHighest,
                border: Border.all(
                  color: hasError
                      ? colorScheme.error
                      : (focused
                          ? colorScheme.primary
                          : colorScheme.outlineVariant),
                  width: (focused || hasError) ? 2 : 1,
                ),
                borderRadius: AppRadius.radiusMd,
              ),
              child: TextField(
                controller: widget.controller,
                focusNode: widget.focusNode,
                obscureText: widget.obscureText,
                keyboardType: widget.keyboardType,
                textInputAction: widget.textInputAction,
                onChanged: (_) => widget.onChanged?.call(),
                onSubmitted: widget.onSubmitted,
                decoration: InputDecoration(
                  hintText: widget.hint,
                  hintStyle: AppTextStyles.bodyMedium.copyWith(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  counterText: '',
                  filled: false,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.lg,
                  ),
                  suffixIcon: widget.suffix,
                  suffixIconConstraints: const BoxConstraints(
                    minWidth: 0,
                    minHeight: 0,
                  ),
                ),
                style: AppTextStyles.bodyMedium.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Themed checkbox that renders in the primary colour.
class _BrandCheckbox extends StatelessWidget {
  const _BrandCheckbox({
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 22,
      height: 22,
      child: Checkbox(
        value: value,
        onChanged: onChanged,
        activeColor: colorScheme.primary,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusXs),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

/// Full-width "Sign in" primary button.
/// Full-width "Sign in" primary button with a blinking blur glow.
///
/// A soft coloured shadow behind the button pulses in and out using a
/// sine-bell curve, creating a "blinking blur" effect that draws attention
/// to the CTA without altering the button's own background colour.
class _SignInButton extends StatefulWidget {
  const _SignInButton({required this.onPressed, this.isLoading = false});

  final VoidCallback onPressed;
  final bool isLoading;

  @override
  State<_SignInButton> createState() => _SignInButtonState();
}

class _SignInButtonState extends State<_SignInButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _blurController;
  late final Animation<double> _blur;

  @override
  void initState() {
    super.initState();
    _blurController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    _blur = CurvedAnimation(
      parent: _blurController,
      curve: Curves.easeInOutSine,
    );
  }

  @override
  void dispose() {
    _blurController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: AnimatedBuilder(
        animation: _blur,
        builder: (context, child) {
          // Smooth sine-bell: 0 → 1 → 0 with no cusps.
          // (1 - cos(2πt)) / 2 gives a perfect 0 → 1 → 0 wave.
          final pulse = (1 - math.cos(math.pi * 2 * _blur.value)) * 0.5;

          return DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: AppRadius.radiusMd,
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(
                    alpha: 0.15 + 0.40 * pulse,
                  ),
                  blurRadius: 6 + 20 * pulse,
                  spreadRadius: 1 + 2 * pulse,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: child,
          );
        },
        child: FilledButton(
          onPressed: widget.isLoading ? null : widget.onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: AppRadius.radiusMd,
            ),
            textStyle: AppTextStyles.labelLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          child: widget.isLoading
              ? SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: colorScheme.onPrimary,
                  ),
                )
              : const Text('Sign in'),
        ),
      ),
    );
  }
}

/// "or continue with" row divider.
class _OrDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
            child: Divider(color: colorScheme.outlineVariant, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            'or continue with',
            style: AppTextStyles.bodySmall.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
            child: Divider(color: colorScheme.outlineVariant, thickness: 1)),
      ],
    );
  }
}

/// Outlined social sign-in button.
class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final Widget icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        backgroundColor: isDark
            ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
            : colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        side: BorderSide(color: colorScheme.outlineVariant),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.radiusMd,
        ),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        minimumSize: const Size(0, AppSpacing.minTouchTarget),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(width: 20, height: 20, child: icon),
          const SizedBox(width: AppSpacing.sm),
          Text(
            label,
            style: AppTextStyles.labelLarge.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

/// Legal footer with tappable "Terms of Service" and "Privacy Policy" links.
class _LegalFooter extends StatelessWidget {
  const _LegalFooter();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: 'By continuing, you agree to our ',
            style: AppTextStyles.caption.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          TextSpan(
            text: 'Terms of Service',
            style: AppTextStyles.caption.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                // TODO(legal): Open terms of service
              },
          ),
          TextSpan(
            text: ' and ',
            style: AppTextStyles.caption.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          TextSpan(
            text: 'Privacy Policy',
            style: AppTextStyles.caption.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                // TODO(legal): Open privacy policy
              },
          ),
          TextSpan(
            text: '.',
            style: AppTextStyles.caption.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
