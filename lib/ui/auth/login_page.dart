import 'package:aphora/data/database_service/user_database_service.dart';
import 'package:aphora/logic/language_service.dart';
import 'package:aphora/logic/locator.dart';
import 'package:aphora/ui/auth/auth_shell.dart';
import 'package:aphora/ui/design/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _form = GlobalKey<FormState>();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await Locator.userDatabaseService.login(
        phone: normalisePhone(_phone.text),
        password: _password.text,
      );
      TextInput.finishAutofillContext();
      if (mounted) context.go('/home');
    } on AuthFailure catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = tr('Could not sign in. Check your internet and try again.',
          'உள்நுழைய முடியவில்லை.'));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      title: tr('Welcome back', 'மீண்டும் வருக'),
      subtitle: tr('Sign in to continue your practice.', 'பயிற்சியைத் தொடர உள்நுழையுங்கள்.'),
      footer: [
        AphButton.secondary(
          label: tr('Create a new account', 'புதிய கணக்கு உருவாக்கு'),
          icon: Icons.person_add_alt_1_rounded,
          onPressed: () => context.go('/signup'),
        ),
        const Gap(AphSpace.sm),
        Center(
          child: AphButton.ghost(
            label: tr('I am a therapist', 'நான் சிகிச்சையாளர்'),
            icon: Icons.medical_services_outlined,
            onPressed: () => context.go('/therapist'),
          ),
        ),
      ],
      children: [
        AutofillGroup(
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AphTextField(
                  controller: _phone,
                  label: tr('Mobile number', 'மொபைல் எண்'),
                  hint: '98765 43210',
                  icon: Icons.phone_rounded,
                  keyboardType: TextInputType.phone,
                  autofillHints: const [AutofillHints.telephoneNumberNational],
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]')),
                    LengthLimitingTextInputFormatter(12),
                  ],
                  validator: validatePhone,
                ),
                const Gap(AphSpace.md),
                AphTextField(
                  controller: _password,
                  label: tr('Password', 'கடவுச்சொல்'),
                  icon: Icons.lock_rounded,
                  obscure: true,
                  autofillHints: const [AutofillHints.password],
                  textInputAction: TextInputAction.done,
                  validator: validatePassword,
                  onSubmitted: (_) => _login(),
                ),
                if (_error != null) ...[
                  const Gap(AphSpace.md),
                  FeedbackBanner(tone: FeedbackTone.error, title: _error!),
                ],
                const Gap(AphSpace.lg),
                AphButton(
                  label: tr('Sign in', 'உள்நுழை'),
                  icon: Icons.login_rounded,
                  loading: _loading,
                  onPressed: _login,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
