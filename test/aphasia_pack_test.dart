import 'dart:io';
import 'dart:math';

import 'package:aphora/data/learning/aphasia_content.dart';
import 'package:aphora/data/learning/packs/aphasia_pack.dart';
import 'package:aphora/data/learning/packs/condition_packs.dart';
import 'package:aphora/data/learning/practice_catalog.dart';
import 'package:aphora/logic/language_service.dart';
import 'package:aphora/logic/speech_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tamil script, spaces and light punctuation only (targets and cues).
final _tamilOnly = RegExp(r'^[஀-௿\s.,;?!‌‍’]+$');

/// Minimum entries per level, per task: enough for two weeks of daily
/// sessions without the same item every day.
const _minPerLevel = {
  AphasiaTask.automatic: 6,
  AphasiaTask.repetition: 12,
  AphasiaTask.naming: 15,
  AphasiaTask.completion: 8,
  AphasiaTask.functional: 10,
  AphasiaTask.clearSpeech: 8,
};

String _squash(String s) =>
    s.replaceAll(RegExp(r'[\s·|.,?!]'), '').toLowerCase();

void main() {
  group('aphasia item bank integrity', () {
    for (final task in AphasiaTask.values) {
      test('${task.name}: unique ids, en + ta, levels 1–3 filled', () {
        final entries = aphasiaEntries(task);
        final ids = entries.map((e) => e.id).toList();
        expect(ids.toSet().length, ids.length, reason: 'duplicate id in ${task.name}');
        for (final e in entries) {
          expect(e.task, task, reason: e.id);
          expect(e.en.trim(), isNotEmpty, reason: e.id);
          expect(e.ta.trim(), isNotEmpty, reason: e.id);
          expect(e.level, inInclusiveRange(1, 3), reason: e.id);
          expect(_tamilOnly.hasMatch(e.ta), isTrue,
              reason: '${task.name}/${e.id}: "${e.ta}" has non-Tamil characters');
          expect(e.ta.contains(RegExp(r'[a-zA-Z0-9]')), isFalse, reason: e.id);
        }
        for (final level in [1, 2, 3]) {
          expect(entries.where((e) => e.level == level).length,
              greaterThanOrEqualTo(_minPerLevel[task]!),
              reason: '${task.name} level $level');
        }
      });
    }

    test('item ids are unique across the whole pack', () {
      final all = [
        for (final t in AphasiaTask.values)
          for (final e in aphasiaEntries(t)) AphasiaPack.itemId(e),
      ];
      expect(all.toSet().length, all.length);
    });

    test('at least 40 naming pictures, each with a picture, cues and a group', () {
      expect(aphasiaNaming.length, greaterThanOrEqualTo(40));
      for (final e in aphasiaNaming) {
        expect(e.image != null || e.icon != null, isTrue, reason: e.id);
        expect(e.cueEn, isNotEmpty, reason: e.id);
        expect(e.cueTa, isNotEmpty, reason: e.id);
        expect(_tamilOnly.hasMatch(e.cueTa!), isTrue, reason: '${e.id}: ${e.cueTa}');
        expect(e.category, isNotNull, reason: e.id);
        // The cue must not give the word away.
        expect(e.cueEn!.toLowerCase().contains(e.en.toLowerCase()), isFalse,
            reason: '${e.id}: cue says the word');
        expect(e.cueTa!.contains(e.ta), isFalse, reason: '${e.id}: cue says the word');
      }
    });

    test('every photo exists in assets/images/questions', () {
      for (final e in aphasiaNaming.where((e) => e.image != null)) {
        expect(File(e.picturePath).existsSync(), isTrue, reason: e.picturePath);
      }
    });

    test('sentence completion: one blank in each language, cue for each', () {
      for (final e in aphasiaCompletion) {
        expect('___'.allMatches(e.promptEn!).length, 1, reason: e.id);
        expect('___'.allMatches(e.promptTa!).length, 1, reason: e.id);
        expect(e.cueEn, isNotEmpty, reason: e.id);
        expect(_tamilOnly.hasMatch(e.cueTa!), isTrue, reason: e.id);
      }
    });

    test('clear speech: the guide spells out exactly the target', () {
      for (final e in aphasiaClearSpeech) {
        expect(_squash(e.promptEn!), _squash(e.en), reason: e.id);
        expect(_squash(e.promptTa!), _squash(e.ta), reason: e.id);
        expect(e.promptEn!.contains(RegExp(r'[·|]')), isTrue, reason: e.id);
      }
    });

    test('check-up: 20 items that all exist, covering every level', () {
      expect(aphasiaCheckUp.length, 20);
      final levels = <int>{};
      for (final (task, id) in aphasiaCheckUp) {
        final e = aphasiaEntries(task).where((e) => e.id == id);
        expect(e, hasLength(1), reason: '${task.name}/$id');
        levels.add(e.first.level);
      }
      expect(levels, {1, 2, 3});
      final items = AphasiaPack.checkUp(Language.tamil);
      expect(items.map((i) => i.id).toSet().length, 20);
    });

    test('a correct answer scores 100, in Tamil and in English', () {
      for (final ta in [true, false]) {
        for (final t in AphasiaTask.values) {
          for (final e in aphasiaEntries(t)) {
            final i = AphasiaPack.item(e, ta);
            expect(TextEvaluator.analyze(i.target, i.target).similarity, 100,
                reason: i.id);
          }
        }
      }
    });
  });

  group('aphasia pack sessions', () {
    const pack = AphasiaPack();

    test('a session starts at the chosen level, then fills from below', () {
      final l1 = AphasiaPack.pick(AphasiaTask.repetition, 1, 8, random: Random(1));
      expect(l1.every((e) => e.level == 1), isTrue);
      final l3 = AphasiaPack.pick(AphasiaTask.automatic, 3, 12, random: Random(1));
      final n3 = aphasiaAutomatic.where((e) => e.level == 3).length;
      expect(l3.take(n3).every((e) => e.level == 3), isTrue);
      expect(l3.skip(n3).first.level, 2, reason: 'then the level below');
      expect(l3, hasLength(12));
    });

    test('items per kind: right size, language and cue ladder', () {
      for (final kind in pack.speakingKinds) {
        final items = pack.items(kind, level: 2, language: Language.tamil);
        expect(items, isNotEmpty, reason: kind.name);
        expect(items.every((i) => i.locale == 'ta-IN'), isTrue, reason: kind.name);
      }
      final naming = pack.items(PracticeKind.naming, level: 1, language: Language.english);
      expect(naming, hasLength(10));
      expect(naming.every((i) => i.hideTarget && i.semanticCue != null), isTrue);
      expect(naming.every((i) => i.imagePath != null || i.icon != null), isTrue);
      expect(naming.every((i) => i.emoji == null), isTrue, reason: 'no cartoons for adults');
      expect(naming.every((i) => i.locale == 'en-IN'), isTrue);

      final completion =
          pack.items(PracticeKind.completion, level: 2, language: Language.english);
      for (final i in completion) {
        expect(i.hideTarget, isTrue);
        expect(i.prompt, contains('___'));
        expect(i.alternates, contains(i.prompt!.replaceAll('___', i.target)),
            reason: 'saying the whole sentence counts');
        expect(i.instruction, isNotNull);
      }

      final clear = pack.items(PracticeKind.clearSpeech, level: 1, language: Language.tamil);
      expect(clear.every((i) => !i.hideTarget && i.prompt != null), isTrue);
    });

    test('Tamil items keep spoken and written forms and an English gloss', () {
      final e = aphasiaFunctional.firstWhere((e) => e.id == 'want_water');
      final i = AphasiaPack.item(e, true);
      expect(i.target, 'தண்ணி வேணும்');
      expect(i.alternates, contains('தண்ணீர் வேண்டும்'));
      expect(i.meaning, 'I want water');
      expect(TextEvaluator.analyze(i.alternates.first, 'தண்ணீர் வேண்டும்').similarity, 100);
    });

    test('kinds outside the pack fall back to a sensible aphasia set', () {
      for (final kind in [PracticeKind.letters, PracticeKind.words, PracticeKind.sentences]) {
        expect(pack.items(kind, level: 1, language: Language.english), isNotEmpty);
      }
    });

    test('the check-up is 20 items and maps its score to a start level', () {
      final items = pack.items(PracticeKind.assessment, level: 2, language: Language.english);
      expect(items, hasLength(20));
      expect(items.where((i) => i.hideTarget).length, 9, reason: '6 naming + 3 completion');
      for (final level in [1, 2, 3]) {
        expect(pack.checkUpAdvice(level), isNotEmpty);
      }
    });

    test('"Copy the voice" uses the adult recordings until family records', () {
      final items = pack.items(PracticeKind.phonetic, level: 1, language: Language.tamil);
      expect(items.every((i) => i.referenceAudio != null), isTrue);
    });

    test('Family Voice sets cover words, needs and sentences, sharing session keys', () {
      final sets = pack.familyVoiceSets(language: Language.tamil);
      expect(sets.map((s) => s.id), ['words', 'needs', 'sentences']);
      expect(sets.first.items.length, aphasiaNaming.length);
      expect(sets.first.items.every((i) => !i.hideTarget), isTrue);
      final sessionKeys = {
        for (final e in aphasiaNaming) AphasiaPack.item(e, true).voiceKey,
      };
      expect(sets.first.items.map((i) => i.voiceKey).toSet(), sessionKeys,
          reason: 'a family recording must play in the naming session');
      expect(sets[1].progress(2, 33), contains('2'));
    });

    test('picture match: word rounds, same-group distractors, then questions', () {
      final l1 = pack.matchRounds(level: 1, language: Language.english, random: Random(3));
      expect(l1, hasLength(10));
      for (final r in l1) {
        expect(r.options, hasLength(4));
        expect(r.options.where((o) => o.id == r.answer.id), hasLength(1));
        expect(r.isQuestion, isFalse);
        expect(r.prompt, r.answer.label);
        expect(r.options.every((o) => o.emoji == null), isTrue);
      }
      final l2 = pack.matchRounds(level: 2, language: Language.english, random: Random(3));
      for (final r in l2) {
        final sameGroup = aphasiaNaming
                .where((e) => e.category == r.answer.category)
                .length -
            1;
        expect(
          r.options.where((o) => o.id != r.answer.id && o.category == r.answer.category).length,
          sameGroup >= 3 ? 3 : sameGroup,
          reason: 'level 2 uses semantic neighbours (${r.answer.id})',
        );
      }
      final l3 = pack.matchRounds(level: 3, language: Language.tamil, random: Random(3));
      expect(l3.every((r) => r.isQuestion && r.prompt != r.answer.label), isTrue);
    });

    test("Today's plan follows the level and puts clear speech first for slurred speech", () {
      expect(pack.plan(level: 1), contains(ConditionPack.pictureMatchId));
      expect(pack.plan(level: 1).first, 'automatic');
      expect(pack.plan(level: 2).first, 'repetition');
      expect(pack.plan(level: 3), containsAll(['naming', 'completion']));
      final slurred = pack.plan(level: 3, focus: ['clear_speech', 'naming']);
      expect(slurred.first, 'clearSpeech');
      final both = pack.plan(level: 2, focus: ['naming', 'clear_speech']);
      expect(both.first, 'repetition');
      expect(both.last, 'clearSpeech');
      for (final level in [1, 2, 3]) {
        final minutes = pack.plan(level: level).fold<int>(0, (sum, id) {
          if (id == ConditionPack.pictureMatchId) return sum + 3;
          return sum + pack.minutes(PracticeKind.values.byName(id));
        });
        expect(minutes, inInclusiveRange(8, 13), reason: 'about 10 minutes a day');
      }
      expect(pack.recommendedKind(level: 1), PracticeKind.automatic);
      expect(pack.recommendedKind(level: 3, focus: ['clear_speech']),
          PracticeKind.clearSpeech);
    });

    test('adult titles and wording, no children\'s copy', () {
      LanguageService.setLanguage(Language.english);
      expect(pack.forChildren, isFalse);
      expect(pack.title(PracticeKind.naming), 'Name the picture');
      expect(pack.title(PracticeKind.assessment), 'Speech check-up');
      for (final k in [...pack.speakingKinds, PracticeKind.assessment]) {
        expect(pack.description(k).toLowerCase(), isNot(contains('child')), reason: k.name);
      }
      for (final level in [1, 2, 3]) {
        expect(pack.checkUpAdvice(level).toLowerCase(), isNot(contains('child')));
      }
    });
  });
}
