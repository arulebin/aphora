// End-to-end test of the whole app on a real device.
//
// Runs against the local Firebase emulators (never live data):
//   firebase emulators:start --only auth,firestore --project aphora-b2392
//   adb reverse tcp:9099 tcp:9099 && adb reverse tcp:8080 tcp:8080
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/app_test.dart \
//     --dart-define=USE_FIREBASE_EMULATOR=true
//
// The microphone is replaced by [SpeechService.debugListenOverride]: each
// time the child "speaks", the app hears whatever [heard] holds.
import 'package:aphora/data/learning/kids_words.dart';
import 'package:aphora/logic/speech_service.dart';
import 'package:aphora/main.dart' as app;
import 'package:aphora/ui/design/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

late IntegrationTestWidgetsFlutterBinding binding;

/// What the fake microphone hears on the next listen.
String heard = '';

const patientPhone = '9000000201';
const patientPassword = 'kid123';
const therapistPhone = '9000000301';
const therapistPassword = 'ther123';

/// Every non-picture prompt the content can show (sounds, phrases,
/// recordings, drill fallbacks), so the test can read the current target.
final _knownTargets = <String>{
  for (final s in ['M', 'P', 'B', 'D', 'T', 'N', 'K', 'G', 'F', 'S', 'L', 'R']) ...[
    s,
    '$s $s $s',
    s.toLowerCase(),
    '${s.toLowerCase()} ${s.toLowerCase()} ${s.toLowerCase()}',
  ],
  'Mummy, come', 'Daddy, come', 'Drink milk', 'Throw the ball', 'I want water',
  'I am hungry', 'The cat is sleeping', 'The dog is running', 'I want to play',
  'Big elephant', 'Red ball',
  'வணக்கம்', 'சாப்பிட்டீர்களா', 'எப்படி இருக்கிறீர்கள்',
  // Tamil sounds / phrases (Tamil-mode session).
  'அ', 'ஆ', 'இ', 'உ', 'மா', 'பா', 'தா', 'நா', 'கா', 'வா',
  'அம்மா வா', 'அப்பா வா', 'பால் குடி', 'பந்து போடு', 'தண்ணீர் வேண்டும்',
  'எனக்குப் பசிக்கிறது', 'பூனை தூங்குகிறது', 'நாய் ஓடுகிறது',
  'நான் விளையாட வேண்டும்', 'பெரிய யானை', 'சிவப்பு பந்து',
};

