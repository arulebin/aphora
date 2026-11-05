import 'package:aphora/data/learning/kids_words.dart';
import 'package:aphora/data/learning/letter_training_data.dart';
import 'package:aphora/logic/family_voice_store.dart';
import 'package:aphora/logic/language_service.dart';
import 'package:flutter/material.dart';

/// Every speaking exercise in the app is a list of [PracticeItem]s run by
/// the one practice engine (`PracticeSessionPage`). Which kinds a person
/// sees, and their content, come from their condition pack
/// (`lib/data/learning/packs/`); this file holds the shared item model and
/// the children's content ([PracticeCatalog]).
///
/// Children's ladder (how children acquire speech): single sounds →
/// syllables → picture words → naming without the word shown (with hints)
/// → two- and three-word phrases. The adult aphasia pack follows the
/// classic aphasia hierarchy: automatic speech, repetition, naming,
/// sentence completion, functional phrases, plus clear (slow) speech.
enum PracticeKind {
  letters,
  words,
  naming,
  sentences,
  phonetic,
  assessment,
  drill,
  // Adult aphasia pack.
  automatic,
  repetition,
  completion,
  functional,
  clearSpeech,
  // Oral-cancer pack: one mixed ~10-minute session built for the day.
  daily,
}

/// Default (children's) names. A pack may rename a kind for its audience —
/// always go through `ConditionPack.title` on screens.
extension PracticeKindInfo on PracticeKind {
  String get id => name;

  String get title => switch (this) {
        PracticeKind.letters => tr('Sounds', 'ஒலிகள்'),
        PracticeKind.words => tr('Say the word', 'சொல்லைச் சொல்'),
        PracticeKind.naming => tr('What is this?', 'இது என்ன?'),
        PracticeKind.sentences => tr('Little sentences', 'சிறு வாக்கியங்கள்'),
        PracticeKind.phonetic => tr('Copy the voice', 'குரலைப் போலச் சொல்'),
        PracticeKind.assessment => tr('Sound check', 'ஒலிப் பரிசோதனை'),
        PracticeKind.drill => tr('Tricky sounds', 'கடினமான ஒலிகள்'),
        PracticeKind.automatic => tr('Familiar sequences', 'பழகிய வரிசைகள்'),
        PracticeKind.repetition =>
          tr('Listen and repeat', 'கேட்டுத் திருப்பிச் சொல்லுங்கள்'),
        PracticeKind.completion =>
          tr('Finish the sentence', 'வாக்கியத்தை முடியுங்கள்'),
        PracticeKind.functional => tr('Everyday needs', 'அன்றாடத் தேவைகள்'),
        PracticeKind.clearSpeech => tr('Clear speech', 'தெளிவான பேச்சு'),
        PracticeKind.daily => tr("Today's session", 'இன்றைய பயிற்சி'),
      };

