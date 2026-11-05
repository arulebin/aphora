import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:aphora/ui/design/components.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// Private patient↔therapist video room.
///
/// Fixes from the old page: every call used one shared "demo_channel";
/// the Agora App ID was hard-coded; permission denials were ignored; the
/// engine leaked if you left early; and there were no call controls.
///
/// Configure with `--dart-define=AGORA_APP_ID=...` (and AGORA_TOKEN for
/// projects with certificates enabled).
class VideoCallPage extends StatefulWidget {
  const VideoCallPage({
    super.key,
    required this.channelName,
    this.peerName = 'your therapist',
  });

  final String channelName;
  final String peerName;

  @override
  State<VideoCallPage> createState() => _VideoCallPageState();
}

class _VideoCallPageState extends State<VideoCallPage> {
  static const _appId = String.fromEnvironment('AGORA_APP_ID');
  static const _token = String.fromEnvironment('AGORA_TOKEN');

  RtcEngine? _engine;
  int? _remoteUid;
  bool _joined = false;
  bool _muted = false;
  bool _cameraOff = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    if (kIsWeb) {
      setState(() => _error =
          'Video calls work in the Android and iOS app. Please open Vernacura on your phone.');
      return;
    }
    if (_appId.isEmpty) {
      setState(() => _error =
          'Video calling is not set up in this build yet. Ask the Vernacura team to add the video key.');
      return;
    }
    final perms = await [Permission.camera, Permission.microphone].request();
    if (perms.values.any((s) => !s.isGranted)) {
      if (mounted) {
        setState(() => _error =
            'Vernacura needs camera and microphone permission for video calls. '
            'Please allow both in your phone settings.');
      }
      return;
    }
    try {
      final engine = createAgoraRtcEngine();
      _engine = engine;
      await engine.initialize(const RtcEngineContext(appId: _appId));
      engine.registerEventHandler(RtcEngineEventHandler(
        onJoinChannelSuccess: (_, _) {
          if (mounted) setState(() => _joined = true);
        },
        onUserJoined: (_, uid, _) {
          if (mounted) setState(() => _remoteUid = uid);
        },
        onUserOffline: (_, _, _) {
          if (mounted) setState(() => _remoteUid = null);
        },
        onError: (err, msg) {
          if (mounted) setState(() => _error = 'Call error: $msg');
        },
      ));
      await engine.enableVideo();
      await engine.startPreview();
      await engine.joinChannel(
        token: _token,
        channelId: widget.channelName,
        uid: 0,
        options: const ChannelMediaOptions(),
      );
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not start the call. ($e)');
    }
  }

  @override
  void dispose() {
    final e = _engine;
    if (e != null) {
      e.leaveChannel().whenComplete(e.release);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    if (_error != null) {
      return AphScaffold(
        title: 'Video call',
        children: [
          EmptyState(
            icon: Icons.videocam_off_rounded,
            title: 'Video call unavailable',
            message: _error,
            action: AphButton.secondary(
              label: 'Go back',
              expand: false,
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      );
    }
    final engine = _engine;
    return Scaffold(
      backgroundColor: const Color(0xFF0E1A1F),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: engine != null && _remoteUid != null
                  ? AgoraVideoView(
                      controller: VideoViewController.remote(
                        rtcEngine: engine,
                        canvas: VideoCanvas(uid: _remoteUid),
                        connection: RtcConnection(channelId: widget.channelName),
                      ),
                    )
                  : Center(
                      child: Semantics(
                        liveRegion: true,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(color: Colors.white),
                            const Gap(AphSpace.md),
                            Text(
                              _joined
                                  ? 'Waiting for ${widget.peerName} to join…'
                                  : 'Connecting…',
                              style: t.titleMedium?.copyWith(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
            if (engine != null && !_cameraOff)
              Positioned(
                top: AphSpace.md,
                right: AphSpace.md,
                width: 110,
                height: 150,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AphRadius.md),
                  child: AgoraVideoView(
                    controller: VideoViewController(
                      rtcEngine: engine,
                      canvas: const VideoCanvas(uid: 0),
                    ),
                  ),
                ),
              ),
            Positioned(
              left: 0,
              right: 0,
              bottom: AphSpace.lg,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _CallButton(
                    icon: _muted ? Icons.mic_off_rounded : Icons.mic_rounded,
                    label: _muted ? 'Unmute' : 'Mute',
                    onTap: () {
                      setState(() => _muted = !_muted);
                      engine?.muteLocalAudioStream(_muted);
                    },
                  ),
                  _CallButton(
                    icon: Icons.call_end_rounded,
                    label: 'End call',
                    color: AphColors.danger,
                    onTap: () => Navigator.pop(context),
                  ),
                  _CallButton(
                    icon: _cameraOff
                        ? Icons.videocam_off_rounded
                        : Icons.videocam_rounded,
                    label: _cameraOff ? 'Camera on' : 'Camera off',
                    onTap: () {
                      setState(() => _cameraOff = !_cameraOff);
                      engine?.muteLocalVideoStream(_cameraOff);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CallButton extends StatelessWidget {
  const _CallButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = const Color(0x33FFFFFF),
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: color,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: SizedBox(
                width: 68,
                height: 68,
                child: Icon(icon, color: Colors.white, size: 32),
              ),
            ),
          ),
          const Gap(AphSpace.xs),
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}
