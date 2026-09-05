import 'package:flutter/material.dart';

import '../../../../app/theme/design_system.dart';

/// Horizontal step indicator for the 3-step registration flow.
///
/// Steps: Details -> Profile -> Done.
/// The active step is highlighted with the primary colour and a ring.
/// Completed previous steps show a checkmark. Future steps are muted.
///
/// Connector lines are drawn behind the circles in a [Stack] so they always
/// meet the circle edges precisely, regardless of label widths.
class RegistrationStepIndicator extends StatelessWidget {
  const RegistrationStepIndicator({
    super.key,
    required this.currentStep,
  });

  /// 0-indexed step (0 = Details, 1 = Profile, 2 = Done).
  final int currentStep;

  static const List<String> _labels = ['DETAILS', 'PROFILE', 'DONE'];
  static const double _circleSize = 32;
  static const double _lineThickness = 2;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: _circleSize + 28, // circle + gap + label
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          // Each step occupies an equal slice. The circle sits at the
          // horizontal centre of each slice, so connector lines run between
          // consecutive circle centres.
          final sliceWidth = width / _labels.length;
          final circleCentres = [
            for (var i = 0; i < _labels.length; i++) sliceWidth * (i + 0.5),
          ];

          return Stack(
            children: [
              // --- Connector lines (drawn behind circles) ---
              for (var i = 0; i < _labels.length - 1; i++)
                _AnimatedConnector(
                  start: Offset(circleCentres[i], _circleSize / 2),
                  end: Offset(circleCentres[i + 1], _circleSize / 2),
                  thickness: _lineThickness,
                  // A connector is "filled" once the step it leads from is
                  // completed (i.e. we've moved past it).
                  filled: i < currentStep,
                  activeColor: colorScheme.primary,
                  inactiveColor:
                      colorScheme.outlineVariant.withValues(alpha: 0.35),
                ),

              // --- Circles + labels ---
              Row(
                children: [
                  for (var i = 0; i < _labels.length; i++)
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _AnimatedCircle(
                            index: i,
                            isActive: i == currentStep,
                            isCompleted: i < currentStep,
                            circleSize: _circleSize,
                            colorScheme: colorScheme,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          _AnimatedLabel(
                            label: _labels[i],
                            isActive: i == currentStep,
                            isCompleted: i < currentStep,
                            colorScheme: colorScheme,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Animated connector line between two steps.
class _AnimatedConnector extends StatelessWidget {
  const _AnimatedConnector({
    required this.start,
    required this.end,
    required this.thickness,
    required this.filled,
    required this.activeColor,
    required this.inactiveColor,
  });

  final Offset start;
  final Offset end;
  final double thickness;
  final bool filled;
  final Color activeColor;
  final Color inactiveColor;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: filled ? 1 : 0),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOut,
      builder: (context, progress, _) {
        // Draw the full inactive track, then overlay an animated active
        // segment that grows from the start toward the end.
        final activeEnd = Offset(
          start.dx + (end.dx - start.dx) * progress,
          end.dy,
        );

        return CustomPaint(
          size: Size.infinite,
          painter: _ConnectorPainter(
            trackStart: start,
            trackEnd: end,
            activeStart: start,
            activeEnd: activeEnd,
            thickness: thickness,
            activeColor: activeColor,
            inactiveColor: inactiveColor,
          ),
        );
      },
    );
  }
}

class _ConnectorPainter extends CustomPainter {
  _ConnectorPainter({
    required this.trackStart,
    required this.trackEnd,
    required this.activeStart,
    required this.activeEnd,
    required this.thickness,
    required this.activeColor,
    required this.inactiveColor,
  });

  final Offset trackStart;
  final Offset trackEnd;
  final Offset activeStart;
  final Offset activeEnd;
  final double thickness;
  final Color activeColor;
  final Color inactiveColor;

  @override
  void paint(Canvas canvas, Size size) {
    final trackPaint = Paint()
      ..color = inactiveColor
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(trackStart, trackEnd, trackPaint);

    if (activeEnd.dx > activeStart.dx + 0.5) {
      final activePaint = Paint()
        ..color = activeColor
        ..strokeWidth = thickness
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(activeStart, activeEnd, activePaint);
    }
  }

  @override
  bool shouldRepaint(_ConnectorPainter oldDelegate) =>
      oldDelegate.activeEnd != activeEnd ||
      oldDelegate.activeColor != activeColor ||
      oldDelegate.inactiveColor != inactiveColor;
}

/// Animated step circle with a subtle scale pop on state change.
class _AnimatedCircle extends StatelessWidget {
  const _AnimatedCircle({
    required this.index,
    required this.isActive,
    required this.isCompleted,
    required this.circleSize,
    required this.colorScheme,
  });

  final int index;
  final bool isActive;
  final bool isCompleted;
  final double circleSize;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final filled = isActive || isCompleted;
    final bg = filled
        ? colorScheme.primary
        : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5);
    final content = filled
        ? colorScheme.onPrimary
        : colorScheme.onSurfaceVariant;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.85, end: 1),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
        width: circleSize,
        height: circleSize,
        decoration: BoxDecoration(
          color: isActive && !isCompleted ? colorScheme.surface : bg,
          shape: BoxShape.circle,
          border: isActive && !isCompleted
              ? Border.all(color: colorScheme.primary, width: 2)
              : null,
          boxShadow: [
            if (isActive && !isCompleted)
              BoxShadow(
                color: colorScheme.primary.withValues(alpha: 0.25),
                blurRadius: 12,
                spreadRadius: 1,
              ),
          ],
        ),
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
            child: isCompleted
                ? Icon(
                    Icons.check_rounded,
                    key: const ValueKey('check'),
                    size: 18,
                    color: content,
                  )
                : Text(
                    '${index + 1}',
                    key: ValueKey('num$index'),
                    style: AppTextStyles.labelLarge.copyWith(
                      color: isActive && !isCompleted
                          ? colorScheme.primary
                          : content,
                      fontWeight: FontWeight.w700,
                      height: 1,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

/// Animated label that fades/colours on state change.
class _AnimatedLabel extends StatelessWidget {
  const _AnimatedLabel({
    required this.label,
    required this.isActive,
    required this.isCompleted,
    required this.colorScheme,
  });

  final String label;
  final bool isActive;
  final bool isCompleted;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final color = isActive
        ? colorScheme.primary
        : (isCompleted ? colorScheme.onSurface : colorScheme.onSurfaceVariant);

    return AnimatedDefaultTextStyle(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      style: AppTextStyles.labelSmall.copyWith(
        color: color,
        fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
        letterSpacing: 0.8,
      ),
      child: Text(label),
    );
  }
}
