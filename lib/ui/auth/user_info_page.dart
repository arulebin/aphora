import 'package:aphora/data/database_service/user_database_service.dart';
import 'package:aphora/data/intake/condition.dart';
import 'package:aphora/data/intake/intake_questions.dart';
import 'package:aphora/data/learning/child_profile.dart';
import 'package:aphora/logic/comfort_settings.dart';
import 'package:aphora/logic/language_service.dart';
import 'package:aphora/logic/locator.dart';
import 'package:aphora/ui/auth/auth_shell.dart';
import 'package:aphora/ui/design/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

/// Step 2 of 3: who will practise, their name/age, consent. Creates the
/// account; step 3 is the intake questionnaire (`IntakePage`), which picks
/// the condition pack and fills `aphasiaType` / `severityLevel`.
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

  /// 'child' | 'adult' | 'self' — the first intake question, asked here so
  /// the name/age/consent wording fits.
  String? _who;
  String? _gender;
  bool _consent = false;
  bool _loading = false;

  /// Bump when the consent text below changes.
  static const consentVersion = '2026-11-05-intake';
  String? _error;

  bool get _child => _who == 'child';
  bool get _self => _who == 'self';

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    super.dispose();
  }

  static IconData _whoIcon(String v) => switch (v) {
        'child' => Icons.child_care_rounded,
        'adult' => Icons.elderly_rounded,
        _ => Icons.person_rounded,
      };

  String _genderLabel(String v) => _child
      ? ChildProfile.gender(v)
      : switch (v) {
          'Male' => tr('Man', 'ஆண்'),
          'Female' => tr('Woman', 'பெண்'),
          _ => tr('Other', 'மற்றவை'),
        };

  Future<void> _create() async {
    if (widget.phone.isEmpty) {
      context.go('/signup'); // Deep-linked without step 1.
      return;
    }
    if (_who == null) {
      setState(() => _error = tr('Please choose who this is for.',
          'இது யாருக்காக என்று தேர்ந்தெடுக்கவும்.'));
      return;
    }
    if (!_form.currentState!.validate()) return;
    if (_gender == null) {
      setState(
        () => _error = tr(
          'Please answer every question above.',
          'மேலே உள்ள அனைத்துக் கேள்விகளுக்கும் பதிலளிக்கவும்.',
        ),
      );
      return;
    }
    if (!_consent) {
      setState(
        () => _error = tr(
          'Please tick the box to agree before creating the account.',
          'கணக்கை உருவாக்கும் முன் ஒப்புதல் பெட்டியைத் தேர்வு செய்யவும்.',
        ),
      );
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final age = int.tryParse(_age.text.trim()) ?? 0;
      final created = await Locator.userDatabaseService.signUp(
        phone: widget.phone,
        password: widget.password,
        name: _name.text.trim(),
        age: age,
        gender: _gender!,
        // Filled from the questionnaire's answers on the next screens.
        aphasiaType: 'Not sure',
        severityLevel: '',
        condition: _child ? Condition.childSpeechDelay : Condition.unknown,
      );
      await Locator.userDatabaseService.recordParentConsent(
        created.uid,
        version: consentVersion,
      );
      // A parent or carer practises alongside: start with the hand-over
      // screen and helper log switched on (not when signing up for oneself).
      ComfortSettings.instance.assistedMode.value = !_self;
      if (mounted) {
        context.go('/intake', extra: {
          'who': _who,
          'age': age,
          'fromSignUp': true,
        });
      }
    } on AuthFailure catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(
        () => _error = tr(
          'Could not create the account. Please try again.',
          'கணக்கை உருவாக்க முடியவில்லை.',
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final whoQuestion = IntakeQuestionnaire.byId('who')!;
    return AuthShell(
      title: tr('Who will practise?', 'யார் பயிற்சி செய்யப் போகிறார்கள்?'),
      subtitle: tr(
        'Step 2 of 3 · Next, a few questions to choose the right exercises.',
        'படி 2/3 · அடுத்து, சரியான பயிற்சிகளைத் தேர்ந்தெடுக்கச் சில கேள்விகள்.',
      ),
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
              const StepProgress(current: 2, total: 3),
              const Gap(AphSpace.lg),
              ChoiceGroup<String>(
                label: whoQuestion.prompt.text,
                options: [
                  for (final o in whoQuestion.options)
                    (o.value, o.label.text, _whoIcon(o.value)),
                ],
                value: _who,
                onChanged: (v) => setState(() {
                  _who = v;
                  _error = null;
                }),
              ),
              if (_who != null) ...[
                const Gap(AphSpace.lg),
                AphTextField(
                  controller: _name,
                  label: _child
                      ? tr("Child's name", 'குழந்தையின் பெயர்')
                      : _self
                          ? tr('Your name', 'உங்கள் பெயர்')
                          : tr("Person's name", 'அவரது பெயர்'),
                  icon: Icons.badge_rounded,
                  textCapitalization: TextCapitalization.words,
                  validator: (v) => (v ?? '').trim().length < 2
                      ? tr('Please enter a name.', 'பெயரை உள்ளிடவும்.')
                      : null,
                ),
                const Gap(AphSpace.md),
                AphTextField(
                  controller: _age,
                  label: tr('Age in years', 'வயது (ஆண்டுகள்)'),
                  icon: Icons.cake_rounded,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(3),
                  ],
                  validator: (v) {
                    final n = int.tryParse(v ?? '');
                    final (lo, hi) = _child ? (2, 18) : (18, 110);
                    return n == null || n < lo || n > hi
                        ? tr('Enter an age between $lo and $hi.',
                            '$lo முதல் $hi வரை வயதை உள்ளிடவும்.')
                        : null;
                  },
                ),
                const Gap(AphSpace.lg),
                ChoiceGroup<String>(
                  label: _child
                      ? tr('Your child is a', 'உங்கள் குழந்தை')
                      : tr('Gender', 'பாலினம்'),
                  options: [
                    for (final g in ChildProfile.genders)
                      (g, _genderLabel(g), null),
                  ],
                  value: _gender,
                  onChanged: (v) => setState(() => _gender = v),
                ),
                const Gap(AphSpace.lg),
                AphCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AphSpace.xs,
                    vertical: AphSpace.xs,
                  ),
                  // Transparent Material so the tile's ink isn't hidden by
                  // the card's decoration (Flutter asserts on that).
                  child: Material(
                    type: MaterialType.transparency,
                    child: CheckboxListTile(
                      key: const Key('parent-consent'),
                      value: _consent,
                      onChanged: (v) => setState(() => _consent = v ?? false),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AphSpace.xs,
                      ),
                      title: Text(
                        _child
                            ? tr(
                                "I am this child's parent or guardian, and I agree",
                                'நான் இந்தக் குழந்தையின் பெற்றோர் / பாதுகாவலர், நான் ஒப்புக்கொள்கிறேன்',
                              )
                            : tr(
                                'I am this person or their carer, and I agree',
                                'நானே அந்த நபர் அல்லது அவரைக் கவனித்துக்கொள்பவர், நான் ஒப்புக்கொள்கிறேன்',
                              ),
                      ),
                      subtitle: Text(
                        tr(
                          'Vernacura saves the name, age, questionnaire answers and practice results to show progress, and shares them only with the therapist you link. '
                              'Family Voice recordings stay on this phone. You can delete the account at any time from Me.',
                          'முன்னேற்றத்தைக் காட்ட பெயர், வயது, கேள்வித்தாள் பதில்கள், பயிற்சி முடிவுகளை Vernacura சேமிக்கிறது; நீங்கள் இணைக்கும் சிகிச்சையாளருடன் மட்டுமே பகிரப்படும். '
                              'குடும்பக் குரல் பதிவுகள் இந்தத் தொலைபேசியிலேயே இருக்கும். "நான்" பக்கத்தில் எப்போது வேண்டுமானாலும் கணக்கை நீக்கலாம்.',
                        ),
                      ),
                    ),
                  ),
                ),
              ],
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
