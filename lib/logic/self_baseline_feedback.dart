import 'package:aphora/data/learning/oral/oral_rehab_pack.dart';
import 'package:aphora/data/learning/practice_catalog.dart';
import 'package:aphora/data/models/oral_records.dart';
import 'package:aphora/data/models/practice_record.dart';
import 'package:aphora/logic/baseline_scoring.dart';
import 'package:aphora/logic/language_service.dart';

/// What the oral-cancer pack shows: progress against the person's own
/// starting point ([BaselineScoring]). The patient gets only band
/// messages — never a number, never "wrong"; numbers are for the
/// therapist.
abstract final class SelfBaselineFeedback {
  /// Attempt records → scoring attempts (records without any score are
  /// skipped, never counted as zero). Picture taps are not speech.
  static List<OralAttempt> fromRecords(Iterable<AttemptRecord> records) => [
        for (final r in records)
          if (r.method != 'tap')
            if (OralAttempt.fromRecord(r) case final a?) a,
      ];

  /// One attempt just made in a session.
  static OralAttempt? attempt({
    required String itemId,
    required DateTime at,
    required String method,
    required double score,
    double? cer,
    String? transcript,
  }) =>
      OralAttempt.from(
        itemId: itemId,
        at: at,
        cer: cer,
        serverScore: method == 'server' ? score : null,
        deviceScore: method == 'server' ? null : score,
        transcript: transcript,
      );

  /// Band for [itemId] after its latest attempt ([history] includes it).
  /// The first attempts set the starting point.
  static ProgressBand bandFor(String itemId, List<OralAttempt> history,
          {DateTime? since}) =>
      BaselineScoring.scoreItem(itemId, history, since: since).band;

  /// The two lines the patient sees for [band].
  static ({String title, String detail}) messageFor(ProgressBand band, Language language) =>
      (
        title: language == Language.tamil ? band.message.ta : band.message.en,
        detail: language == Language.tamil ? band.detail.ta : band.detail.en,
      );

  /// Scores a finished clarity check from this session's attempts.
  static IntelligibilityResult clarity(
    List<OralAttempt> testAttempts,
    List<PracticeItem> items,
    Language language,
  ) =>
      BaselineScoring.intelligibility(
        testAttempts,
        OralRehabPack.intelligibilityIds(language),
        targets: {for (final i in items) i.id: [i.target, ...i.alternates]},
      );

  /// This check against the starting point (the first complete earlier
  /// test; this one becomes it when there is none).
  static ProgressBand clarityBand(List<ClarityTest> earlier, IntelligibilityResult now) =>
      BaselineScoring.compareIntelligibility(
          ClarityTest.startingPoint(earlier)?.result, now);
}
