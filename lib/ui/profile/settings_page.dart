import 'package:aphora/logic/comfort_settings.dart';
import 'package:aphora/logic/language_service.dart';
import 'package:aphora/logic/locator.dart';
import 'package:aphora/logic/speech_service.dart';
import 'package:aphora/ui/design/components.dart';
import 'package:flutter/material.dart';

/// Comfort (accessibility) settings. Every change applies immediately and
/// is remembered on this device.
class ComfortSettingsSection extends StatelessWidget {
  const ComfortSettingsSection({super.key, this.showAssisted = true});
  final bool showAssisted;

  @override
  Widget build(BuildContext context) {
    final c = ComfortSettings.instance;
    final t = Theme.of(context).textTheme;
    return ListenableBuilder(
      listenable: c.any,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(tr('Language', 'மொழி')),
          AphCard(
            child: ChoiceGroup<Language>(
              label: tr('App and exercise language', 'செயலி மற்றும் பயிற்சி மொழி'),
              options: const [
                (Language.tamil, 'தமிழ்', Icons.translate_rounded),
                (Language.english, 'English', Icons.translate_rounded),
              ],
              value: c.language.value,
              onChanged: (l) {
                c.language.value = l;
                Locator.userDatabaseService
                    .setLanguagePreference(l == Language.tamil ? 'Tamil' : 'English')
                    .catchError((_) {});
              },
            ),
          ),
          SectionHeader(
            tr('Comfort', 'வசதி'),
            subtitle: tr('Make Vernacura easier to see, hear and use.',
                'பார்க்க, கேட்க, பயன்படுத்த எளிதாக்குங்கள்.'),
          ),
          AphCard(
            padding: const EdgeInsets.symmetric(
              horizontal: AphSpace.md,
              vertical: AphSpace.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SliderRow(
                  icon: Icons.format_size_rounded,
                  title: tr('Text size', 'எழுத்து அளவு'),
                  valueLabel: '${(c.textScale.value * 100).round()}%',
                  value: c.textScale.value,
                  min: 1.0,
                  max: 1.6,
                  divisions: 6,
                  onChanged: (v) => c.textScale.value = v,
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: AphSpace.sm),
                  child: Text(
                    tr('Preview: வணக்கம் — Hello', 'மாதிரி: வணக்கம் — Hello'),
                    style: t.bodyLarge,
                  ),
                ),
                const Divider(),
                _SliderRow(
                  icon: Icons.speed_rounded,
                  title: tr('Speaking speed', 'பேச்சு வேகம்'),
                  valueLabel: c.speechRate.value < 0.38
                      ? tr('Slow', 'மெதுவாக')
                      : c.speechRate.value < 0.5
                          ? tr('Relaxed', 'நிதானம்')
                          : tr('Normal', 'சாதாரணம்'),
                  value: c.speechRate.value,
                  min: 0.25,
                  max: 0.6,
                  divisions: 7,
                  onChanged: (v) => c.speechRate.value = v,
                  onChangeEnd: (_) => SpeechService.shared.speakText(
                    tr('This is how I will speak.', 'நான் இப்படிப் பேசுவேன்.'),
                  ),
                ),
                const Divider(),
                _SliderRow(
                  icon: Icons.hourglass_bottom_rounded,
                  title: tr('Time to answer', 'பதிலளிக்க நேரம்'),
                  subtitle: tr('How long a pause ends your answer',
                      'எவ்வளவு இடைநிறுத்தம் பதிலை முடிக்கும்'),
                  valueLabel: tr('${c.listenPauseSeconds.value} s pause',
                      '${c.listenPauseSeconds.value} வி'),
                  value: c.listenPauseSeconds.value.toDouble(),
                  min: 2,
                  max: 8,
                  divisions: 6,
                  onChanged: (v) {
                    c.listenPauseSeconds.value = v.round();
                    c.listenMaxSeconds.value = (v.round() * 5).clamp(15, 40);
                  },
                ),
                const Divider(),
                _SwitchRow(
                  icon: Icons.record_voice_over_rounded,
                  title: tr('Read instructions aloud', 'வழிமுறைகளை உரக்கப் படி'),
                  subtitle: tr('Each exercise speaks its prompt automatically',
                      'ஒவ்வொரு பயிற்சியும் தானாகப் பேசும்'),
                  value: c.autoReadAloud.value,
                  onChanged: (v) => c.autoReadAloud.value = v,
                ),
                const Divider(),
                _SwitchRow(
                  icon: Icons.contrast_rounded,
                  title: tr('High contrast', 'உயர் மாறுபாடு'),
                  value: c.highContrast.value,
                  onChanged: (v) => c.highContrast.value = v,
                ),
                const Divider(),
                _SwitchRow(
                  icon: Icons.motion_photos_off_rounded,
                  title: tr('Reduce motion', 'அசைவைக் குறை'),
                  subtitle: tr('Turn off pulsing and animations',
                      'துடிப்பு மற்றும் அனிமேஷனை அணை'),
                  value: c.reduceMotion.value,
                  onChanged: (v) => c.reduceMotion.value = v,
                ),
              ],
            ),
          ),
          if (showAssisted) ...[
            SectionHeader(
              tr('Helper', 'உதவியாளர்'),
              subtitle: tr(
                'For the parent, grandparent or volunteer who practises with the child.',
                'குழந்தையுடன் பயிற்சி செய்யும் பெற்றோர், தாத்தா பாட்டி அல்லது தன்னார்வலருக்கு.',
              ),
            ),
            AphCard(
              padding: const EdgeInsets.symmetric(
                horizontal: AphSpace.md,
                vertical: AphSpace.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SwitchRow(
                    icon: Icons.volunteer_activism_rounded,
                    title: tr('Assisted sessions', 'உதவியுடன் அமர்வுகள்'),
                    subtitle: tr('Adds a hand-over step and a note for the therapist',
                        'ஒப்படைப்பு படி மற்றும் சிகிச்சையாளருக்கான குறிப்பு'),
                    value: c.assistedMode.value,
                    onChanged: (v) => c.assistedMode.value = v,
                  ),
                  if (c.assistedMode.value) ...[
                    const Gap(AphSpace.sm),
                    _HelperName(initial: c.helperName.value),
                    const Gap(AphSpace.sm),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HelperName extends StatefulWidget {
  const _HelperName({required this.initial});
  final String initial;
  @override
  State<_HelperName> createState() => _HelperNameState();
}

class _HelperNameState extends State<_HelperName> {
  late final _c = TextEditingController(text: widget.initial)
    ..addListener(_save);

  // Save on every change so leaving the screen never loses the name.
  void _save() => ComfortSettings.instance.helperName.value = _c.text.trim();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AphTextField(
        controller: _c,
        label: tr("Helper's name", 'உதவியாளர் பெயர்'),
        hint: tr('e.g. Meena (ASHA worker)', 'எ.கா. மீனா'),
        icon: Icons.badge_rounded,
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.done,
      );
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    // The card paints its own white background, which would hide the
    // tile's ink ripple (and trips a ListTile assertion); a transparent
    // Material gives the ripple a surface above the card.
    return MergeSemantics(
      child: Material(
        type: MaterialType.transparency,
        child: SwitchListTile(
          contentPadding: EdgeInsets.zero,
          secondary: Icon(icon, color: AphColors.primary, size: 28),
          title: Text(title, style: Theme.of(context).textTheme.titleMedium),
          subtitle: subtitle == null
              ? null
              : Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
          value: value,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.icon,
    required this.title,
    required this.valueLabel,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
    this.subtitle,
    this.onChangeEnd,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String valueLabel;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;
  final ValueChanged<double>? onChangeEnd;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: AphSpace.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: AphColors.primary, size: 28),
              const Gap(AphSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: t.titleMedium),
                    if (subtitle != null) Text(subtitle!, style: t.bodySmall),
                  ],
                ),
              ),
              Text(valueLabel, style: t.labelLarge),
            ],
          ),
          Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            label: valueLabel,
            semanticFormatterCallback: (_) => '$title $valueLabel',
            onChanged: onChanged,
            onChangeEnd: onChangeEnd,
          ),
        ],
      ),
    );
  }
}
