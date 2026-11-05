// Content of the oral-cancer speech rehabilitation pack.
//
// Written for adults after surgery for mouth / tongue cancer. Everything
// here is *speech* practice — syllables, words, pairs, phrases. There are
// deliberately no tongue-strength or range-of-motion drills: those load
// healing tissue and belong to the treating therapist, not a home app.
//
// Ids are stable and keyed into baseline scoring — never rename one; add a
// new item instead. Clinician review sheet: wiki
// `projects/vernacura-intake-questions.md`, "Oral-cancer pack".
import 'package:aphora/data/learning/oral/oral_item.dart';

typedef _G = OralSoundGroup;
typedef _P = SoundPosition;
typedef _K = OralItemKind;
typedef _S = OralSituation;

// ── Syllables ────────────────────────────────────────────────────────────

/// Tamil consonants used for syllable work: (letter, roman, group).
/// ங and ஞ are practised inside words only — as syllables they are not
/// natural to say.
const _taConsonants = [
  ('ப', 'pa', _G.lips), ('ம', 'ma', _G.lips), ('வ', 'va', _G.lips),
  ('த', 'tha', _G.tongueTip), ('ந', 'na', _G.tongueTip), ('ட', 'da', _G.tongueTip),
  ('ண', 'nna', _G.tongueTip), ('ல', 'la', _G.tongueTip), ('ள', 'lla', _G.tongueTip),
  ('ழ', 'zha', _G.tongueTip), ('ர', 'ra', _G.tongueTip), ('ற', 'rra', _G.tongueTip),
  ('க', 'ka', _G.tongueBack),
  ('ச', 'cha', _G.palatal), ('ய', 'ya', _G.palatal),
];

/// Vowel signs ா ி ு — the open "aa" first, which needs the least tongue.
const _taVowels = [('ா', 'aa'), ('ி', 'i'), ('ு', 'u')];

String _stem(String roman) => roman.substring(0, roman.length - 1);

List<OralItem> _taSyllables() => [
      // L1: one consonant + one vowel (தா, தி, து).
      for (final (c, r, g) in _taConsonants)
        for (final (v, vr) in _taVowels)
          OralItem(
            id: 'oral_syl_ta_${_stem(r)}$vr',
            kind: _K.syllables,
            level: 1,
            lang: OralLang.ta,
            ta: '$c$v',
            en: '${_stem(r)}$vr',
            taSpoken: ['${_stem(r)}$vr'],
            group: g,
            sounds: [c],
            position: _P.initial,
          ),
      // L2: vowel ladder on one sound (தா தி து).
      for (final (c, r, g) in _taConsonants)
        OralItem(
          id: 'oral_syl2_ta_${_stem(r)}',
          kind: _K.syllables,
          level: 2,
          lang: OralLang.ta,
          ta: [for (final (v, _) in _taVowels) '$c$v'].join(' '),
          en: [for (final (_, vr) in _taVowels) '${_stem(r)}$vr'].join(' '),
          group: g,
          sounds: [c],
          position: _P.initial,
        ),
      // L3: alternating places — lips → tongue → back. Spoken, unhurried;
      // never as a speed drill.
      for (final (slug, ta, en, g, s) in _taSequences)
        OralItem(
          id: 'oral_syl3_ta_$slug',
          kind: _K.syllables,
          level: 3,
          lang: OralLang.ta,
          ta: ta,
          en: en,
          group: g,
          sounds: s,
          position: _P.initial,
        ),
    ];

const _taSequences = [
  ('pa_tha_ka', 'பா தா கா', 'paa thaa kaa', _G.tongueTip, ['த', 'க']),
  ('ma_na_ka', 'மா நா கா', 'maa naa kaa', _G.tongueTip, ['ந', 'க']),
  ('tha_ka_tha', 'தா கா தா', 'thaa kaa thaa', _G.tongueBack, ['க', 'த']),
  ('pa_ka_pa', 'பா கா பா', 'paa kaa paa', _G.tongueBack, ['க']),
  ('la_lla_la', 'லா ளா லா', 'laa llaa laa', _G.tongueTip, ['ல', 'ள']),
  ('la_zha_la', 'லா ழா லா', 'laa zhaa laa', _G.tongueTip, ['ல', 'ழ']),
  ('ra_rra_ra', 'ரா றா ரா', 'raa rraa raa', _G.tongueTip, ['ர', 'ற']),
  ('tha_da_tha', 'தா டா தா', 'thaa daa thaa', _G.tongueTip, ['த', 'ட']),
  ('cha_ya_cha', 'சா யா சா', 'chaa yaa chaa', _G.palatal, ['ச', 'ய']),
  ('pa_cha_ka', 'பா சா கா', 'paa chaa kaa', _G.palatal, ['ச', 'க']),
];

/// English L1 "syllables" are real consonant-vowel words — recognisers
/// cannot transcribe nonsense syllables like "pah". (target, reading aid,
/// group, sounds).
const _enSyllables1 = [
  ('pie', 'பை', _G.lips, ['p']), ('bee', 'பீ', _G.lips, ['b']),
  ('me', 'மீ', _G.lips, ['m']), ('bay', 'பே', _G.lips, ['b']),
  ('way', 'வே', _G.lips, ['w']), ('fee', 'ஃபீ', _G.lips, ['f']),
  ('tea', 'டீ', _G.tongueTip, ['t']), ('two', 'டூ', _G.tongueTip, ['t']),
  ('toe', 'டோ', _G.tongueTip, ['t']), ('day', 'டே', _G.tongueTip, ['d']),
  ('do', 'டூ', _G.tongueTip, ['d']), ('knee', 'நீ', _G.tongueTip, ['n']),
  ('no', 'நோ', _G.tongueTip, ['n']), ('low', 'லோ', _G.tongueTip, ['l']),
  ('lie', 'லை', _G.tongueTip, ['l']), ('see', 'ஸீ', _G.tongueTip, ['s']),
  ('say', 'ஸே', _G.tongueTip, ['s']), ('ray', 'ரே', _G.tongueTip, ['r']),
  ('row', 'ரோ', _G.tongueTip, ['r']),
  ('key', 'கீ', _G.tongueBack, ['k']), ('car', 'கார்', _G.tongueBack, ['k']),
  ('cow', 'கௌ', _G.tongueBack, ['k']), ('go', 'கோ', _G.tongueBack, ['g']),
  ('guy', 'கை', _G.tongueBack, ['g']),
  ('chew', 'சூ', _G.palatal, ['ch']), ('shoe', 'ஷூ', _G.palatal, ['sh']),
  ('she', 'ஷீ', _G.palatal, ['sh']), ('jaw', 'ஜா', _G.palatal, ['j']),
  ('joy', 'ஜாய்', _G.palatal, ['j']), ('you', 'யூ', _G.palatal, ['y']),
];

/// L2: one sound, three vowels. (slug, target, reading aid, group, sounds)
const _enSyllables2 = [
  ('p', 'pea, pay, pie', 'பீ, பே, பை', _G.lips, ['p']),
  ('b', 'bee, bay, buy', 'பீ, பே, பை', _G.lips, ['b']),
  ('m', 'me, may, my', 'மீ, மே, மை', _G.lips, ['m']),
  ('t', 'tea, tie, toe', 'டீ, டை, டோ', _G.tongueTip, ['t']),
  ('d', 'day, die, door', 'டே, டை, டோர்', _G.tongueTip, ['d']),
  ('n', 'knee, no, new', 'நீ, நோ, நியூ', _G.tongueTip, ['n']),
  ('l', 'lay, lie, low', 'லே, லை, லோ', _G.tongueTip, ['l']),
  ('s', 'see, say, sigh', 'ஸீ, ஸே, ஸை', _G.tongueTip, ['s']),
  ('r', 'ray, rye, row', 'ரே, ரை, ரோ', _G.tongueTip, ['r']),
  ('k', 'key, car, cow', 'கீ, கார், கௌ', _G.tongueBack, ['k']),
  ('g', 'go, guy, goo', 'கோ, கை, கூ', _G.tongueBack, ['g']),
  ('ch', 'chew, chai, cheese', 'சூ, சாய், சீஸ்', _G.palatal, ['ch']),
  ('sh', 'she, shy, show', 'ஷீ, ஷை, ஷோ', _G.palatal, ['sh']),
  ('j', 'jay, joy, jaw', 'ஜே, ஜாய், ஜா', _G.palatal, ['j']),
  ('y', 'yes, you, yard', 'யெஸ், யூ, யார்ட்', _G.palatal, ['y']),
];

