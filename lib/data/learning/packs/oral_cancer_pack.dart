import 'dart:math';

import 'package:aphora/data/intake/condition.dart';
import 'package:aphora/data/learning/oral/oral_rehab_pack.dart';
import 'package:aphora/data/learning/packs/condition_pack.dart';
import 'package:aphora/data/learning/practice_catalog.dart';
import 'package:aphora/data/models/oral_records.dart';
import 'package:aphora/data/models/usermodel.dart';
import 'package:aphora/logic/language_service.dart';
import 'package:flutter/material.dart';

/// Oral-cancer speech rehab pack (after mouth / tongue cancer surgery).
/// Content and scoring rules come from `lib/data/learning/oral/`
/// ([OralRehabPack], see its README); this class plugs them into the app.
///
/// * Adult wording; progress is compared only with the person's own
///   starting point (`selfBaselineScoring`), never a healthy voice — so
///   there is no "Copy the voice" and no Picture match.
/// * Today's plan is one mixed ~10-minute session ([PracticeKind.daily],
///   [OralRehabPack.dailySession]) for the person's level and day.
/// * The check-up is the monthly clarity (intelligibility) test: fixed
///   order, no hints, no spoken model; it measures, it does not place.
/// * Safety: the safety line is shown before the first practice; intake
///   hold flags keep practice closed until the person confirms their
///   surgeon / care team said they may start ([safetyFor]).
class OralCancerPack extends ConditionPack {
  const OralCancerPack({
    this.personal = const {},
    this.day = 0,
    this.surgery = OralSurgery.unsure,
  });

  /// Filled phrase templates (`UserModel.oralPersonal`).
  final Map<String, String> personal;

  /// Days since the person started (intake date), for the daily rotation.
  final int day;

  /// From the intake answer `o_surgery`.
  final OralSurgery surgery;

  /// Days between clarity checks.
  static const checkEveryDays = 30;

  @override
  Condition get condition => Condition.oralCancerRehab;

  @override
  bool get forChildren => false;

  @override
  bool get hasPictureMatch => false;

  @override
  bool get checkUpSetsLevel => false;

  @override
  bool get checkUpIsMeasure => true;

  @override
  bool get selfBaselineScoring => true;

  @override
  List<PracticeKind> get speakingKinds => [
        PracticeKind.daily,
        for (final k in OralRehabPack.kinds)
          if (k != PracticeKind.assessment) k,
      ];

  static Language get _lang => LanguageService.currentLanguage;

  @override
  String title(PracticeKind kind) {
    if (kind == PracticeKind.daily) return kind.title;
    final oral = OralRehabPack.oralKindFor(kind);
    return oral == null ? kind.title : OralRehabPack.title(oral).inLanguage(_lang);
  }

  @override
  String description(PracticeKind kind) {
    if (kind == PracticeKind.daily) return kind.description;
    final oral = OralRehabPack.oralKindFor(kind);
    return oral == null
        ? kind.description
        : OralRehabPack.description(oral).inLanguage(_lang);
  }

  @override
  String get safetyLine => OralRehabPack.safetyLine.inLanguage(_lang);

  @override
  String get restCue => OralRehabPack.restCue.inLanguage(_lang);

  @override
  ConditionPack tailorTo(UserModel? user) {
    if (user == null) return this;
    final since = user.intake?.completedAt ?? user.createdAt;
    final days = DateTime.now().difference(since).inDays;
    return OralCancerPack(
      personal: user.oralPersonal,
      day: days < 0 ? 0 : days,
      surgery: OralSurgery.fromId(user.intake?.answers['o_surgery']),
    );
  }

  /// Hold flags from the intake (pain, < 6 weeks after surgery,
  /// radiotherapy going on).
  static Set<String> holdFlagsOf(UserModel? user) => {
        for (final f in user?.intake?.redFlags ?? const <String>[])
          if (OralRehabPack.holdFlags.contains(f)) f,
      };

  /// A confirmation counts only if it was given after the latest intake
  /// (a retaken questionnaire may bring new flags).
  static bool _current(SafetyConfirmation c, UserModel user) {
    final intakeAt = user.intake?.completedAt;
    return intakeAt == null || !c.at.isBefore(intakeAt);
  }

