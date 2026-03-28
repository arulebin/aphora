import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;

class VideoCallPage extends StatefulWidget {
  final String channelName;

  const VideoCallPage({super.key, required this.channelName});

  @override
  State<VideoCallPage> createState() => _VideoCallPageState();
}

class _VideoCallPageState extends State<VideoCallPage> {
  late RtcEngine _engine;
  int? _remoteUid;
  bool _isAgoraSupported = false;
  String _errorMessage = '';

  final String appId = "20a8a131f3a74bf9ab55456cf33e22c2";

  @override
  void initState() {
    super.initState();
    initAgora();
  }

  bool _isWeb() {
    try {
      return !Platform.isAndroid && !Platform.isIOS && !Platform.isWindows && !Platform.isLinux && !Platform.isMacOS;
    } catch (e) {
      return true;
    }
  }

  Future<void> initAgora() async {
    try {
      // Agora RTC Engine is not supported on web platform
      if (_isWeb()) {
        setState(() {
          _errorMessage = 'Video calls are not supported on web platform. Please use mobile or desktop.';
          _isAgoraSupported = false;
        });
        return;
      }

      await [Permission.camera, Permission.microphone].request();

      _engine = createAgoraRtcEngine();
      await _engine.initialize(RtcEngineContext(appId: appId));
      
      setState(() {
        _isAgoraSupported = true;
      });

      _engine.registerEventHandler(
        RtcEngineEventHandler(
          onUserJoined: (connection, remoteUid, elapsed) {
            setState(() {
              _remoteUid = remoteUid;
            });
          },
          onUserOffline: (connection, remoteUid, reason) {
            setState(() {
              _remoteUid = null;
            });
          },
        ),
      );

      await _engine.enableVideo();
      await _engine.startPreview();

      await _engine.joinChannel(
        token: "",
        channelId: widget.channelName,
        uid: 0,
        options: const ChannelMediaOptions(),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Error initializing video call: ${e.toString()}';
        _isAgoraSupported = false;
      });
      print('Agora initialization error: $e');
    }
  }

  @override
  void dispose() {
    if (_isAgoraSupported) {
      try {
        _engine.leaveChannel();
        _engine.release();
      } catch (e) {
        print('Error disposing Agora engine: $e');
      }
    }
    super.dispose();
  }

  Widget _remoteVideo() {
    if (_remoteUid != null) {
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: _engine,
          canvas: VideoCanvas(uid: _remoteUid),
          connection: RtcConnection(channelId: widget.channelName),
        ),
      );
    } else {
      return const Center(child: Text("Waiting for user..."));
    }
  }

  Widget _localVideo() {
    return AgoraVideoView(
      controller: VideoViewController(
        rtcEngine: _engine,
        canvas: const VideoCanvas(uid: 0),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAgoraSupported && _errorMessage.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Video Call")),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.videocam_off, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Video Call")),
      body: _isAgoraSupported
          ? Stack(
              children: [
                _remoteVideo(),
                Positioned(
                  top: 20,
                  right: 20,
                  width: 120,
                  height: 160,
                  child: _localVideo(),
                ),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}