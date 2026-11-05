import 'package:aphora/logic/language_service.dart';

// The intake questionnaire as DATA. One generic page (`IntakePage`) renders
// any question here; the rules that turn answers into a pack, start level,
// focus areas and red flags live in `lib/logic/intake_engine.dart`.
//
// Screening, not diagnosis. Questions are written for this app, "informed
// by" free screening scales — never copied from them:
//   child:  CDC "Learn the Signs. Act Early." milestones, LEST (0–3),
//           Intelligibility in Context Scale (ICS)
//   stroke: Communicative Effectiveness Index (CETI) situations, FAST
//   mouth:  speech domain of the UW Quality of Life questionnaire (UW-QOL)
// The clinician review sheet is the wiki note `vernacura-intake-questions`.
//
// Change a question, an option value or a rule → bump [intakeVersion], so
// stored answers can always be read against the wording that produced them.

/// Stored with every completed intake.
const intakeVersion = 'vernacura-intake-2026-11-06';

/// Answers so far: question id → option value. Two hidden inputs may also be
/// present: `age` (years, from sign-up/profile) and `name`.
typedef Answers = Map<String, String>;

/// A bilingual string; [text] follows the app language.
class L {
  const L(this.en, this.ta);
  final String en;
  final String ta;
  String get text => tr(en, ta);
}

class IntakeOption {
  const IntakeOption(this.value, this.label, {this.emoji});

  /// Stable value stored in Firestore and read by the rules.
  final String value;
  final L label;
  final String? emoji;
}

class IntakeQuestion {
  const IntakeQuestion({
    required this.id,
    required this.prompt,
    required this.options,
    required this.summaryLabel,
    this.helper,
    this.showIf,
  });

  final String id;
  final L prompt;
  final L? helper;
  final List<IntakeOption> options;

  /// Short English label for the therapist summary ("First words").
  final String summaryLabel;

  /// Branching on earlier answers. Null = always asked.
  final bool Function(Answers)? showIf;

  bool visible(Answers a) => showIf?.call(a) ?? true;

  IntakeOption? option(String? value) {
    for (final o in options) {
      if (o.value == value) return o;
    }
    return null;
  }
}

/// Answer value for "Not sure" everywhere.
const unsure = 'unsure';
const _unsure = IntakeOption(unsure, L('Not sure', 'தெரியவில்லை'), emoji: '🤔');
const _no = IntakeOption('no', L('No', 'இல்லை'), emoji: '👎');
const _yes = IntakeOption('yes', L('Yes', 'ஆம்'), emoji: '👍');

// ── Branches ──────────────────────────────────────────────────────────────

bool isChild(Answers a) => a['who'] == 'child';
bool isAdult(Answers a) => a['who'] == 'adult' || a['who'] == 'self';
bool isStroke(Answers a) => isAdult(a) && a['event'] == 'stroke';
bool isMouth(Answers a) => isAdult(a) && a['event'] == 'surgery';
bool isOtherAdult(Answers a) => isAdult(a) && a['event'] == 'other';

/// The child's age in years: the number from sign-up when known, else the
/// lower bound of the band chosen in `c_age`. Null when neither exists.
int? childAge(Answers a) {
  final n = int.tryParse(a['age'] ?? '');
  if (n != null && n > 0) return n;
  return switch (a['c_age']) {
    '2' => 2,
    '3to4' => 3,
    '5to7' => 5,
    '8plus' => 8,
    _ => null,
  };
}

bool _childNeedsAge(Answers a) => isChild(a) && childAge(a) == null;

/// Two-word phrases are asked up to age 5; older children are assumed past
/// that milestone (the intelligibility questions still catch problems).
bool _childYoung(Answers a) => isChild(a) && (childAge(a) ?? 0) <= 5;
bool _strokeRecent(Answers a) => isStroke(a) && a['a_when'] == 'lt2w';
bool _strokeOrMouth(Answers a) => isStroke(a) || isMouth(a);

// ── Shared option sets ────────────────────────────────────────────────────

/// ICS-style "how much is understood" (five steps, most → least).
const _howMuch = [
  IntakeOption('always', L('All of it', 'முழுவதும் புரிகிறது'), emoji: '😀'),
  IntakeOption('usually', L('Most of it', 'பெரும்பாலும் புரிகிறது'), emoji: '🙂'),
  IntakeOption('sometimes', L('About half', 'பாதி அளவு புரிகிறது'), emoji: '😐'),
  IntakeOption('rarely', L('A little', 'கொஞ்சம்தான் புரிகிறது'), emoji: '😕'),
  IntakeOption('never', L('Hardly any', 'கிட்டத்தட்ட புரிவதில்லை'), emoji: '😟'),
];

