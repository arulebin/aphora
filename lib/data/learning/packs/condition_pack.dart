import 'dart:math';

import 'package:aphora/data/intake/condition.dart';
import 'package:aphora/data/learning/practice_catalog.dart';
import 'package:aphora/logic/language_service.dart';
import 'package:flutter/material.dart';

/// One condition's practice content and wording. The app asks the
/// signed-in person's pack (see `ConditionPacks.forUser`) for everything
/// that depends on the condition: which exercises the Practice hub shows,
/// their names, the items in a session, Picture match rounds, Today's
/// plan, Family Voice sets and the check-up advice. The practice engine
/// (`PracticeSessionPage`), scoring and storage are shared.
///
/// To add a pack (e.g. oral-cancer rehab): implement this class in
/// `lib/data/learning/packs/<name>_pack.dart` and add one entry to
/// `ConditionPacks.builtIn` in `condition_packs.dart` (or call
/// `ConditionPacks.register` at start-up). Until a pack is registered its
/// condition falls back to [KidsPack]-style general practice and the app
/// says the exercises are being prepared.
///
/// Levels are 1 (easiest) to 3 — the intake's start level, a measured
/// check-up, or the therapist's choice (`UserModel.practiceLevel`).
abstract class ConditionPack {
  const ConditionPack();

  /// The condition this pack serves.
  Condition get condition;

  /// Children's wording (parent mode, stars, "your child"). False → adult
  /// wording (helper/carer, a calm "well done", no stars).
  bool get forChildren;

  /// Speaking exercises on the Practice hub, in order. `assessment`
  /// (check-up) and Picture match are shown separately when
  /// [hasCheckUp] / [hasPictureMatch].
  List<PracticeKind> get speakingKinds;

  bool get hasPictureMatch => true;
  bool get hasCheckUp => true;

  /// The "Practise tricky sounds" letter drill after a session.
  bool get offersSoundDrill => false;

  /// Screen name of an exercise, in the app language.
  String title(PracticeKind kind) => kind.title;

  /// One-line description on the Practice hub, in the app language.
  String description(PracticeKind kind) => kind.description;

  int minutes(PracticeKind kind) => kind.minutes;

  IconData icon(PracticeKind kind) => kind.icon;

  /// Picture match tile (listening comprehension).
  String get matchTitle => tr('Picture match', 'படப் பொருத்தம்');
  String get matchDescription => tr(
      'Hear a word and tap its picture — no speaking needed',
      'சொல்லைக் கேட்டு படத்தைத் தட்டுங்கள் — பேச வேண்டியதில்லை');

  /// Items for one session of [kind] at [level] (1–3) in [language].
  /// `PracticeKind.drill` is built from the session's tricky sounds and
  /// is not asked for here.
  List<PracticeItem> items(
    PracticeKind kind, {
    required int level,
    required Language language,
  });

  /// Picture match rounds (listen → tap the picture) at [level].
  List<MatchRound> matchRounds({
    required int level,
    required Language language,
    int count = 10,
    Random? random,
  });

  /// Today's plan: [PracticeKind.id]s, or [pictureMatchId] for Picture
  /// match, in order. About 10 minutes in total.
  List<String> plan({required int level, List<String> focus = const []});

  /// The exercise marked "Recommended for you" on the hub.
  PracticeKind recommendedKind({
    required int level,
    List<String> focus = const [],
  });

  /// What can be recorded in Family Voice, as tabs.
  List<VoiceSet> familyVoiceSets({required Language language});

  /// Check-up result advice for a start level (1–3), in the app language.
  String checkUpAdvice(int level);

  /// Plan id for Picture match.
  static const pictureMatchId = 'picture';
}

/// One picture in Picture match. Labels are already in the session
/// language.
class MatchCard {
  const MatchCard({
    required this.id,
    required this.label,
    required this.category,
    this.emoji,
    this.imagePath,
    this.icon,
    this.question,
  }) : assert(emoji != null || imagePath != null || icon != null);

  /// Stable id; attempts are stored as `match_<id>`.
  final String id;

  /// The word for this picture.
  final String label;

  /// Distractors are chosen by category.
  final String category;

  final String? emoji;
  final String? imagePath;
  final IconData? icon;

  /// A description to answer by pointing ("Which one do we drink tea
  /// from?"); used for harder rounds.
  final String? question;
}

class MatchRound {
  const MatchRound({
    required this.answer,
    required this.options,
    required this.prompt,
    this.isQuestion = false,
  });

  final MatchCard answer;

  /// 4 pictures (fewer only if the pool is tiny), answer included.
  final List<MatchCard> options;

  /// What is said and shown: the word, or a question.
  final String prompt;

  /// [prompt] is a question rather than the word itself.
  final bool isQuestion;
}

/// Builds Picture match rounds from [pool]. Distractors come from other
/// categories (easier) or, with [sameCategory], from the answer's own
/// category first (harder: semantic neighbours). With [askQuestion] the
/// prompt is the card's [MatchCard.question] when it has one.
List<MatchRound> buildMatchRounds(
  List<MatchCard> pool, {
  int count = 10,
  Random? random,
  bool sameCategory = false,
  bool askQuestion = false,
}) {
  final rng = random ?? Random();
  final answers = List<MatchCard>.from(pool)..shuffle(rng);
  return [
    for (final answer in answers.take(count))
      () {
        final near = pool
            .where((c) => c.id != answer.id && c.category == answer.category)
            .toList()
          ..shuffle(rng);
        final far = pool
            .where((c) => c.id != answer.id && c.category != answer.category)
            .toList()
          ..shuffle(rng);
        final distractors = (sameCategory ? [...near, ...far] : far).take(3);
        final question = askQuestion ? answer.question : null;
        return MatchRound(
          answer: answer,
          options: [answer, ...distractors]..shuffle(rng),
          prompt: question ?? answer.label,
          isQuestion: question != null,
        );
      }(),
  ];
}

/// A tab on the Family Voice page.
class VoiceSet {
  const VoiceSet({
    required this.id,
    required this.label,
    required this.icon,
    required this.items,
    required this.progress,
  });

  final String id;
  final String label;
  final IconData icon;
  final List<PracticeItem> items;

  /// "3 of 61 words recorded", given (done, total).
  final String Function(int done, int total) progress;
}
