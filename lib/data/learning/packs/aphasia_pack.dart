import 'dart:math';

import 'package:aphora/data/intake/condition.dart';
import 'package:aphora/data/learning/aphasia_content.dart';
import 'package:aphora/data/learning/packs/condition_pack.dart';
import 'package:aphora/data/learning/practice_catalog.dart';
import 'package:aphora/logic/language_service.dart';
import 'package:flutter/material.dart';

/// Adult aphasia pack (after a stroke). Content: `aphasia_content.dart`,
/// organised by the classic therapy hierarchy — automatic speech →
/// repetition → naming with cues → sentence completion → functional
/// phrases — plus slow "clear speech" for slurred speech, Picture match as
/// auditory comprehension, and "Copy the voice" with the bundled adult
/// Tamil recordings or Family Voice.
class AphasiaPack extends ConditionPack {
  const AphasiaPack();

  @override
  Condition get condition => Condition.adultAphasia;

  @override
  bool get forChildren => false;

  @override
  List<PracticeKind> get speakingKinds => const [
        PracticeKind.automatic,
        PracticeKind.repetition,
        PracticeKind.naming,
        PracticeKind.completion,
        PracticeKind.functional,
        PracticeKind.clearSpeech,
        PracticeKind.phonetic,
      ];

  @override
  String title(PracticeKind kind) => switch (kind) {
        PracticeKind.naming =>
          tr('Name the picture', 'படத்தின் பெயரைச் சொல்லுங்கள்'),
        PracticeKind.phonetic =>
          tr('Copy the voice', 'குரலைப் போலச் சொல்லுங்கள்'),
        PracticeKind.assessment => tr('Speech check-up', 'பேச்சு மதிப்பீடு'),
        _ => kind.title,
      };

  @override
  String description(PracticeKind kind) => switch (kind) {
        PracticeKind.naming => tr(
            'Find the word for the picture — hints: meaning, first sound, the word',
            'படத்துக்கான சொல்லைச் சொல்லுங்கள் — குறிப்புகள்: பொருள், முதல் ஒலி, சொல்'),
        PracticeKind.phonetic => tr(
            'Hear a familiar voice, then say it the same way',
            'பழக்கமான குரலைக் கேட்டு, அதே போலச் சொல்லுங்கள்'),
        PracticeKind.assessment => tr(
            '20 short items to find a good starting level',
            'சரியான தொடக்க நிலையை அறிய 20 சிறு கேள்விகள்'),
        _ => kind.description,
      };

  @override
  String get matchTitle => tr('Listen and point', 'கேட்டுச் சுட்டுங்கள்');

  @override
  String get matchDescription => tr(
      'Hear a word or a question, then tap the right picture — no speaking needed',
      'சொல்லையோ கேள்வியையோ கேட்டு, சரியான படத்தைத் தட்டுங்கள் — பேச வேண்டியதில்லை');

  /// Items per session (about 2–4 minutes each).
  static const sessionSize = {
    AphasiaTask.automatic: 6,
    AphasiaTask.repetition: 8,
    AphasiaTask.naming: 10,
    AphasiaTask.completion: 8,
    AphasiaTask.functional: 8,
    AphasiaTask.clearSpeech: 8,
  };

  static AphasiaTask? taskFor(PracticeKind kind) => switch (kind) {
        PracticeKind.automatic || PracticeKind.letters => AphasiaTask.automatic,
        PracticeKind.repetition || PracticeKind.words => AphasiaTask.repetition,
        PracticeKind.naming => AphasiaTask.naming,
        PracticeKind.completion => AphasiaTask.completion,
        PracticeKind.functional || PracticeKind.sentences => AphasiaTask.functional,
        PracticeKind.clearSpeech || PracticeKind.drill => AphasiaTask.clearSpeech,
        PracticeKind.phonetic || PracticeKind.assessment => null,
      };

