import 'package:aphora/main.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DuoColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: DuoColors.textLight, size: 28),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // const DuoOwl(size: 90),
                const SizedBox(height: 16),
                Text('Create your account', style: DuoTextStyles.heading),
                const SizedBox(height: 4),
                Text(
                  'Join millions recovering their voice.',
                  style: DuoTextStyles.label,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // XP streak badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: DuoColors.greenLight,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: DuoColors.green, width: 2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.bolt, color: DuoColors.green, size: 20),
                      const SizedBox(width: 6),
                      Text(
                        'Start your streak today!',
                        style: DuoTextStyles.label.copyWith(
                          color: DuoColors.greenDark,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                DuoTextField(
                  controller: emailController,
                  label: 'Phone number',
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your phone number';
                    }
                    if (value.trim().length < 10) {
                      return 'Enter a valid phone number';
                    }
                    return null;
                  },
                ),
                DuoTextField(
                  controller: passwordController,
                  label: 'Create a password',
                  prefixIcon: Icons.lock_outline,
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  'By creating an account you agree to our Terms of Service and Privacy Policy.',
                  style: DuoTextStyles.label.copyWith(fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                DuoButton(
                  label: 'CREATE ACCOUNT',
                  onPressed: () {
                    if (!_formKey.currentState!.validate()) return;

                    context.push(
                      '/userinfo',
                      extra: {
                        'phone': emailController.text.trim(),
                        'password': passwordController.text,
                      },
                    );
                  },
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => context.pop(),
                  child: Text(
                    'Already have an account? Log In',
                    style: DuoTextStyles.label.copyWith(
                      color: DuoColors.blue,
                      decoration: TextDecoration.underline,
                      decorationColor: DuoColors.blue,
                    ),
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
