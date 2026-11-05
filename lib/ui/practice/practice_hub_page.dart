import 'package:aphora/data/intake/condition.dart';
import 'package:aphora/data/learning/packs/condition_packs.dart';
import 'package:aphora/data/learning/practice_catalog.dart';
import 'package:aphora/data/models/usermodel.dart';
import 'package:aphora/logic/comfort_settings.dart';
import 'package:aphora/logic/family_voice_store.dart';
import 'package:aphora/logic/language_service.dart';
import 'package:aphora/logic/locator.dart';
import 'package:aphora/ui/design/components.dart';
import 'package:aphora/ui/design/voice_check_banner.dart';
import 'package:aphora/ui/practice/family_voice_page.dart';
import 'package:aphora/ui/practice/my_phrases_page.dart';
import 'package:aphora/ui/practice/practice_safety.dart';
import 'package:aphora/ui/practice/picture_match_page.dart';
import 'package:aphora/ui/practice/practice_session_page.dart';
import 'package:flutter/material.dart';

/// Colours per exercise, so a tile looks the same on every screen.
(Color, Color) kindColors(PracticeKind kind) => switch (kind) {
      PracticeKind.letters ||
      PracticeKind.automatic =>
        (AphColors.letters, AphColors.lettersSoft),
      PracticeKind.words ||
      PracticeKind.repetition =>
        (AphColors.words, AphColors.wordsSoft),
      PracticeKind.naming => (AphColors.naming, AphColors.namingSoft),
      PracticeKind.sentences ||
      PracticeKind.completion =>
        (AphColors.sentences, AphColors.sentencesSoft),
      PracticeKind.functional => (AphColors.accent, AphColors.accentSoft),
      PracticeKind.clearSpeech => (AphColors.info, AphColors.infoSoft),
      _ => (AphColors.primary, AphColors.primarySoft),
    };

