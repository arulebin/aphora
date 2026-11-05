import 'package:aphora/data/learning/oral/oral_rehab_pack.dart';
import 'package:aphora/data/models/practice_record.dart';
import 'package:aphora/logic/baseline_scoring.dart';
import 'package:aphora/logic/language_service.dart';
import 'package:flutter_test/flutter_test.dart';

final _t0 = DateTime(2026, 11, 1, 9);

OralAttempt _dev(String id, int minute, double score) =>
    OralAttempt.from(itemId: id, at: _t0.add(Duration(minutes: minute)), deviceScore: score)!;

OralAttempt _cer(String id, int minute, double cer) =>
    OralAttempt.from(itemId: id, at: _t0.add(Duration(minutes: minute)), cer: cer)!;

void main() {
  group('attempt sources', () {
    test('prefers server CER, then server score, then device score', () {
      final a = OralAttempt.from(itemId: 'x', at: _t0, cer: 0.2, serverScore: 90, deviceScore: 10)!;
      expect(a.source, ScoreSource.serverCer);
      expect(a.score, closeTo(80, 1e-9));
      final b = OralAttempt.from(itemId: 'x', at: _t0, serverScore: 0.62, deviceScore: 10)!;
      expect(b.source, ScoreSource.server);
      expect(b.score, closeTo(62, 1e-9));
      final c = OralAttempt.from(itemId: 'x', at: _t0, deviceScore: 140)!;
      expect(c.source, ScoreSource.device);
      expect(c.score, 100);
      expect(OralAttempt.from(itemId: 'x', at: _t0, cer: 1.6)!.score, 0);
    });

    test('missing server data: no score at all gives no attempt (not a zero)', () {
      expect(OralAttempt.from(itemId: 'x', at: _t0), isNull);
      expect(OralAttempt.from(itemId: 'x', at: _t0, cer: double.nan), isNull);
    });

    test('reads a stored AttemptRecord', () {
      final r = AttemptRecord(
        taskId: 'oral_word_ta_vali',
        category: 'words',
        target: 'வலி',
        spoken: 'வலி',
        score: 70,
        method: 'device',
        assisted: false,
        createdAt: _t0,
      );
      final a = OralAttempt.fromRecord(r)!;
      expect(a.source, ScoreSource.device);
      expect(a.itemId, 'oral_word_ta_vali');
      expect(OralAttempt.fromRecord(r, cer: 0.1)!.source, ScoreSource.serverCer);
    });
  });

  group('self-baseline per item', () {
    test('first attempts set the starting point, with no score', () {
      final p0 = BaselineScoring.scoreItem('w', const []);
      expect(p0.band, ProgressBand.settingStartingPoint);
      expect(p0.attempts, 0);

      final p2 = BaselineScoring.scoreItem('w', [_dev('w', 0, 40), _dev('w', 1, 50)]);
      expect(p2.band, ProgressBand.settingStartingPoint);
      expect(p2.baselineAttemptsSoFar, 2);
      expect(p2.baseline, isNull);
      expect(p2.change, isNull);

      final p3 = BaselineScoring.scoreItem('w', [_dev('w', 0, 40), _dev('w', 1, 50), _dev('w', 2, 30)]);
      expect(p3.band, ProgressBand.settingStartingPoint);
      expect(p3.baseline, 40); // median, set but nothing to compare yet
    });

    test('improvement against own median is "clearer"', () {
      final attempts = [
        _dev('w', 0, 30), _dev('w', 1, 40), _dev('w', 2, 35), // baseline 35
        _dev('w', 10, 50), _dev('w', 11, 55), _dev('w', 12, 45), // now 50
      ];
      final p = BaselineScoring.scoreItem('w', attempts..shuffle());
      expect(p.baseline, 35);
      expect(p.current, 50);
      expect(p.change, 15);
      expect(p.band, ProgressBand.clearer);
      expect(p.band.message.en, 'Clearer than when you started');
    });

    test('small changes either way read as about the same', () {
      final p = BaselineScoring.scoreItem('w', [
        _dev('w', 0, 60), _dev('w', 1, 60), _dev('w', 2, 60),
        _dev('w', 10, 53),
      ]);
      expect(p.change, -7);
      expect(p.band, ProgressBand.aboutTheSame);
    });

    test('a clear decline is "harder today", never a failure', () {
      final p = BaselineScoring.scoreItem('w', [
        _dev('w', 0, 60), _dev('w', 1, 65), _dev('w', 2, 70),
        _dev('w', 10, 40), _dev('w', 11, 45),
      ]);
      expect(p.band, ProgressBand.harderToday);
      expect(p.band.message.en, 'Harder today — rest and try later');
      for (final b in ProgressBand.values) {
        final text = '${b.message.en} ${b.detail.en}'.toLowerCase();
        expect(text, isNot(contains('fail')));
        expect(text, isNot(contains('wrong')));
        expect(text, isNot(contains('bad')));
        expect(b.message.ta, isNotEmpty);
      }
    });

    test('only the latest few attempts count as "now"', () {
      final p = BaselineScoring.scoreItem('w', [
        _dev('w', 0, 50), _dev('w', 1, 50), _dev('w', 2, 50),
        _dev('w', 5, 10), _dev('w', 6, 10), // old dip
        _dev('w', 10, 60), _dev('w', 11, 62), _dev('w', 12, 58),
      ]);
      expect(p.current, 60);
      expect(p.band, ProgressBand.clearer);
    });

    test('"since" scores today against the starting point', () {
      final today = _t0.add(const Duration(days: 1));
      OralAttempt at(DateTime d, double s) => OralAttempt.from(itemId: 'w', at: d, deviceScore: s)!;
      final p = BaselineScoring.scoreItem('w', [
        _dev('w', 0, 50), _dev('w', 1, 50), _dev('w', 2, 50),
        _dev('w', 10, 80), _dev('w', 11, 80), _dev('w', 12, 80), // yesterday good
        at(today, 35), // today tired
      ], since: today);
      expect(p.current, 35);
      expect(p.band, ProgressBand.harderToday);
    });

    test('server data appearing later starts its own baseline (no mixing)', () {
      final attempts = [
        _dev('w', 0, 20), _dev('w', 1, 20), _dev('w', 2, 20), _dev('w', 3, 25),
        _cer('w', 10, 0.1), // server now reachable: first CER attempt
      ];
      final p = BaselineScoring.scoreItem('w', attempts);
      expect(p.source, ScoreSource.serverCer);
      expect(p.band, ProgressBand.settingStartingPoint);
      expect(p.attempts, 1);
    });

    test('ignores other items', () {
      final p = BaselineScoring.scoreItem('a', [_dev('b', 0, 10), _dev('b', 1, 10), _dev('b', 2, 10), _dev('b', 3, 90)]);
      expect(p.attempts, 0);
    });
  });

  group('session summary', () {
    test('new user: setting the starting point', () {
      final s = BaselineScoring.summarise([_dev('a', 0, 40), _dev('b', 1, 50)]);
      expect(s.band, ProgressBand.settingStartingPoint);
      expect(s.items.length, 2);
      expect(s.medianChange, isNull);
    });

    test('median of item changes; items without baseline do not drag it', () {
      final s = BaselineScoring.summarise([
        for (final id in ['a', 'b', 'c']) ...[_dev(id, 0, 40), _dev(id, 1, 40), _dev(id, 2, 40)],
        _dev('a', 10, 50), _dev('b', 10, 48), _dev('c', 10, 20),
        _dev('new', 10, 5),
      ]);
      expect(s.medianChange, 8);
      expect(s.band, ProgressBand.clearer);
      expect(s.count(ProgressBand.settingStartingPoint), 1);
      expect(s.count(ProgressBand.harderToday), 1);
    });

    test('since limits the session to items practised today', () {
      final s = BaselineScoring.summarise([
        _dev('old', 0, 10),
        _dev('today', 100, 50),
      ], since: _t0.add(const Duration(minutes: 50)));
      expect(s.items.map((i) => i.itemId), ['today']);
    });
  });

  group('intelligibility %', () {
    final set = OralRehabPack.intelligibilityIds(Language.english);
    final ids = set.toList();

    test('server CER at or under the threshold counts as understood', () {
      final r = BaselineScoring.intelligibility([
        for (final (i, id) in ids.indexed) _cer(id, i, i < 15 ? 0.1 : 0.6),
      ], set);
      expect(r.total, 20);
      expect(r.attempted, 20);
      expect(r.understood, 15);
      expect(r.percent, 75);
      expect(r.isComplete, isTrue);
      expect(r.missed.length, 5);
    });

    test('device transcript is checked against target + alternates', () {
      final r = BaselineScoring.intelligibility([
        OralAttempt.from(itemId: 'oral_intel_ta_02_thanneer', at: _t0, deviceScore: 10, transcript: 'தண்ணி')!,
        OralAttempt.from(itemId: 'oral_intel_ta_03_vali', at: _t0, deviceScore: 90, transcript: 'வழி')!,
      ], OralRehabPack.intelligibilityIds(Language.tamil), targets: {
        'oral_intel_ta_02_thanneer': ['தண்ணீர்', 'தண்ணி'],
        'oral_intel_ta_03_vali': ['வலி'],
      });
      expect(r.understood, 1);
      expect(r.missed, ['oral_intel_ta_03_vali']);
      expect(r.isComplete, isFalse);
      expect(r.percent, 50);
    });

    test('latest attempt per item wins; items outside the set are ignored', () {
      final r = BaselineScoring.intelligibility([
        _cer(ids[0], 0, 0.9),
        _cer(ids[0], 5, 0.0),
        _cer('oral_word_en_map', 1, 0.0),
      ], set);
      expect(r.attempted, 1);
      expect(r.understood, 1);
    });

    test('no transcript and no CER falls back to the device score', () {
      final r = BaselineScoring.intelligibility([_dev(ids[0], 0, 80), _dev(ids[1], 0, 60)], set);
      expect(r.understood, 1);
    });

    test('monthly comparison is relative to the first complete test', () {
      IntelligibilityResult res(int n) => IntelligibilityResult(
          understood: n, attempted: 20, total: 20, missed: const []);
      final first = res(8);
      expect(BaselineScoring.compareIntelligibility(null, first), ProgressBand.settingStartingPoint);
      expect(BaselineScoring.compareIntelligibility(first, first), ProgressBand.settingStartingPoint);
      expect(BaselineScoring.compareIntelligibility(first, res(10)), ProgressBand.clearer);
      expect(BaselineScoring.compareIntelligibility(first, res(8)), ProgressBand.aboutTheSame);
      expect(BaselineScoring.compareIntelligibility(first, res(5)), ProgressBand.harderToday);
    });

    test('character error rate is grapheme-based', () {
      expect(BaselineScoring.characterErrorRate('வலி', 'வலி'), 0);
      expect(BaselineScoring.characterErrorRate('வலி', 'வழி'), 0.5);
      expect(BaselineScoring.characterErrorRate('Tea!', 'tea'), 0);
      expect(BaselineScoring.characterErrorRate('key', ''), 1);
    });
  });
}
