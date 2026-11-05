import 'package:aphora/data/intake/condition.dart';
import 'package:aphora/data/intake/intake_questions.dart';
import 'package:aphora/data/intake/intake_record.dart';
import 'package:aphora/data/models/usermodel.dart';
import 'package:aphora/logic/intake_engine.dart';
import 'package:flutter_test/flutter_test.dart';

/// A typical child with mild difficulties, no red flags.
Answers childOk() => {
      'who': 'child',
      'age': '4',
      'c_first_words': 'by18m',
      'c_phrases': 'often',
      'c_understand': 'yes',
      'c_family': 'always',
      'c_strangers': 'usually',
      'c_sounds': 'none',
      'c_hearing': 'yes',
      'c_lost': 'no',
      'c_social': 'yes',
      'c_feeding': 'no',
    };

Answers strokeMild() => {
      'who': 'adult',
      'event': 'stroke',
      'a_when': '3to12m',
      'a_new': 'no',
      'a_understand': 'well',
      'a_naming': 'effort',
      'a_repeat': 'easy',
      'a_needs': 'words',
      'a_read': 'ok',
      'swallow': 'no',
    };

Answers mouthOk() => {
      'who': 'self',
      'event': 'surgery',
      'o_surgery': 'part',
      'o_weeks': '3to12m',
      'o_radio': 'done',
      'o_family': 'always',
      'o_phone': 'yes',
      'o_daily': 'little',
      'o_pain': 'no',
      'swallow': 'no',
    };

List<String> ids(Answers a) => IntakeEngine.visible(a).map((q) => q.id).toList();