const _sinceStroke = [
  IntakeOption('lt2w', L('Less than 2 weeks', '2 வாரத்துக்குள்')),
  IntakeOption('2wto3m', L('2 weeks to 3 months', '2 வாரம் முதல் 3 மாதம்')),
  IntakeOption('3to12m', L('3 to 12 months', '3 முதல் 12 மாதம்')),
  IntakeOption('gt1y', L('More than a year', 'ஒரு வருடத்துக்கு மேல்')),
  _unsure,
];

const _sinceSurgery = [
  IntakeOption('lt6w', L('Less than 6 weeks', '6 வாரத்துக்குள்')),
  IntakeOption('6wto3m', L('6 weeks to 3 months', '6 வாரம் முதல் 3 மாதம்')),
  IntakeOption('3to12m', L('3 to 12 months', '3 முதல் 12 மாதம்')),
  IntakeOption('gt1y', L('More than a year', 'ஒரு வருடத்துக்கு மேல்')),
];

// ── The questions, in the order they are asked ────────────────────────────

abstract final class IntakeQuestionnaire {
  static const questions = <IntakeQuestion>[
    IntakeQuestion(
      id: 'who',
      summaryLabel: 'Filled in for',
      prompt: L('Who is this for?', 'இது யாருக்காக?'),
      options: [
        IntakeOption('child', L('My child', 'என் குழந்தை'), emoji: '🧒'),
        IntakeOption('adult', L('An adult in my family', 'என் குடும்பத்தில் ஒரு பெரியவர்'), emoji: '🧓'),
        IntakeOption('self', L('Myself', 'எனக்கே'), emoji: '🙋'),
      ],
    ),
    IntakeQuestion(
      id: 'event',
      showIf: isAdult,
      summaryLabel: 'Cause of the speech difficulty',
      prompt: L('What led to the speech difficulty?', 'பேச்சுச் சிரமம் எதனால் வந்தது?'),
      helper: L('Choose the closest one.', 'நெருக்கமான ஒன்றைத் தேர்ந்தெடுங்கள்.'),
      options: [
        IntakeOption('stroke', L('A stroke', 'பக்கவாதம் (ஸ்ட்ரோக்)'), emoji: '🧠'),
        IntakeOption('surgery', L('Surgery for mouth or tongue cancer', 'வாய் அல்லது நாக்குப் புற்றுநோய்க்கான அறுவை சிகிச்சை'), emoji: '🏥'),
        IntakeOption('other', L('Something else, or not sure', 'வேறு காரணம் / தெரியவில்லை'), emoji: '❓'),
      ],
    ),

    // ── Child ──────────────────────────────────────────────────────────
    IntakeQuestion(
      id: 'c_age',
      showIf: _childNeedsAge,
      summaryLabel: 'Age band',
      prompt: L('How old is your child?', 'உங்கள் குழந்தைக்கு எத்தனை வயது?'),
      options: [
        IntakeOption('2', L('2 years', '2 வயது')),
        IntakeOption('3to4', L('3 to 4 years', '3 முதல் 4 வயது')),
        IntakeOption('5to7', L('5 to 7 years', '5 முதல் 7 வயது')),
        IntakeOption('8plus', L('8 years or more', '8 வயது அல்லது அதற்கு மேல்')),
      ],
    ),
    IntakeQuestion(
      id: 'c_first_words',
      showIf: isChild,
      summaryLabel: 'First words',
      prompt: L("When did your child say their first words, like 'amma' or 'appa'?",
          "உங்கள் குழந்தை 'அம்மா', 'அப்பா' போன்ற முதல் சொற்களை எப்போது சொன்னது?"),
      helper: L('Words said on purpose, not just babbling.',
          'வெறும் மழலை ஒலி அல்ல — அர்த்தத்தோடு சொன்ன சொற்கள்.'),
      options: [
        IntakeOption('by18m', L('Before 1½ years', '1½ வயதுக்கு முன்')),
        IntakeOption('18to24m', L('Between 1½ and 2 years', '1½ முதல் 2 வயதுக்குள்')),
        IntakeOption('after2y', L('After 2 years', '2 வயதுக்குப் பிறகு')),
        IntakeOption('notyet', L('Not yet', 'இன்னும் இல்லை')),
        _unsure,
      ],
    ),
    IntakeQuestion(
      id: 'c_phrases',
      showIf: _childYoung,
      summaryLabel: 'Joins two words',
      prompt: L("Does your child put two words together, like 'amma vaa' or 'more milk'?",
          "'அம்மா வா', 'இன்னும் பால்' என்பது போல இரண்டு சொற்களைச் சேர்த்துப் பேசுகிறதா?"),
      options: [
        IntakeOption('often', L('Yes, often', 'ஆம், அடிக்கடி'), emoji: '👍'),
        IntakeOption('sometimes', L('Sometimes', 'சில நேரம்'), emoji: '🤏'),
        IntakeOption('notyet', L('Not yet', 'இன்னும் இல்லை'), emoji: '⏳'),
        _unsure,
      ],
    ),
    IntakeQuestion(
      id: 'c_understand',
      showIf: isChild,
      summaryLabel: 'Follows simple instructions (no pointing)',
      prompt: L("Without you pointing, does your child follow a simple instruction like 'bring your shoes'?",
          "நீங்கள் கை காட்டாமல், 'உன் செருப்பை எடுத்து வா' போன்ற எளிய சொல்லைப் புரிந்து செய்கிறதா?"),
      options: [
        _yes,
        IntakeOption('sometimes', L('Sometimes', 'சில நேரம்'), emoji: '🤏'),
        _no,
        _unsure,
      ],
    ),
    IntakeQuestion(
      id: 'c_family',
      showIf: isChild,
      summaryLabel: 'Understood by family',
      prompt: L("How much of your child's speech do you and your family understand?",
          'குழந்தை பேசுவது உங்களுக்கும் குடும்பத்தினருக்கும் எவ்வளவு புரிகிறது?'),
      options: _howMuch,
    ),
    IntakeQuestion(
      id: 'c_strangers',
      showIf: isChild,
      summaryLabel: 'Understood by unfamiliar people',
      prompt: L("How much do people who don't know your child understand — like a shopkeeper or a new teacher?",
          'குழந்தையைத் தெரியாதவர்கள் — கடைக்காரர், புதிய ஆசிரியர் போன்றோர் — அதன் பேச்சை எவ்வளவு புரிந்துகொள்கிறார்கள்?'),
      options: [..._howMuch, _unsure],
    ),
    IntakeQuestion(
      id: 'c_sounds',
      showIf: isChild,
      summaryLabel: 'Hard speech sounds',
      prompt: L('Are some speech sounds hard for your child to say?',
          'சில ஒலிகளைச் சொல்வது குழந்தைக்குக் கடினமாக இருக்கிறதா?'),
      helper: L("For example ழ, ர, ச or 's'.", 'உதாரணமாக ழ, ர, ச போன்றவை.'),
      options: [
        IntakeOption('many', L('Yes, many sounds', 'ஆம், பல ஒலிகள்')),
        IntakeOption('few', L('A few sounds', 'சில ஒலிகள் மட்டும்')),
        IntakeOption('none', L('No, sounds are clear', 'இல்லை, ஒலிகள் தெளிவாக உள்ளன')),
        _unsure,
      ],
    ),
    IntakeQuestion(
      id: 'c_hearing',
      showIf: isChild,
      summaryLabel: 'Turns to name / sounds',
      prompt: L('Does your child turn to look when you call their name, or when there is a sound behind them?',
          'பெயர் சொல்லிக் கூப்பிடும்போதோ, பின்னால் சத்தம் கேட்கும்போதோ குழந்தை திரும்பிப் பார்க்கிறதா?'),
      options: [
        IntakeOption('yes', L('Yes, usually', 'ஆம், பொதுவாக'), emoji: '👂'),
        IntakeOption('sometimes', L('Only sometimes', 'சில நேரம் மட்டும்'), emoji: '🤏'),
        IntakeOption('no', L('Rarely or never', 'அரிதாக / இல்லவே இல்லை'), emoji: '🔇'),
      ],
    ),
    IntakeQuestion(
      id: 'c_lost',
      showIf: isChild,
      summaryLabel: 'Lost words used before',
      prompt: L('Has your child stopped saying words they used to say?',
          'முன்பு சொன்ன சொற்களைக் குழந்தை இப்போது சொல்வதை நிறுத்திவிட்டதா?'),
      options: [_no, _yes, _unsure],
    ),
    IntakeQuestion(
      id: 'c_social',
      showIf: isChild,
      summaryLabel: 'Looks and points to share',
      prompt: L('Does your child look at you and point to show you something they want or like?',
          'தனக்கு வேண்டியதையோ பிடித்ததையோ காட்ட, குழந்தை உங்களைப் பார்த்து விரலால் சுட்டிக் காட்டுகிறதா?'),
      options: [
        IntakeOption('yes', L('Yes, often', 'ஆம், அடிக்கடி'), emoji: '👉'),
        IntakeOption('sometimes', L('Sometimes', 'சில நேரம்'), emoji: '🤏'),
        IntakeOption('rarely', L('Rarely', 'அரிதாக'), emoji: '😶'),
      ],
    ),
    IntakeQuestion(
      id: 'c_feeding',
      showIf: isChild,
      summaryLabel: 'Chewing / swallowing / drooling difficulty',
      prompt: L('Does your child have trouble chewing or swallowing, or drool a lot for their age?',
          'மெல்லுவதில் அல்லது விழுங்குவதில் சிரமம் உள்ளதா? வயதுக்கு மீறி அதிகமாக எச்சில் வடிகிறதா?'),
      options: [_no, _yes, _unsure],
    ),

    // ── Adult: after a stroke ──────────────────────────────────────────
    IntakeQuestion(
      id: 'a_when',
      showIf: isStroke,
      summaryLabel: 'Time since stroke',
      prompt: L('How long ago was the stroke?', 'பக்கவாதம் வந்து எவ்வளவு காலம் ஆகிறது?'),
      options: _sinceStroke,
    ),
    IntakeQuestion(
      id: 'a_followup',
      showIf: _strokeRecent,
      summaryLabel: 'Doctor follow-up since the stroke',
      prompt: L('Since the stroke, has a doctor checked and given a follow-up plan?',
          'பக்கவாதத்துக்குப் பிறகு மருத்துவர் பரிசோதித்து, தொடர் சிகிச்சைத் திட்டம் கொடுத்தாரா?'),
      options: [_yes, _no, _unsure],
    ),
    IntakeQuestion(
      id: 'a_new',
      showIf: isStroke,
      summaryLabel: 'New or sudden symptoms in the last few days',
      prompt: L('In the last few days, has anything new or sudden happened — weakness, a drooping face, or speech suddenly worse?',
          'கடந்த சில நாட்களில் புதிதாக அல்லது திடீரென ஏதாவது நடந்ததா — உடல் பலவீனம், முகம் ஒருபக்கம் தொங்குவது, பேச்சு திடீரென மோசமாவது?'),
      options: [_no, _yes],
    ),
    IntakeQuestion(
      id: 'a_kind',
      showIf: isStroke,
      summaryLabel: 'Main kind of speech difficulty',
      prompt: L('Since the stroke, what is the main difficulty with speech?',
          'பக்கவாதத்துக்குப் பிறகு பேச்சில் முக்கியச் சிரமம் என்ன?'),
      helper: L('Choose the closest one.', 'நெருக்கமான ஒன்றைத் தேர்ந்தெடுங்கள்.'),
      options: [
        IntakeOption('words', L('Finding the right words, or understanding what others say',
            'சரியான சொல் வராதது, அல்லது மற்றவர்கள் சொல்வது புரியாதது'), emoji: '💬'),
        IntakeOption('slurred', L('The words are right, but speech sounds slurred or unclear',
            'சொற்கள் சரிதான், ஆனால் பேச்சு குழறுகிறது / தெளிவில்லை'), emoji: '🗣️'),
        IntakeOption('both', L('Both', 'இரண்டும்'), emoji: '➕'),
        _unsure,
      ],
    ),
    IntakeQuestion(
      id: 'a_understand',
      showIf: isStroke,
      summaryLabel: 'Understands everyday talk',
      prompt: L("How well is everyday talk understood — like 'Do you want tea?'",
          "'டீ வேண்டுமா?' போன்ற அன்றாடப் பேச்சு எவ்வளவு புரிகிறது?"),
      options: [
        IntakeOption('well', L('Understood well', 'நன்றாகப் புரிகிறது'), emoji: '😀'),
        IntakeOption('short', L('Only short, simple sentences', 'சிறிய, எளிய வாக்கியங்கள் மட்டும்'), emoji: '🙂'),
        IntakeOption('words', L('Only single words, with gestures', 'சைகையுடன் தனிச் சொற்கள் மட்டும்'), emoji: '😐'),
        IntakeOption('little', L('Very little', 'மிகக் குறைவாக'), emoji: '😟'),
        _unsure,
      ],
    ),
    IntakeQuestion(
      id: 'a_naming',
      showIf: isStroke,
      summaryLabel: 'Naming everyday objects',
      prompt: L("Naming everyday things, like 'cup' or 'phone', is…",
          "'கப்', 'போன்' போன்ற அன்றாடப் பொருட்களின் பெயரைச் சொல்வது…"),
      options: [
        IntakeOption('easy', L('Easy', 'எளிது')),
        IntakeOption('effort', L('Possible, with effort', 'முயற்சி செய்தால் முடிகிறது')),
        IntakeOption('help', L('Only with help, like the first sound', 'முதல் ஒலி போன்ற உதவி கொடுத்தால் மட்டும்')),
        IntakeOption('hard', L('Very hard', 'மிகக் கடினம்')),
      ],
    ),
    IntakeQuestion(
      id: 'a_repeat',
      showIf: isStroke,
      summaryLabel: 'Repeats a short sentence',
      prompt: L("Repeating a short sentence right after someone, like 'I want water', is…",
          "'எனக்குத் தண்ணீர் வேண்டும்' போன்ற சிறு வாக்கியத்தை உடனே திருப்பிச் சொல்வது…"),
      options: [
        IntakeOption('easy', L('Easy', 'எளிது')),
        IntakeOption('part', L('Only some words come out', 'சில சொற்கள் மட்டும் வருகின்றன')),
        IntakeOption('hard', L('Very hard', 'மிகக் கடினம்')),
        _unsure,
      ],
    ),
    IntakeQuestion(
      id: 'a_needs',
      showIf: isStroke,
      summaryLabel: 'Gets needs across',
      prompt: L('Needs like food, pain or the toilet are made known…',
          'சாப்பாடு, வலி, கழிவறை போன்ற தேவைகளைத் தெரிவிப்பது…'),
      options: [
        IntakeOption('words', L('In words', 'சொற்களால்'), emoji: '🗣️'),
        IntakeOption('gestures', L('With gestures or pointing', 'சைகை அல்லது சுட்டிக்காட்டுதலால்'), emoji: '👉'),
        IntakeOption('hard', L('Hard, even with gestures', 'சைகையாலும் கடினம்'), emoji: '😟'),
      ],
    ),
    IntakeQuestion(
      id: 'a_read',
      showIf: isStroke,
      summaryLabel: 'Reading / writing a short message',
      prompt: L('Reading or writing a short message, like a name, is…',
          'பெயர் போன்ற சிறு செய்தியைப் படிப்பது அல்லது எழுதுவது…'),
      options: [
        IntakeOption('ok', L('Still possible', 'இப்போதும் முடிகிறது')),
        IntakeOption('some', L('Harder than before', 'முன்பைவிடக் கடினம்')),
        IntakeOption('no', L('Not possible now', 'இப்போது முடிவதில்லை')),
        IntakeOption('na', L("Didn't read or write before", 'முன்பும் படிக்க / எழுதத் தெரியாது')),
      ],
    ),

    // ── Adult: after mouth / tongue cancer surgery ─────────────────────
    IntakeQuestion(
      id: 'o_surgery',
      showIf: isMouth,
      summaryLabel: 'Surgery',
      prompt: L('What surgery was done?', 'என்ன அறுவை சிகிச்சை செய்யப்பட்டது?'),
      helper: L('If more than one, choose the biggest.', 'ஒன்றுக்கு மேல் இருந்தால், பெரியதைத் தேர்ந்தெடுங்கள்.'),
      options: [
        IntakeOption('part', L('Part of the tongue removed', 'நாக்கின் ஒரு பகுதி அகற்றப்பட்டது')),
        IntakeOption('most', L('Most or all of the tongue', 'நாக்கின் பெரும்பகுதி அல்லது முழுவதும்')),
        IntakeOption('jaw', L('Part of the jaw bone', 'தாடை எலும்பின் ஒரு பகுதி')),
        _unsure,
      ],
    ),
    IntakeQuestion(
      id: 'o_weeks',
      showIf: isMouth,
      summaryLabel: 'Time since surgery',
      prompt: L('How long ago was the surgery?', 'அறுவை சிகிச்சை நடந்து எவ்வளவு காலம் ஆகிறது?'),
      options: _sinceSurgery,
    ),
    IntakeQuestion(
      id: 'o_radio',
      showIf: isMouth,
      summaryLabel: 'Radiotherapy',
      prompt: L('Radiotherapy (radiation) to the mouth or neck?',
          'வாய் அல்லது கழுத்துக்குக் கதிர்வீச்சு சிகிச்சை (ரேடியோதெரபி)?'),
      options: [
        IntakeOption('done', L('Yes, finished', 'ஆம், முடிந்துவிட்டது')),
        IntakeOption('ongoing', L('Yes, still going on', 'ஆம், இன்னும் நடக்கிறது')),
        _no,
        _unsure,
      ],
    ),
    IntakeQuestion(
      id: 'o_family',
      showIf: isMouth,
      summaryLabel: 'Understood by family',
      prompt: L('How much of the speech does the family understand now?',
          'இப்போது பேச்சு குடும்பத்தினருக்கு எவ்வளவு புரிகிறது?'),
      options: _howMuch,
    ),
    IntakeQuestion(
      id: 'o_phone',
      showIf: isMouth,
      summaryLabel: 'Understood outside the family / on the phone',
      prompt: L('Can people outside the family — or on the phone — understand the speech?',
          'குடும்பத்துக்கு வெளியே உள்ளவர்களுக்கோ, தொலைபேசியிலோ பேச்சு புரிகிறதா?'),
      options: [
        _yes,
        IntakeOption('effort', L('With difficulty', 'சிரமத்துடன்')),
        _no,
        _unsure,
      ],
    ),
    IntakeQuestion(
      id: 'o_daily',
      showIf: isMouth,
      summaryLabel: 'Effect on daily life',
      prompt: L('How much does speech get in the way of daily life — family, work, phone calls?',
          'குடும்பம், வேலை, தொலைபேசி அழைப்புகள் — அன்றாட வாழ்க்கையைப் பேச்சுச் சிரமம் எவ்வளவு பாதிக்கிறது?'),
      options: [
        IntakeOption('none', L('Not at all', 'பாதிப்பில்லை')),
        IntakeOption('little', L('A little', 'கொஞ்சம்')),
        IntakeOption('lot', L('A lot', 'அதிகம்')),
        IntakeOption('avoid', L('Mostly stopped talking to others', 'மற்றவர்களிடம் பேசுவதே குறைந்துவிட்டது')),
      ],
    ),
    IntakeQuestion(
      id: 'o_pain',
      showIf: isMouth,
      summaryLabel: 'Pain, bleeding or unhealed wound in the mouth',
      prompt: L('Is there pain, bleeding, or a wound in the mouth that has not healed?',
          'வாயில் வலி, இரத்தக்கசிவு, அல்லது ஆறாத புண் உள்ளதா?'),
      options: [_no, _yes],
    ),

    // Shared by the stroke and mouth branches, asked last.
    IntakeQuestion(
      id: 'swallow',
      showIf: _strokeOrMouth,
      summaryLabel: 'Coughing / choking when eating or drinking',
      prompt: L('Is there coughing or choking while eating or drinking?',
          'சாப்பிடும்போது அல்லது குடிக்கும்போது இருமல் அல்லது புரையேறுதல் உண்டா?'),
      options: [
        _no,
        IntakeOption('sometimes', L('Sometimes', 'சில நேரம்')),
        IntakeOption('often', L('Often', 'அடிக்கடி')),
      ],
    ),

    // ── Adult: other / not sure ────────────────────────────────────────
    IntakeQuestion(
      id: 'g_problem',
      showIf: isOtherAdult,
      summaryLabel: 'Main difficulty',
      prompt: L('What is the main difficulty?', 'முக்கியச் சிரமம் என்ன?'),
      options: [
        IntakeOption('words', L('Finding or saying words', 'சொற்களைத் தேடுவது / சொல்வது')),
        IntakeOption('clarity', L('Speech is unclear or slurred', 'பேச்சு தெளிவில்லை / குழறுகிறது')),
        IntakeOption('fluency', L('Stammering', 'திக்கித் திக்கிப் பேசுவது')),
        IntakeOption('voice', L('Voice is hoarse or weak', 'குரல் கரகரப்பு / பலவீனம்')),
        IntakeOption('other', L('Something else', 'வேறு ஏதாவது')),
      ],
    ),
    IntakeQuestion(
      id: 'g_sudden',
      showIf: isOtherAdult,
      summaryLabel: 'Started suddenly in the last few days',
      prompt: L('Did this start suddenly, in the last few days?',
          'இது கடந்த சில நாட்களில் திடீரென்று தொடங்கியதா?'),
      options: [
        IntakeOption('yes', L('Yes, suddenly', 'ஆம், திடீரென்று')),
        IntakeOption('no', L('No, slowly or long ago', 'இல்லை, மெதுவாக / நீண்ட காலமாக')),
        _unsure,
      ],
    ),
  ];

