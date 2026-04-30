import 'package:aphora/logic/locator.dart';
import 'package:aphora/logic/speech_service.dart';
import 'package:aphora/ui/learning/letter_training_page.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class PhoneticTestPage extends StatefulWidget {
  const PhoneticTestPage({super.key});

  @override
  State<PhoneticTestPage> createState() => _PhoneticTestPageState();
}

class _PhoneticTestPageState extends State<PhoneticTestPage> {
  // Each task has a Tamil reference phrase, a romanized version, and
  // an audio asset for playback. We keep both transcriptions because
  // device STT engines are inconsistent — some return Tamil graphemes,
  // others romanise the speech, so we match against whichever scores
  // higher (same approach as the visual learning page).
  final List<Map<String, String>> _tasks = const [
    {
      'id': 'phonetic_vannakam',
      'title': 'Vanakkam',
      'titleTamil': 'வணக்கம்',
      'roman': 'vanakkam',
      'subtitle': 'Greeting in Tamil',
      'asset': 'assets/vannakam.wav',
      'language': 'ta-IN',
    },
    {
      'id': 'phonetic_saptirgala',
      'title': 'Saptirgala',
      'titleTamil': 'சாப்பிட்டீர்களா',
      'roman': 'saptittiirgala',
      'subtitle': 'Have you eaten?',
      'asset': 'assets/saptiya.wav',
      'language': 'ta-IN',
    },
    {
      'id': 'phonetic_epadi',
      'title': 'Epadi irukkindrirgal',
      'titleTamil': 'எப்படி இருக்கிறீர்கள்',
      'roman': 'eppadi irukkindrirgal',
      'subtitle': 'How are you?',
      'asset': 'assets/epdi.wav',
      'language': 'ta-IN',
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
                      expectedTamil: task['titleTamil']!,
                      expectedRoman: task['roman']!,
                      language: task['language'] ?? 'ta-IN',
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

  /// The phrase the patient is expected to say in Tamil script.
  final String expectedTamil;

  /// Romanised version of [expectedTamil]. Used as a second comparison
  /// target for STT engines that return Latin output for Tamil speech.
  final String expectedRoman;

  final String language;

  const PhoneticTaskDetailPage({
    super.key,
    required this.taskId,
    required this.title,
    required this.subtitle,
    required this.assetPath,
    required this.expectedTamil,
    required this.expectedRoman,
    this.language = 'ta-IN',
  });

  @override
  State<PhoneticTaskDetailPage> createState() => _PhoneticTaskDetailPageState();
}

class _PhoneticTaskDetailPageState extends State<PhoneticTaskDetailPage> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  late final SpeechService _speechService;

  bool _isPlaying = false;
  bool _isListening = false;
  bool _isEvaluating = false;
  PronunciationAnalysis? _result;
  String _spokenText = '';
  bool _heardSomething = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _speechService = SpeechService();
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
    _audioPlayer.dispose();
    _speechService.dispose();
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

  Future<void> _speakViaTts() async {
    await _speechService.speakText(
      widget.expectedTamil,
      language: widget.language,
    );
  }

  /// Run the analyzer against both the Tamil script and the romanised
  /// transliteration; return whichever scores higher. STT may emit
  /// either depending on locale availability.
  PronunciationAnalysis _bestAnalysis(String spoken) {
    final tamil = TextEvaluator.analyze(widget.expectedTamil, spoken);
    final roman = TextEvaluator.analyze(widget.expectedRoman, spoken);
    return tamil.similarity >= roman.similarity ? tamil : roman;
  }

  Future<void> _startListening() async {
    if (_isListening || _isEvaluating) return;

    setState(() {
      _isListening = true;
      _errorMessage = null;
      _result = null;
      _spokenText = '';
      _heardSomething = false;
    });

    try {
      final spoken = await _speechService.startListening(
        language: widget.language,
        maxDuration: 8,
      );
      if (!mounted) return;

      setState(() {
        _isListening = false;
        _isEvaluating = true;
        _spokenText = spoken;
        _heardSomething = spoken.trim().isNotEmpty;
      });

      // Empty STT response — usually means the patient was silent or
      // the mic permission/engine is misconfigured. Don't display 0%.
      if (!_heardSomething) {
        if (!mounted) return;
        setState(() {
          _isEvaluating = false;
          _result = null;
          _errorMessage =
              "We couldn't hear you. Make sure the mic is on and try again.";
        });
        return;
      }

      final result = _bestAnalysis(spoken);

      if (!mounted) return;
      setState(() {
        _isEvaluating = false;
        _result = result;
      });

      // Persist the attempt so it shows up on the homepage chart.
      await Locator.userDatabaseService.recordExerciseResult(
        taskId: widget.taskId,
        accuracy: result.similarity,
        fluency: result.similarity,
      );

      // Even ONE mispronounced letter triggers the targeted drill.
      if (result.needsTraining) {
        await Future.delayed(const Duration(milliseconds: 600));
        if (!mounted) return;
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => LetterTrainingPage(
              letters: result.mispronouncedLetters,
              // Use the script that scored higher (so we drill the
              // right alphabet — Tamil graphemes vs Latin letters).
              language: result.expectedNormalized == widget.expectedRoman
                  .toLowerCase()
                  .trim()
                  ? 'en-US'
                  : widget.language,
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isListening = false;
        _isEvaluating = false;
        _errorMessage = 'Failed to evaluate: $e';
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
              "Tap the microphone and say the phrase below:",
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
            const SizedBox(height: 6),
            Text(
              widget.expectedRoman,
              style: const TextStyle(
                fontSize: 16,
                fontStyle: FontStyle.italic,
                color: Colors.indigo,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              widget.subtitle,
              style: const TextStyle(fontSize: 18, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: _playReferenceAudio,
                  icon: Icon(
                    _isPlaying ? Icons.stop_circle : Icons.play_circle,
                    size: 48,
                    color: Colors.indigo,
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: _isEvaluating ? null : _speakViaTts,
                  icon: const Icon(
                    Icons.volume_up,
                    size: 40,
                    color: Colors.indigo,
                  ),
                ),
              ],
            ),
            const Text(
              "Reference audio  •  TTS",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const Spacer(),

            _buildResultPanel(),

            const SizedBox(height: 30),

            GestureDetector(
              onTap: _isEvaluating ? null : _startListening,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: _isListening ? 120 : 100,
                width: _isListening ? 120 : 100,
                decoration: BoxDecoration(
                  color: _isListening ? Colors.red : Colors.indigo,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (_isListening ? Colors.red : Colors.indigo)
                          .withOpacity(0.4),
                      blurRadius: 15,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(
                  _isListening ? Icons.graphic_eq : Icons.mic_none,
                  color: Colors.white,
                  size: 50,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _isEvaluating
                  ? "Analyzing your pronunciation..."
                  : _isListening
                      ? "Listening… speak now"
                      : "Tap to speak",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),
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
        child: Row(
          children: [
            const Icon(Icons.mic_off, color: Colors.deepOrange),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _errorMessage!,
                style: const TextStyle(fontSize: 14, color: Colors.deepOrange),
              ),
            ),
          ],
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
                isCorrect ? 'Great job!' : 'Let\'s practice',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: color,
                ),
              ),
              const Spacer(),
              Text(
                '${result.similarity.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: color,
                ),
              ),
            ],
          ),
          if (_spokenText.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'You said: "$_spokenText"',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ),
          if (result.mispronouncedLetters.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Practice these: ${result.mispronouncedLetters.take(8).join("  ")}',
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
