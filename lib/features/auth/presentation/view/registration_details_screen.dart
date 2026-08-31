import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/design_system.dart';
import '../../../../core/validators/auth_validator.dart';
import '../../../../core/widgets/app_field_error.dart';
import '../widget/auth_header.dart';
import '../widget/auth_text_field.dart';
import '../widget/country_code_picker.dart';
import '../widget/registration_step_indicator.dart';
import 'registration_verify_screen.dart';

/// Registration step 1 — collect full name, email, Nepali mobile number and password.
///
/// The user must also agree to the Terms of Service and Privacy Policy before
/// continuing. All fields are validated on submit; invalid fields shake and
/// display an inline error.
class RegistrationDetailsScreen extends StatefulWidget {
  const RegistrationDetailsScreen({super.key});

  @override
  State<RegistrationDetailsScreen> createState() =>
      _RegistrationDetailsScreenState();
}

class _RegistrationDetailsScreenState extends State<RegistrationDetailsScreen>
    with TickerProviderStateMixin {
  // ── Form state ──
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();

  final _nameFieldKey = GlobalKey<AuthTextFieldState>();
  final _emailFieldKey = GlobalKey<AuthTextFieldState>();
  final _phoneFieldKey = GlobalKey<AuthTextFieldState>();
  final _passwordFieldKey = GlobalKey<AuthTextFieldState>();
  final _confirmPasswordFieldKey = GlobalKey<AuthTextFieldState>();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreed = false;

  // ── Validation error state ──
  String? _nameError;
  String? _emailError;
  String? _phoneError;
  String? _passwordError;
  String? _confirmPasswordError;
  String? _agreedError;

  // ── Password strength visibility ──
  bool _showPasswordStrength = false;

  // ── Entrance animation ──
  late final AnimationController _entranceController;
  late final Animation<double> _formFade;
  late final Animation<Offset> _formSlide;

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
    _startEntrance();
  }

  Future<void> _startEntrance() async {
    await Future.delayed(const Duration(milliseconds: 120));
    if (!mounted) return;
    _entranceController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  bool _validate() {
    final nameErr = AuthValidator.fullName(_nameController.text);
    final emailErr = AuthValidator.email(_emailController.text);
    final phoneErr = AuthValidator.phoneNepal(_phoneController.text);
    final passErr = AuthValidator.password(_passwordController.text);
    final confirmErr = AuthValidator.confirmPassword(
      _confirmPasswordController.text,
      _passwordController.text,
    );
    final agreedErr = _agreed ? null : 'You must agree to the terms to continue';

    setState(() {
      _nameError = nameErr;
      _emailError = emailErr;
      _phoneError = phoneErr;
      _passwordError = passErr;
      _confirmPasswordError = confirmErr;
      _agreedError = agreedErr;
    });

    if (nameErr != null) _nameFieldKey.currentState?.shake();
    if (emailErr != null) _emailFieldKey.currentState?.shake();
    if (phoneErr != null) _phoneFieldKey.currentState?.shake();
    if (passErr != null) _passwordFieldKey.currentState?.shake();
    if (confirmErr != null) _confirmPasswordFieldKey.currentState?.shake();

    return nameErr == null &&
        emailErr == null &&
        phoneErr == null &&
        passErr == null &&
        confirmErr == null &&
        agreedErr == null;
  }

  void _onNameChanged() {
    // Clear any existing error while the user is still typing.
    // Full validation is run when the user presses Continue.
    if (_nameError != null) setState(() => _nameError = null);
  }

  void _onEmailChanged() {
    // Clear any existing error while typing; validation runs on Continue.
    if (_emailError != null) setState(() => _emailError = null);
  }

  void _onPhoneChanged() {
    final input = _phoneController.text.trim();
    if (input.isEmpty) {
      if (_phoneError != null) setState(() => _phoneError = null);
      return;
    }

    if (input.length >= 2 && !input.startsWith('98') && !input.startsWith('97')) {
      if (_phoneError != 'Enter valid mobile number') {
        setState(() => _phoneError = 'Enter valid mobile number');
      }
      return;
    }

    if (_phoneError != null) setState(() => _phoneError = null);
  }

  void _onPasswordChanged() {
    final input = _passwordController.text;

    // Show the strength bar as soon as the user starts typing.
    final shouldShowStrength = input.isNotEmpty;
    if (shouldShowStrength != _showPasswordStrength) {
      setState(() => _showPasswordStrength = shouldShowStrength);
    }

    // Clear any existing error while typing; validation runs on Continue.
    if (_passwordError != null) {
      setState(() => _passwordError = null);
      return;
    }

    // Trigger a rebuild so the strength bar updates on every keystroke.
    if (input.isNotEmpty) {
      setState(() {});
    }
  }

  void _onConfirmPasswordChanged() {
    // Clear any existing error while typing; validation runs on Continue.
    if (_confirmPasswordError != null) {
      setState(() => _confirmPasswordError = null);
    }
  }

  void _onContinue() {
    if (!_validate()) return;

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RegistrationVerifyScreen(
          fullName: _nameController.text.trim(),
          email: _emailController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          password: _passwordController.text,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                      const SizedBox(height: AppSpacing.md),

                      // Step indicator
                      const RegistrationStepIndicator(currentStep: 0),

                      const SizedBox(height: AppSpacing.xxl),

                      // Header
                      AuthHeader(
                        animation: _entranceController,
                        title: 'Split bills, not friendships',
                        subtitle: 'Create an account to start tracking group expenses.',
                        isRegistration: true,
                      ),

                      const SizedBox(height: AppSpacing.xxl),

                      // Form
                      SlideTransition(
                        position: _formSlide,
                        child: FadeTransition(
                          opacity: _formFade,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Full name
                              Text(
                                'Full name',
                                style: AppTextStyles.labelLarge.copyWith(
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              AuthTextField(
                                key: _nameFieldKey,
                                controller: _nameController,
                                focusNode: _nameFocus,
                                hint: 'e.g. Sujata Rai',
                                keyboardType: TextInputType.name,
                                textInputAction: TextInputAction.next,
                                prefixIcon: Icon(
                                  Icons.person_outline,
                                  size: 22,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                onChanged: _onNameChanged,
                                onSubmitted: (_) => _emailFocus.requestFocus(),
                                errorText: _nameError,
                              ),
                              AppFieldError(errorText: _nameError, isDark: isDark),

                              const SizedBox(height: AppSpacing.lg),

                              // Email
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
                                hint: 'e.g. sujata@example.com',
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                prefixIcon: Icon(
                                  Icons.mail_outline,
                                  size: 22,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                onChanged: _onEmailChanged,
                                onSubmitted: (_) => _phoneFocus.requestFocus(),
                                errorText: _emailError,
                              ),
                              AppFieldError(errorText: _emailError, isDark: isDark),

                              const SizedBox(height: AppSpacing.lg),

                              // Mobile number
                              Text(
                                'Mobile number',
                                style: AppTextStyles.labelLarge.copyWith(
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              _PhoneField(
                                fieldKey: _phoneFieldKey,
                                controller: _phoneController,
                                focusNode: _phoneFocus,
                                nextFocus: _passwordFocus,
                                errorText: _phoneError,
                                onChanged: _onPhoneChanged,
                              ),

                              const SizedBox(height: AppSpacing.sm),

                              Text(
                                "We'll text a 6-digit code to confirm this number",
                                style: AppTextStyles.caption.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
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
                              AuthTextField(
                                key: _passwordFieldKey,
                                controller: _passwordController,
                                focusNode: _passwordFocus,
                                obscureText: _obscurePassword,
                                hint: 'Create a password',
                                keyboardType: TextInputType.visiblePassword,
                                textInputAction: TextInputAction.done,
                                prefixIcon: Icon(
                                  Icons.lock_outline,
                                  size: 22,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                onChanged: _onPasswordChanged,
                                onSubmitted: (_) => _onContinue(),
                                suffix: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    size: 20,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                                  splashRadius: 20,
                                ),
                                errorText: _passwordError,
                              ),
                              AppFieldError(errorText: _passwordError, isDark: isDark),

                              const SizedBox(height: AppSpacing.xs),

                              // Password strength indicator — only visible
                              // once the user starts typing a password.
                              if (_showPasswordStrength)
                                _PasswordStrengthBar(
                                  password: _passwordController.text,
                                ),

                              const SizedBox(height: AppSpacing.lg),

                              // Confirm password
                              Text(
                                'Confirm password',
                                style: AppTextStyles.labelLarge.copyWith(
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              AuthTextField(
                                key: _confirmPasswordFieldKey,
                                controller: _confirmPasswordController,
                                focusNode: _confirmPasswordFocus,
                                obscureText: _obscureConfirmPassword,
                                hint: 'Re-enter your password',
                                keyboardType: TextInputType.visiblePassword,
                                textInputAction: TextInputAction.done,
                                prefixIcon: Icon(
                                  Icons.lock_outline,
                                  size: 22,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                onChanged: _onConfirmPasswordChanged,
                                onSubmitted: (_) => _onContinue(),
                                suffix: IconButton(
                                  icon: Icon(
                                    _obscureConfirmPassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    size: 20,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  onPressed: () => setState(
                                    () => _obscureConfirmPassword =
                                        !_obscureConfirmPassword,
                                  ),
                                  splashRadius: 20,
                                ),
                                errorText: _confirmPasswordError,
                              ),
                              AppFieldError(
                                errorText: _confirmPasswordError,
                                isDark: isDark,
                              ),

                              const SizedBox(height: AppSpacing.lg),

                              // Terms checkbox
                              _TermsCheckbox(
                                value: _agreed,
                                onChanged: (v) {
                                  setState(() {
                                    _agreed = v ?? false;
                                    if (_agreed) _agreedError = null;
                                  });
                                },
                              ),
                              AppFieldError(errorText: _agreedError, isDark: isDark),

                              const SizedBox(height: AppSpacing.xxl),

                              // Continue button
                              _ContinueButton(onPressed: _onContinue),

                              const SizedBox(height: AppSpacing.xl),
                            ],
                          ),
                        ),
                      ),
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

/// Phone number field split into country-code dropdown + number text field.
class _PhoneField extends StatelessWidget {
  const _PhoneField({
    this.fieldKey,
    required this.controller,
    required this.focusNode,
    required this.nextFocus,
    this.errorText,
    this.onChanged,
  });

  final GlobalKey<AuthTextFieldState>? fieldKey;
  final TextEditingController controller;
  final FocusNode focusNode;
  final FocusNode nextFocus;
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
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CountryCodePicker(
              selected: CountryCodePicker.defaultCountry,
              onSelected: (_) {},
              hasError: errorText != null,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: AuthTextField(
                key: fieldKey,
                controller: controller,
                focusNode: focusNode,
                hint: '98XXXXXXXX',
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                prefixIcon: Icon(
                  Icons.phone_outlined,
                  size: 22,
                  color: colorScheme.onSurfaceVariant,
                ),
                onChanged: onChanged,
                onSubmitted: (_) => nextFocus.requestFocus(),
                errorText: errorText,
              ),
            ),
          ],
        ),
        AppFieldError(errorText: errorText, isDark: isDark),
      ],
    );
  }
}

/// Smoothly animated password strength bar.
///
/// Uses a single [AnimationController] to drive both the fill width and the
/// colour simultaneously, so transitions between strength levels are
/// buttery-smooth instead of snapping. A shimmer sweep plays across the
/// filled portion when the password is strong.
class _PasswordStrengthBar extends StatefulWidget {
  const _PasswordStrengthBar({required this.password});

  final String password;

  @override
  State<_PasswordStrengthBar> createState() => _PasswordStrengthBarState();
}

class _PasswordStrengthBarState extends State<_PasswordStrengthBar>
    with TickerProviderStateMixin {
  // ── Strength transition animation ──
  late final AnimationController _progressController;
  late Animation<double> _progressAnim;
  late Animation<Color?> _colorAnim;

  // ── Shimmer sweep (loops forever) ──
  late final AnimationController _shimmerController;

  // ── Current displayed strength ──
  PasswordStrength _currentStrength = PasswordStrength.weak;
  Color _currentColor = AppColors.error;
  bool _initialised = false;

  @override
  void initState() {
    super.initState();

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    // Determine the initial strength — but defer colour resolution
    // (which needs Theme.of(context)) to didChangeDependencies.
    _currentStrength = AuthValidator.passwordStrength(widget.password);
    _progressAnim = AlwaysStoppedAnimation<double>(_currentStrength.value);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_initialised) {
      _currentColor = _currentStrength.color(context);
      _colorAnim = AlwaysStoppedAnimation<Color?>(_currentColor);
      _initialised = true;
    }
  }

  @override
  void didUpdateWidget(covariant _PasswordStrengthBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    final newStrength = AuthValidator.passwordStrength(widget.password);
    if (newStrength == _currentStrength) return;

    // Animate from the old strength to the new one.
    final oldColor = _currentColor;
    final newColor = newStrength.color(context);
    final oldValue = _currentStrength.value;
    final newValue = newStrength.value;

    _progressAnim = Tween<double>(begin: oldValue, end: newValue).animate(
      CurvedAnimation(
        parent: _progressController,
        curve: Curves.easeOutCubic,
      ),
    );
    _colorAnim = ColorTween(begin: oldColor, end: newColor).animate(
      CurvedAnimation(
        parent: _progressController,
        curve: Curves.easeOutCubic,
      ),
    );

    _currentStrength = newStrength;
    _currentColor = newColor;

    _progressController.forward(from: 0);
  }

  @override
  void dispose() {
    _progressController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final strengthColor = _currentStrength.color(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress bar + label
        Row(
          children: [
            // Smooth animated bar
            Expanded(
              child: ClipRRect(
                borderRadius: AppRadius.radiusFull,
                child: SizedBox(
                  height: 8,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Track
                      Container(
                        decoration: BoxDecoration(
                          color:
                              colorScheme.outlineVariant.withValues(alpha: 0.3),
                          borderRadius: AppRadius.radiusFull,
                        ),
                      ),
                      // Animated fill — width and colour tween together
                      AnimatedBuilder(
                        animation: _progressController,
                        builder: (context, _) {
                          return FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: _progressAnim.value,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              decoration: BoxDecoration(
                                borderRadius: AppRadius.radiusFull,
                                color: _colorAnim.value ?? strengthColor,
                                boxShadow: [
                                  BoxShadow(
                                    color: (_colorAnim.value ?? strengthColor)
                                        .withValues(alpha: 0.45),
                                    blurRadius: 10,
                                    spreadRadius: 0,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      // Shimmer sweep — only when strong
                      if (_currentStrength == PasswordStrength.strong)
                        AnimatedBuilder(
                          animation: _shimmerController,
                          builder: (context, _) {
                            return CustomPaint(
                              painter: _ShimmerPainter(
                                position: _shimmerController.value,
                                opacity: 0.6,
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Animated label
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, anim) {
                return FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.3),
                      end: Offset.zero,
                    ).animate(anim),
                    child: child,
                  ),
                );
              },
              child: SizedBox(
                key: ValueKey(_currentStrength.label),
                width: 52,
                child: Text(
                  _currentStrength.label,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: strengthColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.sm),

        // Animated hint text
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            key: ValueKey(_hintFor(_currentStrength)),
            _hintFor(_currentStrength),
            style: AppTextStyles.caption.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  String _hintFor(PasswordStrength strength) {
    switch (strength) {
      case PasswordStrength.weak:
        return 'Use 8+ characters, with a number';
      case PasswordStrength.fair:
        return 'Add uppercase, number or symbol';
      case PasswordStrength.strong:
        return 'Great password';
    }
  }
}

/// Paints a horizontal white shimmer sweep across the bar.
class _ShimmerPainter extends CustomPainter {
  _ShimmerPainter({required this.position, required this.opacity});

  /// Sweep position, 0 → 1 (left to right).
  final double position;

  /// Peak opacity of the shimmer.
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    final sweepWidth = width * 0.35;
    final center = position * width;

    final shader = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        Colors.white.withValues(alpha: 0),
        Colors.white.withValues(alpha: opacity),
        Colors.white.withValues(alpha: 0),
      ],
      stops: const [0.0, 0.5, 1.0],
    ).createShader(
      Rect.fromCenter(
        center: Offset(center, height / 2),
        width: sweepWidth,
        height: height,
      ),
    );

    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(center, height / 2),
        width: sweepWidth,
        height: height,
      ),
      Paint()..shader = shader,
    );
  }

  @override
  bool shouldRepaint(_ShimmerPainter oldDelegate) =>
      oldDelegate.position != position || oldDelegate.opacity != opacity;
}

/// Terms and Privacy Policy agreement checkbox.
class _TermsCheckbox extends StatelessWidget {
  const _TermsCheckbox({
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: Checkbox(
              value: value,
              onChanged: onChanged,
              activeColor: colorScheme.primary,
              checkColor: colorScheme.onPrimary,
              side: BorderSide(
                color: value ? colorScheme.primary : colorScheme.outline,
                width: 1.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.radiusSm,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text.rich(
              TextSpan(
                text: 'I agree to the ',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: colorScheme.onSurface,
                  fontSize: 13,
                ),
                children: [
                  TextSpan(
                    text: 'Terms of Service',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: colorScheme.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const TextSpan(text: ' and '),
                  TextSpan(
                    text: 'Privacy Policy',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: colorScheme.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-width primary "Continue" button with a blurring background glow.
class _ContinueButton extends StatefulWidget {
  const _ContinueButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_ContinueButton> createState() => _ContinueButtonState();
}

class _ContinueButtonState extends State<_ContinueButton>
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
          // Perfect smooth 0 → 1 → 0 sine wave.
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
          onPressed: widget.onPressed,
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
          child: const Text('Continue'),
        ),
      ),
    );
  }
}