  static IntakeQuestion? byId(String id) {
    for (final q in questions) {
      if (q.id == id) return q;
    }
    return null;
  }
}

// ── What the result screen shows ──────────────────────────────────────────

enum RedFlagLevel {
  /// Act now (call 108 / go to hospital).
  emergency,

  /// See a doctor before starting practice.
  doctorFirst,

  /// Practice can start; also get this checked.
  referral,
}

class RedFlag {
  const RedFlag(this.id, this.level, this.message);
  final String id;
  final RedFlagLevel level;
  final L message;

  static const all = <RedFlag>[
    RedFlag('emergency_now', RedFlagLevel.emergency, L(
      'New or sudden symptoms can mean a new stroke. Call 108 or go to a hospital now — before any practice.',
      'புதிய அல்லது திடீர் அறிகுறிகள் மீண்டும் பக்கவாதத்தின் அறிகுறியாக இருக்கலாம். பயிற்சிக்கு முன், உடனே 108-ஐ அழையுங்கள் அல்லது மருத்துவமனைக்குச் செல்லுங்கள்.',
    )),
    RedFlag('stroke_followup', RedFlagLevel.doctorFirst, L(
      'The stroke was recent and no doctor follow-up is in place. Please see a doctor first.',
      'பக்கவாதம் சமீபத்தில் வந்துள்ளது; மருத்துவரின் தொடர் கவனிப்பு இல்லை. முதலில் மருத்துவரைப் பாருங்கள்.',
    )),
    RedFlag('swallow_check', RedFlagLevel.doctorFirst, L(
      'Coughing or choking while eating or drinking can be risky. Please tell a doctor first — a swallowing check may be needed.',
      'சாப்பிடும்போது இருமல், புரையேறுதல் ஆபத்தாகலாம். முதலில் மருத்துவரிடம் சொல்லுங்கள் — விழுங்கும் திறன் பரிசோதனை தேவைப்படலாம்.',
    )),
    RedFlag('oral_pain', RedFlagLevel.doctorFirst, L(
      'Pain, bleeding or a wound that has not healed: please see your doctor or surgeon before starting practice.',
      'வலி, இரத்தக்கசிவு அல்லது ஆறாத புண்: பயிற்சி தொடங்கும் முன் உங்கள் மருத்துவர் அல்லது அறுவை மருத்துவரைப் பாருங்கள்.',
    )),
    RedFlag('ask_surgeon', RedFlagLevel.doctorFirst, L(
      'The surgery was less than 6 weeks ago. Please ask the surgeon when it is safe to start speech exercises.',
      'அறுவை சிகிச்சை நடந்து 6 வாரங்கள் ஆகவில்லை. பேச்சுப் பயிற்சியை எப்போது தொடங்கலாம் என்று அறுவை மருத்துவரிடம் கேளுங்கள்.',
    )),
    RedFlag('radiotherapy_team', RedFlagLevel.referral, L(
      'Radiotherapy is still going on and the mouth may be sore. Check with the cancer care team before starting.',
      'கதிர்வீச்சு சிகிச்சை இன்னும் நடக்கிறது; வாய் புண்ணாக இருக்கலாம். தொடங்கும் முன் புற்றுநோய் சிகிச்சைக் குழுவிடம் கேளுங்கள்.',
    )),
    RedFlag('dysarthria_assess', RedFlagLevel.referral, L(
      'Slurred or unclear speech with the right words is often weakness of the speech muscles (dysarthria), which needs its own therapy. Please ask a speech therapist to assess it; meanwhile practise speaking slowly and clearly.',
      'சொற்கள் சரியாக இருந்தும் பேச்சு குழறுவது பெரும்பாலும் பேச்சுத் தசைகளின் பலவீனம் (டிசார்த்ரியா); அதற்குத் தனிச் சிகிச்சை தேவை. பேச்சு சிகிச்சையாளரிடம் மதிப்பீடு செய்யச் சொல்லுங்கள்; அதுவரை மெதுவாகவும் தெளிவாகவும் பேசிப் பயிற்சி செய்யுங்கள்.',
    )),
    RedFlag('hearing_test', RedFlagLevel.referral, L(
      'Your child does not always respond to sounds. Please get a hearing test — hearing affects speech.',
      'குழந்தை ஒலிகளுக்கு எப்போதும் திரும்புவதில்லை. செவித்திறன் பரிசோதனை செய்யுங்கள் — கேட்கும் திறன் பேச்சைப் பாதிக்கும்.',
    )),
    RedFlag('lost_skills', RedFlagLevel.referral, L(
      'Losing words a child used to say should always be checked. Please see a paediatrician soon.',
      'முன்பு சொன்ன சொற்களைக் குழந்தை இழந்தால் கட்டாயம் பரிசோதிக்க வேண்டும். விரைவில் குழந்தைகள் மருத்துவரைப் பாருங்கள்.',
    )),
    RedFlag('developmental_check', RedFlagLevel.referral, L(
      'Every child is different. Pointing and looking at you are less frequent, so a development check with a paediatrician can help.',
      'ஒவ்வொரு குழந்தையும் வேறுபட்டது. சுட்டிக் காட்டுவதும் உங்களைப் பார்ப்பதும் குறைவாக இருப்பதால், குழந்தைகள் மருத்துவரிடம் வளர்ச்சிப் பரிசோதனை செய்வது உதவும்.',
    )),
    RedFlag('feeding_check', RedFlagLevel.referral, L(
      'Trouble with chewing, swallowing or drooling: please mention it to a doctor or speech therapist.',
      'மெல்லுதல், விழுங்குதல், எச்சில் வடிதல் சிரமங்களை மருத்துவர் அல்லது பேச்சு சிகிச்சையாளரிடம் சொல்லுங்கள்.',
    )),
    RedFlag('see_slp', RedFlagLevel.referral, L(
      'Speech is developing later than expected for this age. Home practice helps, but please also see a speech therapist in person.',
      'இந்த வயதுக்கு எதிர்பார்ப்பதைவிடப் பேச்சு மெதுவாக வளர்கிறது. வீட்டுப் பயிற்சி உதவும்; ஆனாலும் பேச்சு சிகிச்சையாளரை நேரில் பாருங்கள்.',
    )),
    RedFlag('see_professional', RedFlagLevel.referral, L(
      "This app can't tell what is causing the speech difficulty. Please see a doctor or speech therapist first; meanwhile you can use the general practice set.",
      'பேச்சுச் சிரமத்துக்கான காரணத்தை இந்தச் செயலியால் சொல்ல முடியாது. முதலில் மருத்துவர் அல்லது பேச்சு சிகிச்சையாளரைப் பாருங்கள்; அதுவரை பொதுப் பயிற்சிகளைப் பயன்படுத்தலாம்.',
    )),
    RedFlag('ent_check', RedFlagLevel.referral, L(
      'A hoarse or weak voice that lasts more than 3 weeks should be checked by an ENT doctor.',
      '3 வாரங்களுக்கு மேல் நீடிக்கும் குரல் கரகரப்பு அல்லது பலவீனத்தைக் காது-மூக்கு-தொண்டை (ENT) மருத்துவர் பரிசோதிக்க வேண்டும்.',
    )),
  ];

