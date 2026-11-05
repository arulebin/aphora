import 'package:aphora/data/intake/condition.dart';
import 'package:aphora/data/intake/intake_questions.dart';
import 'package:aphora/data/intake/intake_record.dart';

/// Deterministic scoring and routing for the intake questionnaire.
/// Pure Dart, no AI: the same answers always give the same result, and every
/// rule is covered by `test/intake_engine_test.dart`. The rules are listed
/// for clinician review in the wiki note `vernacura-intake-questions`.
class IntakeResult {
  const IntakeResult({
    required this.condition,
    required this.startLevel,
    required this.focus,
    required this.redFlags,
    required this.concern,
  });

  final Condition condition;

  /// 1 (easiest) to 3.
  final int startLevel;

  /// `FocusArea` ids, 2–3 of them, most important first.
  final List<String> focus;

  /// `RedFlag` ids, in questionnaire order.
  final List<String> redFlags;

  /// Value for the legacy `aphasiaType` field (child's main concern, read
  /// by `ChildProfile.concern`); 'Not sure' for adults — no diagnosis label.
  final String concern;

  /// Legacy `severityLevel`: level 1 → severe … level 3 → mild.
  String get severity => const ['severe', 'moderate', 'mild'][startLevel - 1];

  /// Legacy `recommendedFocus` used by Today's plan and the Practice hub.
  String get recommendedFocus => StartLevel.legacyFocus[startLevel - 1];

  /// Something must happen before practice (emergency or doctor first).
  bool get practiceOnHold => redFlags.any((id) =>
      RedFlag.byId(id)?.level != RedFlagLevel.referral);
}

abstract final class IntakeEngine {
  /// Questions to ask, in order, given the answers so far.
  static List<IntakeQuestion> visible(Answers a) =>
      IntakeQuestionnaire.questions.where((q) => q.visible(a)).toList();

  /// Drops answers to questions that are no longer asked (e.g. the stroke
  /// answers after "Who is this for?" changed to "My child"). Hidden inputs
  /// (`age`, `name`) are kept.
  static Answers prune(Answers a) {
    var current = Map<String, String>.of(a);
    while (true) {
      final next = Map<String, String>.of(current)
        ..removeWhere((id, _) {
          final q = IntakeQuestionnaire.byId(id);
          return q != null && !q.visible(current);
        });
      if (next.length == current.length) return next;
      current = next;
    }
  }

  /// All visible questions have an answer.
  static bool isComplete(Answers a) =>
      visible(a).every((q) => a.containsKey(q.id));

  static IntakeResult evaluate(Answers raw) {
    final a = prune(raw);
    if (isChild(a)) return _child(a);
    if (isStroke(a)) return _stroke(a);
    if (isMouth(a)) return _mouth(a);
    if (isOtherAdult(a)) return _otherAdult(a);
    return const IntakeResult(
      condition: Condition.unknown,
      startLevel: 2,
      focus: ['general'],
      redFlags: [],
      concern: 'Not sure',
    );
  }

  // ── Child ────────────────────────────────────────────────────────────

