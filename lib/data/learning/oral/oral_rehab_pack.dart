import 'dart:math';

import 'package:aphora/data/learning/oral/oral_content.dart';
import 'package:aphora/data/learning/oral/oral_item.dart';
import 'package:aphora/data/learning/practice_catalog.dart';
import 'package:aphora/logic/language_service.dart';

export 'oral_item.dart';

/// Bilingual text pair, independent of the current app language so the
/// pack can be tested and rendered for either language.
typedef OralText = ({String en, String ta});

extension OralTextIn on OralText {
  String inLanguage(Language l) => l == Language.tamil ? ta : en;
}

/// Surgery type from the intake answer `o_surgery`.
enum OralSurgery {
  partTongue('part'),
  mostTongue('most'),
  jaw('jaw'),
  unsure('unsure');

  const OralSurgery(this.id);
  final String id;

  static OralSurgery fromId(Object? id) =>
      values.firstWhere((s) => s.id == id, orElse: () => OralSurgery.unsure);
}

/// Speech practice for adults after mouth / tongue cancer surgery
/// (`Condition.oralCancerRehab`). Pure content + selection; the session UI
/// consumes it through [itemsFor] / [dailySession]. See `README.md` next to
/// this file for the integration contract.
abstract final class OralRehabPack {
  static const String conditionId = 'oral_cancer_rehab';
  static const int maxLevel = 3;

  static List<OralItem> get all => oralItems;

  static final Map<String, OralItem> _byId = {for (final i in oralItems) i.id: i};
  static OralItem? byId(String id) => _byId[id];

  // ── Safety ───────────────────────────────────────────────────────────

  /// Show before the first session and on the pack's home card. Never hide
  /// it behind a setting.
  static const OralText safetyLine = (
    en: 'Start these exercises only after your surgeon or speech therapist '
        'says it is OK. Stop and rest if you feel pain, or if there is '
        'bleeding or swelling, and tell your care team.',
    ta: 'உங்கள் அறுவை மருத்துவர் அல்லது பேச்சுப் பயிற்சியாளர் சரி என்று '
        'சொன்ன பிறகே இந்தப் பயிற்சிகளைத் தொடங்குங்கள். வலி, ரத்தம் வருதல் '
        'அல்லது வீக்கம் இருந்தால் உடனே நிறுத்தி ஓய்வெடுங்கள்; உங்கள் '
        'மருத்துவக் குழுவிடம் சொல்லுங்கள்.',
  );

  /// Short form for the in-session footer / pause sheet.
  static const OralText restCue = (
    en: 'Pain or bleeding? Stop now and rest.',
    ta: 'வலி அல்லது ரத்தம் வருகிறதா? இப்போதே நிறுத்தி ஓய்வெடுங்கள்.',
  );

  /// Intake red flags (`IntakeResult.redFlags`) that mean: show the safety
  /// line as a blocking notice and do not start practice until the person
  /// confirms their team has said yes.
  static const Set<String> holdFlags = {'ask_surgeon', 'oral_pain', 'radiotherapy_team'};

  // ── Kinds ────────────────────────────────────────────────────────────

  /// Which [PracticeKind] runs each content group.
  static PracticeKind practiceKindFor(OralItemKind kind) => switch (kind) {
        OralItemKind.syllables => PracticeKind.letters,
        OralItemKind.words => PracticeKind.words,
        OralItemKind.minimalPairs => PracticeKind.drill,
        OralItemKind.phrases => PracticeKind.functional,
        OralItemKind.clearSpeech => PracticeKind.clearSpeech,
        OralItemKind.intelligibility => PracticeKind.assessment,
      };

  /// Reverse of [practiceKindFor]; null for kinds this pack does not use:
  /// naming and the aphasia language tasks (word-finding is not the
  /// problem after oral surgery) and `phonetic` ("Copy the voice" scores
  /// against a healthy voice; this pack compares only with the person's
  /// own starting point). `sentences` is accepted as an alias of phrases.
  static OralItemKind? oralKindFor(PracticeKind kind) => switch (kind) {
        PracticeKind.letters => OralItemKind.syllables,
        PracticeKind.words => OralItemKind.words,
        PracticeKind.drill => OralItemKind.minimalPairs,
        PracticeKind.functional || PracticeKind.sentences => OralItemKind.phrases,
        PracticeKind.clearSpeech => OralItemKind.clearSpeech,
        PracticeKind.assessment => OralItemKind.intelligibility,
        PracticeKind.naming ||
        PracticeKind.phonetic ||
        PracticeKind.automatic ||
        PracticeKind.repetition ||
        PracticeKind.completion =>
          null,
      };

  /// The PracticeKinds this pack offers, in the order to show them.
  static const List<PracticeKind> kinds = [
    PracticeKind.letters,
    PracticeKind.words,
    PracticeKind.drill,
    PracticeKind.functional,
    PracticeKind.clearSpeech,
    PracticeKind.assessment,
  ];