  static RedFlag? byId(String id) {
    for (final f in all) {
      if (f.id == id) return f;
    }
    return null;
  }
}

class FocusArea {
  const FocusArea(this.id, this.label, this.practice);
  final String id;
  final L label;

  /// The existing exercise that trains it: a `PracticeKind` name, or
  /// 'picture' for Picture match.
  final String practice;

  static const all = <FocusArea>[
    FocusArea('sounds', L('First sounds', 'முதல் ஒலிகள்'), 'letters'),
    FocusArea('first_words', L('Everyday words', 'அன்றாடச் சொற்கள்'), 'words'),
    FocusArea('phrases', L('Two-word phrases', 'இரு சொல் வாக்கியங்கள்'), 'sentences'),
    FocusArea('understanding', L('Understanding words', 'சொற்களைப் புரிந்துகொள்ளுதல்'), 'picture'),
    FocusArea('clear_sounds', L('Clearer speech sounds', 'தெளிவான ஒலிகள்'), 'letters'),
    FocusArea('naming', L('Naming things', 'பொருட்களின் பெயர் சொல்லுதல்'), 'naming'),
    FocusArea('repetition', L('Repeating after a voice', 'கேட்டுத் திருப்பிச் சொல்லுதல்'), 'phonetic'),
    FocusArea('needs', L('Asking for everyday needs', 'அன்றாடத் தேவைகளைக் கேட்பது'), 'sentences'),
    FocusArea('reading', L('Reading short words', 'சிறு சொற்களைப் படித்தல்'), 'words'),
    FocusArea('clarity', L('Making words clearer', 'சொற்களைத் தெளிவாகச் சொல்லுதல்'), 'words'),
    FocusArea('phone', L('Being understood by others and on the phone', 'மற்றவர்களுக்கும் தொலைபேசியிலும் புரியும்படி பேசுதல்'), 'sentences'),
    FocusArea('conversation', L('Everyday conversation', 'அன்றாட உரையாடல்'), 'sentences'),
    FocusArea('clear_speech', L('Slow, clear speech', 'மெதுவான, தெளிவான பேச்சு'), 'clearSpeech'),
    FocusArea('general', L('General speech practice', 'பொதுப் பேச்சுப் பயிற்சி'), 'words'),
  ];

  static FocusArea? byId(String id) {
    for (final f in all) {
      if (f.id == id) return f;
    }
    return null;
  }
}

/// Start levels 1 (easiest) → 3. Level n maps to the existing
/// `recommendedFocus` value [legacyFocus][n-1].
abstract final class StartLevel {
  static const legacyFocus = ['letters', 'words', 'sentences'];
  static const labels = [
    L('Level 1 · sounds and single words', 'நிலை 1 · ஒலிகளும் தனிச் சொற்களும்'),
    L('Level 2 · words', 'நிலை 2 · சொற்கள்'),
    L('Level 3 · short sentences', 'நிலை 3 · சிறு வாக்கியங்கள்'),
  ];
  static L label(int level) => labels[(level - 1).clamp(0, 2)];

  /// `recommendedFocus` → level, or null when unset/unknown.
  static int? fromLegacyFocus(String? focus) {
    final i = legacyFocus.indexOf(focus ?? '');
    return i < 0 ? null : i + 1;
  }
}
