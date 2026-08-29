import 'package:flutter/material.dart';

/// Demonstrates text-input fields from the inputDecorationTheme.
class InputShowcase extends StatelessWidget {
  const InputShowcase({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TextField(
          decoration: InputDecoration(
            labelText: 'Email',
            hintText: 'you@example.com',
            prefixIcon: Icon(Icons.email_outlined),
          ),
        ),
        const SizedBox(height: 16),
        const TextField(
          decoration: InputDecoration(
            labelText: 'Password',
            hintText: 'Enter your password',
            prefixIcon: Icon(Icons.lock_outline),
            suffixIcon: Icon(Icons.visibility_outlined),
          ),
          obscureText: true,
        ),
        const SizedBox(height: 16),
        const TextField(
          decoration: InputDecoration(
            labelText: 'Amount',
            prefixIcon: Icon(Icons.attach_money_rounded),
            hintText: '0.00',
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        TextField(
          enabled: false,
          decoration: const InputDecoration(
            labelText: 'Disabled Field',
            hintText: 'Cannot edit',
            prefixIcon: Icon(Icons.lock_rounded),
          ),
        ),
        const SizedBox(height: 16),
        const TextField(
          decoration: InputDecoration(
            labelText: 'Error State',
            errorText: 'This field is required',
            prefixIcon: Icon(Icons.error_outline),
          ),
        ),
      ],
    );
  }
}
