import 'dart:math';

import 'package:aphora/data/learning/aphasia_content.dart';
import 'package:aphora/data/learning/packs/aphasia_pack.dart';
import 'package:aphora/data/learning/practice_catalog.dart';
import 'package:aphora/logic/comfort_settings.dart';
import 'package:aphora/logic/language_service.dart';
import 'package:aphora/ui/practice/kid_rewards.dart';
import 'package:aphora/ui/practice/picture_match_page.dart';
import 'package:aphora/ui/practice/practice_session_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// The adult aphasia screens: pictures instead of emoji, the sentence to
/// complete on the card, no stars.
void main() {
  setUp(() {
    LanguageService.setLanguage(Language.english);
    ComfortSettings.instance.autoReadAloud.value = false;
    ComfortSettings.instance.assistedMode.value = false;
    // Plugins (TTS, audio, recorder) are not available in widget tests.
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    for (final name in [
      'flutter_tts',
      'xyz.luan/audioplayers',
      'xyz.luan/audioplayers.global',
      'com.llfbandit.record/messages',
    ]) {
      messenger.setMockMethodCallHandler(MethodChannel(name), (_) async => null);
    }
  });

  void phone(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.6;
    addTearDown(tester.view.reset);
  }

  testWidgets('sentence completion shows the sentence, hides the word, no stars',
      (tester) async {
    phone(tester);
    final e = aphasiaCompletion.firstWhere((e) => e.id == 'cup_of');
    await tester.pumpWidget(MaterialApp(
      home: PracticeSessionPage(
        kind: PracticeKind.completion,
        pack: const AphasiaPack(),
        items: [AphasiaPack.item(e, false)],
      ),
    ));
    await tester.pump();

    expect(find.text('Finish the sentence'), findsWidgets, reason: 'adult title');
    expect(find.text('Finish the sentence:'), findsOneWidget);
    expect(find.text('Every morning I drink a cup of ___'), findsOneWidget);
    expect(find.text('tea'), findsNothing, reason: 'the answer stays hidden');
    expect(find.byType(StarCounter), findsNothing, reason: 'no stars for adults');

    await tester.tap(find.text('Give me a hint'));
    await tester.pump();
    expect(find.textContaining('A hot drink'), findsOneWidget);
  });

  testWidgets('naming shows an icon or photo, never an emoji', (tester) async {
    phone(tester);
    final e = aphasiaNaming.firstWhere((e) => e.id == 'phone');
    await tester.pumpWidget(MaterialApp(
      home: PracticeSessionPage(
        kind: PracticeKind.naming,
        pack: const AphasiaPack(),
        items: [AphasiaPack.item(e, false)],
      ),
    ));
    await tester.pump();
    expect(find.text('Name the picture'), findsWidgets);
    expect(find.byIcon(Icons.smartphone), findsOneWidget);
    expect(find.bySemanticsLabel('Picture to name'), findsOneWidget);
  });

  testWidgets('carer mode hand-over speaks to a helper, not a parent', (tester) async {
    phone(tester);
    ComfortSettings.instance.assistedMode.value = true;
    addTearDown(() => ComfortSettings.instance.assistedMode.value = false);
    await tester.pumpWidget(MaterialApp(
      home: PracticeSessionPage(
        kind: PracticeKind.functional,
        pack: const AphasiaPack(),
        items: [AphasiaPack.item(aphasiaFunctional.first, false)],
      ),
    ));
    await tester.pump();
    expect(find.text('Practise together with a helper'), findsOneWidget);
    expect(find.textContaining('child'), findsNothing);
    expect(find.text('👩‍👧'), findsNothing);
  });

  testWidgets('listen and point: level 3 asks a question with pictures', (tester) async {
    phone(tester);
    await tester.pumpWidget(MaterialApp(
      home: PictureMatchPage(pack: const AphasiaPack(), level: 3, rounds: 3),
    ));
    await tester.pump();
    expect(find.text('Listen and point'), findsOneWidget);
    expect(find.text('Which picture is it?'), findsOneWidget);
    expect(find.byWidgetPredicate((w) => w is Icon || w is Image), findsWidgets);
  });

  test('random seeds give different but valid sessions', () {
    final a = AphasiaPack.pick(AphasiaTask.naming, 2, 10, random: Random(1));
    final b = AphasiaPack.pick(AphasiaTask.naming, 2, 10, random: Random(2));
    expect(a.map((e) => e.id).toSet().length, 10);
    expect(a.map((e) => e.id).join(), isNot(b.map((e) => e.id).join()));
  });
}