/// L3: alternating places with real words.
const _enSyllables3 = [
  ('pea_tea_key', 'pea, tea, key', 'பீ, டீ, கீ', _G.tongueBack, ['p', 't', 'k']),
  ('pie_tie_guy', 'pie, tie, guy', 'பை, டை, கை', _G.tongueBack, ['p', 't', 'g']),
  ('me_knee_key', 'me, knee, key', 'மீ, நீ, கீ', _G.tongueBack, ['m', 'n', 'k']),
  ('boat_coat_goat', 'boat, coat, goat', 'போட், கோட், கோட்', _G.tongueBack, ['b', 'k', 'g']),
  ('pin_tin_kin', 'pin, tin, kin', 'பின், டின், கின்', _G.tongueBack, ['p', 't', 'k']),
  ('pat_tap_cap', 'pat, tap, cap', 'பேட், டேப், கேப்', _G.tongueTip, ['p', 't', 'k']),
  ('sea_she_tea', 'sea, she, tea', 'ஸீ, ஷீ, டீ', _G.palatal, ['s', 'sh', 't']),
  ('low_row_go', 'low, row, go', 'லோ, ரோ, கோ', _G.tongueTip, ['l', 'r', 'g']),
  ('chew_shoe_two', 'chew, shoe, two', 'சூ, ஷூ, டூ', _G.palatal, ['ch', 'sh', 't']),
  ('jaw_saw_law', 'jaw, saw, law', 'ஜா, ஸா, லா', _G.palatal, ['j', 's', 'l']),
];

List<OralItem> _enSyllables() => [
      for (final (w, aid, g, s) in _enSyllables1)
        OralItem(
          id: 'oral_syl_en_$w',
          kind: _K.syllables,
          level: 1,
          lang: OralLang.en,
          en: w,
          ta: aid,
          group: g,
          sounds: s,
          position: _P.initial,
        ),
      for (final (slug, en, aid, g, s) in _enSyllables2)
        OralItem(
          id: 'oral_syl2_en_$slug',
          kind: _K.syllables,
          level: 2,
          lang: OralLang.en,
          en: en,
          ta: aid,
          enAlternates: [en.replaceAll(',', '')],
          group: g,
          sounds: s,
          position: _P.initial,
        ),
      for (final (slug, en, aid, g, s) in _enSyllables3)
        OralItem(
          id: 'oral_syl3_en_$slug',
          kind: _K.syllables,
          level: 3,
          lang: OralLang.en,
          en: en,
          ta: aid,
          enAlternates: [en.replaceAll(',', '')],
          group: g,
          sounds: s,
          position: _P.initial,
        ),
    ];

// ── Words ────────────────────────────────────────────────────────────────