  @override
  List<PracticeItem> items(
    PracticeKind kind, {
    required int level,
    required Language language,
  }) {
    final ta = language == Language.tamil;
    if (kind == PracticeKind.phonetic) {
      return PracticeCatalog.fromFamilyOrBundled(recordable(language));
    }
    if (kind == PracticeKind.assessment) return checkUp(language);
    final task = taskFor(kind)!;
    return [
      for (final e in pick(task, level, sessionSize[task]!)) item(e, ta),
    ];
  }

  /// [count] entries of [task]: all of [level] first (shuffled), then the
  /// levels below it, then above it, so a session is never short.
  static List<AphasiaEntry> pick(
    AphasiaTask task,
    int level,
    int count, {
    Random? random,
  }) {
    final l = level.clamp(1, 3);
    final all = aphasiaEntries(task);
    List<AphasiaEntry> at(int n) =>
        all.where((e) => e.level == n).toList()..shuffle(random);
    return [
      ...at(l),
      for (var n = l - 1; n >= 1; n--) ...at(n),
      for (var n = l + 1; n <= 3; n++) ...at(n),
    ].take(count).toList();
  }

  static String itemId(AphasiaEntry e) => 'aph_${e.task.name}_${e.id}';

  /// One entry as a practice item in Tamil ([ta]) or English.
  static PracticeItem item(AphasiaEntry e, bool ta, {bool? hide}) {
    final target = ta ? e.ta : e.en;
    final prompt = ta ? e.promptTa : e.promptEn;
    final cue = ta ? e.cueTa : e.cueEn;
    final completion = e.task == AphasiaTask.completion;
    return PracticeItem(
      id: itemId(e),
      target: target,
      alternates: [
        ...(ta ? [...e.taAlt, e.en] : e.enAlt),
        // Saying the whole sentence also counts.
        if (completion && prompt != null) prompt.replaceAll('___', target),
      ],
      meaning: ta
          ? (completion
              ? e.promptEn!.replaceAll('___', e.en)
              : (e.glossEn ?? e.en))
          : null,
      imagePath: e.image == null ? null : e.picturePath,
      icon: e.icon,
      locale: ta ? 'ta-IN' : 'en-IN',
      hideTarget:
          hide ?? (e.task == AphasiaTask.naming || completion),
      semanticCue: cue,
      prompt: prompt,
      instruction: switch (e.task) {
        AphasiaTask.automatic => tr('Say it along:', 'சேர்ந்து சொல்லுங்கள்:'),
        AphasiaTask.completion =>
          tr('Finish the sentence:', 'வாக்கியத்தை முடியுங்கள்:'),
        AphasiaTask.clearSpeech => tr('Say it slowly, part by part:',
            'மெதுவாக, பகுதி பகுதியாகச் சொல்லுங்கள்:'),
        _ => null,
      },
    );
  }

  /// The 20-item adult check-up, in order.
  static List<PracticeItem> checkUp(Language language) {
    final ta = language == Language.tamil;
    return [
      for (final (i, (task, id)) in aphasiaCheckUp.indexed)
        () {
          final e = aphasiaEntries(task).firstWhere((e) => e.id == id);
          final base = item(e, ta);
          return PracticeItem(
            id: 'aph_check_$i',
            target: base.target,
            alternates: base.alternates,
            meaning: base.meaning,
            imagePath: base.imagePath,
            icon: base.icon,
            locale: base.locale,
            hideTarget: base.hideTarget,
            semanticCue: base.semanticCue,
            prompt: base.prompt,
            instruction: base.instruction,
            familyKey: base.voiceKey,
          );
        }(),
    ];
  }

  /// Everything Family Voice can record and "Copy the voice" can use.
  static List<PracticeItem> recordable(Language language) => [
        for (final s in const AphasiaPack().familyVoiceSets(language: language))
          ...s.items,
      ];

