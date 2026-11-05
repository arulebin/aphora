import 'package:aphora/data/models/practice_record.dart';
import 'package:characters/characters.dart';

/// Self-baseline scoring for the oral-cancer pack.
///
/// After tongue or jaw surgery, speech will not match a healthy reference
/// voice, and scoring against one only measures the surgery. So every
/// score here is relative to the person's **own first attempts** at the
/// same item: the first [BaselineConfig.baselineAttempts] attempts set the
/// starting point (no score is shown for them), and later attempts are
/// compared with the median of that starting point.
///
/// Pure Dart: takes attempt lists in, returns plain values. No Firebase,
/// no UI. The patient sees only the friendly [ProgressBand] message; the
/// numbers are for the therapist screens.

/// How an attempt was scored. A starting point is kept per source, so a
/// server score is never compared with a phone score.
enum ScoreSource {
  /// Server `/evaluate` returned a character error rate for the
  /// transcript — the closest thing to "would a stranger understand it".
  serverCer,

  /// Server acoustic score without a transcript (audio similarity).
  server,

  /// On-device speech recognition match (0–100).
  device,
}

/// One attempt, reduced to what scoring needs.
class OralAttempt {
  const OralAttempt({
    required this.itemId,
    required this.at,
    required this.score,
    required this.source,
    this.cer,
    this.transcript,
  });

  /// Builds from whatever the attempt has, preferring a server CER, then a
  /// server score, then the on-device score.
  ///
  /// * [cer] — `EvaluationResult.characterErrorRate` (0–1, may exceed 1).
  /// * [serverScore] — server score 0–100 (or 0–1 audio similarity).
  /// * [deviceScore] — on-device match 0–100.
  ///
  /// Returns null when there is no usable score at all (e.g. the server was
  /// unreachable and recognition heard nothing) — such attempts are
  /// skipped, never counted as zero.
  static OralAttempt? from({
    required String itemId,
    required DateTime at,
    double? cer,
    double? serverScore,
    double? deviceScore,
    String? transcript,
  }) {
    if (cer != null && cer.isFinite) {
      return OralAttempt(
        itemId: itemId,
        at: at,
        score: _clamp100((1 - cer) * 100),
        source: ScoreSource.serverCer,
        cer: cer,
        transcript: transcript,
      );
    }
    if (serverScore != null && serverScore.isFinite) {
      return OralAttempt(
        itemId: itemId,
        at: at,
        score: _clamp100(serverScore <= 1 ? serverScore * 100 : serverScore),
        source: ScoreSource.server,
        transcript: transcript,
      );
    }
    if (deviceScore != null && deviceScore.isFinite) {
      return OralAttempt(
        itemId: itemId,
        at: at,
        score: _clamp100(deviceScore),
        source: ScoreSource.device,
        transcript: transcript,
      );
    }
    return null;
  }

  /// From a stored [AttemptRecord]. Records keep only `score` + `method`,
  /// so pass [cer] when the session still has the server result.
  static OralAttempt? fromRecord(AttemptRecord r, {double? cer}) => from(
        itemId: r.taskId,
        at: r.createdAt,
        cer: cer,
        serverScore: r.method == 'server' ? r.score : null,
        deviceScore: r.method == 'server' ? null : r.score,
        transcript: r.spoken,
      );

  final String itemId;
  final DateTime at;

  /// 0–100, higher is clearer.
  final double score;
  final ScoreSource source;
  final double? cer;

  /// What the recogniser heard (server `user_text` or device transcript).
  final String? transcript;
}

class BaselineConfig {
  const BaselineConfig({
    this.baselineAttempts = 3,
    this.recentAttempts = 3,
    this.clearerBy = 5,
    this.harderBy = 10,
    this.intelligibleCer = 0.25,
  });

  /// First N attempts per item (per [ScoreSource]) form the starting point.
  final int baselineAttempts;

  /// "Now" = median of up to this many latest attempts after the baseline.
  final int recentAttempts;

  /// Points above the starting point that count as clearer.
  final double clearerBy;

  /// Points below the starting point before we say "harder today".
  /// Deliberately larger than [clearerBy]: an off day should read as
  /// "about the same", not a decline.
  final double harderBy;

  /// An intelligibility item counts as understood when the recogniser's
  /// character error rate is at or below this.
  final double intelligibleCer;
}

enum ProgressBand { settingStartingPoint, clearer, aboutTheSame, harderToday }

extension ProgressBandText on ProgressBand {
  /// Headline shown to the person. Never a number, never a "fail".
  ({String en, String ta}) get message => switch (this) {
        ProgressBand.settingStartingPoint => (
            en: 'Setting your starting point',
            ta: 'உங்கள் தொடக்க நிலையைப் பதிவு செய்கிறோம்',
          ),
        ProgressBand.clearer => (
            en: 'Clearer than when you started',
            ta: 'தொடங்கியதைவிடத் தெளிவாக இருக்கிறது',
          ),
        ProgressBand.aboutTheSame => (
            en: 'About the same — steady practice helps',
            ta: 'ஏறக்குறைய அதே அளவு — தொடர்ந்த பயிற்சி உதவும்',
          ),
        ProgressBand.harderToday => (
            en: 'Harder today — rest and try later',
            ta: 'இன்று கொஞ்சம் கடினம் — ஓய்வெடுத்துப் பிறகு முயலுங்கள்',
          ),
      };