  String get description => switch (this) {
        PracticeKind.letters =>
          tr('Warm up with first sounds', 'முதல் ஒலிகளுடன் தொடங்குவோம்'),
        PracticeKind.words =>
          tr('Look at the picture and the word, then say it', 'படத்தையும் சொல்லையும் பார்த்துச் சொல்'),
        PracticeKind.naming =>
          tr('Name the picture — hints if you need them', 'படத்தின் பெயரைச் சொல் — தேவைப்பட்டால் குறிப்பு'),
        PracticeKind.sentences =>
          tr('Two or three words together', 'இரண்டு மூன்று சொற்கள் சேர்த்து'),
        PracticeKind.phonetic =>
          tr('Listen to a recording, then say it the same way', 'பதிவைக் கேட்டு, அதே போலச் சொல்'),
        PracticeKind.assessment =>
          tr('20 short items to find where your child should start', 'உங்கள் குழந்தை எங்கிருந்து தொடங்கலாம் என்று அறிய 20 சிறு கேள்விகள்'),
        PracticeKind.drill =>
          tr('Focused practice on sounds that were hard', 'கடினமான ஒலிகளில் கவனம்'),
        PracticeKind.automatic => tr(
            'Counting, days, months and greetings — say them along',
            'எண்ணுதல், கிழமைகள், மாதங்கள், வணக்கங்கள் — சேர்ந்து சொல்லுங்கள்'),
        PracticeKind.repetition => tr(
            'Words, then phrases, then sentences',
            'சொற்கள், பிறகு தொடர்கள், பிறகு வாக்கியங்கள்'),
        PracticeKind.completion => tr(
            'Say the missing word — hints if you need them',
            'விடுபட்ட சொல்லைச் சொல்லுங்கள் — தேவைப்பட்டால் குறிப்பு'),
        PracticeKind.functional => tr(
            'Water, toilet, pain, calling family — the words that matter most',
            'தண்ணீர், கழிவறை, வலி, குடும்பத்தை அழைப்பது — மிக முக்கியமான சொற்கள்'),
        PracticeKind.clearSpeech => tr(
            'Slow and strong, one part at a time',
            'மெதுவாக, அழுத்தமாக, ஒவ்வொரு பகுதியாக'),
        PracticeKind.daily => tr(
            'About 10 minutes: sounds, words, pairs, phrases, one word at a time',
            'சுமார் 10 நிமிடம்: ஒலிகள், சொற்கள், இணைகள், சொற்றொடர்கள், ஒவ்வொரு சொல்லாக'),
      };

  IconData get icon => switch (this) {
        PracticeKind.letters => Icons.spatial_audio_off_rounded,
        PracticeKind.words => Icons.image_rounded,
        PracticeKind.naming => Icons.image_search_rounded,
        PracticeKind.sentences => Icons.forum_rounded,
        PracticeKind.phonetic => Icons.graphic_eq_rounded,
        PracticeKind.assessment => Icons.assignment_rounded,
        PracticeKind.drill => Icons.track_changes_rounded,
        PracticeKind.automatic => Icons.format_list_numbered_rounded,
        PracticeKind.repetition => Icons.hearing_rounded,
        PracticeKind.completion => Icons.short_text_rounded,
        PracticeKind.functional => Icons.volunteer_activism_rounded,
        PracticeKind.clearSpeech => Icons.slow_motion_video_rounded,
        PracticeKind.daily => Icons.today_rounded,
      };

  /// Rough minutes per session, for the daily plan. Kept short: young
  /// children's attention runs out quickly, and so does an adult's energy
  /// after a stroke.
  int get minutes => switch (this) {
        PracticeKind.letters => 3,
        PracticeKind.words => 4,
        PracticeKind.naming => 4,
        PracticeKind.sentences => 4,
        PracticeKind.phonetic => 3,
        PracticeKind.assessment => 8,
        PracticeKind.drill => 2,
        PracticeKind.automatic => 2,
        PracticeKind.repetition => 3,
        PracticeKind.completion => 3,
        PracticeKind.functional => 3,
        PracticeKind.clearSpeech => 3,
        PracticeKind.daily => 10,
      };
}

class PracticeItem {
  const PracticeItem({
    required this.id,
    required this.target,
    required this.locale,
    this.alternates = const [],
    this.meaning,
    this.imagePath,
    this.emoji,
    this.icon,
    this.referenceAudio,
    this.hideTarget = false,
    this.semanticCue,
    this.familyKey,
    this.prompt,
    this.instruction,
    this.chunks,
  });

  /// Stable id used in Firestore attempts.
  final String id;

  /// What the person should say, in the script STT returns.
  final String target;

  /// Other accepted forms (spoken Tamil, English) — device engines
  /// sometimes return Latin text for Tamil speech.
  final List<String> alternates;

  /// Translation / gloss shown under the target.
  final String? meaning;
  final String? imagePath;

  /// Picture drawn as a large emoji (children's word bank).
  final String? emoji;

  /// Picture drawn as a plain icon (adult packs, when no photo exists).
  final IconData? icon;

  /// Bundled recording of a fluent speaker; enables server scoring.
  final String? referenceAudio;

