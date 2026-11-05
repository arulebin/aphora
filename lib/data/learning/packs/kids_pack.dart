import 'dart:math';

import 'package:aphora/data/intake/condition.dart';
import 'package:aphora/data/intake/intake_questions.dart';
import 'package:aphora/data/learning/kids_words.dart';
import 'package:aphora/data/learning/packs/condition_pack.dart';
import 'package:aphora/data/learning/practice_catalog.dart';
import 'package:aphora/logic/language_service.dart';
import 'package:flutter/material.dart';

/// Children's speech delay pack: the content in [PracticeCatalog] and
/// [kidWords]. Also the general set for accounts without a pack of their
/// own (`Condition.unknown`, and packs still being built).
class KidsPack extends ConditionPack {
  const KidsPack();

  @override
  Condition get condition => Condition.childSpeechDelay;

  @override
  bool get forChildren => true;

  @override
  bool get offersSoundDrill => true;

  @override
  List<PracticeKind> get speakingKinds => const [
        PracticeKind.letters,
        PracticeKind.words,
        PracticeKind.naming,
        PracticeKind.sentences,
        PracticeKind.phonetic,
      ];

  /// The children's sets ignore the level inside a session (words already
  /// start with early sounds); the level picks Today's plan.
  @override
  List<PracticeItem> items(
    PracticeKind kind, {
    required int level,
    required Language language,
  }) =>
      PracticeCatalog.items(kind, language: language);

  @override
  List<MatchRound> matchRounds({
    required int level,
    required Language language,
    int count = 10,
    Random? random,
  }) {
    final ta = language == Language.tamil;
    return buildMatchRounds(
      [
        for (final w in kidWords)
          MatchCard(
            id: w.id,
            label: ta ? w.ta : w.en,
            category: w.category.name,
            emoji: w.emoji,
          ),
      ],
      count: count,
      random: random,
    );
  }

  @override
  List<String> plan({required int level, List<String> focus = const []}) =>
      switch (level) {
        1 => const ['letters', 'words', ConditionPack.pictureMatchId],
        3 => const ['words', 'sentences', 'naming'],
        _ => const ['letters', 'words', 'naming'],
      };

  @override
  PracticeKind recommendedKind({
    required int level,
    List<String> focus = const [],
  }) =>
      PracticeCatalog.kindForFocus(StartLevel.legacyFocus[(level - 1).clamp(0, 2)]);

  @override
  List<VoiceSet> familyVoiceSets({required Language language}) => [
        VoiceSet(
          id: 'words',
          label: tr('Words', 'சொற்கள்'),
          icon: Icons.image_rounded,
          items: PracticeCatalog.familyWords(language: language),
          progress: (d, n) =>
              tr('$d of $n words recorded', '$n சொற்களில் $d பதிவாகியுள்ளன'),
        ),
        VoiceSet(
          id: 'sounds',
          label: tr('Sounds', 'ஒலிகள்'),
          icon: Icons.abc_rounded,
          items: PracticeCatalog.familySounds(language: language),
          progress: (d, n) =>
              tr('$d of $n sounds recorded', '$n ஒலிகளில் $d பதிவாகியுள்ளன'),
        ),
        VoiceSet(
          id: 'sentences',
          label: tr('Sentences', 'வாக்கியங்கள்'),
          icon: Icons.forum_rounded,
          items: PracticeCatalog.familySentences(language: language),
          progress: (d, n) => tr('$d of $n sentences recorded',
              '$n வாக்கியங்களில் $d பதிவாகியுள்ளன'),
        ),
      ];

  @override
  String checkUpAdvice(int level) => switch (level) {
        1 => tr('Begin with letter sounds to build a strong base.',
            'வலுவான அடித்தளத்திற்கு எழுத்து ஒலிகளுடன் தொடங்குங்கள்.'),
        2 => tr('Your child is ready for single words with pictures.',
            'படங்களுடன் தனிச் சொற்களுக்கு உங்கள் குழந்தை தயார்.'),
        _ => tr('Your child is ready for short everyday sentences.',
            'சிறு அன்றாட வாக்கியங்களுக்கு உங்கள் குழந்தை தயார்.'),
      };
}