void main() {
  binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  SpeechService.debugListenOverride = () async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return heard;
  };

  testWidgets('Vernacura end to end', (tester) async {
    final d = Driver(tester);
    app.main();
    await d.wait(find.text('Vernacura'), why: 'welcome screen', seconds: 40);
    await d.shot('welcome');

    // ── Welcome → English ────────────────────────────────────────────
    await d.tapText('English');
    await d.tapText('Continue');
    await d.wait(find.text('Welcome back'), why: 'login page');
    await d.shot('login');

    // Wrong password on an unknown account → friendly error.
    await d.type('Mobile number', '9999999999');
    await d.type('Password', 'nope123');
    await d.tap(find.widgetWithText(AphButton, 'Sign in'), why: 'Sign in');
    await d.wait(find.textContaining('incorrect'), why: 'login error');
    await d.shot('login_error');

    // ── Therapist registers ─────────────────────────────────────────
    await d.tapText('I am a therapist');
    await d.tapText('Register');
    await d.type('Full name', 'Dr. Priya');
    await d.type('Mobile number', therapistPhone);
    await d.type('Password', therapistPassword);
    await d.tapText('Create therapist account');
    await d.wait(find.text('Your code for families'), why: 'therapist dashboard', seconds: 30);
    final code = (tester.widget(find.byType(SelectableText).first) as SelectableText)
        .data!
        .trim();
    expect(code.length, 6, reason: 'therapist code "$code"');
    await d.shot('therapist_dashboard_empty');
    await d.therapistSignOut();

    // ── Parent creates the child's account ───────────────────────────
    await d.tapText('Create a new account');
    await d.wait(find.text('Create your account'), why: 'sign-up step 1');
    await d.wait(find.text('Your mobile number'), why: 'phone field on step 1');
    await d.shot('signup_1');
    await d.typeAt(0, patientPhone);
    await d.typeAt(1, patientPassword);
    await d.typeAt(2, patientPassword);
    await d.tap(find.widgetWithText(AphButton, 'Continue'), why: 'Continue');
    await d.wait(find.text('Who will practise?'), why: 'sign-up step 2');
    await d.wait(find.text('Who is this for?'), why: 'who question on step 2');
    await d.shot('signup_2');
    // Name/age fields appear once "Who is this for?" is answered.
    await d.tapText('My child');
    await d.wait(find.text("Child's name"), why: 'child wording on step 2');
    // Assisted (parent) mode is switched on for every parent sign-up.
    await d.typeAt(0, 'Kavin');
    await d.typeAt(1, '6');
    await d.tapText('Boy');
    // Without consent the account is not created.
    await d.tap(find.widgetWithText(AphButton, 'Create account'), why: 'Create (no consent)');
    await d.wait(find.textContaining('tick the box'), why: 'consent required');
    await d.tap(find.byKey(const Key('parent-consent')), why: 'parent consent');
    await d.shot('signup_2_filled');
    await d.tap(find.widgetWithText(AphButton, 'Create account'), why: 'Create account');

    // ── Step 3: intake questionnaire (child, age 6 → 9 questions) ─────
    await d.wait(find.text('A few questions'), why: 'questionnaire after sign-up', seconds: 30);
    await d.wait(find.text('1 of 9'), why: 'questionnaire progress');
    await d.shot('intake_first');
    await d.answer('Before 1½ years'); // first words
    await d.answer('Yes'); // follows a simple instruction
    await d.answer('Most of it'); // understood by family
    await d.answer('About half'); // understood by strangers
    await d.answer('A few sounds'); // hard sounds
    await d.answer('Yes, usually'); // turns to name / sounds
    await d.answer('No'); // lost words
    await d.answer('Yes, often'); // looks and points
    await d.answer('No', next: 'See the result'); // chewing / swallowing
    await d.wait(find.text('Your starting plan'), why: 'intake result');
    await d.wait(find.text('Level 2 · words'), why: 'start level');
    expect(find.text('Please also check'), findsNothing, reason: 'no red flags expected');
    await d.shot('intake_result');
    await d.tap(find.widgetWithText(AphButton, 'Save and continue'), why: 'save intake');
    await d.wait(find.text('Today'), why: 'home after sign-up', seconds: 30);
    expect(find.byKey(const ValueKey('today_intake')), findsNothing,
        reason: 'questionnaire answered, Today should not ask again');
    await d.idle(1500);
    await d.shot('today_new');

    // ── Sound check (placement) ──────────────────────────────────────
    await d.tap(find.textContaining('check-up'), why: 'check-up tile');
    await d.runSession('sound_check', wrongEvery: 4);
    await d.wait(find.text('Today'), why: 'back on Today');
    await d.shot('today_after_check');

    // ── Practice tab: every exercise ────────────────────────────────
    await d.tab('Practice');
    await d.shot('practice_hub');

    await d.openTile('Sounds');
    await d.runSession('sounds', wrongEvery: 3, testNoSpeech: true, openDrill: true);

    await d.tab('Practice');
    await d.openTile('Say the word');
    await d.runSession('words', testTyping: true);

    await d.tab('Practice');
    await d.openTile('What is this?');
    await d.runSession('naming');

    await d.tab('Practice');
    await d.openTile('Little sentences');
    await d.runSession('sentences');

    await d.tab('Practice');
    await d.openTile('Copy the voice');
    await d.runSession('copy_voice');

    await d.tab('Practice');
    await d.openTile('Picture match');
    await d.runPictureMatch();

    // ── Progress ─────────────────────────────────────────────────────
    await d.tab('Progress');
    await d.wait(find.text('Recent sessions'), why: 'progress loaded', seconds: 20);
    await d.idle(1500);
    await d.shot('progress');
    expect(find.text('No sessions yet'), findsNothing,
        reason: 'sessions were finished but Progress shows none');

    // ── Me: comfort settings, assisted mode ─────────────────────────
    await d.tab('Me');
    await d.wait(find.text('Retake questionnaire'), why: 'retake questionnaire on Me');
    await d.shot('me');
    await d.toggle('High contrast');
    await d.shot('me_high_contrast');
    await d.toggle('High contrast');
    await d.toggle('Reduce motion');
    await d.toggle('Read instructions aloud');
    final assisted = find.widgetWithText(SwitchListTile, 'Assisted sessions');
    await d.wait(assisted, why: 'assisted switch');
    expect((tester.widget(assisted.first) as SwitchListTile).value, isTrue,
        reason: 'assisted (parent) mode should be on after sign-up');
    await d.setSwitch('Assisted sessions', true);
    await d.idle();
    final helper = find.descendant(
        of: find.widgetWithText(AphTextField, "Helper's name"),
        matching: find.byType(TextFormField));
    if (helper.evaluate().isNotEmpty) {
      await tester.ensureVisible(helper);
      await tester.enterText(helper, 'Meena');
      await d.idle();
    }
    await d.shot('me_assisted');

    await d.tab('Practice');
    await d.openTile('Sounds');
    await d.wait(find.text('Start'), why: 'assisted hand-over screen');
    await d.shot('assisted_handover');
    await d.tapText('Start');
    await d.runSession('assisted_sounds', helperNote: 'Kavin was tired today');
    await d.tab('Me');
    await d.setSwitch('Assisted sessions', false);
    await d.toggle('Reduce motion');
    await d.toggle('Read instructions aloud');

    // ── Tamil ────────────────────────────────────────────────────────
    await d.tapText('தமிழ்');
    await d.idle(1200);
    await d.shot('ta_me');
    for (final (label, name) in [
      ('இன்று', 'ta_today'),
      ('பயிற்சி', 'ta_practice'),
      ('வளர்ச்சி', 'ta_progress'),
      ('சிகிச்சை', 'ta_care'),
    ]) {
      await d.tab(label);
      await d.idle(1200);
      await d.shot(name);
    }
    await d.tab('பயிற்சி');
    await d.openTile('சொல்லைச் சொல்');
    await d.runSession('ta_words', tamil: true);
    await d.tab('நான்');
    await d.tapText('English');
    await d.idle(1000);

    // ── Care team: link, book, video ────────────────────────────────
    await d.tab('Care team');
    await d.shot('care_unlinked');
    await d.typeAt(0, 'ZZZZZZ');
    await d.tapText('Link therapist');
    await d.wait(find.byType(FeedbackBanner), why: 'bad-code error');
    await d.shot('care_bad_code');
    await d.typeAt(0, code);
    await d.tapText('Link therapist');
    await d.wait(find.textContaining('Dr. Priya'), why: 'linked therapist card', seconds: 20);
    await d.shot('care_linked');

    await d.tapText('Book session');
    await d.tapText('OK'); // date: tomorrow
    await d.tapText('OK'); // time: 10:00
    await d.wait(find.textContaining('Requested'), why: 'booking requested');
    await d.idle(1500);
    await d.shot('care_booked');

    await d.tapText('Video call');
    await d.idle(1500);
    await d.shot('video_call');
    await d.backOut();

    // Sign out.
    await d.tab('Me');
    await d.tap(find.widgetWithText(AphButton, 'Sign out'), why: 'Sign out');
    await d.wait(find.text('Sign out?'), why: 'sign-out dialog');
    await d.tap(find.text('Sign out').last, why: 'confirm sign out');
    await d.wait(find.text('Welcome back'), why: 'login after sign out');

    // ── Therapist reviews ────────────────────────────────────────────
    await d.tapText('I am a therapist');
    await d.type('Mobile number', therapistPhone);
    await d.type('Password', therapistPassword);
    await d.tap(find.widgetWithText(AphButton, 'Sign in'), why: 'therapist sign in');
    await d.wait(find.text('Kavin'), why: 'patient on caseload', seconds: 30);
    await d.idle(1500);
    await d.shot('therapist_caseload');
    await d.tapText('Confirm');
    await d.idle(1500);
    await d.shot('therapist_confirmed');
    await d.tap(find.text('Kavin').last, why: 'open patient');
    // The intake section sits near the top; attempts are far below it on
    // this (lazily built) page, so check top-down and give the scroll time.
    await d.wait(find.text('Intake summary'), why: 'patient detail', seconds: 20);
    await d.idle(1500);
    await d.shot('patient_detail');
    await d.wait(find.textContaining('speech delay pack'), why: 'condition pill');
    await d.wait(find.textContaining('First words: Before 1½ years.'), why: 'intake summary text');
    await d.shot('patient_intake');
    await tester.scrollUntilVisible(find.text('Recent attempts'), 500,
        scrollable: find.byWidgetPredicate((w) =>
            w is Scrollable && w.axisDirection == AxisDirection.down).first,
        maxScrolls: 60);
    await d.idle(800);
    expect(find.text('No attempts recorded yet'), findsNothing,
        reason: 'therapist cannot see the attempts the child made');
    await d.type('Home practice guidance', 'Practise ப and ம words with picture cards.');
    await d.tapText('Save note');
    await d.wait(find.textContaining('Note saved'), why: 'note saved');
    await d.shot('note_saved');
    await d.backOut();
    await d.therapistSignOut();

    // ── Parent sees the note, cancels booking, unlinks ──────────────
    await d.type('Mobile number', patientPhone);
    await d.type('Password', patientPassword);
    await d.tap(find.widgetWithText(AphButton, 'Sign in'), why: 'patient sign in');
    await d.wait(find.text('Today'), why: 'home after login', seconds: 30);
    await d.idle(1500);
    await d.wait(find.textContaining('picture cards'), why: "therapist's note on Today");
    await d.shot('today_with_note');
    await d.tab('Care team');
    await d.idle(1500);
    await d.shot('care_confirmed');
    await d.tap(find.widgetWithText(AphButton, 'Cancel'), why: 'cancel booking');
    await d.tap(find.text('Cancel session').last, why: 'confirm cancel');
    await d.idle(1500);
    await d.tapText('Unlink therapist');
    await d.tap(find.text('Unlink').last, why: 'confirm unlink');
    await d.wait(find.text('Link therapist'), why: 'unlinked');
    await d.shot('care_unlinked_again');

    if (d.notes.isNotEmpty) {
      // ignore: avoid_print
      print('E2E NOTES:\n${d.notes.join('\n')}');
    }
  });
}