  /// Second line.
  ({String en, String ta}) get detail => switch (this) {
        ProgressBand.settingStartingPoint => (
            en: 'Say it a few times. We compare you only with yourself.',
            ta: 'சில முறை சொல்லுங்கள். உங்களை உங்களுடனே மட்டும் ஒப்பிடுகிறோம்.',
          ),
        ProgressBand.clearer => (
            en: 'Your practice is working. Keep going.',
            ta: 'உங்கள் பயிற்சி பலன் தருகிறது. தொடருங்கள்.',
          ),
        ProgressBand.aboutTheSame => (
            en: 'Clarity often improves slowly over weeks.',
            ta: 'தெளிவு பொதுவாக வாரங்களில் மெதுவாக மேம்படும்.',
          ),
        ProgressBand.harderToday => (
            en: 'Tiredness, a sore mouth or treatment can change speech for a day. That is normal.',
            ta: 'களைப்பு, வாய்ப் புண் அல்லது சிகிச்சையால் ஒரு நாள் பேச்சு மாறலாம். இது இயல்பானது.',
          ),
      };
}

/// Progress on one item.
class ItemProgress {
  const ItemProgress({
    required this.itemId,
    required this.band,
    required this.attempts,
    required this.baselineAttemptsSoFar,
    this.source,
    this.baseline,
    this.current,
  });

  final String itemId;
  final ProgressBand band;

  /// Scored attempts of [source] (other sources are ignored).
  final int attempts;

  /// How many of the starting-point attempts are done (0..N).
  final int baselineAttemptsSoFar;
  final ScoreSource? source;

  /// Median of the starting-point attempts (null until all N are done).
  final double? baseline;

  /// Median of the latest attempts after the starting point.
  final double? current;

  /// current − baseline, in points (therapist view only).
  double? get change =>
      baseline == null || current == null ? null : current! - baseline!;
}

/// Summary over several items (a session, or the whole pack).
class ProgressSummary {
  const ProgressSummary({
    required this.band,
    required this.items,
    this.medianChange,
  });

  final ProgressBand band;
  final List<ItemProgress> items;

  /// Median of the items' changes (null when no item has a starting point).
  final double? medianChange;

  int count(ProgressBand b) => items.where((i) => i.band == b).length;
}

class IntelligibilityResult {
  const IntelligibilityResult({
    required this.understood,
    required this.attempted,
    required this.total,
    required this.missed,
  });

  /// Items the recogniser transcribed correctly.
  final int understood;
  final int attempted;

  /// Size of the fixed set.
  final int total;

  /// Attempted but not understood — for the therapist, not the person.
  final List<String> missed;

  /// Share of *attempted* items understood, 0–100.
  double get percent => attempted == 0 ? 0 : understood * 100 / attempted;

  /// Only complete tests should be compared month to month.
  bool get isComplete => attempted == total;
}

abstract final class BaselineScoring {
  /// Scores one item from its attempts (any order; other items' attempts
  /// are ignored). When [since] is given (e.g. start of today's session),
  /// "now" uses post-baseline attempts from [since] onwards if there are
  /// any.
  static ItemProgress scoreItem(
    String itemId,
    List<OralAttempt> attempts, {
    DateTime? since,
    BaselineConfig config = const BaselineConfig(),
  }) {
    final mine = [for (final a in attempts) if (a.itemId == itemId) a]
      ..sort((a, b) => a.at.compareTo(b.at));
    if (mine.isEmpty) {
      return ItemProgress(
        itemId: itemId,
        band: ProgressBand.settingStartingPoint,
        attempts: 0,
        baselineAttemptsSoFar: 0,
      );
    }
    // Compare like with like: the latest attempt's scoring source decides.
    final source = mine.last.source;
    final same = [for (final a in mine) if (a.source == source) a];
    final n = config.baselineAttempts;
    if (same.length <= n) {
      return ItemProgress(
        itemId: itemId,
        band: ProgressBand.settingStartingPoint,
        attempts: same.length,
        baselineAttemptsSoFar: same.length,
        source: source,
        baseline: same.length == n ? _median(same.map((a) => a.score)) : null,
      );
    }
    final baseline = _median(same.take(n).map((a) => a.score));
    final after = same.skip(n).toList();
    final today = since == null
        ? const <OralAttempt>[]
        : [for (final a in after) if (!a.at.isBefore(since)) a];
    final window = (today.isNotEmpty ? today : after);
    final recent = window.skip(
        (window.length - config.recentAttempts).clamp(0, window.length));
    final current = _median(recent.map((a) => a.score));
    return ItemProgress(
      itemId: itemId,
      band: bandFor(current - baseline, config),
      attempts: same.length,
      baselineAttemptsSoFar: n,
      source: source,
      baseline: baseline,
      current: current,
    );
  }

