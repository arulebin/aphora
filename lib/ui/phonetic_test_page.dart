import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';

class PhoneticTestPage extends StatefulWidget {
  const PhoneticTestPage({Key? key}) : super(key: key);

  @override
  State<PhoneticTestPage> createState() => _PhoneticTestPageState();
}

class _PhoneticTestPageState extends State<PhoneticTestPage> {
  final List<Map<String, String>> _tasks = [
    {
      'title': 'Vanakkam',
      'titleTamil': 'வணக்கம்',
      'subtitle': 'Greeting in Tamil',
      'asset': 'assets/vannakam.wav',
    },
    {
      'title': 'Saptirgala',
      'titleTamil': 'சாப்பிட்டீர்களா',
      'subtitle': 'Have you eaten?',
      'asset': 'assets/saptiya.wav',
    },
    {
      'title': 'Epadi irukkindrirgal',
      'titleTamil': 'எப்படி இருக்கிறீர்கள்',
      'subtitle': 'How are you?',
      'asset': 'assets/epdi.wav',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Phonetic Sound Test'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _tasks.length,
        itemBuilder: (context, index) {
          final task = _tasks[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                backgroundColor: Colors.indigo.withOpacity(0.1),
                child: const Icon(
                  Icons.record_voice_over,
                  color: Colors.indigo,
                ),
              ),
              title: Text(
                task['titleTamil'] ?? task['title']!,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              subtitle: Text("${task['title']!} - ${task['subtitle']!}"),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PhoneticTaskDetailPage(
                      title: task['titleTamil'] ?? task['title']!,
                      subtitle: task['subtitle']!,
                      assetPath: task['asset']!,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class PhoneticTaskDetailPage extends StatefulWidget {
  final String title;
  final String subtitle;
  final String assetPath;

  const PhoneticTaskDetailPage({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.assetPath,
  }) : super(key: key);

  @override
  State<PhoneticTaskDetailPage> createState() => _PhoneticTaskDetailPageState();
}

class _PhoneticTaskDetailPageState extends State<PhoneticTaskDetailPage> {
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isRecording = false;
  bool _isPlaying = false;
  String? _recordedFilePath;
  bool _isTesting = false;
  String _resultMessage = '';

  @override
  void initState() {
    super.initState();
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playReferenceAudio() async {
    try {
      if (_isPlaying) {
        await _audioPlayer.stop();
      } else {
        await _audioPlayer.play(
          AssetSource(widget.assetPath.replaceFirst('assets/', '')),
        );
      }
    } catch (e) {
      print('Error playing audio: $e');
    }
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        String path = '';

        if (!kIsWeb) {
          final dir = await getApplicationDocumentsDirectory();
          path =
              '${dir.path}/user_audio_${DateTime.now().millisecondsSinceEpoch}.wav';
        }

        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.wav),
          path: path,
        );

        setState(() {
          _isRecording = true;
          _recordedFilePath = null;
          _resultMessage = '';
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission denied!')),
        );
      }
    } catch (e) {
      print('Error starting record: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
        _recordedFilePath = path;
      });

      if (path != null) {
        _uploadAndCompare(path);
      }
    } catch (e) {
      print('Error stopping record: $e');
    }
  }

  Future<void> _uploadAndCompare(String userAudioPath) async {
    setState(() {
      _isTesting = true;
      _resultMessage = 'Analyzing your pronunciation...';
    });

    try {
      final host = Platform.isAndroid ? "10.0.2.2" : "127.0.0.1";
      var uri = Uri.parse("http://$host:8000/compare-audio/");
      var request = http.MultipartRequest('POST', uri);

      // Load reference background API file
      final byteData = await rootBundle.load(widget.assetPath);
      final refBytes = byteData.buffer.asUint8List();

      request.files.add(
        http.MultipartFile.fromBytes(
          'audio_ref',
          refBytes,
          filename: 'ref.wav',
        ),
      );

      // User recorded audio
      if (kIsWeb) {
        final audioResponse = await http.get(Uri.parse(userAudioPath));
        request.files.add(
          http.MultipartFile.fromBytes(
            'audio_user',
            audioResponse.bodyBytes,
            filename: 'user_audio_${DateTime.now().millisecondsSinceEpoch}.wav',
          ),
        );
      } else {
        request.files.add(
          await http.MultipartFile.fromPath('audio_user', userAudioPath),
        );
      }

      var response = await request.send();
      var responseData = await response.stream.bytesToString();

      if (response.statusCode == 200 || response.statusCode == 422) {
        setState(() {
          _resultMessage = "Result: $responseData";
        });
      } else {
        setState(() {
          _resultMessage =
              "Error: API returned status ${response.statusCode}\n$responseData";
        });
      }
    } catch (e) {
      setState(() {
        _resultMessage = "Failed to evaluate: $e";
      });
    } finally {
      setState(() {
        _isTesting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Spacer(),
            const Text(
              "Press and hold the microphone to say the word below:",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              widget.subtitle,
              style: const TextStyle(fontSize: 20, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            IconButton(
              onPressed: _playReferenceAudio,
              icon: Icon(
                _isPlaying ? Icons.stop_circle : Icons.play_circle,
                size: 48,
                color: Colors.indigo,
              ),
            ),
            const Text(
              "Listen to reference",
              style: TextStyle(color: Colors.grey),
            ),
            const Spacer(),

            // Result Display
            if (_resultMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isTesting
                      ? Colors.blue.shade50
                      : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isTesting ? Colors.blue : Colors.green,
                  ),
                ),
                child: Text(
                  _resultMessage,
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),

            const SizedBox(height: 40),

            // Record Button
            GestureDetector(
              onLongPressStart: (_) => _startRecording(),
              onLongPressEnd: (_) => _stopRecording(),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: _isRecording ? 120 : 100,
                width: _isRecording ? 120 : 100,
                decoration: BoxDecoration(
                  color: _isRecording ? Colors.red : Colors.indigo,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (_isRecording ? Colors.red : Colors.indigo)
                          .withOpacity(0.4),
                      blurRadius: 15,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(
                  _isRecording ? Icons.mic : Icons.mic_none,
                  color: Colors.white,
                  size: 50,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _isRecording
                  ? "Recording... Release to submit"
                  : "Hold to Record",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