  /// ta-IN / en-IN.
  final String locale;

  /// Naming tasks hide the word until the person asks for a hint.
  final bool hideTarget;

  /// First rung of the cueing ladder: a meaning hint ("It says meow").
  final String? semanticCue;

  /// Overrides [voiceKey] when the same word appears under another id
  /// (e.g. a Sound check word reuses the parent's recording of that word).
  final String? familyKey;

  /// Text always shown above the target: a sentence with a blank to
  /// complete ("I drink a cup of ___"), or a slow-speech guide split into
  /// parts ("Wa · ter").
  final String? prompt;

  /// Overrides the session's line above the card ("Finish the sentence:").
  final String? instruction;

  /// Paced speech: the target split into the words to say one at a time,
  /// with a pause after each (oral-cancer "one word at a time").
  final List<String>? chunks;

  /// Key of the Family Voice recording for this item. Includes the
  /// language because the Tamil and English words are different recordings.
  String get voiceKey => familyKey ?? '${id}_${locale.split('-').first}';

  /// Second rung: the first sound of the word (phonemic cue). In Tamil one
  /// grapheme is one syllable (யா of யானை); taking two would give away a
  /// two-syllable word entirely.
  String get firstSound {
    final chars = target.characters;
    if (chars.isEmpty) return '';
    return chars.take(locale.startsWith('ta') ? 1 : 2).toString();
  }
}

/// The children's content. Tamil is the default; English mode uses the
/// same pictures with English words so the app works for bilingual
/// families. Every method takes an optional [Language] (default: the app
/// language) so packs can ask for either.
abstract final class PracticeCatalog {
  static bool _isTa(Language? l) =>
      (l ?? LanguageService.currentLanguage) == Language.tamil;
  static String _loc(bool ta) => ta ? 'ta-IN' : 'en-IN';

  /// Developmental order: vowels and early consonants (as syllables with
  /// ஆ, which young children say most easily) before the late sounds
  /// ச ல ர ழ ள ற.
  static const _tamilSounds = [
    ('அ', 'a'), ('ஆ', 'aa'), ('இ', 'i'), ('உ', 'u'),
    ('மா', 'maa'), ('பா', 'paa'), ('தா', 'thaa'), ('நா', 'naa'),
    ('கா', 'kaa'), ('வா', 'vaa'), ('சா', 'saa'), ('லா', 'laa'),
    ('ரா', 'raa'), ('ழா', 'zhaa'), ('ளா', 'llaa'), ('றா', 'rraa'),
  ];

  static const _englishSounds = [
    ('M', 'm'), ('P', 'p'), ('B', 'b'), ('D', 'd'), ('T', 't'),
    ('N', 'n'), ('K', 'k'), ('G', 'g'), ('F', 'f'), ('S', 's'),
    ('L', 'l'), ('R', 'r'),
  ];

  /// Short phrases a young child uses at home: (Tamil, spoken forms, English).
  static const _kidSentences = [
    ('அம்மா வா', <String>[], 'Mummy, come'),
    ('அப்பா வா', <String>[], 'Daddy, come'),
    ('பால் குடி', <String>[], 'Drink milk'),
    ('பந்து போடு', <String>[], 'Throw the ball'),
    ('தண்ணீர் வேண்டும்', ['தண்ணி வேணும்'], 'I want water'),
    ('எனக்குப் பசிக்கிறது', ['எனக்கு பசிக்குது'], 'I am hungry'),
    ('பூனை தூங்குகிறது', ['பூனை தூங்குது'], 'The cat is sleeping'),
    ('நாய் ஓடுகிறது', ['நாய் ஓடுது'], 'The dog is running'),
    ('நான் விளையாட வேண்டும்', ['நான் விளையாடணும்'], 'I want to play'),
    ('பெரிய யானை', <String>[], 'Big elephant'),
    ('சிவப்பு பந்து', <String>[], 'Red ball'),
  ];

