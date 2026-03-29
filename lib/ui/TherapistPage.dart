import 'package:aphora/logic/locator.dart';
import 'package:aphora/main.dart';
import 'package:aphora/ui/TherapistDashboardPage.dart';
import 'package:aphora/ui/login_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TherapistPage extends StatefulWidget {
  const TherapistPage({super.key});

  @override
  State<TherapistPage> createState() => _TherapistPageState();
}

class _TherapistPageState extends State<TherapistPage> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DuoColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Purple hero section for Therapist
              Container(
                width: double.infinity,
                color: Colors.purple,
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    Text(
                      'Therapist Portal',
                      style: DuoTextStyles.display.copyWith(
                        color: Colors.white,
                        fontSize: 36,
                        shadows: [
                          const Shadow(
                            color: Colors.purple,
                            offset: Offset(0, 3),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage your patients seamlessly.',
                      style: DuoTextStyles.label.copyWith(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              // Form section
              Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Welcome Therapist!', style: DuoTextStyles.heading),
                      const SizedBox(height: 4),
                      Text(
                        'Log in or sign up to view patient progress.',
                        style: DuoTextStyles.label,
                      ),
                      const SizedBox(height: 24),
                      DuoTextField(
                        controller: nameController,
                        label: 'Name (for new signups)',
                        prefixIcon: Icons.person_outline,
                      ),
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
                        label: 'Password',
                        prefixIcon: Icons.lock_outline,
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DuoButton(
                        label: 'THERAPIST LOGIN',
                        color: Colors.purple,
                        shadowColor: Colors.purple.shade700,
                        onPressed: () async {
                          if (!_formKey.currentState!.validate()) return;

                          final phone = emailController.text.trim();
                          final password = passwordController.text;
                          final name = nameController.text.trim();

                          if (phone.isEmpty || password.isEmpty) return;

                          try {
                            final user = await Locator.userDatabaseService
                                .loginTherapist(
                                  phone: phone,
                                  password: password,
                                  name: name.isNotEmpty ? name : null,
                                );

                            if (user != null) {
                              if (context.mounted) {
                                context.go('/therapist_dashboard');
                              }
                            } else {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Invalid credentials. Please try again.',
                                    ),
                                  ),
                                );
                              }
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e.toString())),
                              );
                            }
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Are you a patient?",
                            style: DuoTextStyles.label.copyWith(
                              color: DuoColors.text,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              context.go('/login');
                            },
                            child: const Text(
                              'Patient Login here',
                              style: TextStyle(color: DuoColors.blue),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