/// Tamil words: (slug, word, spoken forms, English meaning, group,
/// sounds, position, level).
const _taWords = <(String, String, List<String>, String, _G, List<String>, _P, int)>[
  // L1 — short, everyday words.
  ('paal', 'பால்', [], 'milk', _G.lips, ['ப'], _P.initial, 1),
  ('poo', 'பூ', [], 'flower', _G.lips, ['ப'], _P.initial, 1),
  ('vaa', 'வா', [], 'come', _G.lips, ['வ'], _P.initial, 1),
  ('meen', 'மீன்', [], 'fish', _G.lips, ['ம'], _P.initial, 1),
  ('paai', 'பாய்', [], 'mat', _G.lips, ['ப'], _P.initial, 1),
  ('vaai', 'வாய்', [], 'mouth', _G.lips, ['வ'], _P.initial, 1),
  ('appa', 'அப்பா', [], 'father', _G.lips, ['ப'], _P.medial, 1),
  ('amma', 'அம்மா', [], 'mother', _G.lips, ['ம'], _P.medial, 1),
  ('thaai', 'தாய்', [], 'mother', _G.tongueTip, ['த'], _P.initial, 1),
  ('then', 'தேன்', [], 'honey', _G.tongueTip, ['த'], _P.initial, 1),
  ('thalai', 'தலை', [], 'head', _G.tongueTip, ['த', 'ல'], _P.initial, 1),
  ('naai', 'நாய்', [], 'dog', _G.tongueTip, ['ந'], _P.initial, 1),
  ('naan', 'நான்', [], 'I', _G.tongueTip, ['ந', 'ன'], _P.initial, 1),
  ('neer', 'நீர்', [], 'water', _G.tongueTip, ['ந', 'ர'], _P.initial, 1),
  ('laddu', 'லட்டு', [], 'laddu (sweet)', _G.tongueTip, ['ல', 'ட'], _P.initial, 1),
  ('rasam', 'ரசம்', [], 'rasam', _G.tongueTip, ['ர'], _P.initial, 1),
  ('vali', 'வலி', [], 'pain', _G.tongueTip, ['ல'], _P.medial, 1),
  ('malai', 'மலை', [], 'mountain', _G.tongueTip, ['ல'], _P.medial, 1),
  ('aaru', 'ஆறு', [], 'six / river', _G.tongueTip, ['ற'], _P.medial, 1),
  ('veedu', 'வீடு', [], 'house', _G.tongueTip, ['ட'], _P.medial, 1),
  ('mann', 'மண்', [], 'soil', _G.tongueTip, ['ண'], _P.medial, 1),
  ('pathu', 'பத்து', [], 'ten', _G.tongueTip, ['த'], _P.medial, 1),
  ('kai', 'கை', [], 'hand', _G.tongueBack, ['க'], _P.initial, 1),
  ('kaal', 'கால்', [], 'leg', _G.tongueBack, ['க'], _P.initial, 1),
  ('kaathu', 'காது', [], 'ear', _G.tongueBack, ['க'], _P.initial, 1),
  ('kaai', 'காய்', [], 'vegetable', _G.tongueBack, ['க'], _P.initial, 1),
  ('kadai', 'கடை', [], 'shop', _G.tongueBack, ['க', 'ட'], _P.initial, 1),
  ('akka', 'அக்கா', [], 'elder sister', _G.tongueBack, ['க'], _P.medial, 1),
  ('enge', 'எங்கே', ['எங்க'], 'where', _G.tongueBack, ['ங', 'க'], _P.medial, 1),
  ('inge', 'இங்கே', ['இங்க'], 'here', _G.tongueBack, ['ங', 'க'], _P.medial, 1),
  ('saavi', 'சாவி', [], 'key', _G.palatal, ['ச'], _P.initial, 1),
  ('soru', 'சோறு', [], 'cooked rice', _G.palatal, ['ச', 'ற'], _P.initial, 1),
  ('seeppu', 'சீப்பு', [], 'comb', _G.palatal, ['ச'], _P.initial, 1),
  ('sattai', 'சட்டை', [], 'shirt', _G.palatal, ['ச', 'ட'], _P.initial, 1),
  ('yaar', 'யார்', [], 'who', _G.palatal, ['ய'], _P.initial, 1),
  ('yaanai', 'யானை', [], 'elephant', _G.palatal, ['ய'], _P.initial, 1),
  ('pachai', 'பச்சை', [], 'green', _G.palatal, ['ச'], _P.medial, 1),
  ('manjal', 'மஞ்சள்', [], 'yellow / turmeric', _G.palatal, ['ஞ', 'ச'], _P.medial, 1),
  ('inji', 'இஞ்சி', [], 'ginger', _G.palatal, ['ஞ', 'ச'], _P.medial, 1),

  // L2 — two or three syllables, sounds in the middle, double consonants.
  ('panam', 'பணம்', [], 'money', _G.lips, ['ப', 'ண'], _P.initial, 2),
  ('marundhu', 'மருந்து', [], 'medicine', _G.lips, ['ம', 'ர'], _P.initial, 2),
  ('maambazham', 'மாம்பழம்', [], 'mango', _G.lips, ['ம', 'ப'], _P.initial, 2),
  ('paambu', 'பாம்பு', [], 'snake', _G.lips, ['ம', 'ப'], _P.medial, 2),
  ('boomi', 'பூமி', [], 'earth', _G.lips, ['ப', 'ம'], _P.initial, 2),
  ('veppam', 'வெப்பம்', [], 'heat', _G.lips, ['வ', 'ப'], _P.medial, 2),
  ('thanneer', 'தண்ணீர்', ['தண்ணி'], 'water', _G.tongueTip, ['த', 'ண'], _P.initial, 2),
  ('puthagam', 'புத்தகம்', [], 'book', _G.tongueTip, ['த'], _P.medial, 2),
  ('kadhavu', 'கதவு', [], 'door', _G.tongueTip, ['த'], _P.medial, 2),
  ('pandhu', 'பந்து', [], 'ball', _G.tongueTip, ['ந', 'த'], _P.medial, 2),
  ('pattam', 'பட்டம்', [], 'kite', _G.tongueTip, ['ட'], _P.medial, 2),
  ('thattu', 'தட்டு', [], 'plate', _G.tongueTip, ['த', 'ட'], _P.medial, 2),
  ('petti', 'பெட்டி', [], 'box', _G.tongueTip, ['ட'], _P.medial, 2),
  ('vanakkam', 'வணக்கம்', [], 'hello', _G.tongueTip, ['ண'], _P.medial, 2),
  ('kannaadi', 'கண்ணாடி', [], 'mirror / glasses', _G.tongueTip, ['ண', 'ட'], _P.medial, 2),
  ('palli', 'பள்ளி', [], 'school', _G.tongueTip, ['ள'], _P.medial, 2),
  ('ulle', 'உள்ளே', ['உள்ள'], 'inside', _G.tongueTip, ['ள'], _P.medial, 2),
  ('mazhai', 'மழை', [], 'rain', _G.tongueTip, ['ழ'], _P.medial, 2),
  ('pazham', 'பழம்', [], 'fruit', _G.tongueTip, ['ழ'], _P.medial, 2),
  ('thamizh', 'தமிழ்', [], 'Tamil', _G.tongueTip, ['த', 'ழ'], _P.medial, 2),
  ('ezhu', 'ஏழு', [], 'seven', _G.tongueTip, ['ழ'], _P.medial, 2),
  ('iravu', 'இரவு', [], 'night', _G.tongueTip, ['ர'], _P.medial, 2),
  ('maram', 'மரம்', [], 'tree', _G.tongueTip, ['ர'], _P.medial, 2),
  ('kari', 'கறி', [], 'curry', _G.tongueTip, ['ற'], _P.medial, 2),
  ('kaatru', 'காற்று', ['காத்து'], 'wind', _G.tongueTip, ['ற'], _P.medial, 2),
  ('paravai', 'பறவை', [], 'bird', _G.tongueTip, ['ற'], _P.medial, 2),
  ('neram', 'நேரம்', [], 'time', _G.tongueTip, ['ந', 'ர'], _P.initial, 2),
  ('kaapi', 'காபி', ['காஃபி'], 'coffee', _G.tongueBack, ['க'], _P.initial, 2),
  ('kudai', 'குடை', [], 'umbrella', _G.tongueBack, ['க', 'ட'], _P.initial, 2),
  ('kovil', 'கோவில்', ['கோயில்'], 'temple', _G.tongueBack, ['க'], _P.initial, 2),
  ('kuzhandhai', 'குழந்தை', [], 'child', _G.tongueBack, ['க', 'ழ'], _P.initial, 2),
  ('makkal', 'மக்கள்', [], 'people', _G.tongueBack, ['க'], _P.medial, 2),
  ('pakkam', 'பக்கம்', [], 'side / page', _G.tongueBack, ['க'], _P.medial, 2),
  ('chakkaram', 'சக்கரம்', [], 'wheel', _G.tongueBack, ['க'], _P.medial, 2),
  ('thangam', 'தங்கம்', [], 'gold', _G.tongueBack, ['ங', 'க'], _P.medial, 2),
  ('singam', 'சிங்கம்', [], 'lion', _G.tongueBack, ['ங', 'க'], _P.medial, 2),
  ('maangaai', 'மாங்காய்', [], 'raw mango', _G.tongueBack, ['ங', 'க'], _P.medial, 2),
  ('saappaadu', 'சாப்பாடு', [], 'food / meal', _G.palatal, ['ச'], _P.initial, 2),
  ('seruppu', 'செருப்பு', [], 'slippers', _G.palatal, ['ச'], _P.initial, 2),
  ('chatni', 'சட்னி', [], 'chutney', _G.palatal, ['ச'], _P.initial, 2),
  ('pechu', 'பேச்சு', [], 'speech', _G.palatal, ['ச'], _P.medial, 2),
  ('kaaichal', 'காய்ச்சல்', [], 'fever', _G.palatal, ['ச'], _P.medial, 2),
  ('oonjal', 'ஊஞ்சல்', [], 'swing', _G.palatal, ['ஞ', 'ச'], _P.medial, 2),
  ('panju', 'பஞ்சு', [], 'cotton', _G.palatal, ['ஞ', 'ச'], _P.medial, 2),
  ('thayir', 'தயிர்', [], 'curd', _G.palatal, ['ய'], _P.medial, 2),
  ('mayil', 'மயில்', [], 'peacock', _G.palatal, ['ய'], _P.medial, 2),
  ('paayasam', 'பாயசம்', [], 'payasam', _G.palatal, ['ய', 'ச'], _P.medial, 2),
  ('gnaayiru', 'ஞாயிறு', [], 'Sunday', _G.palatal, ['ஞ', 'ய'], _P.initial, 2),

  // L3 — long words and two-word names with several target sounds.
  ('vaazhaippazham', 'வாழைப்பழம்', [], 'banana', _G.lips, ['வ', 'ழ', 'ப'], _P.initial, 3),
  ('maruthuvamanai', 'மருத்துவமனை', ['ஆஸ்பத்திரி'], 'hospital', _G.lips, ['ம', 'த'], _P.initial, 3),
  ('perundhu_nilaiyam', 'பேருந்து நிலையம்', ['பஸ் ஸ்டாண்ட்'], 'bus stand', _G.lips, ['ப', 'ந'], _P.initial, 3),
  ('maathirai', 'மாத்திரை', [], 'tablet (medicine)', _G.lips, ['ம', 'த'], _P.initial, 3),
  ('tholaipesi', 'தொலைபேசி', ['போன்'], 'telephone', _G.tongueTip, ['த', 'ல'], _P.initial, 3),
  ('naarkaali', 'நாற்காலி', [], 'chair', _G.tongueTip, ['ந', 'ற', 'ல'], _P.initial, 3),
  ('thanneer_baatil', 'தண்ணீர் பாட்டில்', ['தண்ணி பாட்டில்'], 'water bottle', _G.tongueTip, ['த', 'ண', 'ட'], _P.initial, 3),
  ('kaalai_vanakkam', 'காலை வணக்கம்', [], 'good morning', _G.tongueTip, ['ல', 'ண'], _P.medial, 3),
  ('thalaivali', 'தலைவலி', [], 'headache', _G.tongueTip, ['த', 'ல'], _P.initial, 3),
  ('pal_vali', 'பல் வலி', ['பல்வலி'], 'toothache', _G.tongueTip, ['ல'], _P.medial, 3),
  ('rayil_nilaiyam', 'ரயில் நிலையம்', ['ரயில்வே ஸ்டேஷன்'], 'railway station', _G.tongueTip, ['ர', 'ல', 'ந'], _P.initial, 3),
  ('kaaikari_kadai', 'காய்கறிக் கடை', ['காய்கறி கடை'], 'vegetable shop', _G.tongueBack, ['க', 'ற', 'ட'], _P.initial, 3),
  ('kaipesi', 'கைபேசி', ['மொபைல்'], 'mobile phone', _G.tongueBack, ['க', 'ச'], _P.initial, 3),
  ('kudineer', 'குடிநீர்', [], 'drinking water', _G.tongueBack, ['க', 'ட', 'ந'], _P.initial, 3),
  ('kozhikkari', 'கோழிக்கறி', ['சிக்கன்'], 'chicken curry', _G.tongueBack, ['க', 'ழ', 'ற'], _P.initial, 3),
  ('chakkara_naarkaali', 'சக்கர நாற்காலி', ['வீல் சேர்'], 'wheelchair', _G.palatal, ['ச', 'க', 'ற'], _P.initial, 3),
  ('sarkkarai_noi', 'சர்க்கரை நோய்', ['சுகர்'], 'diabetes', _G.palatal, ['ச', 'ர', 'க'], _P.initial, 3),
  ('pachai_milagaai', 'பச்சை மிளகாய்', [], 'green chilli', _G.palatal, ['ச', 'ள', 'க'], _P.medial, 3),
  ('gnaayitrukkizhamai', 'ஞாயிற்றுக்கிழமை', ['ஞாயித்துக்கிழமை'], 'Sunday', _G.palatal, ['ஞ', 'ய', 'ற', 'ழ'], _P.initial, 3),
];

