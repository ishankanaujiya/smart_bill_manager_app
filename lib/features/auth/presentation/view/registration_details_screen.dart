import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/theme/design_system.dart';
import '../../../../core/validators/auth_validator.dart';
import '../../../../core/widgets/app_field_error.dart';
import '../widget/auth_header.dart';
import '../widget/auth_text_field.dart';
import '../widget/country_code_picker.dart';
import '../widget/registration_step_indicator.dart';
import 'registration_verify_screen.dart';

/// Registration step 1 — collect full name, Nepali mobile number and password.
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
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  final _nameFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _passwordFocus = FocusNode();

  final _nameFieldKey = GlobalKey<AuthTextFieldState>();
  final _phoneFieldKey = GlobalKey<AuthTextFieldState>();
  final _passwordFieldKey = GlobalKey<AuthTextFieldState>();

  bool _obscurePassword = true;
  bool _agreed = false;

  // ── Validation error state ──
  String? _nameError;
  String? _phoneError;
  String? _passwordError;
  String? _agreedError;

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
    _phoneController.dispose();
    _passwordController.dispose();
    _nameFocus.dispose();
    _phoneFocus.dispose();
    _passwordFocus.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  bool _validate() {
    final nameErr = AuthValidator.fullName(_nameController.text);
    final phoneErr = AuthValidator.phoneNepal(_phoneController.text);
    final passErr = AuthValidator.password(_passwordController.text);
    final agreedErr = _agreed ? null : 'You must agree to the terms to continue';

    setState(() {
      _nameError = nameErr;
      _phoneError = phoneErr;
      _passwordError = passErr;
      _agreedError = agreedErr;
    });

    if (nameErr != null) _nameFieldKey.currentState?.shake();
    if (phoneErr != null) _phoneFieldKey.currentState?.shake();
    if (passErr != null) _passwordFieldKey.currentState?.shake();

    return nameErr == null &&
        phoneErr == null &&
        passErr == null &&
        agreedErr == null;
  }

  void _onNameChanged() {
    final input = _nameController.text.trim();
    if (input.isEmpty) {
      if (_nameError != null) setState(() => _nameError = null);
      return;
    }
    final err = AuthValidator.fullName(input);
    if (err != _nameError) setState(() => _nameError = err);
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
    if (input.isEmpty) {
      if (_passwordError != null) setState(() => _passwordError = null);
      return;
    }
    final err = AuthValidator.password(input);
    if (err != _passwordError) setState(() => _passwordError = err);
  }

  void _onContinue() {
    if (!_validate()) return;

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RegistrationVerifyScreen(
          phoneNumber: _phoneController.text.trim(),
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
                      const SizedBox(height: AppSpacing.sm),

                      // Back button
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.arrow_back_rounded),
                          style: IconButton.styleFrom(
                            foregroundColor: colorScheme.onSurface,
                          ),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // Step indicator
                      const RegistrationStepIndicator(currentStep: 0),

                      const SizedBox(height: AppSpacing.xxl),

                      // Header
                      AuthHeader(
                        animation: _entranceController,
                        title: 'Split bills, not friendships',
                        subtitle: 'Create an account to start tracking group expenses.',
                      ),

                      const SizedBox(height: AppSpacing.xl),

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
                                onSubmitted: (_) => _phoneFocus.requestFocus(),
                                errorText: _nameError,
                              ),
                              AppFieldError(errorText: _nameError, isDark: isDark),

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

                              Text(
                                'Use 8+ characters, with a number',
                                style: AppTextStyles.caption.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
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
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
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
                ),
                children: [
                  TextSpan(
                    text: 'Terms of Service',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const TextSpan(text: ' and '),
                  TextSpan(
                    text: 'Privacy Policy',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: colorScheme.primary,
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
