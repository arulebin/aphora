import 'package:aphora/data/learning/kids_words.dart';
import 'package:aphora/data/learning/letter_training_data.dart';
import 'package:aphora/logic/family_voice_store.dart';
import 'package:aphora/logic/language_service.dart';
import 'package:flutter/material.dart';

/// Every speaking exercise in the app is a list of [PracticeItem]s run by
/// the one practice engine (`PracticeSessionPage`). Content lives here and
/// behaviour in one place.
///
/// Vernacura is for children with speech delay, so the ladder follows how
/// children acquire speech: single sounds → syllables → picture words →
/// naming without the word shown (with hints) → two- and three-word phrases.
enum PracticeKind {
  letters,
  words,
  naming,
  sentences,
  phonetic,
  assessment,
  drill,
}

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
      };

  IconData get icon => switch (this) {
        PracticeKind.letters => Icons.abc_rounded,
        PracticeKind.words => Icons.image_rounded,
        PracticeKind.naming => Icons.image_search_rounded,
        PracticeKind.sentences => Icons.forum_rounded,
        PracticeKind.phonetic => Icons.graphic_eq_rounded,
        PracticeKind.assessment => Icons.assignment_rounded,
        PracticeKind.drill => Icons.track_changes_rounded,
      };

  /// Rough minutes per session, for the daily plan. Kept short: young
  /// children's attention runs out quickly.
  int get minutes => switch (this) {
        PracticeKind.letters => 3,
        PracticeKind.words => 4,
        PracticeKind.naming => 4,
        PracticeKind.sentences => 4,
        PracticeKind.phonetic => 3,
        PracticeKind.assessment => 8,
        PracticeKind.drill => 2,
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
    this.referenceAudio,
    this.hideTarget = false,
    this.semanticCue,
    this.familyKey,
  });

  /// Stable id used in Firestore attempts.
  final String id;

  /// What the child should say, in the script STT returns.
  final String target;

  /// Other accepted forms (spoken Tamil, English) — device engines
  /// sometimes return Latin text for Tamil speech.
  final List<String> alternates;

  /// Translation / gloss shown under the target.
  final String? meaning;
  final String? imagePath;

  /// Picture drawn as a large emoji (children's word bank).
  final String? emoji;

  /// Bundled recording of a fluent speaker; enables server scoring.
  final String? referenceAudio;

  /// ta-IN / en-IN.
  final String locale;

  /// Naming tasks hide the word until the child asks for a hint.
  final bool hideTarget;

  /// First rung of the cueing ladder: a meaning hint ("It says meow").
  final String? semanticCue;

  /// Overrides [voiceKey] when the same word appears under another id
  /// (e.g. a Sound check word reuses the parent's recording of that word).
  final String? familyKey;

  /// Key of the parent's Family Voice recording for this item. Includes the
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

/// Content source. Tamil is the default; English mode uses the same
/// pictures with English words so the app works for bilingual families.
abstract final class PracticeCatalog {
  static bool get _ta => LanguageService.currentLanguage == Language.tamil;
  static String get _locale => _ta ? 'ta-IN' : 'en-IN';

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

  static List<PracticeItem> items(PracticeKind kind) => switch (kind) {
        PracticeKind.letters => letters(),
        PracticeKind.words => words(),
        PracticeKind.naming => naming(),
        PracticeKind.sentences => sentences(),
        PracticeKind.phonetic => phonetic(),
        PracticeKind.assessment => assessment(),
        PracticeKind.drill => const [],
      };

  static List<PracticeItem> letters({int count = 10}) => [
        for (final (l, roman) in (_ta ? _tamilSounds : _englishSounds).take(count))
          PracticeItem(
            id: 'letter_$roman',
            target: l,
            alternates: [roman],
            locale: _locale,
          ),
      ];

  static PracticeItem _fromKid(KidWord w, {bool hide = false}) => PracticeItem(
        id: 'kid_${w.id}',
        target: _ta ? w.ta : w.en,
        alternates: _ta ? [...w.taAlternates, w.en] : const [],
        meaning: _ta ? w.en : null,
        emoji: w.emoji,
        locale: _locale,
        hideTarget: hide,
        semanticCue: _ta ? w.cueTa : w.cueEn,
      );