/// English words: (word, reading aid, group, sounds, position, level).
const _enWords = <(String, String, _G, List<String>, _P, int)>[
  // L1
  ('map', 'மேப்', _G.lips, ['m', 'p'], _P.initial, 1),
  ('mop', 'மாப்', _G.lips, ['m'], _P.initial, 1),
  ('pen', 'பென்', _G.lips, ['p'], _P.initial, 1),
  ('ball', 'பால்', _G.lips, ['b'], _P.initial, 1),
  ('fan', 'ஃபேன்', _G.lips, ['f'], _P.initial, 1),
  ('van', 'வேன்', _G.lips, ['v'], _P.initial, 1),
  ('boy', 'பாய்', _G.lips, ['b'], _P.initial, 1),
  ('bed', 'பெட்', _G.lips, ['b'], _P.initial, 1),
  ('top', 'டாப்', _G.tongueTip, ['t'], _P.initial, 1),
  ('ten', 'டென்', _G.tongueTip, ['t', 'n'], _P.initial, 1),
  ('dog', 'டாக்', _G.tongueTip, ['d'], _P.initial, 1),
  ('door', 'டோர்', _G.tongueTip, ['d'], _P.initial, 1),
  ('nose', 'நோஸ்', _G.tongueTip, ['n'], _P.initial, 1),
  ('name', 'நேம்', _G.tongueTip, ['n'], _P.initial, 1),
  ('leg', 'லெக்', _G.tongueTip, ['l'], _P.initial, 1),
  ('lip', 'லிப்', _G.tongueTip, ['l'], _P.initial, 1),
  ('sun', 'ஸன்', _G.tongueTip, ['s'], _P.initial, 1),
  ('soap', 'ஸோப்', _G.tongueTip, ['s'], _P.initial, 1),
  ('red', 'ரெட்', _G.tongueTip, ['r', 'd'], _P.initial, 1),
  ('rice', 'ரைஸ்', _G.tongueTip, ['r', 's'], _P.initial, 1),
  ('cup', 'கப்', _G.tongueBack, ['k'], _P.initial, 1),
  ('cat', 'கேட்', _G.tongueBack, ['k'], _P.initial, 1),
  ('coat', 'கோட்', _G.tongueBack, ['k'], _P.initial, 1),
  ('gate', 'கேட்', _G.tongueBack, ['g'], _P.initial, 1),
  ('gum', 'கம்', _G.tongueBack, ['g'], _P.initial, 1),
  ('goat', 'கோட்', _G.tongueBack, ['g'], _P.initial, 1),
  ('chair', 'சேர்', _G.palatal, ['ch'], _P.initial, 1),
  ('cheese', 'சீஸ்', _G.palatal, ['ch'], _P.initial, 1),
  ('jam', 'ஜாம்', _G.palatal, ['j'], _P.initial, 1),
  ('jug', 'ஜக்', _G.palatal, ['j'], _P.initial, 1),
  ('juice', 'ஜூஸ்', _G.palatal, ['j'], _P.initial, 1),
  ('ship', 'ஷிப்', _G.palatal, ['sh'], _P.initial, 1),
  ('shop', 'ஷாப்', _G.palatal, ['sh'], _P.initial, 1),
  ('yes', 'யெஸ்', _G.palatal, ['y'], _P.initial, 1),
  // L2
  ('apple', 'ஆப்பிள்', _G.lips, ['p'], _P.medial, 2),
  ('happy', 'ஹேப்பி', _G.lips, ['p'], _P.medial, 2),
  ('paper', 'பேப்பர்', _G.lips, ['p'], _P.medial, 2),
  ('lemon', 'லெமன்', _G.lips, ['m'], _P.medial, 2),
  ('open', 'ஓப்பன்', _G.lips, ['p'], _P.medial, 2),
  ('number', 'நம்பர்', _G.lips, ['m', 'b'], _P.medial, 2),
  ('water', 'வாட்டர்', _G.tongueTip, ['t'], _P.medial, 2),
  ('butter', 'பட்டர்', _G.tongueTip, ['t'], _P.medial, 2),
  ('letter', 'லெட்டர்', _G.tongueTip, ['t'], _P.medial, 2),
  ('button', 'பட்டன்', _G.tongueTip, ['t', 'n'], _P.medial, 2),
  ('ladder', 'லேடர்', _G.tongueTip, ['d'], _P.medial, 2),
  ('money', 'மனி', _G.tongueTip, ['n'], _P.medial, 2),
  ('dinner', 'டின்னர்', _G.tongueTip, ['d', 'n'], _P.medial, 2),
  ('banana', 'பனானா', _G.tongueTip, ['n'], _P.medial, 2),
  ('hello', 'ஹலோ', _G.tongueTip, ['l'], _P.medial, 2),
  ('pillow', 'பில்லோ', _G.tongueTip, ['l'], _P.medial, 2),
  ('balloon', 'பலூன்', _G.tongueTip, ['l', 'n'], _P.medial, 2),
  ('glasses', 'கிளாஸஸ்', _G.tongueTip, ['s', 'l'], _P.medial, 2),
  ('bicycle', 'பைசைக்கிள்', _G.tongueTip, ['s'], _P.medial, 2),
  ('carrot', 'கேரட்', _G.tongueTip, ['r', 't'], _P.medial, 2),
  ('sorry', 'ஸாரி', _G.tongueTip, ['s', 'r'], _P.medial, 2),
  ('mirror', 'மிரர்', _G.tongueTip, ['r'], _P.medial, 2),
  ('pocket', 'பாக்கெட்', _G.tongueBack, ['k'], _P.medial, 2),
  ('cookie', 'குக்கீ', _G.tongueBack, ['k'], _P.medial, 2),
  ('bucket', 'பக்கெட்', _G.tongueBack, ['k'], _P.medial, 2),
  ('ticket', 'டிக்கெட்', _G.tongueBack, ['k'], _P.medial, 2),
  ('doctor', 'டாக்டர்', _G.tongueBack, ['k', 't'], _P.medial, 2),
  ('sugar', 'ஷுகர்', _G.tongueBack, ['g'], _P.medial, 2),
  ('tiger', 'டைகர்', _G.tongueBack, ['g'], _P.medial, 2),
  ('finger', 'ஃபிங்கர்', _G.tongueBack, ['ng', 'g'], _P.medial, 2),
  ('monkey', 'மங்கி', _G.tongueBack, ['ng', 'k'], _P.medial, 2),
  ('kitchen', 'கிச்சன்', _G.palatal, ['ch'], _P.medial, 2),
  ('teacher', 'டீச்சர்', _G.palatal, ['ch'], _P.medial, 2),
  ('watches', 'வாச்சஸ்', _G.palatal, ['ch'], _P.medial, 2),
  ('magic', 'மேஜிக்', _G.palatal, ['j'], _P.medial, 2),
  ('pigeon', 'பிஜன்', _G.palatal, ['j'], _P.medial, 2),
  ('fishing', 'ஃபிஷிங்', _G.palatal, ['sh'], _P.medial, 2),
  ('washing', 'வாஷிங்', _G.palatal, ['sh'], _P.medial, 2),
  ('crayon', 'க்ரேயான்', _G.palatal, ['y'], _P.medial, 2),
  ('onion', 'ஆனியன்', _G.palatal, ['y'], _P.medial, 2),
  ('yellow', 'யெல்லோ', _G.palatal, ['y', 'l'], _P.initial, 2),
  // L3
  ('paper bag', 'பேப்பர் பேக்', _G.lips, ['p', 'b'], _P.initial, 3),
  ('bus pass', 'பஸ் பாஸ்', _G.lips, ['b', 'p', 's'], _P.initial, 3),
  ('medicine', 'மெடிசின்', _G.lips, ['m', 'd', 's'], _P.initial, 3),
  ('happy birthday', 'ஹேப்பி பர்த்டே', _G.lips, ['p', 'b'], _P.medial, 3),
  ('toothpaste', 'டூத்பேஸ்ட்', _G.tongueTip, ['t', 's'], _P.initial, 3),
  ('telephone', 'டெலிஃபோன்', _G.tongueTip, ['t', 'l', 'n'], _P.initial, 3),
  ('tomorrow', 'டுமாரோ', _G.tongueTip, ['t', 'r'], _P.initial, 3),
  ('drinking water', 'டிரிங்கிங் வாட்டர்', _G.tongueTip, ['d', 'r', 't'], _P.initial, 3),
  ('railway station', 'ரெயில்வே ஸ்டேஷன்', _G.tongueTip, ['r', 'l', 's', 't'], _P.initial, 3),
  ('television', 'டெலிவிஷன்', _G.tongueTip, ['t', 'l'], _P.initial, 3),
  ('cooking gas', 'குக்கிங் கேஸ்', _G.tongueBack, ['k', 'g'], _P.initial, 3),
  ('bus ticket', 'பஸ் டிக்கெட்', _G.tongueBack, ['k', 't'], _P.medial, 3),
  ('coconut', 'கோகனட்', _G.tongueBack, ['k', 'n'], _P.initial, 3),
  ('good morning', 'குட் மார்னிங்', _G.tongueBack, ['g', 'ng'], _P.initial, 3),
  ('blood sugar', 'பிளட் ஷுகர்', _G.tongueBack, ['g', 'sh'], _P.medial, 3),
  ('wheelchair', 'வீல்சேர்', _G.palatal, ['ch'], _P.medial, 3),
  ('orange juice', 'ஆரஞ்சு ஜூஸ்', _G.palatal, ['j'], _P.medial, 3),
  ('washing machine', 'வாஷிங் மெஷின்', _G.palatal, ['sh'], _P.medial, 3),
  ('shopping bag', 'ஷாப்பிங் பேக்', _G.palatal, ['sh'], _P.initial, 3),
  ('yesterday', 'யெஸ்டர்டே', _G.palatal, ['y', 's'], _P.initial, 3),
];