  static OralText title(OralItemKind kind) => switch (kind) {
        OralItemKind.syllables => (en: 'Sound warm-up', ta: 'ஒலிப் பயிற்சி'),
        OralItemKind.words => (en: 'Clear words', ta: 'தெளிவான சொற்கள்'),
        OralItemKind.minimalPairs => (en: 'Sound pairs', ta: 'ஒலி இணைகள்'),
        OralItemKind.phrases => (en: 'Everyday phrases', ta: 'அன்றாடச் சொற்றொடர்கள்'),
        OralItemKind.clearSpeech => (en: 'One word at a time', ta: 'ஒவ்வொரு சொல்லாக'),
        OralItemKind.intelligibility => (en: 'Monthly clarity check', ta: 'மாதாந்திரத் தெளிவுப் பரிசோதனை'),
      };

  static OralText description(OralItemKind kind) => switch (kind) {
        OralItemKind.syllables => (
            en: 'Start with easy lip sounds, then the sounds that need the tongue',
            ta: 'எளிய உதட்டு ஒலிகளில் தொடங்கி, நாக்கு தேவைப்படும் ஒலிகளுக்குச் செல்வோம்',
          ),
        OralItemKind.words => (
            en: 'Say each word slowly and fully — close enough is good',
            ta: 'ஒவ்வொரு சொல்லையும் மெதுவாக, முழுமையாகச் சொல்லுங்கள் — அருகில் வந்தாலே நல்லது',
          ),
        OralItemKind.minimalPairs => (
            en: 'Listen to two words that differ by one sound, then make them sound different',
            ta: 'ஒரே ஒலியில் மாறும் இரண்டு சொற்களைக் கேட்டு, வேறுபாடு தெரியும்படி சொல்லுங்கள்',
          ),
        OralItemKind.phrases => (
            en: 'Words for daily needs, safety, the shop, the bus and the phone',
            ta: 'அன்றாடத் தேவைகள், பாதுகாப்பு, கடை, பேருந்து, தொலைபேசிக்கான சொற்கள்',
          ),
        OralItemKind.clearSpeech => (
            en: 'Say the phrase slowly, pausing after every word',
            ta: 'ஒவ்வொரு சொல்லுக்குப் பிறகும் நிறுத்தி, மெதுவாகச் சொல்லுங்கள்',
          ),
        OralItemKind.intelligibility => (
            en: 'The same 20 items each month, so you can see your progress',
            ta: 'உங்கள் முன்னேற்றம் தெரிய, ஒவ்வொரு மாதமும் அதே 20 சொற்கள்',
          ),
      };

  /// Pacing cue for [OralItem.pacing] items.
  static const OralText pacingCue = (
    en: 'One word at a time. Pause after each word. Open your mouth a little wider and finish every word.',
    ta: 'ஒவ்வொரு சொல்லாக. ஒவ்வொரு சொல்லுக்குப் பின் சிறு இடைவெளி. வாயைச் சற்று அகலமாகத் திறந்து, ஒவ்வொரு சொல்லையும் முழுமையாக முடியுங்கள்.',
  );

  /// Compensatory-articulation cue per sound group (used when an item has
  /// no hint of its own). Strategy cues only — no tongue exercises.
  static OralText groupHint(OralSoundGroup group) => switch (group) {
        OralSoundGroup.lips => (
            en: 'Close your lips firmly, then open. These sounds are your anchor.',
            ta: 'உதடுகளை நன்றாக மூடித் திறங்கள். இந்த ஒலிகள் உங்களுக்கு எளிது.',
          ),
        OralSoundGroup.tongueTip => (
            en: 'Go slowly. Let your jaw rise a little to help the sound. It may sound different — close enough is good.',
            ta: 'மெதுவாகச் சொல்லுங்கள். தாடையைச் சற்று உயர்த்தினால் உதவும். ஒலி கொஞ்சம் மாறலாம் — அருகில் வந்தாலே போதும்.',
          ),
        OralSoundGroup.tongueBack => (
            en: 'Make the sound further back, strong and short. Take a breath first.',
            ta: 'ஒலியைத் தொண்டைக்கு அருகில், அழுத்தமாகவும் சுருக்கமாகவும் சொல்லுங்கள். முதலில் மூச்சு இழுங்கள்.',
          ),
        OralSoundGroup.palatal => (
            en: 'Round your lips a little and stretch the sound: ch-air, y-es.',
            ta: 'உதடுகளைச் சற்றுக் குவித்து, ஒலியை நீட்டிச் சொல்லுங்கள்: சா-வி, யா-னை.',
          ),
      };

  static OralText groupTitle(OralSoundGroup group) => switch (group) {
        OralSoundGroup.lips => (en: 'Lip sounds', ta: 'உதட்டு ஒலிகள்'),
        OralSoundGroup.tongueTip => (en: 'Tongue-tip sounds', ta: 'நுனிநாக்கு ஒலிகள்'),
        OralSoundGroup.tongueBack => (en: 'Back-of-tongue sounds', ta: 'பின்நாக்கு ஒலிகள்'),
        OralSoundGroup.palatal => (en: 'Roof-of-mouth sounds', ta: 'மேல்வாய் ஒலிகள்'),
      };

