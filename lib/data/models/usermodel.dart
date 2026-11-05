import 'package:aphora/data/intake/condition.dart';
import 'package:aphora/data/intake/intake_record.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String role; // "patient", "caregiver", "therapist"
  final int age;
  final String gender;
  final String phoneNumber;
  final String languagePreference; // e.g., "Tamil", "English"

  // Aphasia-specific fields
  final String aphasiaType; // Broca, Wernicke, Global, etc.
  final String severityLevel; // mild, moderate, severe
  final List<String> goals; // speech goals

  // Progress tracking
  final int sessionsCompleted;
  double progressScore; // AI-generated score
  List<String> completedExercises;

  // Analytics
  final double averageAccuracy;
  final double averageFluency;

  /// Per-day exercise count, keyed by ISO date (yyyy-MM-dd).
  /// Used to render the homepage's Recent Activity chart.
  final Map<String, int> dailyActivity;

  /// Returns the activity counts for the most recent [days] days, oldest first.
  /// The list always has [days] entries; missing days fill with 0.
  List<int> recentActivityCounts({int days = 7}) {
    final now = DateTime.now();
    final result = <int>[];
    for (int i = days - 1; i >= 0; i--) {
      final d = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      final key =
          '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      result.add(dailyActivity[key] ?? 0);
    }
    return result;
  }

  /// Total scored attempts (sessionsCompleted counts finished sessions).
  /// Older documents lack it, so it falls back to sessionsCompleted.
  final int totalAttempts;

  /// Latest placement test result, 0–100, and when it was taken.
  final double? preAssessmentScore;
  final DateTime? preAssessmentDate;

  /// 'letters' | 'words' | 'sentences' — what the placement test suggests.
  final String? recommendedFocus;

  /// A short note the linked therapist leaves for the patient/caregiver.
  final String? therapistNote;

  /// Condition pack chosen by the intake questionnaire. Accounts created
  /// before the intake existed read as [Condition.unknown].
  final Condition condition;

  /// The latest completed intake questionnaire, or null if never answered.
  final IntakeRecord? intake;

  /// Child wording applies to the children's pack and to older accounts
  /// that never answered the intake (all of them were children's accounts).
  bool get isChild =>
      condition == Condition.childSpeechDelay ||
      (condition == Condition.unknown && intake == null);

  // Caregiver/Therapist linkage (holds the therapist's 6-char code).
  String? linkedCaregiverId;

  bool get hasTherapist =>
      linkedCaregiverId != null && linkedCaregiverId!.isNotEmpty;

  /// Consecutive days (ending today or yesterday) with at least one exercise.
  int get streakDays {
    var day = DateTime.now();
    String k(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    if ((dailyActivity[k(day)] ?? 0) == 0) {
      day = day.subtract(const Duration(days: 1));
    }
    var streak = 0;
    while ((dailyActivity[k(day)] ?? 0) > 0) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }
  // Metadata
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.age,
    required this.gender,
    required this.phoneNumber,
    required this.languagePreference,
    required this.aphasiaType,
    required this.severityLevel,
    required this.goals,
    required this.sessionsCompleted,
    required this.progressScore,
    required this.completedExercises,
    this.averageAccuracy = 0.0,
    this.averageFluency = 0.0,
    Map<String, int>? dailyActivity,
    this.linkedCaregiverId,
    int? totalAttempts,
    this.preAssessmentScore,
    this.preAssessmentDate,
    this.recommendedFocus,
    this.therapistNote,
    this.condition = Condition.unknown,
    this.intake,
    required this.createdAt,
    required this.updatedAt,
  }) : dailyActivity = dailyActivity ?? <String, int>{},
       totalAttempts = totalAttempts ?? sessionsCompleted;

  // Convert to Map (for Firebase)
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'role': role,
      'age': age,
      'gender': gender,
      'phoneNumber': phoneNumber,
      'languagePreference': languagePreference,
      'aphasiaType': aphasiaType,
      'severityLevel': severityLevel,
      'goals': goals,
      'sessionsCompleted': sessionsCompleted,
      'progressScore': progressScore,
      'completedExercises': completedExercises,
      'averageAccuracy': averageAccuracy,
      'averageFluency': averageFluency,
      'dailyActivity': dailyActivity,
      'linkedCaregiverId': linkedCaregiverId,
      'totalAttempts': totalAttempts,
      'preAssessmentScore': preAssessmentScore,
      'preAssessmentDate': preAssessmentDate?.toIso8601String(),
      'recommendedFocus': recommendedFocus,
      'therapistNote': therapistNote,
      'condition': condition.id,
      if (intake != null) 'intake': intake!.toMap(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Convert from Map (from Firebase)
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'patient',
      age: map['age'] ?? 0,
      gender: map['gender'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      languagePreference: map['languagePreference'] ?? 'Tamil',
      aphasiaType: map['aphasiaType'] ?? '',
      severityLevel: map['severityLevel'] ?? '',
      goals: List<String>.from(map['goals'] ?? []),
      sessionsCompleted: map['sessionsCompleted'] ?? 0,
      progressScore: ((map['progressScore'] ?? 0) as num).toDouble(),
      completedExercises: List<String>.from(map['completedExercises'] ?? []),
      averageAccuracy: ((map['averageAccuracy'] ?? 0) as num).toDouble(),
      averageFluency: ((map['averageFluency'] ?? 0) as num).toDouble(),
      dailyActivity: (map['dailyActivity'] as Map?)?.map(
            (key, value) => MapEntry(key.toString(), (value as num).toInt()),
          ) ??
          <String, int>{},
      linkedCaregiverId: map['linkedCaregiverId'],
      totalAttempts: (map['totalAttempts'] as num?)?.toInt(),
      preAssessmentScore: (map['preAssessmentScore'] as num?)?.toDouble(),
      preAssessmentDate: DateTime.tryParse(
        map['preAssessmentDate']?.toString() ?? '',
      ),
      recommendedFocus: map['recommendedFocus'] as String?,
      therapistNote: map['therapistNote'] as String?,
      condition: Condition.fromId(map['condition']),
      intake: IntakeRecord.tryFromMap(map['intake']),
      createdAt: DateTime.parse(
        map['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        map['updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  // CopyWith (for updates)
  UserModel copyWith({
    String? name,
    String? email,
    String? role,
    int? age,
    String? gender,
    String? phoneNumber,
    String? languagePreference,
    String? aphasiaType,
    String? severityLevel,
    List<String>? goals,
    int? sessionsCompleted,
    double? progressScore,
    List<String>? completedExercises,
    double? averageAccuracy,
    double? averageFluency,
    Map<String, int>? dailyActivity,
    String? linkedCaregiverId,
    int? totalAttempts,
    double? preAssessmentScore,
    DateTime? preAssessmentDate,
    String? recommendedFocus,
    String? therapistNote,
    Condition? condition,
    IntakeRecord? intake,
    DateTime? updatedAt,
  }) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      languagePreference: languagePreference ?? this.languagePreference,
      aphasiaType: aphasiaType ?? this.aphasiaType,
      severityLevel: severityLevel ?? this.severityLevel,
      goals: goals ?? this.goals,
      sessionsCompleted: sessionsCompleted ?? this.sessionsCompleted,
      progressScore: progressScore ?? this.progressScore,
      completedExercises: completedExercises ?? this.completedExercises,
      averageAccuracy: averageAccuracy ?? this.averageAccuracy,
      averageFluency: averageFluency ?? this.averageFluency,
      dailyActivity: dailyActivity ?? this.dailyActivity,
      linkedCaregiverId: linkedCaregiverId ?? this.linkedCaregiverId,
      totalAttempts: totalAttempts ?? this.totalAttempts,
      preAssessmentScore: preAssessmentScore ?? this.preAssessmentScore,
      preAssessmentDate: preAssessmentDate ?? this.preAssessmentDate,
      recommendedFocus: recommendedFocus ?? this.recommendedFocus,
      therapistNote: therapistNote ?? this.therapistNote,
      condition: condition ?? this.condition,
      intake: intake ?? this.intake,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
