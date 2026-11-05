import 'dart:math';

import 'package:aphora/data/intake/condition.dart';
import 'package:aphora/data/intake/intake_questions.dart';
import 'package:aphora/data/learning/kids_words.dart';
import 'package:aphora/data/learning/packs/aphasia_pack.dart';
import 'package:aphora/data/learning/packs/condition_packs.dart';
import 'package:aphora/data/learning/packs/kids_pack.dart';
import 'package:aphora/data/learning/practice_catalog.dart';
import 'package:aphora/data/models/usermodel.dart';
import 'package:aphora/logic/intake_engine.dart';
import 'package:aphora/logic/language_service.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _base() => {
      'uid': 'u',
      'name': 'Ravi',
      'createdAt': '2026-01-01T00:00:00.000',
      'updatedAt': '2026-01-01T00:00:00.000',
    };

Future<UserModel> _strokeUser({
  Map<String, String> extra = const {},
  Map<String, dynamic> fields = const {},
}) async {
  final rec = await IntakeEngine.record({
    'who': 'adult',
    'event': 'stroke',
    'a_when': '3to12m',
    'a_new': 'no',
    'a_kind': 'words',
    'a_understand': 'short',
    'a_naming': 'help',
    'a_repeat': 'part',
    'a_needs': 'gestures',
    'a_read': 'some',
    'swallow': 'no',
    ...extra,
  }, name: 'Ravi', now: DateTime(2026, 11, 6));
  return UserModel.fromMap({
    ..._base(),
    'condition': rec.condition.id,
    'intake': rec.toMap(),
    ...fields,
  });
}

/// Stand-in for the oral-cancer pack the other branch delivers.
class _FakeOralPack extends KidsPack {
  const _FakeOralPack();
  @override
  Condition get condition => Condition.oralCancerRehab;
  @override
  bool get forChildren => false;
}

