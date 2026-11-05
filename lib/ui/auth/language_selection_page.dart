import 'package:aphora/logic/comfort_settings.dart';
import 'package:aphora/logic/language_service.dart';
import 'package:aphora/logic/speech_service.dart';
import 'package:aphora/ui/auth/auth_shell.dart';
import 'package:aphora/ui/design/components.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// First-run welcome: choose a language (with spoken confirmation), then
/// continue to sign in. Previously this page existed but was never shown.
class LanguageSelectionPage extends StatelessWidget {
  const LanguageSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = ComfortSettings.instance;
    final t = Theme.of(context).textTheme;
    return ValueListenableBuilder<Language>(
      valueListenable: c.language,
      builder: (context, lang, _) => AphScaffold(
        bottom: AphButton(
          label: lang == Language.tamil ? 'தொடரவும்' : 'Continue',
          icon: Icons.arrow_forward_rounded,
          onPressed: () {
            c.onboarded.value = true;
            context.go('/login');
          },
        ),
        children: [
          const Gap(AphSpace.xl),
          const Center(child: AphoraMark(size: 88)),
          const Gap(AphSpace.lg),
          Text('Vernacura', style: t.displayMedium, textAlign: TextAlign.center),
          const Gap(AphSpace.xs),
          Text(
            'பேச்சுப் பயிற்சி, வீட்டிலேயே\nSpeech practice at home',
            style: t.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const Gap(AphSpace.xl),
          Text('மொழியைத் தேர்ந்தெடுக்கவும் · Choose your language',
              style: t.titleMedium, textAlign: TextAlign.center),
          const Gap(AphSpace.md),
          _LangCard(
            title: 'தமிழ்',
            subtitle: 'Tamil',
            selected: lang == Language.tamil,
            onTap: () {
              c.language.value = Language.tamil;
              SpeechService.shared
                  .speakText('தமிழ் தேர்ந்தெடுக்கப்பட்டது', language: 'ta-IN');
            },
          ),
          const Gap(AphSpace.sm),
          _LangCard(
            title: 'English',
            subtitle: 'ஆங்கிலம்',
            selected: lang == Language.english,
            onTap: () {
              c.language.value = Language.english;
              SpeechService.shared
                  .speakText('English selected', language: 'en-IN');
            },
          ),
          const Gap(AphSpace.lg),
          Text(
            lang == Language.tamil
                ? 'இதை பின்னர் "நான்" பக்கத்தில் மாற்றலாம்.'
                : 'You can change this later on the “Me” tab.',
            style: t.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _LangCard extends StatelessWidget {
  const _LangCard({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: AphCard(
        onTap: onTap,
        color: selected ? AphColors.primarySoft : AphColors.surface,
        borderColor: selected ? AphColors.primary : AphColors.border,
        semanticLabel: '$title, $subtitle',
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: t.headlineSmall),
                  Text(subtitle, style: t.bodyMedium),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: selected ? AphColors.primary : AphColors.inkMuted,
              size: 30,
            ),
          ],
        ),
      ),
    );
  }
}
