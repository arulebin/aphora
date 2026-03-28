class UserModel {
  final String uid;
  final String name;
  final String email;
  final String role; // "patient", "caregiver", "therapist"
  final int age;
  final String gender;
  final String languagePreference; // e.g., "Tamil", "English"

  // Aphasia-specific fields
  final String aphasiaType; // Broca, Wernicke, Global, etc.
  final String severityLevel; // mild, moderate, severe
  final List<String> goals; // speech goals

  // Progress tracking
  final int sessionsCompleted;
  final double progressScore; // AI-generated score
  final List<String> completedExercises;
  // Caregiver/Therapist linkage
  final String? linkedCaregiverId;
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
    required this.languagePreference,
    required this.aphasiaType,
    required this.severityLevel,
    required this.goals,
    required this.sessionsCompleted,
    required this.progressScore,
    required this.completedExercises,
    this.linkedCaregiverId,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convert to Map (for Firebase)
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'role': role,
      'age': age,
      'gender': gender,
      'languagePreference': languagePreference,
      'aphasiaType': aphasiaType,
      'severityLevel': severityLevel,
      'goals': goals,
      'sessionsCompleted': sessionsCompleted,
      'progressScore': progressScore,
      'completedExercises': completedExercises,
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
      languagePreference: map['languagePreference'] ?? 'Tamil',
      aphasiaType: map['aphasiaType'] ?? '',
      severityLevel: map['severityLevel'] ?? '',
      goals: List<String>.from(map['goals'] ?? []),
      sessionsCompleted: map['sessionsCompleted'] ?? 0,
      progressScore: (map['progressScore'] ?? 0).toDouble(),
      completedExercises: List<String>.from(map['completedExercises'] ?? []),
      linkedCaregiverId: map['linkedCaregiverId'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  // CopyWith (for updates)
  UserModel copyWith({
    String? name,
    String? email,
    String? role,
    int? age,
    String? gender,
    String? languagePreference,
    String? aphasiaType,
    String? severityLevel,
    List<String>? goals,
    int? sessionsCompleted,
    double? progressScore,
    List<String>? completedExercises,
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
      languagePreference: languagePreference ?? this.languagePreference,
      aphasiaType: aphasiaType ?? this.aphasiaType,
      severityLevel: severityLevel ?? this.severityLevel,
      goals: goals ?? this.goals,
      sessionsCompleted: sessionsCompleted ?? this.sessionsCompleted,
      progressScore: progressScore ?? this.progressScore,
      completedExercises: completedExercises ?? this.completedExercises,
      linkedCaregiverId: linkedCaregiverId ?? this.linkedCaregiverId,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}