  static IntakeResult _child(Answers a) {
    final age = childAge(a) ?? 0;
    final first = a['c_first_words'];
    final phrases = a['c_phrases'];
    final understand = a['c_understand'];
    final family = a['c_family'];
    final strangers = a['c_strangers'];
    final sounds = a['c_sounds'];
    const low = {'rarely', 'never'};

    final int level;
    if (first == 'notyet' || phrases == 'notyet' || low.contains(family)) {
      level = 1;
    } else if (phrases == 'sometimes' ||
        family == 'sometimes' ||
        {'sometimes', ...low}.contains(strangers) ||
        sounds == 'many') {
      level = 2;
    } else {
      level = 3;
    }

    final focus = <String>[
      if (level == 1) ...['sounds', 'first_words'],
      if (understand == 'sometimes' || understand == 'no') 'understanding',
      if (level > 1 && (phrases == 'sometimes' || phrases == 'notyet')) 'phrases',
      if (sounds == 'many' ||
          sounds == 'few' ||
          {'sometimes', ...low}.contains(strangers))
        'clear_sounds',
      'naming',
      'phrases',
    ];

    final flags = <String>[
      if (a['c_hearing'] == 'no' || a['c_hearing'] == 'sometimes') 'hearing_test',
      if (a['c_lost'] == 'yes') 'lost_skills',
      if (a['c_social'] == 'rarely') 'developmental_check',
      if (a['c_feeding'] == 'yes') 'feeding_check',
      if ((age >= 2 && first == 'notyet') ||
          (age >= 3 && phrases == 'notyet') ||
          (age >= 4 && low.contains(strangers)) ||
          low.contains(family))
        'see_slp',
    ];

    final concern = (first == 'after2y' || first == 'notyet' || phrases == 'notyet')
        ? 'late'
        : phrases == 'sometimes'
            ? 'words'
            : (sounds == 'many' || sounds == 'few')
                ? 'sounds'
                : 'Not sure';

    return IntakeResult(
      condition: Condition.childSpeechDelay,
      startLevel: level,
      focus: _top(focus),
      redFlags: flags,
      concern: concern,
    );
  }

  // ── Stroke (aphasia pack) ───────────────────────────────────────────

  static IntakeResult _stroke(Answers a) {
    final understand = switch (a['a_understand']) {
      'well' => 0,
      'short' => 1,
      'words' => 2,
      'little' => 3,
      _ => 1, // not sure → assume some difficulty
    };
    final naming = switch (a['a_naming']) {
      'easy' => 0,
      'effort' => 1,
      'help' => 2,
      _ => 3,
    };
    final repeat = switch (a['a_repeat']) {
      'easy' => 0,
      'part' => 1,
      'hard' => 2,
      _ => 1,
    };
    final needs = switch (a['a_needs']) {
      'words' => 0,
      'gestures' => 1,
      _ => 2,
    };
    final total = understand + naming + repeat + needs; // 0–10
    final level = total <= 3 ? 3 : total <= 6 ? 2 : 1;

    final focus = <String>[
      if (needs >= 1) 'needs',
      if (understand >= 2) 'understanding',
      if (naming >= 1) 'naming',
      if (repeat >= 1) 'repetition',
      if (a['a_read'] == 'some' || a['a_read'] == 'no') 'reading',
      'naming',
      'conversation',
    ];

    final followup = a['a_followup'];
    final flags = <String>[
      if (a['a_new'] == 'yes') 'emergency_now',
      if (a['a_when'] == 'lt2w' && followup != 'yes') 'stroke_followup',
      if (a['swallow'] == 'sometimes' || a['swallow'] == 'often') 'swallow_check',
    ];

    return IntakeResult(
      condition: Condition.adultAphasia,
      startLevel: level,
      focus: _top(focus),
      redFlags: flags,
      concern: 'Not sure',
    );
  }

  // ── Mouth / tongue cancer surgery (oral-cancer pack) ─────────────────

  static IntakeResult _mouth(Answers a) {
    final family = switch (a['o_family']) {
      'always' => 0,
      'usually' => 1,
      'sometimes' => 2,
      'rarely' => 3,
      _ => 4,
    };
    final phone = switch (a['o_phone']) {
      'yes' => 0,
      'no' => 2,
      _ => 1,
    };
    final total = family + phone; // 0–6
    var level = total <= 1 ? 3 : total <= 3 ? 2 : 1;
    // Most or all of the tongue removed: never start at sentences.
    if (a['o_surgery'] == 'most' && level > 2) level = 2;

    final focus = <String>[
      'clarity',
      if (phone >= 1) 'phone',
      if (a['o_daily'] == 'lot' || a['o_daily'] == 'avoid') 'conversation',
      'needs',
    ];

    final flags = <String>[
      if (a['o_pain'] == 'yes') 'oral_pain',
      if (a['o_weeks'] == 'lt6w') 'ask_surgeon',
      if (a['o_radio'] == 'ongoing') 'radiotherapy_team',
      if (a['swallow'] == 'sometimes' || a['swallow'] == 'often') 'swallow_check',
    ];

    return IntakeResult(
      condition: Condition.oralCancerRehab,
      startLevel: level,
      focus: _top(focus),
      redFlags: flags,
      concern: 'Not sure',
    );
  }

