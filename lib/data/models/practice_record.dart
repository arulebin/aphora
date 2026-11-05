import 'package:cloud_firestore/cloud_firestore.dart';

/// One scored answer. Stored at `users/{uid}/attempts/{autoId}` so the
/// linked therapist can review real attempts, not just averages.
class AttemptRecord {
  AttemptRecord({
    required this.taskId,
    required this.category,
    required this.target,
    required this.spoken,
    required this.score,
    required this.method,
    required this.assisted,
    required this.createdAt,
    this.hintsUsed = 0,
    this.id = '',
    this.cer,
  });

  final String id;
  final String taskId;

  /// letters | words | sentences | naming | phonetic | picture | assessment
  final String category;
  final String target;
  final String spoken;

  /// 0–100.
  final double score;

  /// 'device' (on-phone speech recognition), 'server' (acoustic scoring),
  /// 'typed', or 'tap' (picture match).
  final String method;

  /// Done with a caregiver / volunteer helping.
  final bool assisted;

  /// Rungs of the cueing ladder used before this attempt (0–3: meaning
  /// hint, first sound, full model). Older docs have no field → 0.
  final int hintsUsed;
  final DateTime createdAt;

  /// Server character error rate (0–1+) when the server scored the
  /// attempt; used by the oral-cancer self-baseline scoring.
  final double? cer;

  Map<String, dynamic> toMap() => {
        'taskId': taskId,
        'category': category,
        'target': target,
        'spoken': spoken,
        'score': score,
        'method': method,
        'assisted': assisted,
        'hintsUsed': hintsUsed,
        'createdAt': Timestamp.fromDate(createdAt),
        if (cer != null) 'cer': cer,
      };

  factory AttemptRecord.fromMap(String id, Map<String, dynamic> m) =>
      AttemptRecord(
        id: id,
        taskId: m['taskId']?.toString() ?? '',
        category: m['category']?.toString() ?? '',
        target: m['target']?.toString() ?? '',
        spoken: m['spoken']?.toString() ?? '',
        score: (m['score'] as num? ?? 0).toDouble(),
        method: m['method']?.toString() ?? 'device',
        assisted: m['assisted'] == true,
        hintsUsed: (m['hintsUsed'] as num? ?? 0).toInt(),
        createdAt: _date(m['createdAt']),
        cer: (m['cer'] as num?)?.toDouble(),
      );
}

/// One finished practice session. Stored at `users/{uid}/sessions/{autoId}`.
class SessionRecord {
  SessionRecord({
    required this.kind,
    required this.title,
    required this.itemCount,
    required this.averageScore,
    required this.minutes,
    required this.assisted,
    required this.createdAt,
    this.helperName,
    this.note,
    this.id = '',
  });

  final String id;
  final String kind;
  final String title;
  final int itemCount;
  final double averageScore;
  final int minutes;
  final bool assisted;
  final String? helperName;

  /// Free-text observation from the caregiver / volunteer.
  final String? note;
  final DateTime createdAt;

  Map<String, dynamic> toMap() => {
        'kind': kind,
        'title': title,
        'itemCount': itemCount,
        'averageScore': averageScore,
        'minutes': minutes,
        'assisted': assisted,
        'helperName': helperName,
        'note': note,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory SessionRecord.fromMap(String id, Map<String, dynamic> m) =>
      SessionRecord(
        id: id,
        kind: m['kind']?.toString() ?? '',
        title: m['title']?.toString() ?? 'Practice',
        itemCount: (m['itemCount'] as num? ?? 0).toInt(),
        averageScore: (m['averageScore'] as num? ?? 0).toDouble(),
        minutes: (m['minutes'] as num? ?? 0).toInt(),
        assisted: m['assisted'] == true,
        helperName: m['helperName'] as String?,
        note: m['note'] as String?,
        createdAt: _date(m['createdAt']),
      );
}

DateTime _date(Object? v) {
  if (v is Timestamp) return v.toDate();
  if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
  return DateTime.now();
}
