import 'package:aphora/data/learning/practice_catalog.dart';
import 'package:aphora/logic/language_service.dart';

/// Where in the mouth a target sound is made. The groups run from the
/// easiest anchor (lips — usually untouched by tongue surgery) to the
/// sounds that need the parts of the tongue most often removed.
enum OralSoundGroup {
  /// p b m w f v · ப ம வ — easy anchors, practised first and as warm-up.
  lips,

  /// t d n l s r · த ட ந ண ன ல ள ழ ர ற — most affected after partial
  /// glossectomy (front/side of the tongue).
  tongueTip,

  /// k g ng · க ங — affected when the back of the tongue is removed.
  tongueBack,

  /// ch j sh y · ச ஞ ய — tongue body against the hard palate.
  palatal,
}

/// Position of the target sound in the word. Tamil does not allow
/// ட ண ள ழ ற ன (or ங ஞ, mostly) at the start of a word, so those are
/// practised in the middle of words only.
enum SoundPosition { initial, medial }

/// The six content groups of the oral-cancer pack. See
/// `OralRehabPack.practiceKindFor` for how they map onto the app's
/// [PracticeKind]s.
enum OralItemKind {
  /// Sound + vowel (L1), vowel ladder on one sound (L2), alternating
  /// places (L3).
  syllables,

  /// Words with the target sound at the start or in the middle.
  words,

  /// Two words that differ by one sound — listen, then say both so they
  /// sound different.
  minimalPairs,

  /// Everyday needs, safety, personal details, shop / bus / phone.
  phrases,

  /// The same kind of phrase said one word at a time with pauses. The UI
  /// shows a pacing cue ([OralItem.pacing]).
  clearSpeech,

  /// The fixed monthly re-test list. Never shuffled, never changed.
  intelligibility,
}

/// Which language an item's *spoken target* is in.
///
/// * [both] — a translation pair (phrases): [OralItem.en] is the target in
///   English mode and [OralItem.ta] in Tamil mode.
/// * [ta] — Tamil-only sound work: [OralItem.ta] is the target and
///   [OralItem.en] is its English meaning.
/// * [en] — English-only sound work: [OralItem.en] is the target and
///   [OralItem.ta] is a Tamil-script reading aid (how it sounds).
enum OralLang { both, ta, en }

/// Daily-life situation of a phrase; lets the UI group or filter them.
enum OralSituation { needs, health, safety, family, personal, shop, travel, phone, social }

/// One item of the oral-cancer pack.
class OralItem {
  const OralItem({
    required this.id,
    required this.kind,
    required this.level,
    required this.en,
    required this.ta,
    this.lang = OralLang.both,
    this.group,
    this.sounds = const [],
    this.position,
    this.taSpoken = const [],
    this.enAlternates = const [],
    this.hintEn,
    this.hintTa,
    this.pacing = false,
    this.pair,
    this.situation,
  });

  /// Stable id (`oral_…`), used in Firestore attempts and baseline scoring.
  /// Never rename one: the person's starting point is keyed on it.
  final String id;
  final OralItemKind kind;

  /// 1 (easiest) – 3. Matches `IntakeResult.startLevel`.
  final int level;

  /// See [OralLang] for which of these is the target.
  final String en;
  final String ta;
  final OralLang lang;

  /// Primary sound group practised (null for phrases).
  final OralSoundGroup? group;

  /// Target sounds in the item, e.g. `['த']` or `['t', 'd']`.
  final List<String> sounds;
  final SoundPosition? position;

  /// Spoken-Tamil forms the recogniser may return (தண்ணி for தண்ணீர்).
  final List<String> taSpoken;
  final List<String> enAlternates;

  /// Item-specific cue. When null, the UI shows the sound group's hint
  /// (`OralRehabPack.groupHint`) or the clear-speech cue.
  final String? hintEn;
  final String? hintTa;

  /// Clear-speech item: show the pacing cue and reveal [chunks] one at a
  /// time ("one word at a time").
  final bool pacing;

  /// Minimal pair: the two contrasting words, in the item's target
  /// language (`('வலி', 'வழி')`, `('tea', 'key')`).
  final (String, String)? pair;
  final OralSituation? situation;

  /// Placeholders the user fills once (`{name}`, `{phone}` …).
  static final _slot = RegExp(r'\{(\w+)\}');

  List<String> get placeholders =>
      {for (final m in _slot.allMatches('$en $ta')) m.group(1)!}.toList();
  bool get isTemplate => placeholders.isNotEmpty;

  bool availableIn(Language language) => switch (lang) {
        OralLang.both => true,
        OralLang.ta => language == Language.tamil,
        OralLang.en => language == Language.english,
      };

  /// The text the person says in [language] (templates filled from
  /// [personal]; returns null when a placeholder has no value yet).
  String? targetIn(Language language, {Map<String, String> personal = const {}}) {
    final raw = language == Language.tamil ? ta : en;
    return _fill(raw, personal);
  }

  /// What is shown under the target: the other language.
  String glossIn(Language language) => language == Language.tamil ? en : ta;

  String? hintIn(Language language) => language == Language.tamil ? hintTa : hintEn;

  /// Pause points for the pacing cue: one chunk per word.
  List<String> chunks(Language language, {Map<String, String> personal = const {}}) =>
      (targetIn(language, personal: personal) ?? '')
          .split(RegExp(r'\s+'))
          .where((w) => w.isNotEmpty)
          .toList();

  static String? _fill(String raw, Map<String, String> personal) {
    var missing = false;
    final out = raw.replaceAllMapped(_slot, (m) {
      final v = personal[m.group(1)]?.trim();
      if (v == null || v.isEmpty) {
        missing = true;
        return m.group(0)!;
      }
      return v;
    });
    return missing ? null : out;
  }

  /// Converts to the engine's [PracticeItem]. `voiceKey` becomes
  /// `<id>_ta` / `<id>_en`, so Family Voice / therapist recordings work
  /// unchanged. Returns null for a template that is not filled yet, or an
  /// item that is not available in [language].
  PracticeItem? toPracticeItem(Language language, {Map<String, String> personal = const {}}) {
    if (!availableIn(language)) return null;
    final target = targetIn(language, personal: personal);
    if (target == null) return null;
    final tamil = language == Language.tamil;
    return PracticeItem(
      id: id,
      target: target,
      alternates: [
        for (final a in tamil ? taSpoken : enAlternates)
          if (_fill(a, personal) case final f?) f,
      ],
      meaning: _fill(glossIn(language), personal),
      locale: tamil ? 'ta-IN' : 'en-IN',
      semanticCue: hintIn(language),
    );
  }
}