void main() {
  group('questionnaire data', () {
    test('question ids are unique and every question has options', () {
      final all = IntakeQuestionnaire.questions.map((q) => q.id).toList();
      expect(all.toSet().length, all.length);
      for (final q in IntakeQuestionnaire.questions) {
        expect(q.options, isNotEmpty, reason: q.id);
        final values = q.options.map((o) => o.value).toList();
        expect(values.toSet().length, values.length, reason: q.id);
        expect(q.prompt.en, isNotEmpty);
        expect(q.prompt.ta, isNotEmpty);
      }
    });

    test('each branch asks at most 10 questions after "Who is this for?"', () {
      for (final a in [childOk(), {...childOk()}..remove('age'), strokeMild(), mouthOk()]) {
        // c_age is only a fallback for profiles without an age.
        expect(ids(a).where((id) => !{'who', 'event', 'c_age'}.contains(id)).length,
            lessThanOrEqualTo(10), reason: '${a['who']} ${a['event']}');
      }
      expect(ids({...strokeMild(), 'a_when': 'lt2w'}).length, lessThanOrEqualTo(12));
    });
  });

  group('routing', () {
    test('only "Who is this for?" is asked before an answer', () {
      expect(ids({}), ['who']);
    });

    test('child branch asks child questions only', () {
      final q = ids(childOk());
      expect(q, containsAll(['c_first_words', 'c_understand', 'c_family', 'c_hearing', 'c_lost']));
      expect(q.any((id) => id.startsWith('a_') || id.startsWith('o_')), isFalse);
      expect(q, isNot(contains('event')));
      expect(q, isNot(contains('c_age')), reason: 'age known from sign-up');
      expect(IntakeEngine.evaluate(childOk()).condition, Condition.childSpeechDelay);
    });

    test('child without a known age is asked the age band', () {
      expect(ids({'who': 'child'}), contains('c_age'));
      expect(ids({'who': 'child', 'c_age': '8plus'}), isNot(contains('c_phrases')),
          reason: 'two-word phrases are asked up to age 5');
    });

    test('adult asks what happened; stroke → aphasia pack', () {
      expect(ids({'who': 'adult'}), ['who', 'event']);
      expect(IntakeEngine.evaluate(strokeMild()).condition, Condition.adultAphasia);
      expect(ids(strokeMild()), contains('a_naming'));
      expect(ids(strokeMild()), isNot(contains('a_followup')));
    });

    test('mouth or tongue surgery → oral-cancer pack, also for "Myself"', () {
      expect(IntakeEngine.evaluate(mouthOk()).condition, Condition.oralCancerRehab);
      expect(ids(mouthOk()), containsAll(['o_surgery', 'o_weeks', 'swallow']));
    });

    test('other cause → unknown pack and "see a professional first"', () {
      final r = IntakeEngine.evaluate(
          {'who': 'self', 'event': 'other', 'g_problem': 'words', 'g_sudden': 'no'});
      expect(r.condition, Condition.unknown);
      expect(r.redFlags, ['see_professional']);
    });

    test('changing an earlier answer drops answers from the old branch', () {
      final pruned = IntakeEngine.prune({...strokeMild(), 'who': 'child', 'age': '5'});
      expect(pruned.keys.any((k) => k.startsWith('a_') || k == 'event' || k == 'swallow'),
          isFalse);
      expect(pruned['age'], '5', reason: 'hidden inputs are kept');
    });

    test('isComplete only when every visible question is answered', () {
      expect(IntakeEngine.isComplete(childOk()), isTrue);
      expect(IntakeEngine.isComplete({...childOk()}..remove('c_lost')), isFalse);
    });
  });

  group('child rules', () {
    test('no concerns → level 3, no red flags', () {
      final r = IntakeEngine.evaluate(childOk());
      expect(r.startLevel, 3);
      expect(r.redFlags, isEmpty);
      expect(r.focus.length, inInclusiveRange(2, 3));
      expect(r.recommendedFocus, 'sentences');
    });

    test('no words yet → level 1 with sounds and first words, see a therapist', () {
      final r = IntakeEngine.evaluate({...childOk(), 'c_first_words': 'notyet', 'c_phrases': 'notyet'});
      expect(r.startLevel, 1);
      expect(r.focus.take(2), ['sounds', 'first_words']);
      expect(r.redFlags, contains('see_slp'));
      expect(r.recommendedFocus, 'letters');
      expect(r.severity, 'severe');
      expect(r.concern, 'late');
    });

    test('unclear to strangers or many hard sounds → level 2 + clearer sounds', () {
      final r = IntakeEngine.evaluate({...childOk(), 'c_strangers': 'sometimes', 'c_sounds': 'few'});
      expect(r.startLevel, 2);
      expect(r.focus, contains('clear_sounds'));
      expect(r.concern, 'sounds');
      expect(IntakeEngine.evaluate({...childOk(), 'c_sounds': 'many'}).startLevel, 2);
    });

    test('poor understanding adds the understanding focus', () {
      expect(IntakeEngine.evaluate({...childOk(), 'c_understand': 'no'}).focus,
          contains('understanding'));
    });

    test('red flags: hearing, lost words, pointing, feeding', () {
      expect(IntakeEngine.evaluate({...childOk(), 'c_hearing': 'no'}).redFlags, ['hearing_test']);
      expect(IntakeEngine.evaluate({...childOk(), 'c_hearing': 'sometimes'}).redFlags,
          ['hearing_test']);
      expect(IntakeEngine.evaluate({...childOk(), 'c_lost': 'yes'}).redFlags, ['lost_skills']);
      expect(IntakeEngine.evaluate({...childOk(), 'c_social': 'rarely'}).redFlags,
          ['developmental_check']);
      expect(IntakeEngine.evaluate({...childOk(), 'c_feeding': 'yes'}).redFlags, ['feeding_check']);
      expect(IntakeEngine.evaluate({...childOk(), 'c_lost': 'unsure'}).redFlags, isEmpty);
    });

    test('child referrals never put practice on hold', () {
      final r = IntakeEngine.evaluate({...childOk(), 'c_hearing': 'no', 'c_lost': 'yes'});
      expect(r.practiceOnHold, isFalse);
    });

    test('hard to understand by strangers at 4+ → see a therapist', () {
      expect(IntakeEngine.evaluate({...childOk(), 'c_strangers': 'rarely'}).redFlags,
          contains('see_slp'));
      expect(IntakeEngine.evaluate({...childOk(), 'age': '3', 'c_strangers': 'rarely'}).redFlags,
          isNot(contains('see_slp')));
    });
  });

  group('stroke rules', () {
    test('mild answers → level 3', () {
      final r = IntakeEngine.evaluate(strokeMild());
      expect(r.startLevel, 3);
      expect(r.redFlags, isEmpty);
      expect(r.focus, contains('naming'));
      expect(r.concern, 'Not sure', reason: 'no diagnosis label is stored');
    });

    test('severe answers → level 1 with needs and understanding first', () {
      final r = IntakeEngine.evaluate({
        ...strokeMild(),
        'a_understand': 'little',
        'a_naming': 'hard',
        'a_repeat': 'hard',
        'a_needs': 'hard',
      });
      expect(r.startLevel, 1);
      expect(r.focus.take(2), ['needs', 'understanding']);
    });

    test('moderate answers → level 2', () {
      final r = IntakeEngine.evaluate({
        ...strokeMild(),
        'a_understand': 'short',
        'a_naming': 'help',
        'a_needs': 'gestures',
      });
      expect(r.startLevel, 2);
    });

    test('new or sudden symptoms → emergency, practice on hold', () {
      final r = IntakeEngine.evaluate({...strokeMild(), 'a_new': 'yes'});
      expect(r.redFlags.first, 'emergency_now');
      expect(r.practiceOnHold, isTrue);
    });

    test('stroke < 2 weeks: follow-up question, flag without a doctor', () {
      final recent = {...strokeMild(), 'a_when': 'lt2w'};
      expect(ids(recent), contains('a_followup'));
      expect(IntakeEngine.evaluate({...recent, 'a_followup': 'no'}).redFlags,
          contains('stroke_followup'));
      expect(IntakeEngine.evaluate({...recent, 'a_followup': 'unsure'}).redFlags,
          contains('stroke_followup'));
      expect(IntakeEngine.evaluate({...recent, 'a_followup': 'yes'}).redFlags, isEmpty);
    });

    test('coughing or choking → swallow check', () {
      expect(IntakeEngine.evaluate({...strokeMild(), 'swallow': 'often'}).redFlags,
          ['swallow_check']);
    });
  });

  group('oral-cancer rules', () {
    test('well understood → level 3, clarity first', () {
      final r = IntakeEngine.evaluate(mouthOk());
      expect(r.startLevel, 3);
      expect(r.focus.first, 'clarity');
      expect(r.redFlags, isEmpty);
    });

    test('hard to understand → level 1, phone focus', () {
      final r = IntakeEngine.evaluate({...mouthOk(), 'o_family': 'rarely', 'o_phone': 'no'});
      expect(r.startLevel, 1);
      expect(r.focus, contains('phone'));
    });

    test('most of the tongue removed never starts at level 3', () {
      expect(IntakeEngine.evaluate({...mouthOk(), 'o_surgery': 'most'}).startLevel, 2);
    });

    test('red flags: pain, < 6 weeks, radiotherapy, choking', () {
      expect(IntakeEngine.evaluate({...mouthOk(), 'o_pain': 'yes'}).redFlags, ['oral_pain']);
      final early = IntakeEngine.evaluate({...mouthOk(), 'o_weeks': 'lt6w'});
      expect(early.redFlags, ['ask_surgeon']);
      expect(early.practiceOnHold, isTrue);
      expect(IntakeEngine.evaluate({...mouthOk(), 'o_radio': 'ongoing'}).redFlags,
          ['radiotherapy_team']);
      expect(IntakeEngine.evaluate({...mouthOk(), 'swallow': 'sometimes'}).redFlags,
          ['swallow_check']);
    });
  });

  group('record and summary', () {
    test('record stores the version, pruned answers and the result', () async {
      final now = DateTime(2026, 11, 5, 10);
      final rec = await IntakeEngine.record(
        {...childOk(), 'a_naming': 'easy'}, // stale answer from another branch
        name: 'Kavin',
        now: now,
      );
      expect(rec.version, intakeVersion);
      expect(rec.answers.containsKey('a_naming'), isFalse);
      expect(rec.condition, Condition.childSpeechDelay);
      expect(rec.summary, contains('Kavin'));
      expect(rec.summary, contains('First words: Before 1½ years.'));
      expect(rec.summary, contains('Red flags: none reported.'));
      expect(rec.summary, contains('not a diagnosis'));

      final map = rec.toMap();
      expect(map['version'], intakeVersion);
      expect((map['result'] as Map)['startLevel'], 3);
      final back = IntakeRecord.tryFromMap(map)!;
      expect(back.focus, rec.focus);
      expect(back.completedAt, now);
    });

    test('the summary lists red flags', () {
      final a = {...strokeMild(), 'a_new': 'yes'};
      final s = TemplateIntakeSummarizer.build(
        name: 'Ravi',
        answers: a,
        result: IntakeEngine.evaluate(a),
        completedAt: DateTime(2026, 11, 5),
      );
      expect(s, contains('Call 108'));
      expect(s, contains('Adult aphasia pack'));
    });

    test('a custom summarizer can replace the template (LLM hook)', () async {
      final rec = await IntakeEngine.record(childOk(),
          name: 'K', now: DateTime(2026), summarizer: const _Fixed());
      expect(rec.summary, 'fixed');
      expect(rec.startLevel, 3, reason: 'rules, not the summarizer, decide');
    });
  });

  group('UserModel compatibility', () {
    Map<String, dynamic> base() => {
          'uid': 'u',
          'name': 'Old',
          'createdAt': '2026-01-01T00:00:00.000',
          'updatedAt': '2026-01-01T00:00:00.000',
        };

    test('old documents without intake read as unknown / null', () {
      final u = UserModel.fromMap(base());
      expect(u.condition, Condition.unknown);
      expect(u.intake, isNull);
      expect(u.isChild, isTrue, reason: 'older accounts were all children');
    });

    test('condition and intake survive a round trip', () async {
      final rec = await IntakeEngine.record(mouthOk(), name: 'S', now: DateTime(2026, 11, 5));
      final u = UserModel.fromMap({...base(), 'condition': 'oral_cancer_rehab', 'intake': rec.toMap()});
      expect(u.condition, Condition.oralCancerRehab);
      expect(u.isChild, isFalse);
      final again = UserModel.fromMap(u.toMap());
      expect(again.intake!.answers['o_surgery'], 'part');
      expect(again.condition, Condition.oralCancerRehab);
    });

    test('garbage intake map does not crash', () {
      expect(UserModel.fromMap({...base(), 'intake': 'oops'}).intake, isNull);
      expect(Condition.fromId('nonsense'), Condition.unknown);
    });
  });
}

class _Fixed implements IntakeSummarizer {
  const _Fixed();
  @override
  Future<String> summarize({
    required String name,
    required Answers answers,
    required IntakeResult result,
    required DateTime completedAt,
  }) async =>
      'fixed';
}
