import 'package:aphora/logic/language_service.dart';

/// A single drill prompt asking the child to say something containing
/// the target letter / sound.
class LetterDrill {
  final String prompt; // What the child is asked to say.
  final String hint; // Short instruction shown above the prompt.

  const LetterDrill({required this.prompt, required this.hint});
}

/// How a letter is shown to the child: English letters in capitals, the
/// same as the Sounds lesson ("B", not "b"). Scoring lower-cases both sides,
/// and Tamil has no case, so this only changes what is displayed.
String displayLetter(String letter) => letter.trim().toUpperCase();

/// Returns up to two simple training prompts for the given grapheme.
///
/// When we have curated example words for the letter we use them;
/// otherwise we fall back to "Say the letter X out loud" / "Say it
/// three times slowly" which works for any character without
/// language-specific data.
List<LetterDrill> drillsForLetter(String letter) {
  final trimmed = letter.trim();
  if (trimmed.isEmpty) return const [];
  final shown = displayLetter(trimmed);

  final curated = _curated[trimmed] ?? _curated[trimmed.toLowerCase()];
  if (curated != null && curated.length >= 2) {
    return [
      LetterDrill(
        hint: tr('Say this sound clearly', 'இந்த ஒலியைத் தெளிவாகச் சொல்'),
        prompt: shown,
      ),
      LetterDrill(
        hint: tr("Now say a word with '$shown'", "இப்போது '$shown' உள்ள சொல்லைச் சொல்"),
        prompt: curated.first,
      ),
    ];
  }

  return [
    LetterDrill(
      hint: tr('Say this sound clearly', 'இந்த ஒலியைத் தெளிவாகச் சொல்'),
      prompt: shown,
    ),
    LetterDrill(
      hint: tr('Say it three times, slowly', 'மூன்று முறை மெதுவாகச் சொல்'),
      prompt: '$shown $shown $shown',
    ),
  ];
}

/// Curated example words for the most common Tamil and English letters.
/// Each entry is a list of simple words containing the target letter.
const Map<String, List<String>> _curated = {
  // ── Tamil vowels (உயிரெழுத்துக்கள்) ──
  'அ': ['அம்மா', 'அப்பா'],
  'ஆ': ['ஆடு', 'ஆமை'],
  'இ': ['இலை', 'இரவு'],
  'ஈ': ['ஈ', 'ஈரம்'],
  'உ': ['உப்பு', 'உரல்'],
  'ஊ': ['ஊர்', 'ஊசி'],
  'எ': ['எலி', 'எழுது'],
  'ஏ': ['ஏணி', 'ஏரி'],
  'ஐ': ['ஐந்து', 'ஐயா'],
  'ஒ': ['ஒன்று', 'ஒட்டகம்'],
  'ஓ': ['ஓடு', 'ஓணான்'],
  'ஔ': ['ஔவை', 'ஔடதம்'],

  // ── Tamil consonants (மெய்யெழுத்துக்கள்) ──
  'க': ['கதவு', 'காகம்'],
  'ங': ['அங்கே', 'திங்கள்'],
  'ச': ['சட்டை', 'சாதம்'],
  'ஞ': ['ஞாயிறு', 'நெஞ்சு'],
  'ட': ['டப்பா', 'பாட்டி'],
  'ண': ['அணில்', 'மணி'],
  'த': ['தலை', 'தண்ணீர்'],
  'ந': ['நரி', 'நாய்'],
  'ப': ['பழம்', 'பால்'],
  'ம': ['மரம்', 'மாடு'],
  'ய': ['யானை', 'யாழ்'],
  'ர': ['ரயில்', 'ராசா'],
  'ல': ['லட்டு', 'லாடம்'],
  'வ': ['வண்டி', 'வாசல்'],
  'ழ': ['மழை', 'வாழை'],
  'ள': ['வெள்ளம்', 'கிளி'],
  'ற': ['ஆறு', 'மாறு'],
  'ன': ['மீன்', 'வீடான'],

  // Common Tamil compound graphemes that frequently get clipped.
  'ணை': ['தலையணை', 'வீணை'],
  'ழை': ['மழை', 'வழை'],
  'ளை': ['இளைய', 'வளை'],

  // ── English letters ──
  'a': ['apple', 'ant'],
  'b': ['ball', 'bat'],
  'c': ['cat', 'cup'],
  'd': ['dog', 'door'],
  'e': ['egg', 'eat'],
  'f': ['fish', 'fan'],
  'g': ['goat', 'go'],
  'h': ['hat', 'hand'],
  'i': ['ink', 'ice'],
  'j': ['jug', 'jam'],
  'k': ['kite', 'key'],
  'l': ['lamp', 'leg'],
  'm': ['man', 'moon'],
  'n': ['nest', 'nose'],
  'o': ['orange', 'open'],
  'p': ['pen', 'pin'],
  'q': ['queen', 'quiet'],
  'r': ['rat', 'red'],
  's': ['sun', 'sit'],
  't': ['top', 'tea'],
  'u': ['umbrella', 'up'],
  'v': ['van', 'vase'],
  'w': ['water', 'wing'],
  'x': ['box', 'fox'],
  'y': ['yes', 'yarn'],
  'z': ['zoo', 'zebra'],
};
