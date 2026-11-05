import 'package:aphora/data/database_service/user_database_service.dart';
import 'package:aphora/logic/comfort_settings.dart';
import 'package:aphora/logic/language_service.dart';
import 'package:aphora/logic/locator.dart';
import 'package:aphora/ui/auth/auth_shell.dart';
import 'package:aphora/ui/design/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

/// Step 2 of 2: about the patient. Creates the account.
class UserInfoPage extends StatefulWidget {
  const UserInfoPage({super.key, required this.phone, required this.password});

  final String phone;
  final String password;

  @override
  State<UserInfoPage> createState() => _UserInfoPageState();
}

class _UserInfoPageState extends State<UserInfoPage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _age = TextEditingController();
  String? _gender;
  String _who = 'patient';
  String _type = 'Not sure';
  String? _severity;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (widget.phone.isEmpty) {
      context.go('/signup'); // Deep-linked without step 1.
      return;
    }
    if (!_form.currentState!.validate()) return;
    if (_gender == null || _severity == null) {
      setState(() => _error = tr('Please answer every question above.',
          'மேலே உள்ள அனைத்துக் கேள்விகளுக்கும் பதிலளிக்கவும்.'));
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await Locator.userDatabaseService.signUp(
        phone: widget.phone,
        password: widget.password,
        name: _name.text.trim(),
        age: int.tryParse(_age.text.trim()) ?? 0,
        gender: _gender!,
        aphasiaType: _type,
        severityLevel: _severity!,
      );
      // A caregiver setting up for someone usually practises alongside them.
      if (_who == 'caregiver') {
        ComfortSettings.instance.assistedMode.value = true;
      }
      if (mounted) context.go('/home');
    } on AuthFailure catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = tr('Could not create the account. Please try again.',
          'கணக்கை உருவாக்க முடியவில்லை.'));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      title: tr('About the patient', 'நோயாளியைப் பற்றி'),
      subtitle: tr('Step 2 of 2 · This helps us pick the right exercises.',
          'படி 2/2 · சரியான பயிற்சிகளைத் தேர்ந்தெடுக்க உதவும்.'),
      footer: [
        Center(
          child: AphButton.ghost(
            label: tr('Back', 'பின் செல்'),
            icon: Icons.arrow_back_rounded,
            onPressed: () => context.go('/signup'),
          ),
        ),
      ],
      children: [
        Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const StepProgress(current: 2, total: 2),
              const Gap(AphSpace.lg),
              ChoiceGroup<String>(
                label: tr('Who is filling this in?', 'யார் இதை நிரப்புகிறார்?'),
                options: [
                  ('patient', tr('The patient', 'நோயாளி'), Icons.person_rounded),
                  ('caregiver', tr('A caregiver / helper', 'பராமரிப்பாளர்'), Icons.volunteer_activism_rounded),
                ],
                value: _who,
                onChanged: (v) => setState(() => _who = v),
              ),
              const Gap(AphSpace.lg),
              AphTextField(
                controller: _name,
                label: tr("Patient's name", 'நோயாளியின் பெயர்'),
                icon: Icons.badge_rounded,
                textCapitalization: TextCapitalization.words,
                validator: (v) => (v ?? '').trim().length < 2
                    ? tr('Please enter a name.', 'பெயரை உள்ளிடவும்.')
                    : null,
              ),
              const Gap(AphSpace.md),
              AphTextField(
                controller: _age,
                label: tr('Age', 'வயது'),
                icon: Icons.cake_rounded,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(3),
                ],
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  return n == null || n < 5 || n > 110
                      ? tr('Enter an age between 5 and 110.', '5 முதல் 110 வரை வயதை உள்ளிடவும்.')
                      : null;
                },
              ),
              const Gap(AphSpace.lg),
              ChoiceGroup<String>(
                label: tr('Gender', 'பாலினம்'),
                options: [
                  ('Male', tr('Male', 'ஆண்'), null),
                  ('Female', tr('Female', 'பெண்'), null),
                  ('Other', tr('Other', 'மற்றவை'), null),
                ],
                value: _gender,
                onChanged: (v) => setState(() => _gender = v),
              ),
              const Gap(AphSpace.lg),
              ChoiceGroup<String>(
                label: tr('Type of aphasia', 'அஃபேசியா வகை'),
                helper: tr('Your doctor or therapist may have told you. "Not sure" is fine.',
                    'தெரியாவிட்டால் "தெரியவில்லை" தேர்ந்தெடுக்கவும்.'),
                options: [
                  ('Not sure', tr('Not sure', 'தெரியவில்லை'), null),
                  ('Broca', 'Broca', null),
                  ('Wernicke', 'Wernicke', null),
                  ('Anomic', 'Anomic', null),
                  ('Global', 'Global', null),
                ],
                value: _type,
                onChanged: (v) => setState(() => _type = v),
              ),
              const Gap(AphSpace.lg),
              ChoiceGroup<String>(
                label: tr('How hard is speaking right now?', 'இப்போது பேசுவது எவ்வளவு கடினம்?'),
                options: [
                  ('mild', tr('A little', 'கொஞ்சம்'), null),
                  ('moderate', tr('Quite hard', 'கடினம்'), null),
                  ('severe', tr('Very hard', 'மிகக் கடினம்'), null),
                ],
                value: _severity,
                onChanged: (v) => setState(() => _severity = v),
              ),
              if (_error != null) ...[
                const Gap(AphSpace.md),
                FeedbackBanner(tone: FeedbackTone.error, title: _error!),
              ],
              const Gap(AphSpace.lg),
              AphButton(
                label: tr('Create account', 'கணக்கை உருவாக்கு'),
                icon: Icons.check_rounded,
                loading: _loading,
                onPressed: _create,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
