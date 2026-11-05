import 'package:aphora/data/learning/oral/oral_rehab_pack.dart';
import 'package:aphora/data/learning/practice_catalog.dart';
import 'package:aphora/logic/language_service.dart';
import 'package:flutter_test/flutter_test.dart';

const _langs = [Language.tamil, Language.english];
const _personal = {
  'name': 'Murugan',
  'address': '12 Church Street, Nagercoil',
  'phone': '98765 43210',
  'son_phone': '91234 56789',
  'place': 'Nagercoil',
};

void main() {
  final all = OralRehabPack.all;

  group('content integrity', () {
    test('ids are unique, prefixed and stable-looking', () {
      final ids = all.map((i) => i.id).toList();
      expect(ids.toSet().length, ids.length);
      for (final id in ids) {
        expect(id, matches(RegExp(r'^oral_[a-z0-9_]+$')), reason: id);
      }
    });

    test('every item has English and Tamil text and a valid level', () {
      for (final i in all) {
        expect(i.en.trim(), isNotEmpty, reason: i.id);
        expect(i.ta.trim(), isNotEmpty, reason: i.id);
        expect(i.ta, matches(RegExp(r'[஀-௿]')), reason: '${i.id} ta has Tamil script');
        expect(i.level, inInclusiveRange(1, 3), reason: i.id);
      }
    });

    test('every level of every kind is populated in both languages', () {
      for (final lang in _langs) {
        for (final kind in OralItemKind.values) {
          for (var level = 1; level <= 3; level++) {
            final items = OralRehabPack.oralItemsFor(kind, level, lang, personal: _personal);
            expect(items, isNotEmpty, reason: '$kind L$level $lang');
          }
        }
      }
    });

    test('every sound group has syllables and words at every level, in both languages', () {
      for (final lang in _langs) {
        for (final g in OralSoundGroup.values) {
          for (final kind in [OralItemKind.syllables, OralItemKind.words]) {
            for (var level = 1; level <= 3; level++) {
              final items = OralRehabPack.oralItemsFor(kind, level, lang).where((i) => i.group == g);
              // L3 syllables are mixed-place sequences; lips are an anchor there.
              if (kind == OralItemKind.syllables && level == 3 && g == OralSoundGroup.lips) continue;
              expect(items, isNotEmpty, reason: '$g $kind L$level $lang');
            }
          }
        }
      }
    });

    test('sound items carry target sounds, group and position', () {
      for (final i in all.where((i) => i.kind == OralItemKind.syllables || i.kind == OralItemKind.words)) {
        expect(i.sounds, isNotEmpty, reason: i.id);
        expect(i.group, isNotNull, reason: i.id);
        expect(i.position, isNotNull, reason: i.id);
      }
      // Word-initial and word-medial targets both present.
      final words = all.where((i) => i.kind == OralItemKind.words);
      expect(words.where((i) => i.position == SoundPosition.medial), isNotEmpty);
      expect(words.where((i) => i.position == SoundPosition.initial), isNotEmpty);
    });

    test('Tamil tongue-tip set covers த ட ந ண ல ள ழ ர ற; back க ங; palatal ச ஞ ய', () {
      final sounds = {
        for (final i in all.where((i) => i.lang == OralLang.ta)) ...i.sounds,
      };
      for (final s in ['த', 'ட', 'ந', 'ண', 'ல', 'ள', 'ழ', 'ர', 'ற', 'க', 'ங', 'ச', 'ஞ', 'ய', 'ப', 'ம']) {
        expect(sounds, contains(s), reason: s);
      }
      final en = {for (final i in all.where((i) => i.lang == OralLang.en)) ...i.sounds};
      for (final s in ['p', 'b', 'm', 't', 'd', 'n', 'l', 's', 'r', 'k', 'g', 'ch', 'sh', 'j', 'y']) {
        expect(en, contains(s), reason: s);
      }
    });

    test('minimal pairs are two different words and the target contains both', () {
      for (final i in all.where((i) => i.kind == OralItemKind.minimalPairs)) {
        final (a, b) = i.pair!;
        expect(a, isNot(b), reason: i.id);
        final target = i.lang == OralLang.ta ? i.ta : i.en;
        if (i.level < 3) {
          expect(target, contains(a), reason: i.id);
          expect(target, contains(b), reason: i.id);
        } else {
          expect(target.contains(a) || target.contains(b), isTrue, reason: i.id);
        }
      }
    });

    test('clear-speech items are marked for pacing and have one chunk per word', () {
      final clear = all.where((i) => i.kind == OralItemKind.clearSpeech).toList();
      expect(clear, isNotEmpty);
      for (final i in clear) {
        expect(i.pacing, isTrue, reason: i.id);
        expect(i.chunks(Language.english).length, greaterThanOrEqualTo(2), reason: i.id);
        expect(i.chunks(Language.tamil).length, greaterThanOrEqualTo(2), reason: i.id);
      }
      expect(all.where((i) => i.pacing && i.kind != OralItemKind.clearSpeech), isEmpty);
    });

    test('no tongue-strength or range-of-motion exercises', () {
      final bad = RegExp(r'push your tongue|stick out|tongue (up|down|left|right)|resist|press (hard|against)|lick',
          caseSensitive: false);
      for (final i in all) {
        expect(bad.hasMatch('${i.en} ${i.hintEn ?? ''}'), isFalse, reason: i.id);
      }
      for (final g in OralSoundGroup.values) {
        expect(bad.hasMatch(OralRehabPack.groupHint(g).en), isFalse);
      }
    });

    test('roughly two weeks of daily 10-minute practice per level', () {
      for (final lang in _langs) {
        for (var level = 1; level <= 3; level++) {
          final n = OralItemKind.values
              .where((k) => k != OralItemKind.intelligibility)
              .map((k) => OralRehabPack.oralItemsFor(k, level, lang, personal: _personal).length)
              .fold(0, (a, b) => a + b);
          expect(n, greaterThanOrEqualTo(60), reason: '$lang L$level has $n items');
        }
      }
    });
  });

  group('templates', () {
    test('unfilled templates are skipped; filled ones substitute', () {
      final name = OralRehabPack.byId('oral_phrase_my_name')!;
      expect(name.isTemplate, isTrue);
      expect(name.placeholders, ['name']);
      expect(name.toPracticeItem(Language.english), isNull);
      final empty = OralRehabPack.oralItemsFor(OralItemKind.phrases, 3, Language.tamil);
      expect(empty.where((i) => i.isTemplate), isEmpty);
      final p = name.toPracticeItem(Language.tamil, personal: _personal)!;
      expect(p.target, 'என் பெயர் Murugan');
      expect(p.alternates, contains('என் பேரு Murugan'));
    });
  });

  group('intelligibility set', () {
    test('20 fixed items per language, same at every level', () {
      for (final lang in _langs) {
        final set = OralRehabPack.intelligibilitySet(lang);
        expect(set.length, 20);
        expect(set.map((i) => i.id).toSet().length, 20);
        for (var level = 1; level <= 3; level++) {
          expect(OralRehabPack.oralItemsFor(OralItemKind.intelligibility, level, lang).map((i) => i.id),
              set.map((i) => i.id));
        }
        expect(set.where((i) => i.isTemplate), isEmpty);
      }
    });

    test('ids are pinned (changing the list breaks month-to-month comparison)', () {
      final ta = OralRehabPack.intelligibilitySet(Language.tamil).map((i) => i.id).toList();
      expect(ta.first, 'oral_intel_ta_01_paal');
      expect(ta[9], 'oral_intel_ta_10_yaanai');
      expect(ta.last, 'oral_intel_phrase_20_good_morning');
      final en = OralRehabPack.intelligibilitySet(Language.english).map((i) => i.id).toList();
      expect(en.first, 'oral_intel_en_01_pie');
    });
  });

  group('engine integration', () {
    test('PracticeKind mapping round-trips and naming is unused', () {
      for (final k in OralItemKind.values) {
        expect(OralRehabPack.oralKindFor(OralRehabPack.practiceKindFor(k)), k);
      }
      expect(OralRehabPack.itemsFor(PracticeKind.naming, 1, Language.tamil), isEmpty);
      for (final k in OralRehabPack.kinds) {
        expect(OralRehabPack.oralKindFor(k), isNotNull);
      }
    });

    test('itemsFor gives engine items with locale, voiceKey and a hint', () {
      final ta = OralRehabPack.itemsFor(PracticeKind.words, 2, Language.tamil);
      expect(ta, isNotEmpty);
      for (final p in ta) {
        expect(p.locale, 'ta-IN');
        expect(p.voiceKey, '${p.id}_ta');
        expect(p.semanticCue, isNotNull);
      }
      final water = ta.firstWhere((p) => p.id == 'oral_word_ta_thanneer');
      expect(water.target, 'தண்ணீர்');
      expect(water.alternates, contains('தண்ணி'));
      expect(water.meaning, 'water');

      final en = OralRehabPack.itemsFor(PracticeKind.clearSpeech, 1, Language.english);
      expect(en.first.locale, 'en-IN');
      expect(en.first.semanticCue, OralRehabPack.pacingCue.en);
      expect(OralRehabPack.itemsFor(PracticeKind.words, 1, Language.english).every((p) => p.locale == 'en-IN'),
          isTrue);
    });

    test('titles, descriptions and the safety line exist in both languages', () {
      for (final k in OralItemKind.values) {
        expect(OralRehabPack.title(k).en, isNotEmpty);
        expect(OralRehabPack.title(k).ta, isNotEmpty);
        expect(OralRehabPack.description(k).ta, isNotEmpty);
      }
      expect(OralRehabPack.safetyLine.en, contains('surgeon'));
      expect(OralRehabPack.safetyLine.en, contains('bleeding'));
      expect(OralRehabPack.safetyLine.inLanguage(Language.tamil), contains('ரத்தம்'));
      expect(OralRehabPack.holdFlags, containsAll(['ask_surgeon', 'oral_pain']));
    });
  });

  group('daily session', () {
    test('about 28 unique items, warm-up first, deterministic', () {
      final s = OralRehabPack.dailySession(level: 1, language: Language.tamil, day: 3);
      expect(s.length, inInclusiveRange(24, 30));
      expect(s.map((i) => i.id).toSet().length, s.length);
      expect(s.first.group, OralSoundGroup.lips);
      expect(s.last.kind, OralItemKind.clearSpeech);
      final again = OralRehabPack.dailySession(level: 1, language: Language.tamil, day: 3);
      expect(again.map((i) => i.id), s.map((i) => i.id));
    });

    test('focus rotates and over two weeks most items come up', () {
      for (final lang in _langs) {
        for (var level = 1; level <= 3; level++) {
          final seen = <String>{};
          for (var day = 0; day < 14; day++) {
            final s = OralRehabPack.dailySession(level: level, language: lang, day: day, personal: _personal);
            expect(s.where((i) => i.availableIn(lang)).length, s.length);
            seen.addAll(s.map((i) => i.id));
          }
          expect(seen.length, greaterThanOrEqualTo(50), reason: '$lang L$level saw ${seen.length}');
        }
      }
    });

    test('most-of-tongue sessions lean on phrases and clear speech', () {
      final s = OralRehabPack.dailySession(
          level: 2, language: Language.english, surgery: OralSurgery.mostTongue);
      final strategy = s.where((i) => i.kind == OralItemKind.phrases || i.kind == OralItemKind.clearSpeech);
      expect(strategy.length, greaterThanOrEqualTo(12));
      expect(OralSurgery.fromId('most'), OralSurgery.mostTongue);
      expect(OralSurgery.fromId(null), OralSurgery.unsure);
    });
  });
}
