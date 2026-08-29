import 'package:flutter/material.dart';

/// Demonstrates every button variant from the design system.
class ButtonShowcase extends StatelessWidget {
  const ButtonShowcase({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            ElevatedButton(
              onPressed: () {},
              child: const Text('Elevated'),
            ),
            FilledButton(
              onPressed: () {},
              child: const Text('Filled'),
            ),
            OutlinedButton(
              onPressed: () {},
              child: const Text('Outlined'),
            ),
            TextButton(
              onPressed: () {},
              child: const Text('Text'),
            ),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            ElevatedButton(
              onPressed: null,
              child: const Text('Disabled'),
            ),
            OutlinedButton(
              onPressed: null,
              child: const Text('Disabled'),
            ),
            TextButton(
              onPressed: null,
              child: const Text('Disabled'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            FloatingActionButton(
              onPressed: () {},
              child: const Icon(Icons.add_rounded),
            ),
            const SizedBox(width: 12),
            FloatingActionButton.extended(
              onPressed: () {},
              icon: const Icon(Icons.edit_rounded),
              label: const Text('Edit'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.favorite_rounded),
            ),
            IconButton.filled(
              onPressed: () {},
              icon: const Icon(Icons.star_rounded),
            ),
            IconButton.outlined(
              onPressed: () {},
              icon: const Icon(Icons.bookmark_rounded),
            ),
          ],
        ),
      ],
    );
  }
}