String _slug(String s) => s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');

List<OralItem> _words() => [
      for (final (slug, ta, spoken, en, g, s, p, l) in _taWords)
        OralItem(
          id: 'oral_word_ta_$slug',
          kind: _K.words,
          level: l,
          lang: OralLang.ta,
          ta: ta,
          en: en,
          taSpoken: spoken,
          group: g,
          sounds: s,
          position: p,
        ),
      for (final (en, aid, g, s, p, l) in _enWords)
        OralItem(
          id: 'oral_word_en_${_slug(en)}',
          kind: _K.words,
          level: l,
          lang: OralLang.en,
          en: en,
          ta: aid,
          group: g,
          sounds: s,
          position: p,
        ),
    ];

// ── Minimal pairs ────────────────────────────────────────────────────────

/// Tamil pairs: (slug, a, b, meaning a / b, group, contrasting sounds, level).
/// All are real words; ல/ள/ழ and ர/ற are contrasts Tamil listeners rely on.
const _taPairs = <(String, String, String, String, _G, List<String>, int)>[
  // L1 — lips vs tongue vs back, one-syllable words.
  ('paai_thaai', 'பாய்', 'தாய்', 'mat / mother', _G.tongueTip, ['ப', 'த'], 1),
  ('thaai_kaai', 'தாய்', 'காய்', 'mother / vegetable', _G.tongueBack, ['த', 'க'], 1),
  ('naai_vaai', 'நாய்', 'வாய்', 'dog / mouth', _G.tongueTip, ['ந', 'வ'], 1),
  ('kai_pai', 'கை', 'பை', 'hand / bag', _G.tongueBack, ['க', 'ப'], 1),
  ('pai_thai', 'பை', 'தை', 'bag / (month) Thai', _G.tongueTip, ['ப', 'த'], 1),
  ('maadu_kaadu', 'மாடு', 'காடு', 'cow / forest', _G.tongueBack, ['ம', 'க'], 1),
  ('saai_thaai', 'சாய்', 'தாய்', 'lean / mother', _G.palatal, ['ச', 'த'], 1),
  // L2 — sounds that change the meaning in Tamil.
  ('kal_kal', 'கல்', 'கள்', 'stone / toddy', _G.tongueTip, ['ல', 'ள'], 2),
  ('puli_puli', 'புலி', 'புளி', 'tiger / tamarind', _G.tongueTip, ['ல', 'ள'], 2),
  ('vali_vazhi', 'வலி', 'வழி', 'pain / way', _G.tongueTip, ['ல', 'ழ'], 2),
  ('malai_mazhai', 'மலை', 'மழை', 'mountain / rain', _G.tongueTip, ['ல', 'ழ'], 2),
  ('ilai_izhai', 'இலை', 'இழை', 'leaf / thread', _G.tongueTip, ['ல', 'ழ'], 2),
  ('vaal_vaal', 'வால்', 'வாள்', 'tail / sword', _G.tongueTip, ['ல', 'ள'], 2),
  ('oli_oli', 'ஒலி', 'ஒளி', 'sound / light', _G.tongueTip, ['ல', 'ள'], 2),
  ('karai_karai', 'கரை', 'கறை', 'shore / stain', _G.tongueTip, ['ர', 'ற'], 2),
  ('arai_arai', 'அரை', 'அறை', 'half / room', _G.tongueTip, ['ர', 'ற'], 2),
  ('pattu_pathu', 'பட்டு', 'பத்து', 'silk / ten', _G.tongueTip, ['ட', 'த'], 2),
  ('paadu_kaadu', 'பாடு', 'காடு', 'sing / forest', _G.tongueBack, ['ப', 'க'], 2),
  ('ser_ther', 'சேர்', 'தேர்', 'join / chariot', _G.palatal, ['ச', 'த'], 2),
];

/// L3: the same contrasts inside a clarifying sentence — exactly what the
/// person says when a listener mishears. (slug, sentence, English, pair,
/// group, sounds)
const _taPairSentences = <(String, String, String, (String, String), _G, List<String>)>[
  ('vali_vazhi', 'நான் சொன்னது வலி, வழி இல்லை', 'I said pain, not way', ('வலி', 'வழி'), _G.tongueTip, ['ல', 'ழ']),
  ('malai_mazhai', 'நான் சொன்னது மழை, மலை இல்லை', 'I said rain, not mountain', ('மழை', 'மலை'), _G.tongueTip, ['ழ', 'ல']),
  ('puli_puli', 'எனக்குப் புளி வேண்டும், புலி இல்லை', 'I want tamarind, not a tiger', ('புளி', 'புலி'), _G.tongueTip, ['ள', 'ல']),
  ('arai_arai', 'அந்த அறைக்குப் போங்கள்', 'Go to that room', ('அறை', 'அரை'), _G.tongueTip, ['ற', 'ர']),
  ('pattu_pathu', 'பத்து ரூபாய் கொடுங்கள்', 'Give ten rupees', ('பத்து', 'பட்டு'), _G.tongueTip, ['த', 'ட']),
  ('kai_pai', 'என் கையில் பை இருக்கிறது', 'There is a bag in my hand', ('கை', 'பை'), _G.tongueBack, ['க', 'ப']),
  ('thaai_kaai', 'தாய் காய் வாங்கினார்', 'Mother bought vegetables', ('தாய்', 'காய்'), _G.tongueBack, ['த', 'க']),
  ('naai_vaai', 'நாய் வாய் திறந்தது', 'The dog opened its mouth', ('நாய்', 'வாய்'), _G.tongueTip, ['ந', 'வ']),
  ('ser_ther', 'தேர் பார்க்கச் சேர்ந்து போவோம்', "Let's go together to see the chariot", ('தேர்', 'சேர்'), _G.palatal, ['த', 'ச']),
  ('kal_kal', 'இது கல், கள் இல்லை', 'This is a stone, not toddy', ('கல்', 'கள்'), _G.tongueTip, ['ல', 'ள']),
];

