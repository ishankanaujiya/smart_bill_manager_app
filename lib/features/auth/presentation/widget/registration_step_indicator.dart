import 'package:flutter/material.dart';

import '../../../../app/theme/design_system.dart';

/// Horizontal step indicator for the 4-step registration flow.
///
/// Steps: Details → Verify → Profile → Done.
/// The active step is highlighted with the primary colour and a ring.
/// Completed previous steps show a checkmark. Future steps are muted.
class RegistrationStepIndicator extends StatelessWidget {
  const RegistrationStepIndicator({
    super.key,
    required this.currentStep,
  });

  /// 0-indexed step (0 = Details, 1 = Verify, 2 = Profile, 3 = Done).
  final int currentStep;

  static const List<String> _labels = ['DETAILS', 'VERIFY', 'PROFILE', 'DONE'];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (var i = 0; i < _labels.length; i++) ...[
          _Step(
            index: i,
            label: _labels[i],
            isActive: i == currentStep,
            isCompleted: i < currentStep,
            isLast: i == _labels.length - 1,
            colorScheme: colorScheme,
          ),
        ],
      ],
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.index,
    required this.label,
    required this.isActive,
    required this.isCompleted,
    required this.isLast,
    required this.colorScheme,
  });

  final int index;
  final String label;
  final bool isActive;
  final bool isCompleted;
  final bool isLast;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final stepColor = isActive || isCompleted
        ? colorScheme.primary
        : colorScheme.surfaceContainerHighest;
    final stepContentColor = isActive || isCompleted
        ? colorScheme.onPrimary
        : colorScheme.onSurfaceVariant;
    final labelColor = isActive
        ? colorScheme.primary
        : (isCompleted ? colorScheme.onSurface : colorScheme.onSurfaceVariant);

    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Connector line on the left (except for first step)
              if (index > 0)
                Expanded(
                  child: Container(
                    height: 2,
                    color: isCompleted
                        ? colorScheme.primary
                        : colorScheme.outlineVariant.withValues(alpha: 0.3),
                  ),
                )
              else
                const Expanded(child: SizedBox()),
              // Step circle
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isActive && !isCompleted
                      ? colorScheme.surface
                      : stepColor,
                  shape: BoxShape.circle,
                  border: isActive && !isCompleted
                      ? Border.all(color: colorScheme.primary, width: 2)
                      : null,
                ),
                child: Center(
                  child: isCompleted
                      ? Icon(
                          Icons.check_rounded,
                          size: 18,
                          color: stepContentColor,
                        )
                      : Text(
                          '${index + 1}',
                          style: AppTextStyles.labelLarge.copyWith(
                            color: isActive && !isCompleted
                                ? colorScheme.primary
                                : stepContentColor,
                            fontWeight: FontWeight.w700,
                            height: 1,
                          ),
                        ),
                ),
              ),
              // Connector line on the right (except for last step)
              if (!isLast)
                Expanded(
                  child: Container(
                    height: 2,
                    color: isActive || isCompleted
                        ? colorScheme.primary
                        : colorScheme.outlineVariant.withValues(alpha: 0.3),
                  ),
                )
              else
                const Expanded(child: SizedBox()),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: labelColor,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}
