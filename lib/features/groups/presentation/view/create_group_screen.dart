import 'package:flutter/material.dart';

import '../../../../app/theme/design_system.dart';
import '../../../../core/widgets/animated_entrance.dart';

/// Create Group tab for the app shell.
///
/// Lets the user start a new group by giving it a name and optional colour.
class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen>
    with TickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _nameFocus = FocusNode();

  late final AnimationController _entranceController;
  int _selectedColorIndex = 0;

  static final _colors = AppColors.chartColorsLight;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
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
    _nameFocus.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: SingleChildScrollView(
        key: const PageStorageKey('create_group_screen'),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.pageTop,
          AppSpacing.lg,
          96,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StaggeredEntrance(
              animation: _entranceController,
              interval: const Interval(0.0, 0.5, curve: Curves.easeOut),
              child: Text(
                'New Group',
                style: AppTextStyles.headlineSmall.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            StaggeredEntrance(
              animation: _entranceController,
              interval: const Interval(0.05, 0.55, curve: Curves.easeOut),
              child: Text(
                'Create a space to split expenses with friends.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxxl),
            StaggeredEntrance(
              animation: _entranceController,
              interval: const Interval(0.1, 0.6, curve: Curves.easeOut),
              child: Text(
                'Group name',
                style: AppTextStyles.labelLarge.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            StaggeredEntrance(
              animation: _entranceController,
              interval: const Interval(0.15, 0.65, curve: Curves.easeOut),
              child: TextField(
                controller: _nameController,
                focusNode: _nameFocus,
                decoration: const InputDecoration(
                  hintText: 'e.g. Weekend Trip',
                ),
                style: AppTextStyles.bodyLarge,
                textInputAction: TextInputAction.done,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            StaggeredEntrance(
              animation: _entranceController,
              interval: const Interval(0.2, 0.7, curve: Curves.easeOut),
              child: Text(
                'Pick a colour',
                style: AppTextStyles.labelLarge.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            StaggeredEntrance(
              animation: _entranceController,
              interval: const Interval(0.25, 0.75, curve: Curves.easeOut),
              child: Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                children: [
                  for (var i = 0; i < _colors.length; i++)
                    _ColorSwatch(
                      color: _colors[i],
                      isSelected: i == _selectedColorIndex,
                      onTap: () => setState(() => _selectedColorIndex = i),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxxl),
            StaggeredEntrance(
              animation: _entranceController,
              interval: const Interval(0.3, 0.8, curve: Curves.easeOut),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Create Group'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSelected
              ? Border.all(color: colorScheme.onSurface, width: 3)
              : null,
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
          ],
        ),
      ),
    );
  }
}