/// English pairs: (a, b, reading aid, group, sounds, level).
const _enPairs = <(String, String, String, _G, List<String>, int)>[
  ('pea', 'tea', 'பீ / டீ', _G.tongueTip, ['p', 't'], 1),
  ('tea', 'key', 'டீ / கீ', _G.tongueBack, ['t', 'k'], 1),
  ('pie', 'tie', 'பை / டை', _G.tongueTip, ['p', 't'], 1),
  ('me', 'knee', 'மீ / நீ', _G.tongueTip, ['m', 'n'], 1),
  ('bay', 'day', 'பே / டே', _G.tongueTip, ['b', 'd'], 1),
  ('no', 'go', 'நோ / கோ', _G.tongueBack, ['n', 'g'], 1),
  ('two', 'shoe', 'டூ / ஷூ', _G.palatal, ['t', 'sh'], 1),
  ('pat', 'cat', 'பேட் / கேட்', _G.tongueBack, ['p', 'k'], 2),
  ('top', 'cop', 'டாப் / காப்', _G.tongueBack, ['t', 'k'], 2),
  ('tape', 'cape', 'டேப் / கேப்', _G.tongueBack, ['t', 'k'], 2),
  ('tin', 'kin', 'டின் / கின்', _G.tongueBack, ['t', 'k'], 2),
  ('dot', 'got', 'டாட் / காட்', _G.tongueBack, ['d', 'g'], 2),
  ('sip', 'ship', 'ஸிப் / ஷிப்', _G.palatal, ['s', 'sh'], 2),
  ('sea', 'she', 'ஸீ / ஷீ', _G.palatal, ['s', 'sh'], 2),
  ('sock', 'shock', 'ஸாக் / ஷாக்', _G.palatal, ['s', 'sh'], 2),
  ('chin', 'tin', 'சின் / டின்', _G.palatal, ['ch', 't'], 2),
  ('chop', 'top', 'சாப் / டாப்', _G.palatal, ['ch', 't'], 2),
  ('lake', 'rake', 'லேக் / ரேக்', _G.tongueTip, ['l', 'r'], 2),
  ('light', 'night', 'லைட் / நைட்', _G.tongueTip, ['l', 'n'], 2),
];

/// L3 English: clarifying sentences. (a, b, sentence, reading aid, group, sounds)
const _enPairSentences = <(String, String, String, String, _G, List<String>)>[
  ('cat', 'pat', 'I said cat, not pat', 'ஐ செட் கேட், நாட் பேட்', _G.tongueBack, ['k', 'p']),
  ('tea', 'key', 'I want tea, not the key', 'ஐ வான்ட் டீ, நாட் த கீ', _G.tongueBack, ['t', 'k']),
  ('ship', 'sip', 'Take a small sip', 'டேக் எ ஸ்மால் ஸிப்', _G.palatal, ['s', 'sh']),
  ('top', 'cop', 'Put it on the top shelf', 'புட் இட் ஆன் த டாப் ஷெல்ஃப்', _G.tongueTip, ['t', 'sh']),
  ('night', 'light', 'Turn off the light at night', 'டர்ன் ஆஃப் த லைட் அட் நைட்', _G.tongueTip, ['l', 'n', 't']),
  ('cape', 'tape', 'I need some tape', 'ஐ நீட் சம் டேப்', _G.tongueTip, ['t', 'n']),
  ('she', 'sea', 'She is at the sea', 'ஷீ இஸ் அட் த ஸீ', _G.palatal, ['sh', 's']),
  ('go', 'no', 'No, I will not go', 'நோ, ஐ வில் நாட் கோ', _G.tongueBack, ['n', 'g']),
  ('chin', 'tin', 'My chin is sore', 'மை சின் இஸ் ஸோர்', _G.palatal, ['ch', 's']),
  ('rake', 'lake', 'We walked to the lake', 'வீ வாக்ட் டு த லேக்', _G.tongueTip, ['l', 'k']),
];

List<OralItem> _pairs() => [
      for (final (slug, a, b, meaning, g, s, l) in _taPairs)
        OralItem(
          id: 'oral_pair_ta_$slug',
          kind: _K.minimalPairs,
          level: l,
          lang: OralLang.ta,
          ta: '$a $b',
          en: meaning,
          pair: (a, b),
          group: g,
          sounds: s,
        ),
      for (final (slug, ta, en, pair, g, s) in _taPairSentences)
        OralItem(
          id: 'oral_pair3_ta_$slug',
          kind: _K.minimalPairs,
          level: 3,
          lang: OralLang.ta,
          ta: ta,
          en: en,
          pair: pair,
          group: g,
          sounds: s,
        ),
      for (final (a, b, aid, g, s, l) in _enPairs)
        OralItem(
          id: 'oral_pair_en_${a}_$b',
          kind: _K.minimalPairs,
          level: l,
          lang: OralLang.en,
          en: '$a $b',
          ta: aid,
          pair: (a, b),
          group: g,
          sounds: s,
        ),
      for (final (a, b, en, aid, g, s) in _enPairSentences)
        OralItem(
          id: 'oral_pair3_en_${a}_$b',
          kind: _K.minimalPairs,
          level: 3,
          lang: OralLang.en,
          en: en,
          ta: aid,
          enAlternates: [en.replaceAll(',', '')],
          pair: (a, b),
          group: g,
          sounds: s,
        ),
    ];

// ── Functional phrases ───────────────────────────────────────────────────

