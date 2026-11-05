import 'dart:math';

import 'package:aphora/logic/language_service.dart';
import 'package:aphora/logic/video_room.dart';
import 'package:aphora/ui/video_call/videocall_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Jitsi room names are the only thing keeping a call private, so they must
/// be random, well-formed and free of personal data.
void main() {
  group('VideoRoom.newName', () {
    test('is vernacura- plus 128 bits of hex', () {
      final name = VideoRoom.newName();
      expect(name, matches(RegExp(r'^vernacura-[0-9a-f]{32}$')));
      expect(VideoRoom.isValid(name), isTrue);
    });

    test('does not repeat', () {
      final names = {for (var i = 0; i < 500; i++) VideoRoom.newName()};
      expect(names, hasLength(500));
    });

    test('depends only on the RNG, never on who is calling', () {
      expect(VideoRoom.newName(Random(7)), VideoRoom.newName(Random(7)));
    });
  });

  test('isValid rejects old guessable and malformed names', () {
    expect(VideoRoom.isValid(null), isFalse);
    expect(VideoRoom.isValid('aphora_AB12CD_uid123'), isFalse);
    expect(VideoRoom.isValid('vernacura-1234'), isFalse);
    expect(VideoRoom.isValid('vernacura-${'G' * 32}'), isFalse);
  });

  test('normaliseServer', () {
    expect(VideoRoom.normaliseServer(''), VideoRoom.defaultServerUrl);
    expect(VideoRoom.normaliseServer('meet.example.org/'),
        'https://meet.example.org');
    expect(VideoRoom.normaliseServer(' https://a.b/jitsi// '), 'https://a.b/jitsi');
  });

  test('firstName', () {
    expect(VideoRoom.firstName('  Anbu Selvan '), 'Anbu');
    expect(VideoRoom.firstName('', fallback: 'Family'), 'Family');
  });

  test('meetingUri opens the room with no pre-join page and the name set', () {
    final room = VideoRoom.newName();
    final uri = VideoRoom.meetingUri(room,
        displayName: 'Anbu', server: 'https://meet.example.org');
    expect(uri.toString(), startsWith('https://meet.example.org/$room#'));
    expect(uri.fragment, contains('config.prejoinConfig.enabled=false'));
    expect(uri.fragment, contains('config.startWithVideoMuted=false'));
    expect(uri.fragment, contains('userInfo.displayName=%22Anbu%22'));
  });

  group('VideoCallPage', () {
    setUp(() => LanguageService.setLanguage(Language.english));

    testWidgets('shows the join screen once the room is ready', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: VideoCallPage(
          patientUid: 'p',
          therapistCode: 'AB12CD',
          displayName: 'Anbu',
          peerName: 'Dr. Priya',
          loadRoom: () async => VideoRoom.newName(),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Video call with Dr. Priya'), findsOneWidget);
      expect(find.text('Join video call'), findsOneWidget);
      expect(find.text('Calls use Jitsi Meet, an open-source video service'),
          findsOneWidget);
      expect(find.textContaining('meet.ffmuc.net'), findsOneWidget);
    });

    testWidgets('offers a retry when the room cannot be loaded', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: VideoCallPage(
          patientUid: 'p',
          therapistCode: 'AB12CD',
          displayName: 'Anbu',
          loadRoom: () async => throw StateError('offline'),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Could not set up the call'), findsOneWidget);
    });

    testWidgets('Tamil copy', (tester) async {
      LanguageService.setLanguage(Language.tamil);
      addTearDown(() => LanguageService.setLanguage(Language.english));
      await tester.pumpWidget(MaterialApp(
        home: VideoCallPage(
          patientUid: 'p',
          therapistCode: 'AB12CD',
          displayName: 'Anbu',
          loadRoom: () async => VideoRoom.newName(),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('வீடியோ அழைப்பில் சேர்'), findsOneWidget);
    });
  });
}
