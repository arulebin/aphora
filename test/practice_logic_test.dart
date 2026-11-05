import 'package:aphora/data/learning/kids_words.dart';
import 'package:aphora/data/learning/practice_catalog.dart';
import 'package:aphora/data/models/usermodel.dart';
import 'package:aphora/logic/language_service.dart';
import 'package:aphora/logic/speech_service.dart';
import 'package:aphora/ui/design/components.dart';
import 'package:flutter_test/flutter_test.dart';

UserModel _user({Map<String, int>? activity}) => UserModel(
      uid: 'u',
      name: 'Test',
      email: '',
      role: 'patient',
      age: 60,
      gender: 'Male',
      phoneNumber: '',
      languagePreference: 'Tamil',
      aphasiaType: '',
      severityLevel: '',
      goals: const [],
      sessionsCompleted: 3,
      progressScore: 0,
      completedExercises: const [],
      dailyActivity: activity,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

String _k(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

void main() {
  test('TextEvaluator scores an exact Tamil answer 100', () {
    expect(TextEvaluator.analyze('வணக்கம்', 'வணக்கம்').similarity, 100);
  });

  test('TextEvaluator gives partial credit for a near miss', () {
    final s = TextEvaluator.analyze('தண்ணீர்', 'தண்ணி').similarity;
    expect(s, greaterThan(30));
    expect(s, lessThan(100));
  });

  test('score bands use words, not only colour', () {
    expect(ScoreBand.of(90).label, 'Excellent');
    expect(ScoreBand.of(72).label, 'Good');
    expect(ScoreBand.of(50).label, 'Getting there');
    expect(ScoreBand.of(10).label, 'Keep practising');
  });

  test('placement test has letters, words and sentences (20 items)', () {
    LanguageService.setLanguage(Language.tamil);
    final items = PracticeCatalog.assessment();
    expect(items.length, 20);
    expect(items.where((i) => i.id.contains('letter')).length, 6);
    expect(items.map((i) => i.id).toSet().length, 20, reason: 'ids unique');
  });

  test('placement score maps to a focus', () {
    expect(PracticeCatalog.focusFor(20), 'letters');
    expect(PracticeCatalog.focusFor(55), 'words');
    expect(PracticeCatalog.focusFor(80), 'sentences');
  });

  test('no Tamil practice text contains foreign-script characters', () {
    LanguageService.setLanguage(Language.tamil);
    final all = [
      ...PracticeCatalog.assessment(),
      ...PracticeCatalog.sentences(count: 100),
      ...PracticeCatalog.words(count: 100),
      ...PracticeCatalog.naming(count: 100),
    ];
    final bad = RegExp(r'[^஀-௿\s.,?!‌‍]');
    for (final i in all) {
      expect(bad.hasMatch(i.target), isFalse, reason: i.target);
    }
  });

  test('naming items hide the word and offer a first-sound cue', () {
    final n = PracticeCatalog.naming(count: 3);
    expect(n.every((i) => i.hideTarget), isTrue);
    expect(n.first.firstSound, isNotEmpty);
  });

  test('kids word bank: unique ids, a picture, and Tamil-only Tamil hints', () {
    final ids = kidWords.map((w) => w.id).toList();
    expect(ids.toSet().length, ids.length, reason: 'duplicate word id');
    final bad = RegExp(r'[^஀-௿\s.,?!’‌‍]');
    for (final w in kidWords) {
      expect(w.emoji, isNotEmpty, reason: w.id);
      expect(bad.hasMatch(w.cueTa), isFalse, reason: '${w.id}: ${w.cueTa}');
      expect(w.cueEn, isNotEmpty, reason: w.id);
    }
  });

  test('Tamil first-sound hint is one syllable, so it never gives a 2-syllable word away', () {
    const elephant = PracticeItem(id: 'x', target: 'யானை', locale: 'ta-IN');
    expect(elephant.firstSound, 'யா');
    const english = PracticeItem(id: 'y', target: 'Elephant', locale: 'en-IN');
    expect(english.firstSound, 'El');
  });

  test('streak counts consecutive days ending today or yesterday', () {
    final now = DateTime.now();
    String d(int n) => _k(now.subtract(Duration(days: n)));
    expect(_user(activity: {d(0): 1, d(1): 2, d(2): 1, d(4): 1}).streakDays, 3);
    expect(_user(activity: {d(1): 1, d(2): 1}).streakDays, 2);
    expect(_user(activity: {d(3): 1}).streakDays, 0);
  });

  test('older user docs without totalAttempts fall back to sessions', () {
    expect(_user().totalAttempts, 3);
    final round = UserModel.fromMap(_user().toMap()..remove('totalAttempts'));
    expect(round.totalAttempts, 3);
  });
}