  /// Hint shown for an item: its own, else the clear-speech cue, else its
  /// sound group's.
  static String? hintFor(OralItem item, Language language) {
    if (item.hintIn(language) case final h?) return h;
    if (item.pacing) return pacingCue.inLanguage(language);
    if (item.group case final g?) return groupHint(g).inLanguage(language);
    return null;
  }

  // ── Selection ────────────────────────────────────────────────────────

  /// All items of [kind] at [level] available in [language], in stable
  /// order. Intelligibility ignores [level]. Templates are included only
  /// when [personal] fills them.
  static List<OralItem> oralItemsFor(
    OralItemKind kind,
    int level,
    Language language, {
    Map<String, String> personal = const {},
  }) {
    if (kind == OralItemKind.intelligibility) return intelligibilitySet(language);
    final l = level.clamp(1, maxLevel);
    return [
      for (final i in oralItems)
        if (i.kind == kind &&
            i.level == l &&
            i.availableIn(language) &&
            i.targetIn(language, personal: personal) != null)
          i,
    ];
  }

  /// Engine-ready items for a [PracticeKind] (empty for kinds the pack
  /// does not use). Hints are resolved via [hintFor].
  static List<PracticeItem> itemsFor(
    PracticeKind kind,
    int level,
    Language language, {
    Map<String, String> personal = const {},
  }) {
    final oral = oralKindFor(kind);
    if (oral == null) return const [];
    return toPracticeItems(oralItemsFor(oral, level, language, personal: personal), language,
        personal: personal);
  }

  static List<PracticeItem> toPracticeItems(
    List<OralItem> items,
    Language language, {
    Map<String, String> personal = const {},
  }) =>
      [
        for (final i in items)
          if (i.toPracticeItem(language, personal: personal) case final p?)
            PracticeItem(
              id: p.id,
              target: p.target,
              alternates: p.alternates,
              meaning: p.meaning,
              locale: p.locale,
              semanticCue: hintFor(i, language),
            ),
      ];

  /// The fixed monthly re-test: 20 items per language, always in this
  /// order. Do not shuffle when presenting.
  static List<OralItem> intelligibilitySet(Language language) => [
        for (final i in oralItems)
          if (i.kind == OralItemKind.intelligibility && i.availableIn(language)) i,
      ];

  static Set<String> intelligibilityIds(Language language) =>
      {for (final i in intelligibilitySet(language)) i.id};

  /// Sound-group focus by day: tongue-tip sounds (most often affected)
  /// come up twice as often. After jaw surgery, lip sounds join the
  /// rotation.
  static OralSoundGroup focusGroup(int day, {OralSurgery surgery = OralSurgery.unsure}) {
    final cycle = surgery == OralSurgery.jaw
        ? const [OralSoundGroup.lips, OralSoundGroup.tongueTip, OralSoundGroup.tongueBack, OralSoundGroup.palatal]
        : const [OralSoundGroup.tongueTip, OralSoundGroup.tongueBack, OralSoundGroup.tongueTip, OralSoundGroup.palatal];
    return cycle[day % cycle.length];
  }

  /// A ~10-minute session (about 28 items) for day [day] (0-based since
  /// the person started). Deterministic for (day, level, language), so a
  /// session can be rebuilt after the app restarts.
  ///
  /// Order: lip-sound warm-up → focus-group syllables → focus-group words
  /// → sound pairs → everyday phrases → one-word-at-a-time. After most or
  /// all of the tongue is removed the session leans on phrases and clear
  /// speech (compensation and pacing) rather than isolated sounds.
  static List<OralItem> dailySession({
    required int level,
    required Language language,
    int day = 0,
    OralSurgery surgery = OralSurgery.unsure,
    Map<String, String> personal = const {},
  }) {
    final rng = Random(day * 7919 + level * 31 + language.index);
    final focus = focusGroup(day, surgery: surgery);
    final most = surgery == OralSurgery.mostTongue;

    final chosen = <String>{};
    List<OralItem> pick(OralItemKind kind, int n, {OralSoundGroup? group}) {
      final pool = [
        for (final i in oralItemsFor(kind, level, language, personal: personal))
          if (!chosen.contains(i.id)) i,
      ];
      final preferred = [for (final i in pool) if (group == null || i.group == group) i]..shuffle(rng);
      final rest = [for (final i in pool) if (!preferred.contains(i)) i]..shuffle(rng);
      final out = [...preferred, ...rest].take(n).toList();
      chosen.addAll(out.map((i) => i.id));
      return out;
    }

    return [
      ...pick(OralItemKind.syllables, most ? 2 : 4, group: OralSoundGroup.lips),
      ...pick(OralItemKind.syllables, most ? 2 : 6, group: focus),
      ...pick(OralItemKind.words, most ? 6 : 8, group: focus),
      ...pick(OralItemKind.minimalPairs, most ? 2 : 3),
      ...pick(OralItemKind.phrases, most ? 7 : 4),
      ...pick(OralItemKind.clearSpeech, most ? 6 : 3),
    ];
  }
}
