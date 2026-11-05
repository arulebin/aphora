import 'package:aphora/data/intake/condition.dart';

/// A completed intake as stored in `users/{uid}.intake`:
/// `{version, answers, result: {condition, startLevel, focus, redFlags},
///   summary, completedAt}`. The pack is also stored top-level as
/// `users/{uid}.condition`.
class IntakeRecord {
  const IntakeRecord({
    required this.version,
    required this.answers,
    required this.condition,
    required this.startLevel,
    required this.focus,
    required this.redFlags,
    required this.summary,
    required this.completedAt,
  });

  final String version;
  final Map<String, String> answers;
  final Condition condition;

  /// 1 (easiest) to 3.
  final int startLevel;

  /// `FocusArea` ids, most important first.
  final List<String> focus;

  /// `RedFlag` ids.
  final List<String> redFlags;

  /// Plain-sentence summary for the therapist (template-built).
  final String summary;
  final DateTime completedAt;

  Map<String, dynamic> toMap() => {
        'version': version,
        'answers': answers,
        'result': {
          'condition': condition.id,
          'startLevel': startLevel,
          'focus': focus,
          'redFlags': redFlags,
        },
        'summary': summary,
        'completedAt': completedAt.toIso8601String(),
      };

  /// Null for a missing or malformed map, so old documents still load.
  static IntakeRecord? tryFromMap(Object? raw) {
    if (raw is! Map) return null;
    try {
      final result = (raw['result'] as Map?) ?? const {};
      return IntakeRecord(
        version: raw['version']?.toString() ?? '',
        answers: ((raw['answers'] as Map?) ?? const {})
            .map((k, v) => MapEntry(k.toString(), v.toString())),
        condition: Condition.fromId(result['condition']),
        startLevel: (result['startLevel'] as num?)?.toInt() ?? 2,
        focus: List<String>.from((result['focus'] as List?) ?? const []),
        redFlags: List<String>.from((result['redFlags'] as List?) ?? const []),
        summary: raw['summary']?.toString() ?? '',
        completedAt: DateTime.tryParse(raw['completedAt']?.toString() ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );
    } catch (_) {
      return null;
    }
  }
}