  @override
  List<MatchRound> matchRounds({
    required int level,
    required Language language,
    int count = 10,
    Random? random,
  }) {
    final ta = language == Language.tamil;
    final l = level.clamp(1, 3);
    final pool = [
      for (final e in aphasiaNaming)
        if (l > 1 || e.level <= 2)
          MatchCard(
            id: 'aph_${e.id}',
            label: ta ? e.ta : e.en,
            category: e.category!,
            imagePath: e.image == null ? null : e.picturePath,
            icon: e.icon,
            question: ta ? e.cueTa : e.cueEn,
          ),
    ];
    // Level 1: hear the word, distractors from other groups. Level 2:
    // distractors from the same group (cup vs plate). Level 3: hear a
    // description and point.
    return buildMatchRounds(
      pool,
      count: count,
      random: random,
      sameCategory: l >= 2,
      askQuestion: l >= 3,
    );
  }

  /// Slurred speech only (intake `a_kind` = slurred) puts clear speech
  /// first; both puts it after the language focus.
  static bool _dysarthriaFirst(List<String> focus) =>
      focus.isNotEmpty && focus.first == 'clear_speech';

  @override
  List<String> plan({required int level, List<String> focus = const []}) {
    if (_dysarthriaFirst(focus)) {
      return const ['clearSpeech', 'repetition', 'functional'];
    }
    final base = switch (level.clamp(1, 3)) {
      1 => const ['automatic', 'repetition', 'functional', ConditionPack.pictureMatchId],
      2 => const ['repetition', 'naming', 'functional'],
      _ => const ['naming', 'completion', 'functional'],
    };
    if (!focus.contains('clear_speech')) return base;
    return [
      ...base.where((id) => id != ConditionPack.pictureMatchId),
      'clearSpeech',
    ];
  }

  @override
  PracticeKind recommendedKind({
    required int level,
    List<String> focus = const [],
  }) {
    if (_dysarthriaFirst(focus)) return PracticeKind.clearSpeech;
    return switch (level.clamp(1, 3)) {
      1 => PracticeKind.automatic,
      2 => PracticeKind.repetition,
      _ => PracticeKind.naming,
    };
  }

  @override
  List<VoiceSet> familyVoiceSets({required Language language}) {
    final ta = language == Language.tamil;
    return [
      VoiceSet(
        id: 'words',
        label: tr('Picture words', 'படச் சொற்கள்'),
        icon: Icons.image_rounded,
        items: [for (final e in aphasiaNaming) item(e, ta, hide: false)],
        progress: (d, n) =>
            tr('$d of $n words recorded', '$n சொற்களில் $d பதிவாகியுள்ளன'),
      ),
      VoiceSet(
        id: 'needs',
        label: tr('Everyday needs', 'அன்றாடத் தேவைகள்'),
        icon: Icons.volunteer_activism_rounded,
        items: [for (final e in aphasiaFunctional) item(e, ta)],
        progress: (d, n) =>
            tr('$d of $n phrases recorded', '$n தொடர்களில் $d பதிவாகியுள்ளன'),
      ),
      VoiceSet(
        id: 'sentences',
        label: tr('Sentences', 'வாக்கியங்கள்'),
        icon: Icons.forum_rounded,
        items: [
          for (final e in aphasiaRepetition)
            if (e.level >= 2) item(e, ta),
        ],
        progress: (d, n) => tr('$d of $n sentences recorded',
            '$n வாக்கியங்களில் $d பதிவாகியுள்ளன'),
      ),
    ];
  }

  @override
  String checkUpAdvice(int level) => switch (level) {
        1 => tr(
            'Start with familiar sequences, repeating words and everyday needs.',
            'பழகிய வரிசைகள், சொற்களைத் திருப்பிச் சொல்வது, அன்றாடத் தேவைகளுடன் தொடங்குங்கள்.'),
        2 => tr('Start with repeating phrases and naming pictures.',
            'தொடர்களைத் திருப்பிச் சொல்வதும் படங்களின் பெயர் சொல்வதும் கொண்டு தொடங்குங்கள்.'),
        _ => tr(
            'Ready for sentences: naming, finishing sentences and everyday requests.',
            'வாக்கியங்களுக்குத் தயார்: பெயர் சொல்வது, வாக்கியங்களை முடிப்பது, அன்றாடக் கோரிக்கைகள்.'),
      };
}