  static ProgressBand bandFor(double change, [BaselineConfig config = const BaselineConfig()]) =>
      change >= config.clearerBy
          ? ProgressBand.clearer
          : change <= -config.harderBy
              ? ProgressBand.harderToday
              : ProgressBand.aboutTheSame;

  /// Summary for a session: scores every item attempted at or after
  /// [since] (all items when null) against its own starting point.
  /// The overall band is from the median change; when no item has a
  /// starting point yet it is [ProgressBand.settingStartingPoint].
  static ProgressSummary summarise(
    List<OralAttempt> attempts, {
    DateTime? since,
    BaselineConfig config = const BaselineConfig(),
  }) {
    final ids = <String>{
      for (final a in attempts)
        if (since == null || !a.at.isBefore(since)) a.itemId,
    };
    final items = [
      for (final id in ids) scoreItem(id, attempts, since: since, config: config),
    ];
    final changes = [for (final i in items) if (i.change case final c?) c];
    if (changes.isEmpty) {
      return ProgressSummary(band: ProgressBand.settingStartingPoint, items: items);
    }
    final m = _median(changes);
    return ProgressSummary(band: bandFor(m, config), items: items, medianChange: m);
  }

  /// Monthly intelligibility %: of the items in [setIds] attempted in
  /// [testAttempts], the share the recogniser understood. Uses each item's
  /// latest attempt. An item is understood when its server CER — or, on
  /// device, the CER of the transcript against [targets] (target +
  /// accepted alternates, keyed by item id) — is ≤
  /// [BaselineConfig.intelligibleCer]. With neither, the device match
  /// score must reach (1 − threshold) × 100.
  static IntelligibilityResult intelligibility(
    List<OralAttempt> testAttempts,
    Set<String> setIds, {
    Map<String, List<String>> targets = const {},
    BaselineConfig config = const BaselineConfig(),
  }) {
    final latest = <String, OralAttempt>{};
    for (final a in testAttempts) {
      if (!setIds.contains(a.itemId)) continue;
      final prev = latest[a.itemId];
      if (prev == null || !a.at.isBefore(prev.at)) latest[a.itemId] = a;
    }
    var understood = 0;
    final missed = <String>[];
    for (final id in setIds) {
      final a = latest[id];
      if (a == null) continue;
      if (_understood(a, targets[id] ?? const [], config.intelligibleCer)) {
        understood++;
      } else {
        missed.add(id);
      }
    }
    return IntelligibilityResult(
      understood: understood,
      attempted: latest.length,
      total: setIds.length,
      missed: missed,
    );
  }

  /// Band for this month's test against the first complete one (the
  /// starting point). One item of 20 is 5 points.
  static ProgressBand compareIntelligibility(
    IntelligibilityResult? first,
    IntelligibilityResult current, {
    BaselineConfig config = const BaselineConfig(),
  }) {
    if (first == null || !first.isComplete || identical(first, current)) {
      return ProgressBand.settingStartingPoint;
    }
    return bandFor(current.percent - first.percent, config);
  }

  static bool _understood(OralAttempt a, List<String> targets, double threshold) {
    if (a.cer case final c?) return c <= threshold;
    final heard = a.transcript;
    if (heard != null && heard.trim().isNotEmpty && targets.isNotEmpty) {
      return targets.map((t) => characterErrorRate(t, heard)).reduce(_min) <= threshold;
    }
    return a.score >= (1 - threshold) * 100;
  }

  /// Character error rate of [heard] against [target]: grapheme-level edit
  /// distance ÷ target length, after lower-casing and stripping
  /// punctuation. Tamil vowel signs stay attached to their letter.
  static double characterErrorRate(String target, String heard) {
    final t = _norm(target).characters.toList();
    final h = _norm(heard).characters.toList();
    if (t.isEmpty) return h.isEmpty ? 0 : 1;
    var prev = List<int>.generate(h.length + 1, (j) => j);
    for (var i = 1; i <= t.length; i++) {
      final cur = List<int>.filled(h.length + 1, 0)..[0] = i;
      for (var j = 1; j <= h.length; j++) {
        final cost = t[i - 1] == h[j - 1] ? 0 : 1;
        cur[j] = [prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + cost].reduce((a, b) => a < b ? a : b);
      }
      prev = cur;
    }
    return prev[h.length] / t.length;
  }

  static String _norm(String s) => s
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9஀-௿\s]'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  static double _min(double a, double b) => a < b ? a : b;

  static double _median(Iterable<double> xs) {
    final s = xs.toList()..sort();
    if (s.isEmpty) return 0;
    final m = s.length ~/ 2;
    return s.length.isOdd ? s[m] : (s[m - 1] + s[m]) / 2;
  }
}

double _clamp100(double v) => v.clamp(0, 100).toDouble();
