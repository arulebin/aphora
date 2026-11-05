import 'package:aphora/logic/language_service.dart';

/// Vernacura keeps the original profile fields in Firestore (`aphasiaType`,
/// `severityLevel`, `gender`) so no data migrates, but now describes a child
/// with speech delay. Stored values stay stable strings; these map them to
/// the words a parent and the therapist read, in the app language.
abstract final class ChildProfile {
  /// Stored in `aphasiaType`: the parent's main concern.
  static const concerns = ['Not sure', 'sounds', 'late', 'words'];

  /// Stored in `severityLevel`: how easily others understand the child.
  static const clarities = ['mild', 'moderate', 'severe'];

  static const genders = ['Male', 'Female', 'Other'];

  static String concern(String v) => switch (v) {
        'sounds' => tr('Some sounds are unclear', 'சில ஒலிகள் தெளிவில்லை'),
        'late' => tr('Started talking late', 'தாமதமாகப் பேசத் தொடங்கியது'),
        'words' => tr('Uses only a few words', 'சில சொற்களை மட்டுமே பேசுகிறது'),
        '' || 'Not sure' => tr('Not sure', 'தெரியவில்லை'),
        _ => v, // accounts created before the switch (Broca, Wernicke…)
      };

  static String clarity(String v) => switch (v) {
        'mild' => tr('Mostly easy to understand', 'பெரும்பாலும் புரிகிறது'),
        'moderate' => tr('Sometimes hard to understand', 'சில நேரம் புரிவது கடினம்'),
        'severe' => tr('Often hard to understand', 'அடிக்கடி புரிவது கடினம்'),
        '' => '—',
        _ => v,
      };

  static String gender(String v) => switch (v) {
        'Male' => tr('Boy', 'ஆண் குழந்தை'),
        'Female' => tr('Girl', 'பெண் குழந்தை'),
        'Other' => tr('Other', 'மற்றவை'),
        '' => '—',
        _ => v,
      };
}