/// (slug, English, Tamil (written), spoken Tamil forms, situation, level).
/// Templates use {name} {address} {phone} {son_phone} {place}; the user
/// fills them once and they are skipped until then.
const _phrases = <(String, String, String, List<String>, _S, int)>[
  // L1 — one or two words for the most urgent needs.
  ('water', 'Water', 'தண்ணீர்', ['தண்ணி'], _S.needs, 1),
  ('pain', 'Pain', 'வலி', [], _S.health, 1),
  ('yes', 'Yes', 'ஆமாம்', ['ஆமா'], _S.social, 1),
  ('no', 'No', 'இல்லை', ['இல்ல'], _S.social, 1),
  ('help', 'Help', 'உதவி', ['ஹெல்ப்'], _S.safety, 1),
  ('doctor', 'Doctor', 'டாக்டர்', ['மருத்துவர்'], _S.health, 1),
  ('toilet', 'Toilet', 'கழிப்பறை', ['பாத்ரூம்', 'டாய்லெட்'], _S.needs, 1),
  ('food', 'Food', 'சாப்பாடு', [], _S.needs, 1),
  ('thank_you', 'Thank you', 'நன்றி', [], _S.social, 1),
  ('hello', 'Hello', 'வணக்கம்', [], _S.social, 1),
  ('medicine', 'Medicine', 'மருந்து', [], _S.health, 1),
  ('enough', 'Enough', 'போதும்', [], _S.needs, 1),
  ('again', 'Again', 'மறுபடி', ['திரும்ப'], _S.social, 1),
  ('slowly', 'Slowly', 'மெதுவாக', ['மெதுவா'], _S.social, 1),
  ('wait', 'Wait', 'கொஞ்சம் இருங்கள்', ['கொஞ்சம் இருங்க'], _S.social, 1),
  ('tea', 'Tea', 'டீ', ['தேநீர்'], _S.needs, 1),
  // L2 — short sentences for needs, health and family.
  ('i_want_water', 'I want water', 'எனக்குத் தண்ணீர் வேண்டும்', ['எனக்கு தண்ணி வேணும்'], _S.needs, 2),
  ('i_have_pain', 'I have pain', 'எனக்கு வலிக்கிறது', ['எனக்கு வலிக்குது'], _S.health, 2),
  ('call_the_doctor', 'Call the doctor', 'டாக்டரைக் கூப்பிடுங்கள்', ['டாக்டரை கூப்பிடுங்க'], _S.health, 2),
  ('i_need_the_doctor', 'I need the doctor', 'எனக்கு டாக்டர் வேண்டும்', ['எனக்கு டாக்டர் வேணும்'], _S.health, 2),
  ('call_my_son', 'Call my son', 'என் மகனைக் கூப்பிடுங்கள்', ['என் பையனை கூப்பிடுங்க'], _S.family, 2),
  ('call_my_daughter', 'Call my daughter', 'என் மகளைக் கூப்பிடுங்கள்', ['என் பொண்ணை கூப்பிடுங்க'], _S.family, 2),
  ('i_am_tired', 'I am tired', 'நான் சோர்வாக இருக்கிறேன்', ['சோர்வா இருக்கு', 'டயர்டா இருக்கு'], _S.health, 2),
  ('i_am_hungry', 'I am hungry', 'எனக்குப் பசிக்கிறது', ['எனக்கு பசிக்குது'], _S.needs, 2),
  ('speak_slowly', 'Please speak slowly', 'மெதுவாகப் பேசுங்கள்', ['மெதுவா பேசுங்க'], _S.social, 2),
  ('say_it_again', 'Please say it again', 'மறுபடி சொல்லுங்கள்', ['திரும்ப சொல்லுங்க'], _S.social, 2),
  ('medicine_time', 'Time for my medicine', 'மருந்து நேரம் ஆகிவிட்டது', ['மருந்து நேரம் ஆச்சு'], _S.health, 2),
  ('i_am_fine', 'I am fine', 'நான் நன்றாக இருக்கிறேன்', ['நான் நல்லா இருக்கேன்'], _S.social, 2),
  ('i_dont_understand', "I don't understand", 'எனக்குப் புரியவில்லை', ['எனக்கு புரியல'], _S.social, 2),
  ('i_want_to_rest', 'I want to rest', 'நான் ஓய்வெடுக்க வேண்டும்', ['நான் ஓய்வு எடுக்கணும்'], _S.health, 2),
  ('turn_on_the_fan', 'Turn on the fan', 'மின்விசிறியைப் போடுங்கள்', ['ஃபேன் போடுங்க'], _S.needs, 2),
  ('i_want_to_sit', 'I want to sit down', 'நான் உட்கார வேண்டும்', ['நான் உட்காரணும்'], _S.needs, 2),
  // L3 — personal details (templates), community, phone, safety.
  ('my_name', 'My name is {name}', 'என் பெயர் {name}', ['என் பேரு {name}'], _S.personal, 3),
  ('my_address', 'My address is {address}', 'என் முகவரி {address}', ['என் அட்ரஸ் {address}'], _S.personal, 3),
  ('my_phone', 'My phone number is {phone}', 'என் தொலைபேசி எண் {phone}', ['என் போன் நம்பர் {phone}'], _S.personal, 3),
  ('son_phone', "My son's number is {son_phone}", 'என் மகனின் எண் {son_phone}', ['என் பையன் நம்பர் {son_phone}'], _S.personal, 3),
  ('tongue_surgery', 'I had surgery on my tongue, please be patient', 'என் நாக்கில் அறுவை சிகிச்சை நடந்தது, கொஞ்சம் பொறுமையாகக் கேளுங்கள்', ['என் நாக்குல ஆபரேஷன் ஆச்சு, கொஞ்சம் பொறுமையா கேளுங்க'], _S.personal, 3),
  ('see_doctor_today', 'I need to see the doctor today', 'நான் இன்று டாக்டரைப் பார்க்க வேண்டும்', ['இன்னைக்கு டாக்டரை பார்க்கணும்'], _S.health, 3),
  ('pain_is_here', 'The pain is here', 'வலி இங்கே இருக்கிறது', ['வலி இங்க இருக்கு'], _S.health, 3),
  ('ambulance', 'Please call an ambulance', 'ஆம்புலன்ஸைக் கூப்பிடுங்கள்', ['ஆம்புலன்ஸ் கூப்பிடுங்க'], _S.safety, 3),
  ('bleeding', 'I am bleeding', 'எனக்கு ரத்தம் வருகிறது', ['எனக்கு ரத்தம் வருது'], _S.safety, 3),
  ('how_much', 'How much is this?', 'இது என்ன விலை?', ['இது எவ்வளவு?'], _S.shop, 3),
  ('kilo_rice', 'Give me one kilo of rice', 'ஒரு கிலோ அரிசி கொடுங்கள்', ['ஒரு கிலோ அரிசி குடுங்க'], _S.shop, 3),
  ('change', 'Do you have change?', 'சில்லறை இருக்கிறதா?', ['சில்லறை இருக்கா?'], _S.shop, 3),
  ('bus_to_place', 'Does this bus go to {place}?', 'இந்தப் பேருந்து {place} போகுமா?', ['இந்த பஸ் {place} போகுமா?'], _S.travel, 3),
  ('ticket_to_place', 'One ticket to {place}', 'ஒரு டிக்கெட், {place}', ['{place} ஒரு டிக்கெட்'], _S.travel, 3),
  ('stop_here', 'Please stop here', 'இங்கே நிறுத்துங்கள்', ['இங்க நிறுத்துங்க'], _S.travel, 3),
  ('phone_hello', 'Hello, this is {name} speaking', 'வணக்கம், நான் {name} பேசுகிறேன்', ['ஹலோ, நான் {name} பேசுறேன்'], _S.phone, 3),
  ('can_you_hear', 'Can you hear me?', 'நான் பேசுவது கேட்கிறதா?', ['நான் பேசுறது கேக்குதா?'], _S.phone, 3),
  ('call_back', 'I will call you back', 'நான் திரும்ப அழைக்கிறேன்', ['நான் திரும்ப கூப்பிடுறேன்'], _S.phone, 3),
  ('send_message', 'Please send me a message', 'எனக்கு ஒரு மெசேஜ் அனுப்புங்கள்', ['எனக்கு ஒரு மெசேஜ் அனுப்புங்க'], _S.phone, 3),
];

List<OralItem> _phraseItems() => [
      for (final (slug, en, ta, spoken, sit, l) in _phrases)
        OralItem(
          id: 'oral_phrase_$slug',
          kind: _K.phrases,
          level: l,
          en: en,
          ta: ta,
          taSpoken: spoken,
          enAlternates: [
            if (en.contains("'")) en.replaceAll("'", ''),
            if (en.endsWith('?')) en.substring(0, en.length - 1),
          ],
          situation: sit,
        ),
    ];

// ── Clear-speech strategy items ──────────────────────────────────────────