  /// The children's set for one exercise.
  static List<PracticeItem> items(PracticeKind kind, {Language? language}) =>
      switch (kind) {
        PracticeKind.letters => letters(language: language),
        PracticeKind.words => words(language: language),
        PracticeKind.naming => naming(language: language),
        PracticeKind.sentences => sentences(language: language),
        PracticeKind.phonetic => phonetic(language: language),
        PracticeKind.assessment => assessment(language: language),
        _ => const [],
      };

  static List<PracticeItem> letters({int count = 10, Language? language}) {
    final ta = _isTa(language);
    return [
      for (final (l, roman) in (ta ? _tamilSounds : _englishSounds).take(count))
        PracticeItem(
          id: 'letter_$roman',
          target: l,
          alternates: [roman],
          locale: _loc(ta),
        ),
    ];
  }

  static PracticeItem _fromKid(KidWord w, bool ta, {bool hide = false}) =>
      PracticeItem(
        id: 'kid_${w.id}',
        target: ta ? w.ta : w.en,
        alternates: ta ? [...w.taAlternates, w.en] : const [],
        meaning: ta ? w.en : null,
        emoji: w.emoji,
        locale: _loc(ta),
        hideTarget: hide,
        semanticCue: ta ? w.cueTa : w.cueEn,
      );

  /// Picture + word shown. Early-sound words first.
  static List<PracticeItem> words({int count = 10, Language? language}) {
    final ta = _isTa(language);
    final early = kidWords.where((w) => w.level == 1).toList()..shuffle();
    final later = kidWords.where((w) => w.level == 2).toList()..shuffle();
    return [...early, ...later].take(count).map((w) => _fromKid(w, ta)).toList();
  }

  /// Picture only — the child finds the word, with the hint ladder.
  static List<PracticeItem> naming({int count = 10, Language? language}) {
    final ta = _isTa(language);
    final pool = List<KidWord>.from(kidWords)..shuffle();
    return pool.take(count).map((w) => _fromKid(w, ta, hide: true)).toList();
  }

  static String _sentenceId(String en) =>
      'kidsentence_${en.toLowerCase().replaceAll(RegExp(r'[^a-z]+'), '_')}';

  static PracticeItem _sentence((String, List<String>, String) s, bool ta) {
    final (tamil, spoken, en) = s;
    return PracticeItem(
      id: _sentenceId(en),
      target: ta ? tamil : en,
      alternates: ta ? [...spoken, en] : const [],
      meaning: ta ? en : null,
      locale: _loc(ta),
    );
  }

  static List<PracticeItem> sentences({int count = 8, Language? language}) {
    final ta = _isTa(language);
    final pool = List.of(_kidSentences)..shuffle();
    return pool.take(count).map((s) => _sentence(s, ta)).toList();
  }

  // ── Family Voice ─────────────────────────────────────────────────────

  /// Everything a parent can record, in a stable order: the full
  /// picture-word bank, the sounds and the sentences.
  static List<PracticeItem> familyWords({Language? language}) {
    final ta = _isTa(language);
    return kidWords.map((w) => _fromKid(w, ta)).toList();
  }

  static List<PracticeItem> familySounds({Language? language}) =>
      letters(count: 100, language: language);

  static List<PracticeItem> familySentences({Language? language}) {
    final ta = _isTa(language);
    return _kidSentences.map((s) => _sentence(s, ta)).toList();
  }

  /// "Copy the voice": when the parent has recorded words, the child copies
  /// Amma/Appa's own voice and the server scores against that recording.
  /// Otherwise the three bundled adult recordings are used.
  static List<PracticeItem> phonetic({
    int count = 8,
    FamilyVoiceStore? store,
    Language? language,
  }) =>
      fromFamilyOrBundled(
        [
          ...familyWords(language: language),
          ...familySounds(language: language),
          ...familySentences(language: language),
        ],
        count: count,
        store: store,
      );

