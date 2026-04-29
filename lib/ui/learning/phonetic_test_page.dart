import 'package:aphora/data/aphora_api_service.dart';
import 'package:aphora/logic/locator.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class PhoneticTestPage extends StatefulWidget {
  const PhoneticTestPage({super.key});

  @override
  State<PhoneticTestPage> createState() => _PhoneticTestPageState();
}

class _PhoneticTestPageState extends State<PhoneticTestPage> {
  final List<Map<String, String>> _tasks = const [
    {
      'id': 'phonetic_vannakam',
      'title': 'Vanakkam',
      'titleTamil': 'வணக்கம்',
      'subtitle': 'Greeting in Tamil',
      'asset': 'assets/vannakam.wav',
      'referenceText': 'vanakkam',
    },
    {
      'id': 'phonetic_saptirgala',
      'title': 'Saptirgala',
      'titleTamil': 'சாப்பிட்டீர்களா',
      'subtitle': 'Have you eaten?',
      'asset': 'assets/saptiya.wav',
      'referenceText': 'saptirgala',
    },
    {
      'id': 'phonetic_epadi',
      'title': 'Epadi irukkindrirgal',
      'titleTamil': 'எப்படி இருக்கிறீர்கள்',
      'subtitle': 'How are you?',
      'asset': 'assets/epdi.wav',
      'referenceText': 'epadi irukkindrirgal',
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
                      taskId: task['id']!,
                      title: task['titleTamil'] ?? task['title']!,
                      subtitle: task['subtitle']!,
                      assetPath: task['asset']!,
                      referenceText: task['referenceText'],
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
  final String taskId;
  final String title;
  final String subtitle;
  final String assetPath;
  final String? referenceText;

  const PhoneticTaskDetailPage({
    super.key,
    required this.taskId,
    required this.title,
    required this.subtitle,
    required this.assetPath,
    this.referenceText,
  });

  @override
  State<PhoneticTaskDetailPage> createState() => _PhoneticTaskDetailPageState();
}

class _PhoneticTaskDetailPageState extends State<PhoneticTaskDetailPage> {
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isRecording = false;
  bool _isPlaying = false;
  bool _isEvaluating = false;
  EvaluationResult? _result;
  String? _errorMessage;

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
      debugPrint('Error playing audio: $e');
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
          _result = null;
          _errorMessage = null;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission denied!')),
        );
      }
    } catch (e) {
      debugPrint('Error starting record: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
      });

      if (path != null) {
        await _evaluateRecording(path);
      }
    } catch (e) {
      debugPrint('Error stopping record: $e');
    }
  }

  Future<void> _evaluateRecording(String userAudioPath) async {
    setState(() {
      _isEvaluating = true;
      _errorMessage = null;
    });

    try {
      final result = await Locator.aphoraApiService.evaluateAgainstAsset(
        referenceAssetPath: widget.assetPath,
        userAudioPath: userAudioPath,
        referenceText: widget.referenceText,
      );

      if (!mounted) return;
      setState(() {
        _result = result;
      });

      // Persist progress for the logged-in patient.
      await Locator.userDatabaseService.recordExerciseResult(
        taskId: widget.taskId,
        accuracy: result.combinedAccuracy,
        fluency: result.audioSimilarity * 100,
      );
    } on AphoraApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to evaluate: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isEvaluating = false;
        });
      }
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

            _buildResultPanel(),

            const SizedBox(height: 40),

            GestureDetector(
              onLongPressStart: _isEvaluating ? null : (_) => _startRecording(),
              onLongPressEnd: _isEvaluating ? null : (_) => _stopRecording(),
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
              _isEvaluating
                  ? "Analyzing your pronunciation..."
                  : _isRecording
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

  Widget _buildResultPanel() {
    if (_isEvaluating) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Analyzing your pronunciation...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange),
        ),
        child: Text(
          _errorMessage!,
          style: const TextStyle(fontSize: 14, color: Colors.deepOrange),
          textAlign: TextAlign.center,
        ),
      );
    }

    final result = _result;
    if (result == null) return const SizedBox.shrink();

    final isCorrect = result.isCorrect;
    final color = isCorrect ? Colors.green : Colors.red;
    final bg = isCorrect ? Colors.green.shade50 : Colors.red.shade50;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCorrect ? Icons.check_circle : Icons.error_outline,
                color: color,
              ),
              const SizedBox(width: 8),
              Text(
                isCorrect ? 'Great job!' : 'Try again',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: color,
                ),
              ),
              const Spacer(),
              Text(
                '${result.combinedAccuracy.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            result.feedbackMessage,
            style: const TextStyle(fontSize: 14),
          ),
          if (result.userText != null && result.userText!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'You said: "${result.userText}"',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ],
      ),
    );
  }
}
