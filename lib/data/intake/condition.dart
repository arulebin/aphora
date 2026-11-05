import 'package:aphora/logic/language_service.dart';

/// Which condition pack a user practises with. Chosen by the intake
/// questionnaire (`IntakeEngine`) and stored as `users/{uid}.condition`.
///
/// These are *pack* names, not diagnoses: the app screens and routes, a
/// therapist diagnoses.
enum Condition {
  childSpeechDelay('child_speech_delay'),
  adultAphasia('adult_aphasia'),
  oralCancerRehab('oral_cancer_rehab'),
  unknown('unknown');

  const Condition(this.id);

  /// Stable value stored in Firestore.
  final String id;

  /// Missing or unrecognised values (accounts created before the intake
  /// existed) read as [unknown].
  static Condition fromId(Object? id) => Condition.values.firstWhere(
        (c) => c.id == id,
        orElse: () => Condition.unknown,
      );

  /// What the family sees, in the app language.
  String get label => tr(english, tamil);

  String get english => switch (this) {
        Condition.childSpeechDelay => "Children's speech and language",
        Condition.adultAphasia => 'Speech after a stroke',
        Condition.oralCancerRehab => 'Speech after mouth or tongue surgery',
        Condition.unknown => 'General speech practice',
      };

  String get tamil => switch (this) {
        Condition.childSpeechDelay => 'குழந்தைகளின் பேச்சும் மொழியும்',
        Condition.adultAphasia => 'பக்கவாதத்துக்குப் பின் பேச்சு',
        Condition.oralCancerRehab => 'வாய் / நாக்கு அறுவைக்குப் பின் பேச்சு',
        Condition.unknown => 'பொதுப் பேச்சுப் பயிற்சி',
      };

  /// Pack name for the therapist screens (English only, like the rest of
  /// the therapist UI).
  String get therapistLabel => switch (this) {
        Condition.childSpeechDelay => "Children's speech delay pack",
        Condition.adultAphasia => 'Adult aphasia pack (post-stroke)',
        Condition.oralCancerRehab => 'Oral-cancer speech rehab pack',
        Condition.unknown => 'No pack yet (general practice)',
      };

  // Whether a condition has its own exercises yet is decided by the pack
  // registry: `ConditionPacks.contentPending`.
}
