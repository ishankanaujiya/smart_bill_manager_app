import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/design_system.dart';
import '../widget/registration_step_indicator.dart';
import 'registration_profile_screen.dart';

/// Registration step 2 — 6-digit OTP verification.
///
/// The user enters the code sent to their Nepali mobile number.
/// Includes auto-focus between boxes, paste support, backspace navigation,
/// a resend countdown, and a "Wrong number?" edit action.
class RegistrationVerifyScreen extends StatefulWidget {
  const RegistrationVerifyScreen({
    super.key,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.password,
  });

  final String fullName;
  final String email;
  final String phoneNumber;
  final String password;

  @override
  State<RegistrationVerifyScreen> createState() =>
      _RegistrationVerifyScreenState();
}

class _RegistrationVerifyScreenState extends State<RegistrationVerifyScreen>
    with TickerProviderStateMixin {
  // ── OTP state ──
  final _controllers = List.generate(6, (_) => TextEditingController());
  final _focusNodes = List.generate(6, (_) => FocusNode());

  // ── Resend countdown ──
  static const int _resendSeconds = 30;
  int _secondsRemaining = _resendSeconds;
  Timer? _resendTimer;

  // ── Entrance animation ──
  late final AnimationController _entranceController;
  late final Animation<double> _contentFade;
  late final Animation<Offset> _contentSlide;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 560),
    );
    _contentFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.15, 0.80, curve: Curves.easeOut),
    );
    _contentSlide = Tween<Offset>(
      begin: const Offset(0, 0.14),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.15, 0.80, curve: Curves.easeOut),
      ),
    );

    _startEntrance();
    _startResendTimer();
  }

  Future<void> _startEntrance() async {
    await Future.delayed(const Duration(milliseconds: 120));
    if (!mounted) return;
    _entranceController.forward();
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    _secondsRemaining = _resendSeconds;
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_secondsRemaining <= 0) {
        _resendTimer?.cancel();
      }
      setState(() => _secondsRemaining--);
    });
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    _entranceController.dispose();
    super.dispose();
  }

  String get _otp => _controllers.map((c) => c.text).join();

  bool get _isOtpComplete => _otp.length == 6;

  void _onOtpChanged(int index, String value) {
    if (value.isNotEmpty) {
      _controllers[index].text = value.substring(value.length - 1);
      _controllers[index].selection = TextSelection.fromPosition(
        TextPosition(offset: _controllers[index].text.length),
      );

      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        if (_isOtpComplete) _onVerify();
      }
    } else if (value.isEmpty && index > 0 && _controllers[index].text.isEmpty) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  KeyEventResult _handleKeyEvent(int index, KeyEvent event) {
    if (event.logicalKey == LogicalKeyboardKey.backspace) {
      if (_controllers[index].text.isEmpty && index > 0) {
        _controllers[index - 1].clear();
        _focusNodes[index - 1].requestFocus();
      } else if (_controllers[index].text.isNotEmpty) {
        _controllers[index].clear();
      }
    }
    return KeyEventResult.ignored;
  }

  void _onPaste(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return;

    for (var i = 0; i < 6 && i < digits.length; i++) {
      _controllers[i].text = digits[i];
    }

    final nextIndex = digits.length.clamp(0, 6) - 1;
    if (nextIndex >= 0 && nextIndex < 6) {
      _focusNodes[nextIndex].requestFocus();
    }

    if (digits.length >= 6 && _isOtpComplete) _onVerify();
  }

  void _onResend() {
    if (_secondsRemaining > 0) return;
    _startResendTimer();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'A new code has been sent',
          style: AppTextStyles.bodyMedium.copyWith(
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _onVerify() {
    if (!_isOtpComplete) {
      _focusNodes[0].requestFocus();
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RegistrationProfileScreen(
          fullName: widget.fullName,
          email: widget.email,
          phoneNumber: widget.phoneNumber,
          password: widget.password,
        ),
      ),
    );
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
                      const SizedBox(height: AppSpacing.md),

                      // Step indicator
                      const RegistrationStepIndicator(currentStep: 1),

                      const SizedBox(height: AppSpacing.xxxl),

                      // Content
                      SlideTransition(
                        position: _contentSlide,
                        child: FadeTransition(
                          opacity: _contentFade,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Verify your number',
                                style: AppTextStyles.headlineLarge.copyWith(
                                  color: colorScheme.onSurface,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  height: 1.1,
                                ),
                              ),

                              const SizedBox(height: AppSpacing.md),

                              Text.rich(
                                TextSpan(
                                  text: 'Enter the 6-digit code we sent to ',
                                  style: AppTextStyles.bodyLarge.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: '+977 ${widget.phoneNumber}',
                                      style: AppTextStyles.bodyLarge.copyWith(
                                        color: colorScheme.onSurface,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const TextSpan(text: '.'),
                                  ],
                                ),
                              ),

                              const SizedBox(height: AppSpacing.lg),

                              // Wrong number row
                              Row(
                                children: [
                                  Text(
                                    'Wrong number? ',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => Navigator.of(context).pop(),
                                    child: Text(
                                      'Edit it',
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: colorScheme.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: AppSpacing.xxl),

                              // OTP input boxes
                              _OtpInput(
                                controllers: _controllers,
                                focusNodes: _focusNodes,
                                onChanged: _onOtpChanged,
                                onKeyEvent: _handleKeyEvent,
                                onPaste: _onPaste,
                              ),

                              const SizedBox(height: AppSpacing.xxl),

                              // Waiting for code
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.access_time_rounded,
                                    size: 16,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: AppSpacing.xs),
                                  Text(
                                    'Waiting for code',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: AppSpacing.xl),

                              // Resend code
                              Center(
                                child: Text.rich(
                                  TextSpan(
                                    text: "Didn't get it? ",
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: _secondsRemaining > 0
                                            ? 'Resend code (${_secondsRemaining}s)'
                                            : 'Resend code',
                                        style: AppTextStyles.bodyMedium.copyWith(
                                          color: _secondsRemaining > 0
                                              ? colorScheme.onSurfaceVariant
                                              : colorScheme.primary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                        recognizer: _secondsRemaining > 0
                                            ? null
                                            : (TapGestureRecognizer()
                                              ..onTap = _onResend),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: AppSpacing.xxl),

                              // Verify button
                              _VerifyButton(onPressed: _onVerify),

                              const SizedBox(height: AppSpacing.lg),

                              // Helper text
                              Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.verified_user_outlined,
                                      size: 16,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: AppSpacing.xs),
                                    Text(
                                      'A verified number is how groups will find you',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

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

/// 6-digit OTP input grid with paste, auto-focus and backspace support.
class _OtpInput extends StatelessWidget {
  const _OtpInput({
    required this.controllers,
    required this.focusNodes,
    required this.onChanged,
    required this.onKeyEvent,
    required this.onPaste,
  });

  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final void Function(int, String) onChanged;
  final KeyEventResult Function(int, KeyEvent) onKeyEvent;
  final void Function(String) onPaste;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () async {
        final data = await Clipboard.getData(Clipboard.kTextPlain);
        if (data?.text != null) onPaste(data!.text!);
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (var i = 0; i < 6; i++) ...[
            Expanded(
              child: _OtpBox(
                index: i,
                controller: controllers[i],
                focusNode: focusNodes[i],
                onChanged: (v) => onChanged(i, v),
                onKeyEvent: (e) => onKeyEvent(i, e),
              ),
            ),
            if (i < 5) const SizedBox(width: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

/// Single OTP digit box.
class _OtpBox extends StatelessWidget {
  const _OtpBox({
    required this.index,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onKeyEvent,
  });

  final int index;
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final KeyEventResult Function(KeyEvent)? onKeyEvent;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Focus(
      child: Builder(
        builder: (ctx) {
          final focused = Focus.of(ctx).hasFocus;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 56,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: AppRadius.radiusMd,
              border: Border.all(
                color: focused ? colorScheme.primary : Colors.transparent,
                width: 2,
              ),
            ),
            child: Focus(
              onKeyEvent: (node, event) => onKeyEvent?.call(event) ?? KeyEventResult.ignored,
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                textAlign: TextAlign.center,
                textAlignVertical: TextAlignVertical.center,
                expands: true,
                maxLines: null,
                minLines: null,
                showCursor: false,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 1,
                onChanged: onChanged,
                decoration: const InputDecoration(
                  counterText: '',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                  isCollapsed: true,
                ),
                style: AppTextStyles.headlineMedium.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Full-width "Verify & continue" primary button with blurring background glow.
class _VerifyButton extends StatefulWidget {
  const _VerifyButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_VerifyButton> createState() => _VerifyButtonState();
}

class _VerifyButtonState extends State<_VerifyButton>
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
          child: const Text('Verify & continue'),
        ),
      ),
    );
  }
}