  @override
  PracticeSafety safetyFor(UserModel? user) {
    if (user == null) return PracticeSafety.clear;
    final c = user.oralSafety;
    final confirmed = c != null && _current(c, user);
    if (holdFlagsOf(user).isNotEmpty) {
      return confirmed && c.hold ? PracticeSafety.clear : PracticeSafety.hold;
    }
    return confirmed ? PracticeSafety.clear : PracticeSafety.notice;
  }

  @override
  bool checkUpDue(UserModel user) {
    final last = ClarityTest.latest(user.oralClarityTests);
    return last == null ||
        DateTime.now().difference(last.at).inDays >= checkEveryDays;
  }

  // ── Items ────────────────────────────────────────────────────────────

  /// One [OralItem] as a practice item; paced items carry their chunks
  /// and the pacing cue.
  PracticeItem? toItem(OralItem i, Language language, {bool measure = false}) {
    final p = i.toPracticeItem(language, personal: personal);
    if (p == null) return null;
    final paced = i.pacing && !measure;
    return PracticeItem(
      id: p.id,
      target: p.target,
      alternates: p.alternates,
      meaning: p.meaning,
      locale: p.locale,
      semanticCue: measure ? null : OralRehabPack.hintFor(i, language),
      instruction: paced
          ? OralRehabPack.pacingCue.inLanguage(language)
          : measure
              ? tr('Say it as clearly as you can:', 'முடிந்தவரை தெளிவாகச் சொல்லுங்கள்:')
              : null,
      chunks: paced ? i.chunks(language, personal: personal) : null,
      prompt: i.pair == null || measure ? null : '${i.pair!.$1}  ·  ${i.pair!.$2}',
    );
  }

  List<PracticeItem> _convert(List<OralItem> items, Language language,
          {bool measure = false}) =>
      [
        for (final i in items)
          if (toItem(i, language, measure: measure) case final p?) p,
      ];

  /// Items per session for a single-kind exercise.
  static const sessionSize = 10;

  @override
  List<PracticeItem> items(
    PracticeKind kind, {
    required int level,
    required Language language,
  }) {
    if (kind == PracticeKind.assessment) {
      // Fixed order, no hints, no model.
      return _convert(OralRehabPack.intelligibilitySet(language), language,
          measure: true);
    }
    if (kind == PracticeKind.daily) {
      return _convert(
        OralRehabPack.dailySession(
          level: level,
          language: language,
          day: day,
          surgery: surgery,
          personal: personal,
        ),
        language,
      );
    }
    final oral = OralRehabPack.oralKindFor(kind) ?? OralItemKind.words;
    final pool = OralRehabPack.oralItemsFor(oral, level, language, personal: personal)
        .toList()
      ..shuffle(Random(day * 31 + kind.index));
    return _convert(pool.take(sessionSize).toList(), language);
  }

  @override
  List<MatchRound> matchRounds({
    required int level,
    required Language language,
    int count = 10,
    Random? random,
  }) =>
      const [];

  @override
  List<String> plan({required int level, List<String> focus = const []}) =>
      const ['daily'];

  @override
  PracticeKind recommendedKind({required int level, List<String> focus = const []}) =>
      PracticeKind.daily;

  @override
  List<VoiceSet> familyVoiceSets({required Language language}) => [
        VoiceSet(
          id: 'phrases',
          label: tr('Everyday phrases', 'அன்றாடச் சொற்றொடர்கள்'),
          icon: Icons.forum_rounded,
          items: _convert(
            [
              for (final l in [1, 2, 3])
                ...OralRehabPack.oralItemsFor(OralItemKind.phrases, l, language,
                    personal: personal),
            ],
            language,
          ),
          progress: (d, n) =>
              tr('$d of $n phrases recorded', '$n சொற்றொடர்களில் $d பதிவாகியுள்ளன'),
        ),
        VoiceSet(
          id: 'words',
          label: tr('Words', 'சொற்கள்'),
          icon: Icons.short_text_rounded,
          items: _convert(
            [
              for (final l in [1, 2, 3])
                ...OralRehabPack.oralItemsFor(OralItemKind.words, l, language),
            ],
            language,
          ),
          progress: (d, n) =>
              tr('$d of $n words recorded', '$n சொற்களில் $d பதிவாகியுள்ளன'),
        ),
      ];

  @override
  String checkUpAdvice(int level) => tr(
      'Done. The same check next month shows how your speech is changing.',
      'முடிந்தது. அடுத்த மாதம் இதே பரிசோதனை உங்கள் பேச்சு எப்படி மாறுகிறது என்று காட்டும்.');

}