  /// Picture + word shown. Early-sound words first.
  static List<PracticeItem> words({int count = 10}) {
    final early = kidWords.where((w) => w.level == 1).toList()..shuffle();
    final later = kidWords.where((w) => w.level == 2).toList()..shuffle();
    return [...early, ...later].take(count).map(_fromKid).toList();
  }

  /// Picture only — the child finds the word, with the hint ladder.
  static List<PracticeItem> naming({int count = 10}) {
    final pool = List<KidWord>.from(kidWords)..shuffle();
    return pool.take(count).map((w) => _fromKid(w, hide: true)).toList();
  }

  static String _sentenceId(String en) =>
      'kidsentence_${en.toLowerCase().replaceAll(RegExp(r'[^a-z]+'), '_')}';

  static PracticeItem _sentence((String, List<String>, String) s) {
    final (ta, spoken, en) = s;
    return PracticeItem(
      id: _sentenceId(en),
      target: _ta ? ta : en,
      alternates: _ta ? [...spoken, en] : const [],
      meaning: _ta ? en : null,
      locale: _locale,
    );
  }

  static List<PracticeItem> sentences({int count = 8}) {
    final pool = List.of(_kidSentences)..shuffle();
    return pool.take(count).map(_sentence).toList();
  }

  // ── Family Voice ─────────────────────────────────────────────────────

  /// Everything a parent can record, in a stable order, for the current
  /// language: the full picture-word bank, the sounds and the sentences.
  static List<PracticeItem> familyWords() => kidWords.map(_fromKid).toList();
  static List<PracticeItem> familySounds() => letters(count: 100);
  static List<PracticeItem> familySentences() =>
      _kidSentences.map(_sentence).toList();

  /// "Copy the voice": when the parent has recorded words, the child copies
  /// Amma/Appa's own voice and the server scores against that recording.
  /// Otherwise the three bundled adult recordings are used.
  static List<PracticeItem> phonetic({int count = 8, FamilyVoiceStore? store}) {
    final s = store ?? FamilyVoiceStore.instance;
    final family = [...familyWords(), ...familySounds(), ...familySentences()]
        .where((i) => s.has(i.voiceKey))
        .toList()
      ..shuffle();
    if (family.isNotEmpty) return family.take(count).toList();
    return bundledPhonetic;
  }

  /// Items with a bundled fluent-speaker recording. These are scored by
  /// the acoustic server when it is reachable.
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
  static List<PracticeItem> assessment() {
    const checkWords = [
      'cat', 'fish', 'cap', 'car', 'dog', 'lion', 'balloon', 'rain',
    ];
    final byId = {for (final w in kidWords) w.id: w};
    return [
      for (final (i, item) in letters(count: 6).indexed)
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
          target: _ta ? byId[id]!.ta : byId[id]!.en,
          alternates: _ta ? [...byId[id]!.taAlternates, byId[id]!.en] : const [],
          meaning: _ta ? byId[id]!.en : null,
          emoji: byId[id]!.emoji,
          locale: _locale,
          familyKey: 'kid_${id}_${_locale.split('-').first}',
        ),
      for (final (i, (ta, spoken, en)) in _kidSentences.take(6).indexed)
        PracticeItem(
          id: 'assess_sentence_$i',
          target: _ta ? ta : en,
          alternates: _ta ? [...spoken, en] : const [],
          meaning: _ta ? en : null,
          locale: _locale,
          familyKey: '${_sentenceId(en)}_${_locale.split('-').first}',
        ),
    ];
  }

  /// Follow-up drill for sounds the child found hard.
  static List<PracticeItem> drill(List<String> letters) => [
        for (final l in letters.take(3))
          for (final (i, d) in drillsForLetter(l).indexed)
            PracticeItem(
              id: 'drill_${l.codeUnits.join('_')}_$i',
              target: d.prompt,
              meaning: d.hint,
              locale: _locale,
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