/// All exercises of the person's condition pack, grouped by what they
/// train. Replaces the old "Clinical Assessment" tab with its
/// Easy/Medium/Hard levels.
class PracticeHubPage extends StatelessWidget {
  const PracticeHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<UserModel?>(
      valueListenable: Locator.userDatabaseService.currentUser,
      builder: (context, user, _) {
        final pack = ConditionPacks.forUser(user);
        final child = ConditionPacks.childWording(user);
        final recommended = pack.recommendedKind(
          level: user?.practiceLevel ?? 2,
          focus: user?.intake?.focus ?? const [],
        );
        // Only once something (intake, check-up, therapist) chose a level.
        final hasPlan = user != null &&
            (user.recommendedFocus != null ||
                user.intake != null ||
                user.therapistLevel != null);
        Widget tile(PracticeKind kind) {
          final (color, soft) = kindColors(kind);
          return Padding(
            padding: const EdgeInsets.only(bottom: AphSpace.sm),
            child: ActionTile(
              icon: pack.icon(kind),
              title: pack.title(kind),
              subtitle: pack.description(kind),
              color: color,
              softColor: soft,
              badge: hasPlan && kind == recommended
                  ? tr('Recommended for you', 'உங்களுக்குப் பரிந்துரை')
                  : null,
              onTap: () => openPractice(context, kind),
            ),
          );
        }

        final pending = user != null &&
            ConditionPacks.contentPending(user.activeCondition);

        return AphScaffold(
          title: tr('Practice', 'பயிற்சி'),
          showBack: false,
          children: [
            const VoiceCheckBanner(),
            if (pack.safetyLine case final line?) ...[
              FeedbackBanner(
                key: const ValueKey('hub_safety_line'),
                tone: pack.safetyFor(user) == PracticeSafety.hold
                    ? FeedbackTone.warning
                    : FeedbackTone.info,
                title: line,
              ),
              if (pack.safetyFor(user) == PracticeSafety.hold) ...[
                const Gap(AphSpace.sm),
                AphButton.secondary(
                  key: const ValueKey('hub_safety_confirm'),
                  label: careTeamSaidYes,
                  icon: Icons.health_and_safety_rounded,
                  onPressed: () => ensurePracticeSafety(context),
                ),
              ],
              const Gap(AphSpace.md),
            ],
            if (pending) ...[
              FeedbackBanner(
                tone: FeedbackTone.info,
                title: tr('Your exercises are being prepared',
                    'உங்களுக்கான பயிற்சிகள் தயாராகி வருகின்றன'),
                message: tr(
                  'Exercises for "${user.activeCondition.english}" are not ready yet. For now, use the general practice set below.',
                  '"${user.activeCondition.tamil}" பயிற்சிகள் இன்னும் தயாராகவில்லை. இப்போதைக்குக் கீழே உள்ள பொதுப் பயிற்சிகளைப் பயன்படுத்துங்கள்.',
                ),
              ),
              const Gap(AphSpace.md),
            ],
            Text(
              tr('Short, focused exercises. Do a little every day — regular practice matters more than long sessions.',
                  'சிறிய பயிற்சிகள். தினமும் கொஞ்சம் செய்யுங்கள் — நீண்ட அமர்வுகளை விட தொடர்ச்சியே முக்கியம்.'),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const Gap(AphSpace.md),
            _ParentModeSwitch(child: child),
            if (pack.condition == Condition.oralCancerRehab) ...[
              const Gap(AphSpace.sm),
              ActionTile(
                key: const ValueKey('hub_my_phrases'),
                icon: Icons.badge_rounded,
                title: tr('My phrases', 'என் சொற்றொடர்கள்'),
                subtitle: (user?.oralPersonal.isEmpty ?? true)
                    ? tr('Add your name, address and who to call — practise saying them',
                        'உங்கள் பெயர், முகவரி, யாரை அழைக்க வேண்டும் — சேர்த்துப் பயிற்சி செய்யுங்கள்')
                    : tr('${user!.oralPersonal.length} details added · tap to change',
                        '${user.oralPersonal.length} விவரங்கள் சேர்க்கப்பட்டன · மாற்றத் தட்டுங்கள்'),
                color: AphColors.primary,
                softColor: AphColors.primarySoft,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MyPhrasesPage()),
                ),
              ),
            ],
            const Gap(AphSpace.sm),
            ValueListenableBuilder<Set<String>>(
              valueListenable: FamilyVoiceStore.instance.recorded,
              builder: (context, _, _) {
                final words = pack
                    .familyVoiceSets(language: LanguageService.currentLanguage)
                    .first
                    .items;
                final done = FamilyVoiceStore.instance
                    .countRecorded(words.map((w) => w.voiceKey));
                return ActionTile(
                  key: const ValueKey('hub_family_voice'),
                  icon: Icons.record_voice_over_rounded,
                  title: tr('Family Voice', 'குடும்பக் குரல்'),
                  subtitle: child
                      ? tr(
                          'Record words in your own voice · $done of ${words.length} words recorded',
                          'உங்கள் குரலில் சொற்களைப் பதிவு செய்யுங்கள் · ${words.length} இல் $done')
                      : tr(
                          'Record words in a familiar voice · $done of ${words.length} words recorded',
                          'பழக்கமான குரலில் சொற்களைப் பதிவு செய்யுங்கள் · ${words.length} இல் $done'),
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
            for (final kind in pack.speakingKinds) tile(kind),
            if (pack.hasPictureMatch) ...[
              SectionHeader(tr('Understanding', 'புரிந்துகொள்ளுதல்')),
              Padding(
                padding: const EdgeInsets.only(bottom: AphSpace.sm),
                child: ActionTile(
                  icon: Icons.grid_view_rounded,
                  title: pack.matchTitle,
                  subtitle: pack.matchDescription,
                  color: AphColors.info,
                  softColor: AphColors.infoSoft,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PictureMatchPage()),
                  ),
                ),
              ),
            ],
            if (pack.hasCheckUp) ...[
              SectionHeader(tr('Check-up', 'மதிப்பீடு')),
              ActionTile(
                icon: pack.icon(PracticeKind.assessment),
                title: pack.title(PracticeKind.assessment),
                subtitle: pack.checkUpIsMeasure || user?.preAssessmentScore == null
                    ? pack.description(PracticeKind.assessment)
                    : tr('Last score ${user!.preAssessmentScore!.round()} — retake to update your plan',
                        'கடைசி மதிப்பெண் ${user.preAssessmentScore!.round()} — திட்டத்தைப் புதுப்பிக்க மீண்டும் எடுங்கள்'),
                color: AphColors.accent,
                softColor: AphColors.accentSoft,
                onTap: () => openPractice(context, PracticeKind.assessment),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Parent mode = the existing assisted mode, reworded for families: big
/// pictures, few words, stars after each correct try. For adults it is
/// carer mode: a hand-over screen and a helper note, no stars.
class _ParentModeSwitch extends StatelessWidget {
  const _ParentModeSwitch({required this.child});

  /// Children's wording.
  final bool child;

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
            title: Text(child
                ? tr('Practise together (parent mode)',
                    'சேர்ந்து பயிற்சி (பெற்றோர் முறை)')
                : tr('Practise with a helper (carer mode)',
                    'உதவியாளருடன் பயிற்சி (பராமரிப்பாளர் முறை)')),
            subtitle: Text(child
                ? tr('Big pictures and stars for your child',
                    'குழந்தைக்குப் பெரிய படங்களும் நட்சத்திரங்களும்')
                : tr('A hand-over screen to start and a note for the therapist at the end',
                    'தொடக்கத்தில் ஒப்படைப்புத் திரை, முடிவில் சிகிச்சையாளருக்கான குறிப்பு')),
          ),
        ),
      ),
    );
  }
}
