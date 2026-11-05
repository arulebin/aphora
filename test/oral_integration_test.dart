import 'package:aphora/data/intake/condition.dart';
import 'package:aphora/data/learning/oral/oral_rehab_pack.dart';
import 'package:aphora/data/learning/packs/aphasia_pack.dart';
import 'package:aphora/data/learning/packs/condition_packs.dart';
import 'package:aphora/data/learning/packs/kids_pack.dart';
import 'package:aphora/data/learning/packs/oral_cancer_pack.dart';
import 'package:aphora/data/learning/practice_catalog.dart';
import 'package:aphora/data/models/oral_records.dart';
import 'package:aphora/data/models/practice_record.dart';
import 'package:aphora/data/models/usermodel.dart';
import 'package:aphora/logic/baseline_scoring.dart';
import 'package:aphora/logic/comfort_settings.dart';
import 'package:aphora/logic/intake_engine.dart';
import 'package:aphora/logic/language_service.dart';
import 'package:aphora/logic/self_baseline_feedback.dart';
import 'package:aphora/ui/practice/practice_session_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, String> _mouth({Map<String, String> extra = const {}}) => {
      'who': 'self',
      'event': 'surgery',
      'o_surgery': 'part',
      'o_weeks': '3to12m',
      'o_radio': 'done',
      'o_family': 'usually',
      'o_phone': 'yes',
      'o_daily': 'little',
      'o_pain': 'no',
      'swallow': 'no',
      ...extra,
    };

Future<UserModel> _oralUser({
  Map<String, String> extra = const {},
  Map<String, dynamic> fields = const {},
  DateTime? intakeAt,
}) async {
  final rec = await IntakeEngine.record(_mouth(extra: extra),
      name: 'Selvi', now: intakeAt ?? DateTime(2026, 11, 1));
  return UserModel.fromMap({
    'uid': 'u',
    'name': 'Selvi',
    'createdAt': '2026-10-01T00:00:00.000',
    'updatedAt': '2026-10-01T00:00:00.000',
    'condition': rec.condition.id,
    'intake': rec.toMap(),
    ...fields,
  });
}

OralAttempt _a(String id, double score, int minute) => OralAttempt(
      itemId: id,
      at: DateTime(2026, 11, 2, 10, minute),
      score: score,
      source: ScoreSource.device,
    );

