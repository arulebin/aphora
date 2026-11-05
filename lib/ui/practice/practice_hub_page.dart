import 'package:aphora/data/learning/practice_catalog.dart';
import 'package:aphora/data/models/usermodel.dart';
import 'package:aphora/logic/comfort_settings.dart';
import 'package:aphora/logic/family_voice_store.dart';
import 'package:aphora/logic/language_service.dart';
import 'package:aphora/logic/locator.dart';
import 'package:aphora/ui/design/components.dart';
import 'package:aphora/ui/practice/family_voice_page.dart';
import 'package:aphora/ui/practice/picture_match_page.dart';
import 'package:aphora/ui/practice/practice_session_page.dart';
import 'package:flutter/material.dart';

/// All exercises, grouped by what they train. Replaces the old
/// "Clinical Assessment" tab with its Easy/Medium/Hard levels.
class PracticeHubPage extends StatelessWidget {
  const PracticeHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<UserModel?>(
      valueListenable: Locator.userDatabaseService.currentUser,
      builder: (context, user, _) {
        final recommended = PracticeCatalog.kindForFocus(user?.recommendedFocus);
        Widget tile(
          PracticeKind kind,
          Color color,
          Color soft,
        ) =>
            Padding(
              padding: const EdgeInsets.only(bottom: AphSpace.sm),
              child: ActionTile(
                icon: kind.icon,
                title: kind.title,
                subtitle: kind.description,
                color: color,
                softColor: soft,
                badge: user?.recommendedFocus != null && kind == recommended
                    ? tr('Recommended for you', 'உங்களுக்குப் பரிந்துரை')
                    : null,
                onTap: () => openPractice(context, kind),
              ),
            );

        return AphScaffold(
          title: tr('Practice', 'பயிற்சி'),
          showBack: false,
          children: [
            Text(
              tr('Short, focused exercises. Do a little every day — regular practice matters more than long sessions.',
                  'சிறிய பயிற்சிகள். தினமும் கொஞ்சம் செய்யுங்கள் — நீண்ட அமர்வுகளை விட தொடர்ச்சியே முக்கியம்.'),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const Gap(AphSpace.md),
            const _ParentModeSwitch(),
            const Gap(AphSpace.sm),
            ValueListenableBuilder<Set<String>>(
              valueListenable: FamilyVoiceStore.instance.recorded,
              builder: (context, _, _) {
                final words = PracticeCatalog.familyWords();
                final done = FamilyVoiceStore.instance
                    .countRecorded(words.map((w) => w.voiceKey));
                return ActionTile(
                  key: const ValueKey('hub_family_voice'),
                  icon: Icons.record_voice_over_rounded,
                  title: tr('Family Voice', 'குடும்பக் குரல்'),
                  subtitle: tr(
                      'Record words in your own voice · $done of ${words.length} words recorded',
                      'உங்கள் குரலில் சொற்களைப் பதிவு செய்யுங்கள் · ${words.length} இல் $done'),
                  color: AphColors.accent,
                  softColor: AphColors.accentSoft,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FamilyVoicePage()),
                  ),
                );
              },
            ),
            SectionHeader(tr('Speaking', 'பேசுதல்')),
            tile(PracticeKind.letters, AphColors.letters, AphColors.lettersSoft),
            tile(PracticeKind.words, AphColors.words, AphColors.wordsSoft),
            tile(PracticeKind.naming, AphColors.naming, AphColors.namingSoft),
            tile(PracticeKind.sentences, AphColors.sentences, AphColors.sentencesSoft),
            tile(PracticeKind.phonetic, AphColors.primary, AphColors.primarySoft),
            SectionHeader(tr('Understanding', 'புரிந்துகொள்ளுதல்')),
            Padding(
              padding: const EdgeInsets.only(bottom: AphSpace.sm),
              child: ActionTile(
                icon: Icons.grid_view_rounded,
                title: tr('Picture match', 'படப் பொருத்தம்'),
                subtitle: tr('Hear a word and tap its picture — no speaking needed',
                    'சொல்லைக் கேட்டு படத்தைத் தட்டுங்கள் — பேச வேண்டியதில்லை'),
                color: AphColors.info,
                softColor: AphColors.infoSoft,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PictureMatchPage()),
                ),
              ),
            ),
            SectionHeader(tr('Check-up', 'மதிப்பீடு')),
            ActionTile(
              icon: PracticeKind.assessment.icon,
              title: PracticeKind.assessment.title,
              subtitle: user?.preAssessmentScore == null
                  ? PracticeKind.assessment.description
                  : tr('Last score ${user!.preAssessmentScore!.round()} — retake to update your plan',
                      'கடைசி மதிப்பெண் ${user.preAssessmentScore!.round()} — திட்டத்தைப் புதுப்பிக்க மீண்டும் எடுங்கள்'),
              color: AphColors.accent,
              softColor: AphColors.accentSoft,
              onTap: () => openPractice(context, PracticeKind.assessment),
            ),
          ],
        );
      },
    );
  }
}

/// Parent mode = the existing assisted mode, reworded for families: big
/// pictures, few words, stars after each correct try.
class _ParentModeSwitch extends StatelessWidget {
  const _ParentModeSwitch();

  @override
  Widget build(BuildContext context) {
    final mode = ComfortSettings.instance.assistedMode;
    return ValueListenableBuilder<bool>(
      valueListenable: mode,
      builder: (context, on, _) => AphCard(
        padding: EdgeInsets.zero,
        child: Material(
          type: MaterialType.transparency,
          child: SwitchListTile(
            key: const ValueKey('hub_parent_mode'),
            value: on,
            onChanged: (v) => mode.value = v,
            secondary: const Icon(Icons.family_restroom_rounded,
                color: AphColors.accent),
            title: Text(tr('Practise together (parent mode)',
                'சேர்ந்து பயிற்சி (பெற்றோர் முறை)')),
            subtitle: Text(tr('Big pictures and stars for your child',
                'குழந்தைக்குப் பெரிய படங்களும் நட்சத்திரங்களும்')),
          ),
        ),
      ),
    );
  }
}
