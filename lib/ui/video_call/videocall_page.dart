import 'package:aphora/logic/language_service.dart';
import 'package:aphora/logic/locator.dart';
import 'package:aphora/logic/video_room.dart';
import 'package:aphora/ui/design/components.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

/// Private therapist ↔ family video room, on Jitsi Meet (open source).
///
/// The page is a join screen: it looks up (or creates, once) the pair's
/// unguessable room — see [VideoRoom] — and "Join video call" opens it.
/// On Android/iOS that launches the native Jitsi Meet SDK screen; on web,
/// where the SDK doesn't run, it opens the same room in a new browser tab.
///
/// Server: `--dart-define=JITSI_SERVER_URL=...` (docs/video-calls.md).
class VideoCallPage extends StatefulWidget {
  const VideoCallPage({
    super.key,
    required this.patientUid,
    required this.therapistCode,
    required this.displayName,
    this.peerName = 'your therapist',
    this.loadRoom,
  });

  /// The pair whose room to open.
  final String patientUid;
  final String therapistCode;

  /// Shown to the other side: the family's first name, or "Therapist".
  final String displayName;
  final String peerName;

  /// Test seam; defaults to `UserDatabaseService.ensureVideoRoom`.
  final Future<String> Function()? loadRoom;

  @override
  State<VideoCallPage> createState() => _VideoCallPageState();
}

class _VideoCallPageState extends State<VideoCallPage> {
  late Future<String> _room;
  bool _joining = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _room = _load();
  }

  Future<String> _load() =>
      (widget.loadRoom ??
          () => Locator.userDatabaseService.ensureVideoRoom(
                patientUid: widget.patientUid,
                therapistCode: widget.therapistCode,
              ))();

  Future<void> _join(String room) async {
    setState(() {
      _joining = true;
      _error = null;
    });
    try {
      if (kIsWeb) {
        final ok = await launchUrl(
          VideoRoom.meetingUri(room, displayName: widget.displayName),
          webOnlyWindowName: '_blank',
        );
        if (!ok) {
          _fail(tr('Could not open the call. Please allow pop-ups and try again.',
              'அழைப்பைத் திறக்க முடியவில்லை. பாப்-அப்களை அனுமதித்து மீண்டும் முயலுங்கள்.'));
        }
        return;
      }
      final perms = await [Permission.camera, Permission.microphone].request();
      if (perms.values.any((s) => !s.isGranted)) {
        _fail(tr(
            'Vernacura needs camera and microphone permission for video calls. '
                'Please allow both in your phone settings.',
            'வீடியோ அழைப்புக்கு கேமரா, மைக்ரோஃபோன் அனுமதி தேவை. '
                'தொலைபேசி அமைப்புகளில் இரண்டையும் அனுமதியுங்கள்.'));
        return;
      }
      await JitsiMeet().join(_options(room));
    } catch (e) {
      debugPrint('Jitsi join failed: $e');
      _fail(tr('Could not start the call. Please try again.',
          'அழைப்பைத் தொடங்க முடியவில்லை. மீண்டும் முயலுங்கள்.'));
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  void _fail(String message) {
    if (mounted) setState(() => _error = message);
  }

  JitsiMeetConferenceOptions _options(String room) => JitsiMeetConferenceOptions(
        serverURL: VideoRoom.serverUrl,
        room: room,
        configOverrides: {
          'startWithAudioMuted': false,
          'startWithVideoMuted': false,
          'prejoinConfig.enabled': false,
          'prejoinPageEnabled': false,
          'disableDeepLinking': true,
          'subject': tr('Vernacura session', 'Vernacura அமர்வு'),
        },
        featureFlags: {
          FeatureFlags.preJoinPageEnabled: false,
          FeatureFlags.welcomePageEnabled: false,
          FeatureFlags.unsafeRoomWarningEnabled: false,
          FeatureFlags.recordingEnabled: false,
          FeatureFlags.iosRecordingEnabled: false,
          FeatureFlags.liveStreamingEnabled: false,
          FeatureFlags.chatEnabled: false,
          FeatureFlags.inviteEnabled: false,
          FeatureFlags.addPeopleEnabled: false,
          FeatureFlags.calenderEnabled: false,
          FeatureFlags.callIntegrationEnabled: false,
          FeatureFlags.videoShareEnabled: false,
          FeatureFlags.breakoutRoomsEnabled: false,
          FeatureFlags.carModeEnabled: false,
          FeatureFlags.helpButtonEnabled: false,
        },
        userInfo: JitsiMeetUserInfo(displayName: widget.displayName),
      );

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return AphScaffold(
      title: tr('Video call', 'வீடியோ அழைப்பு'),
      children: [
        FutureBuilder<String>(
          future: _room,
          builder: (context, snap) {
            if (snap.hasError) {
              return ErrorState(
                title: tr('Could not set up the call', 'அழைப்பை அமைக்க முடியவில்லை'),
                message: tr('Please check your internet connection and try again.',
                    'இணைய இணைப்பைச் சரிபார்த்து மீண்டும் முயலுங்கள்.'),
                onRetry: () => setState(() => _room = _load()),
              );
            }
            final room = snap.data;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AphCard(
                  child: Column(
                    children: [
                      const CircleAvatar(
                        radius: 36,
                        backgroundColor: AphColors.primarySoft,
                        child: Icon(Icons.videocam_rounded,
                            size: 36, color: AphColors.primary),
                      ),
                      const Gap(AphSpace.md),
                      Text(
                        tr('Video call with ${widget.peerName}',
                            '${widget.peerName} உடன் வீடியோ அழைப்பு'),
                        style: t.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                      const Gap(AphSpace.xs),
                      Text(
                        tr('This room is private to you and ${widget.peerName}.',
                            'இந்த அறை உங்களுக்கும் ${widget.peerName} க்கும் மட்டுமே.'),
                        style: t.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const Gap(AphSpace.lg),
                      AphButton(
                        label: tr('Join video call', 'வீடியோ அழைப்பில் சேர்'),
                        icon: Icons.videocam_rounded,
                        loading: room == null || _joining,
                        onPressed: room == null ? null : () => _join(room),
                      ),
                      if (kIsWeb) ...[
                        const Gap(AphSpace.sm),
                        Text(
                          tr('The call opens in a new browser tab.',
                              'அழைப்பு புதிய உலாவி தாவலில் திறக்கும்.'),
                          style: t.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
                if (_error != null) ...[
                  const Gap(AphSpace.md),
                  FeedbackBanner(tone: FeedbackTone.error, title: _error!),
                ],
                const Gap(AphSpace.md),
                FeedbackBanner(
                  tone: FeedbackTone.info,
                  title: tr('Calls use Jitsi Meet, an open-source video service',
                      'அழைப்புகள் Jitsi Meet எனும் திறந்த மூல வீடியோ சேவையைப் பயன்படுத்துகின்றன'),
                  message: tr(
                      'Server: ${VideoRoom.serverHost}. Recording is turned off.',
                      'சேவையகம்: ${VideoRoom.serverHost}. பதிவு செய்தல் அணைக்கப்பட்டுள்ளது.'),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