void main() {
  group('oral pack selection and kinds', () {
    test('an oral-cancer intake → the oral pack, tailored to the person', () async {
      final u = await _oralUser(
        fields: {'oralPersonal': {'name': 'Selvi'}},
        intakeAt: DateTime.now().subtract(const Duration(days: 5)),
      );
      expect(u.activeCondition, Condition.oralCancerRehab);
      final pack = ConditionPacks.forUser(u) as OralCancerPack;
      expect(pack.personal, {'name': 'Selvi'});
      expect(pack.surgery, OralSurgery.partTongue);
      expect(pack.day, 5);
      expect(pack.forChildren, isFalse);
      expect(ConditionPacks.contentPending(Condition.oralCancerRehab), isFalse);
    });

    test('hub kinds: daily session first, then the oral content groups', () {
      LanguageService.setLanguage(Language.english);
      const pack = OralCancerPack();
      expect(pack.speakingKinds, [
        PracticeKind.daily,
        PracticeKind.letters,
        PracticeKind.words,
        PracticeKind.drill,
        PracticeKind.functional,
        PracticeKind.clearSpeech,
      ]);
      expect(pack.hasPictureMatch, isFalse, reason: 'understanding is not the problem');
      expect(pack.speakingKinds, isNot(contains(PracticeKind.phonetic)),
          reason: 'never scored against a healthy voice');
      expect(pack.title(PracticeKind.clearSpeech), 'One word at a time');
      expect(pack.title(PracticeKind.functional), 'Everyday phrases');
      expect(pack.title(PracticeKind.assessment), 'Monthly clarity check');
      expect(pack.plan(level: 2), ['daily']);
      expect(pack.recommendedKind(level: 1), PracticeKind.daily);
      expect(OralRehabPack.oralKindFor(PracticeKind.functional), OralItemKind.phrases);
      expect(OralRehabPack.oralKindFor(PracticeKind.clearSpeech), OralItemKind.clearSpeech);
      expect(OralRehabPack.oralKindFor(PracticeKind.phonetic), isNull);
    });

    test('items: every kind has content at every level, in both languages', () {
      const pack = OralCancerPack();
      for (final language in Language.values) {
        for (final kind in pack.speakingKinds) {
          for (final level in [1, 2, 3]) {
            expect(pack.items(kind, level: level, language: language), isNotEmpty,
                reason: '$kind L$level $language');
          }
        }
      }
      final daily = pack.items(PracticeKind.daily, level: 2, language: Language.tamil);
      expect(daily.length, greaterThan(20), reason: 'about 10 minutes');
    });

    test('paced items carry their words and the pacing cue', () {
      const pack = OralCancerPack();
      final items = pack.items(PracticeKind.clearSpeech, level: 1, language: Language.english);
      for (final i in items) {
        expect(i.chunks, isNotNull);
        expect(i.chunks!.join(' '), i.target);
        expect(i.instruction, OralRehabPack.pacingCue.en);
      }
    });

    test('clarity check: the fixed set, in order, no hints, no pacing', () {
      const pack = OralCancerPack();
      for (final language in Language.values) {
        final items = pack.items(PracticeKind.assessment, level: 3, language: language);
        expect(items.map((i) => i.id).toList(),
            OralRehabPack.intelligibilitySet(language).map((i) => i.id).toList());
        expect(items.every((i) => i.semanticCue == null && i.chunks == null), isTrue);
      }
      expect(pack.checkUpIsMeasure, isTrue);
      expect(pack.checkUpSetsLevel, isFalse);
    });

    test('personal phrases appear once their details are filled', () {
      final templates = OralRehabPack.all.where((i) => i.isTemplate).toList();
      expect(templates, isNotEmpty);
      final t = templates.first;
      final empty = OralCancerPack().items(PracticeKind.functional,
          level: t.level, language: Language.english);
      expect(empty.any((i) => i.id == t.id), isFalse);
      final details = {for (final p in t.placeholders) p: 'X$p'};
      final pack = OralCancerPack(personal: details);
      final all = [
        for (var d = 0; d < 20; d++)
          ...OralCancerPack(personal: details, day: d)
              .items(PracticeKind.functional, level: t.level, language: Language.english),
      ];
      expect(all.any((i) => i.id == t.id && !i.target.contains('{')), isTrue);
      expect(pack.personal, details);
    });

    test('the monthly check is due when never taken, then every 30 days', () async {
      const pack = OralCancerPack();
      final none = await _oralUser();
      expect(pack.checkUpDue(none), isTrue);
      ClarityTest test(int daysAgo) => ClarityTest(
          at: DateTime.now().subtract(Duration(days: daysAgo)),
          understood: 10, attempted: 20, total: 20);
      final recent = none.copyWith(oralClarityTests: [test(10)]);
      expect(pack.checkUpDue(recent), isFalse);
      expect(pack.checkUpDue(none.copyWith(oralClarityTests: [test(31)])), isTrue);
    });
  });

  group('safety gate', () {
    test('no hold flag: show the safety line once', () async {
      final u = await _oralUser();
      const pack = OralCancerPack();
      expect(OralCancerPack.holdFlagsOf(u), isEmpty);
      expect(pack.safetyFor(u), PracticeSafety.notice);
      final seen = u.copyWith(
          oralSafety: SafetyConfirmation(at: DateTime(2026, 11, 2), hold: false));
      expect(pack.safetyFor(seen), PracticeSafety.clear);
    });

    test('hold flags keep practice closed until the care team said yes', () async {
      const pack = OralCancerPack();
      for (final extra in [
        {'o_weeks': 'lt6w'}, // ask_surgeon
        {'o_pain': 'yes'}, // oral_pain
        {'o_radio': 'ongoing'}, // radiotherapy_team
      ]) {
        final u = await _oralUser(extra: extra);
        expect(OralCancerPack.holdFlagsOf(u), isNotEmpty, reason: '$extra');
        expect(pack.safetyFor(u), PracticeSafety.hold, reason: '$extra');
        // Acknowledging the notice is not enough.
        final noticed = u.copyWith(
            oralSafety: SafetyConfirmation(at: DateTime(2026, 11, 2), hold: false));
        expect(pack.safetyFor(noticed), PracticeSafety.hold);
        final yes = u.copyWith(
            oralSafety: SafetyConfirmation(at: DateTime(2026, 11, 2), hold: true));
        expect(pack.safetyFor(yes), PracticeSafety.clear);
      }
    });

    test('a confirmation from before a retaken intake does not count', () async {
      final u = await _oralUser(extra: {'o_pain': 'yes'}, intakeAt: DateTime(2026, 11, 10));
      final old = u.copyWith(
          oralSafety: SafetyConfirmation(at: DateTime(2026, 11, 2), hold: true));
      expect(const OralCancerPack().safetyFor(old), PracticeSafety.hold);
    });

    test('other packs have no safety step', () async {
      final u = await _oralUser();
      expect(const KidsPack().safetyFor(u), PracticeSafety.clear);
      expect(const AphasiaPack().safetyFor(u), PracticeSafety.clear);
      expect(const OralCancerPack().safetyFor(null), PracticeSafety.clear);
    });

    test('the confirmation and personal details survive a round trip', () async {
      final u = (await _oralUser()).copyWith(
        oralSafety: SafetyConfirmation(at: DateTime(2026, 11, 3, 9), hold: true),
        oralPersonal: {'name': 'Selvi', 'place': 'Madurai'},
        oralClarityTests: [
          ClarityTest(at: DateTime(2026, 11, 3), understood: 12, attempted: 20, total: 20,
              missed: ['oral_x']),
        ],
      );
      final back = UserModel.fromMap(u.toMap());
      expect(back.oralSafety!.hold, isTrue);
      expect(back.oralSafety!.at, DateTime(2026, 11, 3, 9));
      expect(back.oralPersonal['place'], 'Madurai');
      expect(back.oralClarityTests.single.percent, 60);
      expect(back.oralClarityTests.single.missed, ['oral_x']);
      expect(SafetyConfirmation.tryFromMap('nope'), isNull);
    });
  });

  group('self-baseline display', () {
    test('the first three attempts set the starting point', () {
      final h = <OralAttempt>[];
      for (var i = 0; i < 3; i++) {
        h.add(_a('oral_w', 50, i));
        expect(SelfBaselineFeedback.bandFor('oral_w', h), ProgressBand.settingStartingPoint);
      }
      h.addAll([_a('oral_w', 80, 10), _a('oral_w', 82, 11)]);
      expect(SelfBaselineFeedback.bandFor('oral_w', h), ProgressBand.clearer);
    });

    test('patient messages carry no numbers and no "wrong"', () {
      for (final b in ProgressBand.values) {
        for (final l in Language.values) {
          final m = SelfBaselineFeedback.messageFor(b, l);
          expect(m.title, isNotEmpty);
          expect('${m.title} ${m.detail}'.contains(RegExp(r'[0-9%]')), isFalse);
          expect('${m.title} ${m.detail}'.toLowerCase(), isNot(contains('wrong')));
        }
      }
      expect(SelfBaselineFeedback.messageFor(ProgressBand.settingStartingPoint, Language.english).title,
          'Setting your starting point');
    });

    test('attempt records → scoring attempts: server CER first, taps skipped', () {
      AttemptRecord r(String method, double score, {double? cer}) => AttemptRecord(
            taskId: 'oral_w', category: 'words', target: 't', spoken: 't',
            score: score, method: method, assisted: false,
            createdAt: DateTime(2026, 11, 2), cer: cer);
      final out = SelfBaselineFeedback.fromRecords([
        r('device', 70),
        r('server', 60, cer: 0.2),
        r('server', 55),
        r('tap', 100),
      ]);
      expect(out.map((a) => a.source),
          [ScoreSource.device, ScoreSource.serverCer, ScoreSource.server]);
      expect(out[1].score, closeTo(80, 0.001));
    });

    test('clarity check: first complete test is the starting point', () {
      const pack = OralCancerPack();
      final items = pack.items(PracticeKind.assessment, level: 1, language: Language.english);
      final now = DateTime(2026, 12, 1);
      final all = [
        for (final i in items)
          OralAttempt(itemId: i.id, at: now, score: 90, source: ScoreSource.device,
              transcript: i.target),
      ];
      final r = SelfBaselineFeedback.clarity(all, items, Language.english);
      expect(r.isComplete, isTrue);
      expect(r.percent, 100);
      expect(SelfBaselineFeedback.clarityBand(const [], r), ProgressBand.settingStartingPoint);
      final first = ClarityTest(at: DateTime(2026, 11, 1), understood: 10, attempted: 20, total: 20);
      expect(SelfBaselineFeedback.clarityBand([first], r), ProgressBand.clearer);
      final incomplete = ClarityTest(at: DateTime(2026, 10, 1), understood: 2, attempted: 5, total: 20);
      expect(ClarityTest.startingPoint([incomplete, first]), first);
    });
  });

  group('oral session screen', () {
    setUp(() {
      LanguageService.setLanguage(Language.english);
      ComfortSettings.instance.autoReadAloud.value = false;
      ComfortSettings.instance.assistedMode.value = false;
      final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      for (final name in [
        'flutter_tts',
        'xyz.luan/audioplayers',
        'xyz.luan/audioplayers.global',
        'com.llfbandit.record/messages',
      ]) {
        messenger.setMockMethodCallHandler(MethodChannel(name), (_) async => null);
      }
    });

    testWidgets('rest cue, paced words, and a band message instead of a score',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.6;
      addTearDown(tester.view.reset);
      const pack = OralCancerPack();
      final item = pack
          .items(PracticeKind.clearSpeech, level: 1, language: Language.english)
          .first;
      await tester.pumpWidget(MaterialApp(
        home: PracticeSessionPage(kind: PracticeKind.clearSpeech, pack: pack, items: [item]),
      ));
      await tester.pump();
      expect(find.byKey(const ValueKey('rest_cue')), findsOneWidget);
      expect(find.text(OralRehabPack.restCue.en), findsOneWidget);
      expect(find.text(OralRehabPack.pacingCue.en), findsOneWidget);
      for (final w in item.chunks!) {
        expect(find.text(w), findsWidgets, reason: 'one word per pause: $w');
      }

      Future<void> tap(Finder f) async {
        await tester.scrollUntilVisible(f, 200, scrollable: find.byType(Scrollable).first);
        await tester.tap(f);
        await tester.pump();
      }

      await tap(find.text('Type instead'));
      await tester.enterText(find.byType(EditableText), item.target);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      await tester.pump(const Duration(seconds: 5)); // let the pacing timer finish
      expect(find.text('Finish'), findsOneWidget, reason: 'the attempt was scored');
      await tester.scrollUntilVisible(find.text('Setting your starting point'), 300,
          scrollable: find.byType(Scrollable).first);
      expect(find.text('Setting your starting point'), findsOneWidget);
      expect(find.textContaining('%'), findsNothing);
      expect(find.text('Excellent'), findsNothing);
    });
  });
}