/// Said one word at a time, with a pause after each word. Level by length:
/// L1 two words, L2 three or four, L3 five or more (English count).
const _clear = <(String, String, String, List<String>, _S, int)>[
  ('water_please', 'Water please', 'தண்ணீர் வேண்டும்', ['தண்ணி வேணும்'], _S.needs, 1),
  ('doctor_please', 'Doctor please', 'டாக்டர் வேண்டும்', ['டாக்டர் வேணும்'], _S.health, 1),
  ('good_morning', 'Good morning', 'காலை வணக்கம்', [], _S.social, 1),
  ('thank_you', 'Thank you', 'மிக்க நன்றி', [], _S.social, 1),
  ('pain_here', 'Pain here', 'இங்கே வலி', ['இங்க வலி'], _S.health, 1),
  ('not_now', 'Not now', 'இப்போது வேண்டாம்', ['இப்ப வேண்டாம்'], _S.social, 1),
  ('come_here', 'Come here', 'இங்கே வாருங்கள்', ['இங்க வாங்க'], _S.family, 1),
  ('very_good', 'Very good', 'மிகவும் நல்லது', ['ரொம்ப நல்லது'], _S.social, 1),
  ('i_want_water', 'I want water', 'எனக்குத் தண்ணீர் வேண்டும்', ['எனக்கு தண்ணி வேணும்'], _S.needs, 2),
  ('please_call_my_son', 'Please call my son', 'என் மகனைக் கூப்பிடுங்கள்', ['என் பையனை கூப்பிடுங்க'], _S.family, 2),
  ('please_speak_slowly', 'Please speak slowly', 'தயவுசெய்து மெதுவாகப் பேசுங்கள்', ['கொஞ்சம் மெதுவா பேசுங்க'], _S.social, 2),
  ('i_have_pain_here', 'I have pain here', 'எனக்கு இங்கே வலிக்கிறது', ['எனக்கு இங்க வலிக்குது'], _S.health, 2),
  ('give_me_the_medicine', 'Give me the medicine', 'எனக்கு மருந்து கொடுங்கள்', ['எனக்கு மருந்து குடுங்க'], _S.health, 2),
  ('how_much_is_this', 'How much is this', 'இது என்ன விலை', ['இது எவ்வளவு'], _S.shop, 2),
  ('i_feel_better', 'I am feeling better', 'எனக்கு இப்போது பரவாயில்லை', ['இப்ப பரவாயில்ல'], _S.health, 2),
  ('please_say_it_again', 'Please say it again', 'தயவுசெய்து மறுபடி சொல்லுங்கள்', ['திரும்ப சொல்லுங்க'], _S.social, 2),
  ('surgery_on_my_tongue', 'I had surgery on my tongue', 'என் நாக்கில் அறுவை சிகிச்சை நடந்தது', ['என் நாக்குல ஆபரேஷன் ஆச்சு'], _S.personal, 3),
  ('i_will_speak_slowly', 'Please listen, I will speak slowly', 'கொஞ்சம் கேளுங்கள், நான் மெதுவாகப் பேசுவேன்', ['கொஞ்சம் கேளுங்க, நான் மெதுவா பேசுவேன்'], _S.social, 3),
  ('bus_to_hospital', 'Does this bus go to the hospital', 'இந்தப் பேருந்து மருத்துவமனைக்குப் போகுமா', ['இந்த பஸ் ஆஸ்பத்திரிக்கு போகுமா'], _S.travel, 3),
  ('see_the_doctor_today', 'I need to see the doctor today', 'நான் இன்று டாக்டரைப் பார்க்க வேண்டும்', ['இன்னைக்கு டாக்டரை பார்க்கணும்'], _S.health, 3),
  ('one_kilo_of_rice', 'Please give me one kilo of rice', 'தயவுசெய்து ஒரு கிலோ அரிசி கொடுங்கள்', ['ஒரு கிலோ அரிசி குடுங்க'], _S.shop, 3),
  ('hear_me_on_the_phone', 'Can you hear me on the phone', 'தொலைபேசியில் நான் பேசுவது கேட்கிறதா', ['போன்ல நான் பேசுறது கேக்குதா'], _S.phone, 3),
  ('call_back_in_ten', 'I will call you back in ten minutes', 'பத்து நிமிடத்தில் திரும்ப அழைக்கிறேன்', ['பத்து நிமிஷத்துல திரும்ப கூப்பிடுறேன்'], _S.phone, 3),
  ('thank_you_for_waiting', 'Thank you for waiting for me', 'எனக்காகக் காத்திருந்ததற்கு நன்றி', ['எனக்காக காத்திருந்ததுக்கு நன்றி'], _S.social, 3),
];

List<OralItem> _clearItems() => [
      for (final (slug, en, ta, spoken, sit, l) in _clear)
        OralItem(
          id: 'oral_clear_$slug',
          kind: _K.clearSpeech,
          level: l,
          en: en,
          ta: ta,
          taSpoken: spoken,
          pacing: true,
          situation: sit,
        ),
    ];

// ── Monthly intelligibility set ──────────────────────────────────────────

/// Fixed list: never reorder, edit or extend — results are only comparable
/// month to month while the list stays identical. 10 words chosen across
/// the sound groups + 10 everyday phrases, per language (20 each).
const _intelTaWords = [
  ('paal', 'பால்', 'milk', _G.lips, ['ப'], <String>[]),
  ('thanneer', 'தண்ணீர்', 'water', _G.tongueTip, ['த', 'ண'], ['தண்ணி']),
  ('vali', 'வலி', 'pain', _G.tongueTip, ['ல'], <String>[]),
  ('mazhai', 'மழை', 'rain', _G.tongueTip, ['ழ'], <String>[]),
  ('palli', 'பள்ளி', 'school', _G.tongueTip, ['ள'], <String>[]),
  ('kaatru', 'காற்று', 'wind', _G.tongueTip, ['ற'], ['காத்து']),
  ('pattu', 'பட்டு', 'silk', _G.tongueTip, ['ட'], <String>[]),
  ('kai', 'கை', 'hand', _G.tongueBack, ['க'], <String>[]),
  ('saavi', 'சாவி', 'key', _G.palatal, ['ச'], <String>[]),
  ('yaanai', 'யானை', 'elephant', _G.palatal, ['ய'], <String>[]),
];

const _intelEnWords = [
  ('pie', 'பை', _G.lips, ['p']),
  ('tea', 'டீ', _G.tongueTip, ['t']),
  ('sun', 'ஸன்', _G.tongueTip, ['s']),
  ('light', 'லைட்', _G.tongueTip, ['l']),
  ('red', 'ரெட்', _G.tongueTip, ['r']),
  ('dog', 'டாக்', _G.tongueTip, ['d']),
  ('key', 'கீ', _G.tongueBack, ['k']),
  ('shoe', 'ஷூ', _G.palatal, ['sh']),
  ('cheese', 'சீஸ்', _G.palatal, ['ch']),
  ('yes', 'யெஸ்', _G.palatal, ['y']),
];

const _intelPhrases = [
  ('i_want_water', 'I want water', 'எனக்குத் தண்ணீர் வேண்டும்', ['எனக்கு தண்ணி வேணும்']),
  ('call_the_doctor', 'Call the doctor', 'டாக்டரைக் கூப்பிடுங்கள்', ['டாக்டரை கூப்பிடுங்க']),
  ('i_have_pain', 'I have pain', 'எனக்கு வலிக்கிறது', ['எனக்கு வலிக்குது']),
  ('how_much', 'How much is this', 'இது என்ன விலை', ['இது எவ்வளவு']),
  ('speak_slowly', 'Please speak slowly', 'மெதுவாகப் பேசுங்கள்', ['மெதுவா பேசுங்க']),
  ('i_am_fine', 'I am fine', 'நான் நன்றாக இருக்கிறேன்', ['நான் நல்லா இருக்கேன்']),
  ('say_it_again', 'Say it again', 'மறுபடி சொல்லுங்கள்', ['திரும்ப சொல்லுங்க']),
  ('stop_here', 'Stop here', 'இங்கே நிறுத்துங்கள்', ['இங்க நிறுத்துங்க']),
  ('thank_you', 'Thank you very much', 'மிக்க நன்றி', ['ரொம்ப நன்றி']),
  ('good_morning', 'Good morning', 'காலை வணக்கம்', <String>[]),
];

/// Intelligibility items carry level 1 but are served at every level
/// (`OralRehabPack.intelligibilitySet` ignores the level).
List<OralItem> _intelItems() => [
      for (final (i, (slug, ta, en, g, s, spoken)) in _intelTaWords.indexed)
        OralItem(
          id: 'oral_intel_ta_${(i + 1).toString().padLeft(2, '0')}_$slug',
          kind: _K.intelligibility,
          level: 1,
          lang: OralLang.ta,
          ta: ta,
          en: en,
          taSpoken: spoken,
          group: g,
          sounds: s,
        ),
      for (final (i, (en, aid, g, s)) in _intelEnWords.indexed)
        OralItem(
          id: 'oral_intel_en_${(i + 1).toString().padLeft(2, '0')}_$en',
          kind: _K.intelligibility,
          level: 1,
          lang: OralLang.en,
          en: en,
          ta: aid,
          group: g,
          sounds: s,
        ),
      for (final (i, (slug, en, ta, spoken)) in _intelPhrases.indexed)
        OralItem(
          id: 'oral_intel_phrase_${(i + 11).toString().padLeft(2, '0')}_$slug',
          kind: _K.intelligibility,
          level: 1,
          en: en,
          ta: ta,
          taSpoken: spoken,
        ),
    ];

/// Every item of the pack, in a stable order.
final List<OralItem> oralItems = List.unmodifiable([
  ..._taSyllables(),
  ..._enSyllables(),
  ..._words(),
  ..._pairs(),
  ..._phraseItems(),
  ..._clearItems(),
  ..._intelItems(),
]);
