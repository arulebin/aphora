import 'package:aphora/logic/locator.dart';
import 'package:aphora/main.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LoginPage extends StatelessWidget {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DuoColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Green hero section
              Container(
                width: double.infinity,
                color: DuoColors.green,
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    // const DuoOwl(size: 110),
                    const SizedBox(height: 16),
                    Text(
                      'Aphora',
                      style: DuoTextStyles.display.copyWith(
                        color: Colors.white,
                        fontSize: 36,
                        shadows: [
                          const Shadow(
                            color: DuoColors.greenDark,
                            offset: Offset(0, 3),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Speak again. One lesson at a time.',
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Welcome back!', style: DuoTextStyles.heading),
                    const SizedBox(height: 4),
                    Text(
                      'Log in to continue your progress.',
                      style: DuoTextStyles.label,
                    ),
                    const SizedBox(height: 24),
                    DuoTextField(
                      controller: emailController,
                      label: 'Phone number',
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                    DuoTextField(
                      controller: passwordController,
                      label: 'Password',
                      prefixIcon: Icons.lock_outline,
                      obscureText: true,
                    ),
                    // const SizedBox(height: 8),
                    // Align(
                    //   alignment: Alignment.centerRight,
                    //   child: TextButton(
                    //     onPressed: () {},
                    //     child: Text(
                    //       'Forgot password?',
                    //       style: DuoTextStyles.label.copyWith(
                    //         color: DuoColors.blue,
                    //         decoration: TextDecoration.underline,
                    //         decorationColor: DuoColors.blue,
                    //       ),
                    //     ),
                    //   ),
                    // ),
                    const SizedBox(height: 16),
                    DuoButton(
                      label: 'LOG IN',
                      onPressed: () async {
                        final phone = emailController.text.trim();
                        final password = passwordController.text;

                        if (phone.isEmpty || password.isEmpty) return;

                        try {
                          final user = await Locator.userDatabaseService.login(
                            phone: phone,
                            password: password,
                          );

                          if (user != null) {
                            if (context.mounted) {
                              context.push('/home');
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
                    DuoButton(
                      label: "DON'T HAVE AN ACCOUNT? SIGN UP",
                      onPressed: () => context.push('/signup'),
                      color: Colors.white,
                      shadowColor: DuoColors.border,
                      textColor: DuoColors.text,
                      outlined: true,
                    ),
                    const SizedBox(height: 24),
                    // const SizedBox(height: 16),
                    // _SocialButton(
                    //   label: 'Continue with Google',
                    //   icon: Icons.g_mobiledata_rounded,
                    //   color: const Color(0xFF4285F4),
                    // ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