void main() {
  group('pack selection', () {
    test('each condition gets its pack; unknown and pending use the general set', () {
      expect(ConditionPacks.of(Condition.childSpeechDelay), isA<KidsPack>());
      expect(ConditionPacks.of(Condition.adultAphasia), isA<AphasiaPack>());
      expect(ConditionPacks.of(Condition.unknown), isA<KidsPack>());
      expect(ConditionPacks.of(Condition.oralCancerRehab), isA<KidsPack>());
    });

    test('"exercises being prepared" only for a condition without its own pack', () {
      expect(ConditionPacks.contentPending(Condition.adultAphasia), isFalse);
      expect(ConditionPacks.contentPending(Condition.childSpeechDelay), isFalse);
      expect(ConditionPacks.contentPending(Condition.unknown), isFalse);
      expect(ConditionPacks.contentPending(Condition.oralCancerRehab), isTrue);
    });

    test('registering the oral-cancer pack takes over its condition', () {
      addTearDown(() => ConditionPacks.unregister(Condition.oralCancerRehab));
      ConditionPacks.register(const _FakeOralPack());
      expect(ConditionPacks.of(Condition.oralCancerRehab), isA<_FakeOralPack>());
      expect(ConditionPacks.contentPending(Condition.oralCancerRehab), isFalse);
      ConditionPacks.unregister(Condition.adultAphasia);
      expect(ConditionPacks.hasPack(Condition.adultAphasia), isTrue,
          reason: 'built-in packs cannot be removed');
    });

    test('a stroke intake → aphasia pack with adult wording', () async {
      final u = await _strokeUser();
      expect(u.activeCondition, Condition.adultAphasia);
      expect(ConditionPacks.forUser(u), isA<AphasiaPack>());
      expect(ConditionPacks.childWording(u), isFalse);
    });

    test('children, old accounts and signed-out → children\'s pack and wording', () {
      final old = UserModel.fromMap(_base());
      expect(ConditionPacks.forUser(old), isA<KidsPack>());
      expect(ConditionPacks.childWording(old), isTrue);
      expect(ConditionPacks.forUser(null), isA<KidsPack>());
      expect(ConditionPacks.childWording(null), isTrue);
    });

    test('an adult whose pack is pending gets the general set, adult wording', () {
      final oral = UserModel.fromMap({
        ..._base(),
        'condition': 'oral_cancer_rehab',
        'intake': {'result': {'condition': 'oral_cancer_rehab', 'startLevel': 2}},
      });
      expect(ConditionPacks.forUser(oral), isA<KidsPack>());
      expect(ConditionPacks.childWording(oral), isFalse);
    });
  });

  group('level', () {
    test('legacy focus ↔ level', () {
      expect(StartLevel.fromLegacyFocus('letters'), 1);
      expect(StartLevel.fromLegacyFocus('words'), 2);
      expect(StartLevel.fromLegacyFocus('sentences'), 3);
      expect(StartLevel.fromLegacyFocus(null), isNull);
      expect(StartLevel.fromLegacyFocus('nonsense'), isNull);
    });

    test('the intake start level picks the difficulty', () async {
      final u = await _strokeUser(); // moderate answers → level 2
      expect(u.intake!.startLevel, 2);
      expect(u.practiceLevel, 2);
      final severe = await _strokeUser(extra: {
        'a_understand': 'little',
        'a_naming': 'hard',
        'a_repeat': 'hard',
        'a_needs': 'hard',
      });
      expect(severe.practiceLevel, 1);
    });

    test('a measured check-up (recommendedFocus) beats the questionnaire', () async {
      final u = await _strokeUser(fields: {'recommendedFocus': 'sentences'});
      expect(u.practiceLevel, 3);
    });

    test('no intake and no check-up → level 2', () {
      expect(UserModel.fromMap(_base()).practiceLevel, 2);
    });
  });

  group('therapist override', () {
    test('therapist pack and level win over the intake', () async {
      final u = await _strokeUser(fields: {
        'recommendedFocus': 'sentences',
        'therapistCondition': 'child_speech_delay',
        'therapistLevel': 1,
      });
      expect(u.condition, Condition.adultAphasia, reason: 'intake result is kept');
      expect(u.activeCondition, Condition.childSpeechDelay);
      expect(u.practiceLevel, 1);
      expect(u.setByTherapist, isTrue);
      expect(ConditionPacks.forUser(u), isA<KidsPack>());
    });

    test('level only: pack still follows the intake', () async {
      final u = await _strokeUser(fields: {'therapistLevel': 3});
      expect(u.activeCondition, Condition.adultAphasia);
      expect(u.practiceLevel, 3);
      expect(u.setByTherapist, isTrue);
    });

    test('bad or missing values are ignored', () async {
      final u = await _strokeUser(fields: {
        'therapistCondition': 'nonsense',
        'therapistLevel': 7,
      });
      expect(u.therapistCondition, isNull);
      expect(u.therapistLevel, isNull);
      expect(u.setByTherapist, isFalse);
      expect(u.practiceLevel, 2);
      expect(UserModel.parseTherapistCondition('unknown'), isNull);
      expect(UserModel.parseTherapistLevel('2'), 2);
    });

    test('override survives a round trip; copyWith keeps it', () async {
      final u = await _strokeUser(fields: {
        'therapistCondition': 'adult_aphasia',
        'therapistLevel': 3,
      });
      final again = UserModel.fromMap(u.toMap());
      expect(again.therapistCondition, Condition.adultAphasia);
      expect(again.therapistLevel, 3);
      final copy = again.copyWith(name: 'R');
      expect(copy.therapistCondition, Condition.adultAphasia);
      expect(copy.therapistLevel, 3);
    });

    test("the patient's own updates never carry the therapist's fields", () {
      expect(UserModel.therapistFields,
          containsAll(['therapistNote', 'therapistCondition', 'therapistLevel']));
    });
  });

  group("children's pack is unchanged", () {
    const kids = KidsPack();

    test('same exercises and content as before the packs', () {
      expect(kids.speakingKinds, [
        PracticeKind.letters,
        PracticeKind.words,
        PracticeKind.naming,
        PracticeKind.sentences,
        PracticeKind.phonetic,
      ]);
      expect(kids.forChildren, isTrue);
      expect(kids.offersSoundDrill, isTrue);
      final letters = kids.items(PracticeKind.letters, level: 1, language: Language.tamil);
      expect(letters.map((i) => i.target),
          PracticeCatalog.letters(language: Language.tamil).map((i) => i.target));
      expect(kids.items(PracticeKind.assessment, level: 3, language: Language.english),
          hasLength(20));
      LanguageService.setLanguage(Language.english);
      expect(kids.title(PracticeKind.naming), 'What is this?');
    });

    test("Today's plan matches the old recommendedFocus plans", () {
      expect(kids.plan(level: 1), ['letters', 'words', 'picture']);
      expect(kids.plan(level: 2), ['letters', 'words', 'naming']);
      expect(kids.plan(level: 3), ['words', 'sentences', 'naming']);
      expect(kids.recommendedKind(level: 1), PracticeKind.letters);
      expect(kids.recommendedKind(level: 2), PracticeKind.words);
      expect(kids.recommendedKind(level: 3), PracticeKind.sentences);
    });

    test('picture match: emoji words, distractors from other groups', () {
      final rounds = kids.matchRounds(level: 2, language: Language.tamil, random: Random(7));
      expect(rounds, hasLength(10));
      final byId = {for (final w in kidWords) w.id: w};
      for (final r in rounds) {
        expect(r.answer.emoji, byId[r.answer.id]!.emoji);
        expect(r.prompt, byId[r.answer.id]!.ta);
        expect(
            r.options.where((o) => o.id != r.answer.id && o.category == r.answer.category),
            isEmpty);
      }
    });

    test('Family Voice keeps words, sounds and sentences', () {
      final sets = kids.familyVoiceSets(language: Language.tamil);
      expect(sets.map((s) => s.id), ['words', 'sounds', 'sentences']);
      expect(sets.first.items.length, kidWords.length);
    });
  });
}
