import 'package:aphora/logic/language_service.dart';
import 'package:aphora/ui/auth/auth_shell.dart';
import 'package:aphora/ui/design/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

/// Step 1 of 2: phone + password. Step 2 is [UserInfoPage].
class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _form = GlobalKey<FormState>();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _phone.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _continue() {
    if (!_form.currentState!.validate()) return;
    context.go('/userinfo', extra: {
      'phone': normalisePhone(_phone.text),
      'password': _password.text,
    });
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      title: tr('Create your account', 'கணக்கை உருவாக்குங்கள்'),
      subtitle: tr('Step 1 of 2 · A caregiver can do this for the patient.',
          'படி 1/2 · பராமரிப்பாளர் இதைச் செய்யலாம்.'),
      footer: [
        Center(
          child: AphButton.ghost(
            label: tr('I already have an account', 'ஏற்கனவே கணக்கு உள்ளது'),
            icon: Icons.login_rounded,
            onPressed: () => context.go('/login'),
          ),
        ),
      ],
      children: [
        Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const StepProgress(current: 1, total: 2),
              const Gap(AphSpace.lg),
              AphTextField(
                controller: _phone,
                label: tr("Patient's mobile number", 'நோயாளியின் மொபைல் எண்'),
                helper: tr('Used to sign in. No SMS is sent.', 'உள்நுழைய பயன்படும். SMS அனுப்பப்படாது.'),
                icon: Icons.phone_rounded,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]')),
                  LengthLimitingTextInputFormatter(12),
                ],
                validator: validatePhone,
              ),
              const Gap(AphSpace.md),
              AphTextField(
                controller: _password,
                label: tr('Choose a password', 'கடவுச்சொல்லைத் தேர்ந்தெடுங்கள்'),
                helper: tr('At least 6 characters. Write it down somewhere safe.',
                    'குறைந்தது 6 எழுத்துகள்.'),
                icon: Icons.lock_rounded,
                obscure: true,
                autofillHints: const [AutofillHints.newPassword],
                validator: validatePassword,
              ),
              const Gap(AphSpace.md),
              AphTextField(
                controller: _confirm,
                label: tr('Type the password again', 'கடவுச்சொல்லை மீண்டும் தட்டச்சு செய்யுங்கள்'),
                icon: Icons.lock_outline_rounded,
                obscure: true,
                textInputAction: TextInputAction.done,
                validator: (v) => v != _password.text
                    ? tr('The passwords do not match.', 'கடவுச்சொற்கள் பொருந்தவில்லை.')
                    : null,
                onSubmitted: (_) => _continue(),
              ),
              const Gap(AphSpace.lg),
              AphButton(
                label: tr('Continue', 'தொடரவும்'),
                icon: Icons.arrow_forward_rounded,
                onPressed: _continue,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