  // ── Any other adult cause: see a professional first ─────────────────

  static IntakeResult _otherAdult(Answers a) {
    final flags = <String>[
      if (a['g_sudden'] == 'yes') 'emergency_now',
      if (a['g_problem'] == 'voice') 'ent_check',
      'see_professional',
    ];
    return IntakeResult(
      condition: Condition.unknown,
      startLevel: 2,
      focus: const ['general', 'conversation'],
      redFlags: flags,
      concern: 'Not sure',
    );
  }

  /// First three distinct ids.
  static List<String> _top(List<String> ids) =>
      ids.toSet().take(3).toList(growable: false);

  /// Builds the record to store. [summarizer] writes the therapist summary;
  /// the default is the plain template.
  static Future<IntakeRecord> record(
    Answers raw, {
    required String name,
    required DateTime now,
    IntakeSummarizer summarizer = const TemplateIntakeSummarizer(),
  }) async {
    final answers = prune(raw);
    final result = evaluate(answers);
    final summary = await summarizer.summarize(
      name: name,
      answers: answers,
      result: result,
      completedAt: now,
    );
    return IntakeRecord(
      version: intakeVersion,
      answers: answers,
      condition: result.condition,
      startLevel: result.startLevel,
      focus: result.focus,
      redFlags: result.redFlags,
      summary: summary,
      completedAt: now,
    );
  }
}

/// Writes the therapist-facing summary of an intake.
///
/// HOOK: an LLM-backed implementation could later rewrite the template
/// text into smoother prose. It must only rephrase — the pack, level, focus
/// and red flags always come from [IntakeEngine], never from a model. No AI
/// service is called today.
abstract interface class IntakeSummarizer {
  Future<String> summarize({
    required String name,
    required Answers answers,
    required IntakeResult result,
    required DateTime completedAt,
  });
}

/// Plain sentences built from the answers (English: the therapist UI is
/// English).
class TemplateIntakeSummarizer implements IntakeSummarizer {
  const TemplateIntakeSummarizer();

  @override
  Future<String> summarize({
    required String name,
    required Answers answers,
    required IntakeResult result,
    required DateTime completedAt,
  }) async =>
      build(name: name, answers: answers, result: result, completedAt: completedAt);

  static String build({
    required String name,
    required Answers answers,
    required IntakeResult result,
    required DateTime completedAt,
  }) {
    final who = switch (answers['who']) {
      'child' => 'a parent or guardian',
      'adult' => 'a family member or carer',
      'self' => 'the person themself',
      _ => 'the account holder',
    };
    final d = completedAt;
    final date =
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    final age = answers['age'];
    final b = StringBuffer()
      ..write('Intake for ${name.isEmpty ? 'this person' : name}')
      ..write(age != null && age != '0' ? ', age $age' : '')
      ..write(', answered by $who on $date (questionnaire $intakeVersion). ')
      ..write('Pack: ${result.condition.therapistLabel}. ')
      ..write('Screening answers only, not a diagnosis.\n');
    for (final q in IntakeEngine.visible(answers)) {
      if (q.id == 'who') continue;
      final o = q.option(answers[q.id]);
      if (o == null) continue;
      b.write('• ${q.summaryLabel}: ${o.label.en}.\n');
    }
    if (result.redFlags.isEmpty) {
      b.write('Red flags: none reported.\n');
    } else {
      b.write('Red flags: ');
      b.write(result.redFlags
          .map((id) => RedFlag.byId(id)?.message.en ?? id)
          .join(' '));
      b.write('\n');
    }
    b.write('Suggested start: ${StartLevel.label(result.startLevel).en}. ');
    b.write('Focus: ${result.focus.map((id) => FocusArea.byId(id)?.label.en ?? id).join(', ')}.');
    return b.toString();
  }
}