class Driver {
  Driver(this.tester);
  final WidgetTester tester;
  final notes = <String>[];
  int _shot = 0;
  bool _surface = false;

  Future<void> idle([int ms = 600]) async {
    final end = DateTime.now().add(Duration(milliseconds: ms));
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 50));
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }

  /// Waits for [f]. Lists build lazily, so after a moment it does what a
  /// person would: closes the keyboard, then scrolls down (and back up).
  Future<void> wait(Finder f, {int seconds = 15, String? why}) async {
    final start = DateTime.now();
    final end = start.add(Duration(seconds: seconds));
    var scrolls = 0;
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 100));
      bool found;
      try {
        found = f.evaluate().isNotEmpty;
      } on StateError {
        found = false; // `.last` / `.at(n)` of a finder with no matches yet
      }
      if (found) return;
      await Future<void>.delayed(const Duration(milliseconds: 150));
      if (DateTime.now().difference(start) > Duration(milliseconds: 1500 + scrolls * 700)) {
        FocusManager.instance.primaryFocus?.unfocus();
        final vertical = find.byWidgetPredicate((w) =>
            w is Scrollable && w.axisDirection == AxisDirection.down);
        if (vertical.evaluate().isNotEmpty) {
          final dy = (scrolls % 10) < 5 ? -450.0 : 450.0;
          try {
            await tester.drag(vertical.first, Offset(0, dy), warnIfMissed: false);
          } catch (_) {}
        }
        scrolls++;
      }
    }
    await shot('FAIL_${(why ?? 'wait').replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_')}');
    throw TestFailure('Timed out waiting for ${why ?? f}');
  }

  Future<void> tap(Finder f, {String? why}) async {
    await wait(f, why: why);
    await tester.ensureVisible(f.first);
    await idle(250);
    await tester.tap(f.first, warnIfMissed: false);
    await idle();
  }

  Future<void> tapText(String s) => tap(find.text(s), why: s);

  /// Intake questionnaire: pick [option], then press [next].
  Future<void> answer(String option, {String next = 'Next'}) async {
    await shot('intake_${option.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_')}');
    await tapText(option);
    await tap(find.widgetWithText(AphButton, next), why: 'intake $next after "$option"');
    await idle(400);
  }

  Future<void> tab(String label) => tap(
        find.descendant(of: find.byType(NavigationBar), matching: find.text(label)),
        why: 'tab $label',
      );

  Future<void> openTile(String title) async {
    await wait(find.text(title), why: 'tile $title');
    await tap(find.text(title).last, why: 'tile $title');
  }

  Future<void> toggle(String title) =>
      tap(find.widgetWithText(SwitchListTile, title), why: 'switch $title');

  /// Sets a settings switch to [on] (no-op when it already is).
  Future<void> setSwitch(String title, bool on) async {
    final f = find.widgetWithText(SwitchListTile, title);
    await wait(f, why: 'switch $title');
    if ((tester.widget(f.first) as SwitchListTile).value != on) {
      await toggle(title);
    }
  }

  Future<void> tapChoice(int index) async {
    final chips = find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.inMutuallyExclusiveGroup == true);
    await wait(chips, why: 'choice chips');
    await tester.tap(chips.at(index));
    await idle();
  }

  Finder _field(String label) => find.descendant(
      of: find.widgetWithText(AphTextField, label),
      matching: find.byType(TextFormField));

  Future<void> type(String label, String value) async {
    final f = _field(label);
    await wait(f, why: 'field $label');
    await tester.ensureVisible(f.first);
    await tester.enterText(f.first, value);
    await idle(300);
  }

  /// Types into the n-th text field on screen (labels that differ by
  /// language or contain curly quotes).
  Future<void> typeAt(int n, String value) async {
    final f = find.byType(TextFormField);
    await wait(f, why: 'text field $n');
    await tester.ensureVisible(f.at(n));
    await tester.enterText(f.at(n), value);
    await idle(300);
  }

  Future<void> backOut() async {
    await tester.pageBack();
    await idle(800);
  }

  Future<void> therapistSignOut() async {
    await tap(find.byTooltip('Sign out'), why: 'therapist sign-out icon');
    await tap(find.text('Sign out').last, why: 'confirm therapist sign out');
    await wait(find.text('Welcome back'), why: 'login after therapist sign out');
  }

  Future<void> shot(String name) async {
    if (!_surface) {
      await binding.convertFlutterSurfaceToImage();
      _surface = true;
    }
    await tester.pump();
    _shot++;
    await binding.takeScreenshot('${_shot.toString().padLeft(2, '0')}_$name');
  }

  String? _pictureLabel() {
    for (final e in find
        .byWidgetPredicate((w) =>
            w is Semantics && (w.properties.label?.startsWith('Picture of ') ?? false))
        .evaluate()) {
      return (e.widget as Semantics).properties.label!.substring('Picture of '.length);
    }
    return null;
  }

  bool get _pictureHidden => find
      .byWidgetPredicate(
          (w) => w is Semantics && w.properties.label == 'Picture to name')
      .evaluate()
      .isNotEmpty;

  /// The text the child is expected to say on the current card.
  Future<String> _target({required bool tamil}) async {
    if (_pictureHidden) {
      // Walk the hint ladder: meaning → first sound → word.
      for (final hint in ['Give me a hint', 'Show the first sound', 'Show the word',
          'குறிப்பு வேண்டும்', 'முதல் ஒலியைக் காட்டு', 'சொல்லைக் காட்டு']) {
        if (find.text(hint).evaluate().isNotEmpty) {
          await tapText(hint);
          if (hint == 'Give me a hint' || hint == 'குறிப்பு வேண்டும்') {
            if (find.textContaining('Hint').evaluate().isEmpty &&
                find.textContaining('குறிப்பு:').evaluate().isEmpty) {
              notes.add('naming: meaning hint not shown');
            }
          }
        }
      }
    }
    final pic = _pictureLabel();
    if (pic != null) {
      // English mode: label is the target. Tamil mode: label is the English
      // gloss, so map it back to the Tamil word.
      if (!tamil) return pic;
      final w = kidWords.where((k) => k.en == pic);
      if (w.isNotEmpty) return w.first.ta;
      return pic;
    }
    for (final t in _knownTargets) {
      if (find.text(t).evaluate().isNotEmpty) return t;
    }
    // Otherwise: the largest text on the exercise card is the prompt.
    String? best;
    var size = 0.0;
    for (final e in find
        .descendant(of: find.byType(AphCard).first, matching: find.byType(Text))
        .evaluate()) {
      final w = e.widget as Text;
      final fs = w.style?.fontSize ?? 0;
      if (w.data != null && fs > size) {
        size = fs;
        best = w.data;
      }
    }
    if (best != null && size >= 24) return best;
    await shot('FAIL_unknown_target');
    throw TestFailure('Could not work out what the child should say on this card');
  }

  Finder get _mic =>
      find.textContaining(RegExp(r'^(Tap and speak|தட்டி பேசுங்கள்)$'));
  Finder get _summary =>
      find.textContaining(RegExp(r'^(Session complete|அமர்வு முடிந்தது)$'));
  Finder get _advance =>
      find.textContaining(RegExp(r'^(Next|Finish|அடுத்து|முடி)$'));

  Future<void> runSession(
    String name, {
    int wrongEvery = 0,
    bool testNoSpeech = false,
    bool testTyping = false,
    bool openDrill = false,
    bool tamil = false,
    String? helperNote,
  }) async {
    var i = 0;
    while (true) {
      await wait(find.byWidgetPredicate((w) =>
          w is Text &&
          RegExp(r'^(Tap and speak|தட்டி பேசுங்கள்|Session complete|அமர்வு முடிந்தது|Start|தொடங்கு)$')
              .hasMatch(w.data ?? '')), why: '$name: card or summary', seconds: 20);
      // Assisted mode opens with a hand-over screen.
      final handover = find.textContaining(RegExp(r'^(Start|தொடங்கு)$'));
      if (handover.evaluate().isNotEmpty && _mic.evaluate().isEmpty) {
        if (i == 0) await shot('${name}_handover');
        await tap(handover.first, why: '$name: Start');
        continue;
      }
      if (_summary.evaluate().isNotEmpty) break;
      i++;
      final target = await _target(tamil: tamil);
      if (i == 1) await shot('${name}_card');

      if (testNoSpeech && i == 1) {
        heard = '';
        await tap(find.byType(MicButton), why: 'mic (silence)');
        await wait(find.textContaining(RegExp(r'try that again|மீண்டும் முயலலாம்')),
            why: '$name: no-speech card');
        await shot('${name}_no_speech');
      }

      if (testTyping && i == 1) {
        await tapText('Type instead');
        await type('Type what you would say', target);
        await tapText('Check');
      } else {
        final wrong = wrongEvery > 0 && i % wrongEvery == 0;
        heard = wrong ? 'zzz' : target;
        await tap(find.byType(MicButton), why: '$name: mic');
      }
      await wait(_advance, why: '$name: result for "$target"');
      if (i == 1) await shot('${name}_result');
      await tap(_advance.first, why: '$name: next');
    }
    await idle(800);
    await shot('${name}_summary');
    if (helperNote != null) {
      await type('Note (optional)', helperNote);
    }
    final drill = find.textContaining('Practise tricky sounds');
    if (openDrill) {
      if (drill.evaluate().isEmpty) {
        notes.add('$name: wrong answers given but no tricky-sounds drill offered');
      } else {
        await tap(drill, why: 'open drill');
        await runSession('${name}_drill');
      }
    }
    if (find.text('Done').evaluate().isNotEmpty ||
        find.text('முடிந்தது').evaluate().isNotEmpty) {
      await tap(find.textContaining(RegExp(r'^(Done|முடிந்தது)$')).last, why: '$name: Done');
    }
    await idle(800);
  }

  Future<void> runPictureMatch() async {
    await wait(find.text('Tap the picture for:'), why: 'picture match');
    await shot('picture_match');
    for (var round = 0; round < 10; round++) {
      await wait(find.text('Tap the picture for:'), why: 'picture round');
      KidWord? answer;
      for (final w in kidWords) {
        if (find.text(w.en).evaluate().isNotEmpty) {
          answer = w;
          break;
        }
      }
      if (answer == null) {
        await shot('FAIL_picture_word');
        throw TestFailure('picture match: answer word not visible');
      }
      // Wrong on round 3, to see the "not quite" feedback.
      if (round == 2) {
        final other = kidWords.firstWhere((w) =>
            w.id != answer!.id && find.text(w.emoji).evaluate().isNotEmpty);
        await tap(find.text(other.emoji), why: 'wrong picture');
        await shot('picture_wrong');
      } else {
        await tap(find.text(answer.emoji), why: 'picture ${answer.en}');
      }
      await tap(_advance.first, why: 'picture next');
    }
    await wait(find.textContaining('pictures matched'), why: 'picture summary');
    await shot('picture_summary');
    await tapText('Done');
  }
}
