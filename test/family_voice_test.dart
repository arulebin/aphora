import 'dart:io';

import 'package:aphora/data/learning/kids_words.dart';
import 'package:aphora/data/learning/practice_catalog.dart';
import 'package:aphora/data/models/practice_record.dart';
import 'package:aphora/logic/family_voice_store.dart';
import 'package:aphora/logic/language_service.dart';
import 'package:aphora/logic/practice_rewards.dart';
import 'package:aphora/ui/practice/kid_rewards.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

List<int> _wav([int n = FamilyVoiceStore.minBytes]) => List.filled(n, 1);

AttemptRecord _attempt(
  String task,
  int hints, {
  String cat = 'naming',
  DateTime? at,
}) => AttemptRecord(
  taskId: task,
  category: cat,
  target: '',
  spoken: '',
  score: 80,
  method: 'device',
  assisted: true,
  hintsUsed: hints,
  createdAt: at ?? DateTime(2026, 11, 5, 10),
);

void main() {
  group('Family Voice store (on-device files)', () {
    late Directory dir;
    setUp(() async => dir = await Directory.systemTemp.createTemp('fv_test'));
    tearDown(() async => dir.delete(recursive: true));

    test('saves, finds, survives a reload, and deletes a recording', () async {
      final store = FamilyVoiceStore.forDirectory(dir);
      expect(store.has('kid_cat_ta'), isFalse);
      expect(await store.save('kid_cat_ta', _wav()), isTrue);
      expect(store.has('kid_cat_ta'), isTrue);
      expect(
        await store.bytesFor('kid_cat_ta'),
        hasLength(FamilyVoiceStore.minBytes),
      );
      expect(store.countRecorded(['kid_cat_ta', 'kid_dog_ta']), 1);

      final reopened = FamilyVoiceStore.forDirectory(dir);
      await reopened.load();
      expect(reopened.has('kid_cat_ta'), isTrue);

      await reopened.delete('kid_cat_ta');
      expect(reopened.has('kid_cat_ta'), isFalse);
      expect(await reopened.pathFor('kid_cat_ta'), isNull);
    });

    test('rejects a mis-tap that is too short to be a word', () async {
      final store = FamilyVoiceStore.forDirectory(dir);
      expect(await store.save('kid_cat_ta', _wav(100)), isFalse);
      expect(store.has('kid_cat_ta'), isFalse);
    });

    test(
      '"Copy the voice" uses family recordings when there are any',
      () async {
        LanguageService.setLanguage(Language.tamil);
        final store = FamilyVoiceStore.forDirectory(dir);
        expect(
          PracticeCatalog.phonetic(store: store),
          same(PracticeCatalog.bundledPhonetic),
        );

        await store.save('kid_cat_ta', _wav());
        await store.save('kid_dog_ta', _wav());
        final items = PracticeCatalog.phonetic(store: store);
        expect(items.map((i) => i.voiceKey).toSet(), {
          'kid_cat_ta',
          'kid_dog_ta',
        });
        expect(items.every((i) => i.referenceAudio == null), isTrue);
      },
    );
  });

  test(
    'voice keys are stable per word and language, and shared by Sound check',
    () {
      LanguageService.setLanguage(Language.tamil);
      final ta = PracticeCatalog.familyWords();
      expect(ta, hasLength(kidWords.length));
      expect(ta.map((i) => i.voiceKey).toSet(), hasLength(kidWords.length));
      expect(ta.firstWhere((i) => i.id == 'kid_cat').voiceKey, 'kid_cat_ta');

      final checkKeys = PracticeCatalog.assessment()
          .map((i) => i.voiceKey)
          .toSet();
      expect(checkKeys, contains('kid_cat_ta'));
      final sentenceKeys = PracticeCatalog.familySentences()
          .map((i) => i.voiceKey)
          .toSet();
      expect(sentenceKeys.intersection(checkKeys), hasLength(6));

      LanguageService.setLanguage(Language.english);
      expect(
        PracticeCatalog.familyWords()
            .firstWhere((i) => i.id == 'kid_cat')
            .voiceKey,
        'kid_cat_en',
      );
      LanguageService.setLanguage(Language.tamil);
    },
  );

  test('a star for each item answered correctly', () {
    expect(PracticeRewards.stars([90, 70, 69.9, 10]), 2);
    expect(PracticeRewards.stars(const []), 0);
  });

  group('hints per word', () {
    test('average of per-word counts; nothing to average is null', () {
      expect(HintStats.average([0, 1, 2, 3]), 1.5);
      expect(HintStats.average(const []), isNull);
      expect(HintStats.format(0.8333), '0.8');
    });

    test('groups retries of a word on a day, ignores no-hint exercises', () {
      final attempts = [
        _attempt('kid_cat', 1),
        _attempt('kid_cat', 3), // same word, same day → 3
        _attempt('kid_dog', 0),
        _attempt('kid_cat', 0, at: DateTime(2026, 11, 6)), // next day → 0
        _attempt('kid_sun', 0, cat: 'words'), // no hints offered → skipped
      ];
      expect(HintStats.averagePerWord(attempts), 1.0); // (3 + 0 + 0) / 3
      expect(HintStats.averagePerWord(const []), isNull);
    });

    test('older attempt docs without the field count as 0 hints', () {
      final old = AttemptRecord.fromMap('x', {
        'taskId': 'kid_cat',
        'category': 'naming',
        'score': 50,
        'createdAt': '2026-11-01T10:00:00',
      });
      expect(old.hintsUsed, 0);
      expect(_attempt('kid_cat', 2).toMap()['hintsUsed'], 2);
      expect(
        AttemptRecord.fromMap('y', _attempt('kid_cat', 2).toMap()).hintsUsed,
        2,
      );
    });
  });

  testWidgets('session end tells the child how many stars they earned', (
    tester,
  ) async {
    LanguageService.setLanguage(Language.english);
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: StarsEarned(stars: 3))),
    );
    await tester.pumpAndSettle();
    expect(find.text('You earned 3 stars!'), findsOneWidget);
    expect(find.text('⭐'), findsNWidgets(3));
    LanguageService.setLanguage(Language.tamil);
  });
}
