import 'package:flutter/material.dart';

import '../../../../app/theme/design_system.dart';
import '../widget/animated_welcome_entrance.dart';
import '../widget/welcome_cta_button.dart';
import '../widget/welcome_headline.dart';
import '../widget/welcome_hero_image.dart';
import '../widget/welcome_sign_in_prompt.dart';

/// First screen shown to users when the app is freshly installed or no user
/// is currently signed in.
///
/// Implements the exact welcome design from the product spec:
///  - "Welcome to" label
///  - "Group Expense Splitter" two-line primary headline
///  - "Manage together. Split easily." subtitle
///  - Hero illustration
///  - "Get Started" primary CTA
///  - "Already have an account? Sign in" footer
///
/// Each element is animated with a staggered slide + fade entrance.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: WelcomeAnimationIntervals.duration,
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: AppSpacing.screenPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSpacing.xxxl),
                    WelcomeHeadline(animation: _animationController),
                    const SizedBox(height: AppSpacing.xl),
                    Expanded(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 360),
                          child: WelcomeHeroImage(animation: _animationController),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    WelcomeCtaButton(
                      animation: _animationController,
                      onPressed: () {},
                    ),
                    const SizedBox(height: AppSpacing.md),
                    WelcomeSignInPrompt(
                      animation: _animationController,
                      onSignInTap: () {},
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
