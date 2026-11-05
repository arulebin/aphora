import 'package:aphora/logic/comfort_settings.dart';
import 'package:aphora/ui/intake/intake_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Walks the child path of the questionnaire the way
/// `integration_test/app_test.dart` does after sign-up, with the same
/// labels, up to the result screen (saving needs Firebase, so it stops
/// there).
void main() {
  setUp(() => ComfortSettings.instance.autoReadAloud.value = false);

  Future<void> answer(WidgetTester tester, String option, {String button = 'Next'}) async {
    await tester.tap(find.text(option));
    await tester.pumpAndSettle();
    await tester.tap(find.text(button));
    await tester.pumpAndSettle();
  }

  testWidgets('child path: one question per screen, then the plan', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.6;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(
      home: IntakePage(who: 'child', age: 4, fromSignUp: true),
    ));
    await tester.pumpAndSettle();

    // "Who is this for?" was answered on sign-up step 2; age is known.
    expect(find.text('Who is this for?'), findsNothing);
    expect(find.text('1 of 10'), findsOneWidget);
    expect(find.text('Skip for now'), findsOneWidget);
    // Next stays disabled until an answer is chosen.
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('1 of 10'), findsOneWidget);

    await answer(tester, 'Between 1½ and 2 years');
    await answer(tester, 'Sometimes'); // two words together
    await answer(tester, 'Yes'); // follows instructions
    await answer(tester, 'Most of it'); // family
    expect(find.text('5 of 10'), findsOneWidget);
    // Back returns to the previous question with its answer kept.
    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();
    expect(find.text('4 of 10'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await answer(tester, 'About half'); // strangers
    await answer(tester, 'A few sounds');
    await answer(tester, 'Yes, usually'); // hearing
    await answer(tester, 'No'); // lost words
    await answer(tester, 'Yes, often'); // pointing
    await answer(tester, 'No', button: 'See the result'); // feeding

    expect(find.text('Your starting plan'), findsOneWidget);
    expect(find.text("Children's speech and language"), findsOneWidget);
    expect(find.text('Level 2 · words'), findsOneWidget);
    expect(find.text('Two-word phrases'), findsOneWidget);
    expect(find.textContaining('not a diagnosis'), findsOneWidget);
    expect(find.text('Save and continue'), findsOneWidget);
    expect(find.text('Please also check'), findsNothing, reason: 'no red flags');
  });

  testWidgets('red flags show on the result screen', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.6;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(
      home: IntakePage(who: 'adult', age: 60, fromSignUp: true),
    ));
    await tester.pumpAndSettle();
    expect(find.text('What led to the speech difficulty?'), findsOneWidget);
    await answer(tester, 'A stroke');
    await answer(tester, 'More than a year');
    await answer(tester, 'Yes'); // new or sudden symptoms
    await answer(tester, 'Understood well');
    await answer(tester, 'Easy');
    await answer(tester, 'Easy');
    await answer(tester, 'In words');
    await answer(tester, 'Still possible');
    await answer(tester, 'No', button: 'See the result');

    expect(find.text('Please do this first'), findsOneWidget);
    expect(find.textContaining('Call 108'), findsOneWidget);
    expect(find.text('Your exercises are being prepared'), findsOneWidget);
  });
}