  /// Up to [count] of [recordable] that have a Family Voice recording, in
  /// random order; the bundled recordings when none do.
  static List<PracticeItem> fromFamilyOrBundled(
    List<PracticeItem> recordable, {
    int count = 8,
    FamilyVoiceStore? store,
  }) {
    final s = store ?? FamilyVoiceStore.instance;
    final family = recordable.where((i) => s.has(i.voiceKey)).toList()
      ..shuffle();
    if (family.isNotEmpty) return family.take(count).toList();
    return bundledPhonetic;
  }

  /// Items with a bundled fluent-speaker recording (an adult Tamil voice).
  /// These are scored by the acoustic server when it is reachable.
  static const List<PracticeItem> bundledPhonetic = [
        PracticeItem(
          id: 'phonetic_vannakam',
          target: 'வணக்கம்',
          alternates: ['vanakkam', 'vanakam'],
          meaning: 'Hello (greeting)',
          referenceAudio: 'assets/vannakam.wav',
          locale: 'ta-IN',
        ),
        PracticeItem(
          id: 'phonetic_saptirgala',
          target: 'சாப்பிட்டீர்களா',
          alternates: ['saptingala', 'saapittirgala', 'saptittiirgala'],
          meaning: 'Have you eaten?',
          referenceAudio: 'assets/saptiya.wav',
          locale: 'ta-IN',
        ),
        PracticeItem(
          id: 'phonetic_epadi',
          target: 'எப்படி இருக்கிறீர்கள்',
          alternates: ['eppadi irukkinga', 'eppadi irukkindrirgal'],
          meaning: 'How are you?',
          referenceAudio: 'assets/epdi.wav',
          locale: 'ta-IN',
        ),
      ];

  /// Sound check: 6 sounds, 8 picture words chosen to cover early and late
  /// sounds (ப ம த க ந early; ச ல ழ late), 6 short phrases.
  static List<PracticeItem> assessment({Language? language}) {
    const checkWords = [
      'cat', 'fish', 'cap', 'car', 'dog', 'lion', 'balloon', 'rain',
    ];
    final ta = _isTa(language);
    final locale = _loc(ta);
    final byId = {for (final w in kidWords) w.id: w};
    return [
      for (final (i, item) in letters(count: 6, language: language).indexed)
        PracticeItem(
          id: 'assess_letter_$i',
          target: item.target,
          alternates: item.alternates,
          locale: item.locale,
          familyKey: item.voiceKey,
        ),
      for (final (i, id) in checkWords.indexed)
        PracticeItem(
          id: 'assess_word_$i',
          target: ta ? byId[id]!.ta : byId[id]!.en,
          alternates: ta ? [...byId[id]!.taAlternates, byId[id]!.en] : const [],
          meaning: ta ? byId[id]!.en : null,
          emoji: byId[id]!.emoji,
          locale: locale,
          familyKey: 'kid_${id}_${locale.split('-').first}',
        ),
      for (final (i, (tamil, spoken, en)) in _kidSentences.take(6).indexed)
        PracticeItem(
          id: 'assess_sentence_$i',
          target: ta ? tamil : en,
          alternates: ta ? [...spoken, en] : const [],
          meaning: ta ? en : null,
          locale: locale,
          familyKey: '${_sentenceId(en)}_${locale.split('-').first}',
        ),
    ];
  }

  /// Follow-up drill for sounds that were hard.
  static List<PracticeItem> drill(List<String> letters, {Language? language}) => [
        for (final l in letters.take(3))
          for (final (i, d) in drillsForLetter(l).indexed)
            PracticeItem(
              id: 'drill_${l.codeUnits.join('_')}_$i',
              target: d.prompt,
              meaning: d.hint,
              locale: _loc(_isTa(language)),
            ),
      ];

  /// Sound-check score → where to start.
  static String focusFor(double score) => score < 40
      ? 'letters'
      : score < 70
          ? 'words'
          : 'sentences';

  static PracticeKind kindForFocus(String? focus) => switch (focus) {
        'letters' => PracticeKind.letters,
        'sentences' => PracticeKind.sentences,
        _ => PracticeKind.words,
      };
}
