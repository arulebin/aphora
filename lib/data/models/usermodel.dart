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

  // Caregiver/Therapist linkage
  String? linkedCaregiverId;
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
    required this.createdAt,
    required this.updatedAt,
  }) : dailyActivity = dailyActivity ?? <String, int>{};

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
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
