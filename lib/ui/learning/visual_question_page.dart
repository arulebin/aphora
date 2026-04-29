import 'dart:io' show File;

import 'package:aphora/data/aphora_api_service.dart';
import 'package:aphora/data/learning/question_data.dart';
import 'package:aphora/logic/locator.dart';
import 'package:aphora/logic/speech_service.dart';
import 'package:aphora/main.dart';
import 'package:aphora/ui/widgets/clinical_app_bar.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// How the question is presented to the patient.
///
/// * [easy]   – image + Tamil text + audio playback. Lowest cognitive load.
/// * [medium] – image only; the patient has to name the object themselves.
/// * [hard]   – English-only sentence prompt; no Tamil scaffolding.
enum VisualQuestionMode { easy, medium, hard }

class VisualQuestionPage extends StatefulWidget {
  final List<QuestionData> questions;
  final String category;
  final VisualQuestionMode mode;

  const VisualQuestionPage({
    super.key,
    required this.questions,
    required this.category,
    this.mode = VisualQuestionMode.easy,
  });

  @override
  State<VisualQuestionPage> createState() => _VisualQuestionPageState();
}

class _VisualQuestionPageState extends State<VisualQuestionPage> {
  late int currentIndex;
  late List<bool> answeredQuestions;
  late SpeechService _speechService;
  final AudioRecorder _recorder = AudioRecorder();

  int score = 0;
  bool _isRecording = false;
  bool _isEvaluating = false;
  EvaluationResult? _lastResult;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    currentIndex = 0;
    answeredQuestions = List.filled(widget.questions.length, false);
    _speechService = SpeechService();
  }

  @override
  void dispose() {
    _speechService.dispose();
    _recorder.dispose();
    super.dispose();
  }

  void _playAudio() async {
    final question = widget.questions[currentIndex];
    final text = widget.mode == VisualQuestionMode.hard
        ? question.englishPhrase
        : question.tamilPhrase;
    final language =
        widget.mode == VisualQuestionMode.hard ? 'en-US' : 'ta-IN';
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Playing audio... Check your volume is on.'),
        duration: Duration(seconds: 1),
      ),
    );
    await _speechService.speakText(text, language: language);
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      await _stopRecordingAndEvaluate();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    try {
      if (!await _recorder.hasPermission()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Microphone permission denied.')),
          );
        }
        return;
      }
      String path = '';
      if (!kIsWeb) {
        final dir = await getApplicationDocumentsDirectory();
        path =
            '${dir.path}/visual_q_${DateTime.now().millisecondsSinceEpoch}.wav';
      }

      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.wav),
        path: path,
      );

      setState(() {
        _isRecording = true;
        _lastResult = null;
        _errorMessage = null;
      });
    } catch (e) {
      debugPrint('Error starting recording: $e');
    }
  }

  Future<void> _stopRecordingAndEvaluate() async {
    String? path;
    try {
      path = await _recorder.stop();
    } catch (e) {
      debugPrint('Error stopping recorder: $e');
    }

    setState(() {
      _isRecording = false;
    });

    if (path == null) return;
    await _evaluateRecording(path);
  }

  Future<void> _evaluateRecording(String userAudioPath) async {
    final question = widget.questions[currentIndex];
    setState(() {
      _isEvaluating = true;
      _errorMessage = null;
    });

    try {
      final result = await _evaluateUserAudio(question, userAudioPath);
      if (!mounted) return;

      setState(() {
        _lastResult = result;
      });

      final isCorrect = result.isCorrect;
      if (isCorrect && !answeredQuestions[currentIndex]) {
        setState(() {
          score++;
          answeredQuestions[currentIndex] = true;
        });
      }

      // Persist for the logged-in patient (every attempt feeds analytics).
      await Locator.userDatabaseService.recordExerciseResult(
        taskId: 'q_${question.id}_${widget.mode.name}',
        accuracy: result.combinedAccuracy,
        fluency: result.audioSimilarity * 100,
      );

      if (!mounted) return;
      _showResultSnackbar(result);

      if (isCorrect) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) _goToNextQuestion();
        });
      }
    } on AphoraApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('API error: ${e.message}')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isEvaluating = false;
        });
      }
    }
  }

  /// Sends the user audio to the Aphora API for scoring.
  ///
  /// We try to synthesize a reference clip via TTS; that gives the
  /// API both an audio-level signal (WavLM/DTW) and a text-level
  /// signal (Wav2Vec2 CTC + CER/WER). If TTS-to-file isn't available
  /// (e.g. on web), we fall back to sending the user audio as both
  /// reference and user — audio similarity is then meaningless but
  /// the text-level CER score is what catches a wrong answer.
  Future<EvaluationResult> _evaluateUserAudio(
    QuestionData question,
    String userAudioPath,
  ) async {
    final referenceText = widget.mode == VisualQuestionMode.hard
        ? question.englishPhrase
        : question.tamilPhrase;
    final language =
        widget.mode == VisualQuestionMode.hard ? 'en-US' : 'ta-IN';

    final refPath = await _speechService.synthesizeToFile(
      referenceText,
      language: language,
    );

    List<int> refBytes;
    if (refPath != null && !kIsWeb) {
      refBytes = await File(refPath).readAsBytes();
    } else if (!kIsWeb) {
      refBytes = await File(userAudioPath).readAsBytes();
    } else {
      // Web: AphoraApiService handles the user blob; for the reference
      // we re-use the same blob URL (audio similarity becomes trivial
      // but text similarity from the user's transcription still scores
      // whether they said the right word).
      throw AphoraApiException(
        'TTS-to-file is not available on web yet. Please run on mobile.',
      );
    }

    return Locator.aphoraApiService.evaluate(
      referenceBytes: refBytes,
      referenceFilename: 'ref.wav',
      userAudioPath: userAudioPath,
      referenceText: referenceText,
    );
  }

  void _showResultSnackbar(EvaluationResult result) {
    final isCorrect = result.isCorrect;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isCorrect ? const Color(0xFF10B981) : Colors.red,
        duration: const Duration(seconds: 3),
        content: Row(
          children: [
            Icon(
              isCorrect ? Icons.check_circle : Icons.cancel,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isCorrect ? 'Correct! +1 Point' : 'Try Again (need 70%)',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${result.combinedAccuracy.toStringAsFixed(1)}% — ${result.feedbackMessage}',
                    style: const TextStyle(color: Colors.white70),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _goToNextQuestion() {
    if (currentIndex < widget.questions.length - 1) {
      setState(() {
        answeredQuestions[currentIndex] = true;
        currentIndex++;
        _lastResult = null;
        _errorMessage = null;
      });
    }
  }

  void _goToPreviousQuestion() {
    if (currentIndex > 0) {
      setState(() {
        currentIndex--;
        _lastResult = null;
        _errorMessage = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.questions[currentIndex];
    final progress = (currentIndex + 1) / widget.questions.length;

    return Scaffold(
      backgroundColor: DuoColors.surface,
      appBar: ClinicalAppBar(title: widget.category),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: DuoColors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Score: $score',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: DuoColors.green,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildProgressIndicator(progress),
              const SizedBox(height: 30),
              Text(
                'Question ${currentIndex + 1} of ${widget.questions.length}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: DuoColors.textLight,
                ),
              ),
              const SizedBox(height: 20),
              _buildImageDisplay(question),
              const SizedBox(height: 24),
              ..._buildPromptForMode(question),
              const SizedBox(height: 12),
              _buildDifficultyBadge(question.difficulty),
              const SizedBox(height: 32),
              _buildControlButtons(),
              const SizedBox(height: 16),
              if (_isEvaluating)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 10),
                      Text('Evaluating with Aphora API...'),
                    ],
                  ),
                ),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),
              if (_lastResult != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: _buildResultCard(_lastResult!),
                ),
              const SizedBox(height: 24),
              _buildNavigationButtons(),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildPromptForMode(QuestionData question) {
    switch (widget.mode) {
      case VisualQuestionMode.easy:
        return [
          Text(
            question.tamilPhrase,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: DuoColors.blue,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            question.englishPhrase,
            style: TextStyle(
              fontSize: 18,
              color: DuoColors.textLight,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ];
      case VisualQuestionMode.medium:
        return [
          Text(
            'Name the object you see',
            style: TextStyle(
              fontSize: 18,
              color: DuoColors.text,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ];
      case VisualQuestionMode.hard:
        return [
          Text(
            'Say this aloud:',
            style: TextStyle(
              fontSize: 16,
              color: DuoColors.textLight,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            question.englishPhrase,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: DuoColors.text,
            ),
            textAlign: TextAlign.center,
          ),
        ];
    }
  }

  Widget _buildResultCard(EvaluationResult result) {
    final isCorrect = result.isCorrect;
    final color = isCorrect ? DuoColors.green : DuoColors.red;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
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
                isCorrect ? 'Correct!' : 'Needs improvement',
                style: TextStyle(fontWeight: FontWeight.bold, color: color),
              ),
              const Spacer(),
              Text(
                '${result.combinedAccuracy.toStringAsFixed(0)}%',
                style: TextStyle(fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(result.feedbackMessage, style: const TextStyle(fontSize: 13)),
          if (result.userText != null && result.userText!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'You said: "${result.userText}"',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildControlButtons() {
    final showHearButton = widget.mode == VisualQuestionMode.easy;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        if (showHearButton)
          ElevatedButton.icon(
            onPressed: _isEvaluating ? null : _playAudio,
            icon: const Icon(Icons.volume_up),
            label: const Text('Hear'),
            style: ElevatedButton.styleFrom(
              backgroundColor: DuoColors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ElevatedButton.icon(
          onPressed: _isEvaluating ? null : _toggleRecording,
          icon: Icon(_isRecording ? Icons.stop : Icons.mic),
          label: Text(_isRecording ? 'Stop' : 'Record'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _isRecording ? Colors.grey : Colors.red,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressIndicator(double progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: DuoColors.text,
              ),
            ),
            Text(
              '${(progress * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: DuoColors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 10,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(DuoColors.green),
          ),
        ),
      ],
    );
  }

  Widget _buildImageDisplay(QuestionData question) {
    return Container(
      width: 280,
      height: 280,
      decoration: BoxDecoration(
        color: DuoColors.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.asset(
          question.imagePath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _buildImagePlaceholder(question),
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder(QuestionData question) {
    const icons = {
      'Water': '💧',
      'Food': '🍽️',
      'Child': '👶',
      'Drink': '🥤',
      'Medicine': '💊',
      'Tablet': '⏱️',
      'Sleep': '😴',
      'Sitting': '🪑',
      'Milk': '🥛',
      'Soup': '🍲',
      'Woman': '👩',
      'Man': '👨',
      'Boy': '👦',
      'Girl': '👧',
      'Sister': '👧',
      'Brother': '👦',
      'Doctor': '👨‍⚕️',
      'Nurse': '👩‍⚕️',
      'Walk': '🚶',
      'Go': '🏃',
      'Come': '🤸',
      'Eat': '🍴',
      'Help': '🤝',
      'Yes': '✅',
      'No': '❌',
      'Hello': '👋',
      'Thank you': '🙏',
      'Please': '🙏',
      'Head': '🗣️',
      'Hand': '✋',
      'Foot': '🦶',
      'Eye': '👁️',
      'Mouth': '👄',
      'Nose': '👃',
      'Thumb': '👍',
      'Arm': '💪',
      'Bed': '🛏️',
      'Cup': '☕',
      'Plate': '🍽️',
      'Book': '📖',
      'Door': '🚪',
      'Window': '🪟',
      'Happy': '😊',
      'Sad': '😢',
      'Pain': '😩',
      'Tired': '😴',
      'Angry': '😠',
      'Cold': '🥶',
      'Hot': '🔥',
      'Scared': '😨',
    };

    final icon = icons[question.englishPhrase] ?? '❓';

    return Container(
      color: DuoColors.blue.withOpacity(0.1),
      child: Center(
        child: Text(icon, style: const TextStyle(fontSize: 100)),
      ),
    );
  }

  Widget _buildDifficultyBadge(String difficulty) {
    Color bgColor;
    Color textColor;

    switch (difficulty) {
      case 'Easy':
        bgColor = DuoColors.green.withOpacity(0.15);
        textColor = DuoColors.green;
        break;
      case 'Medium':
        bgColor = DuoColors.yellow.withOpacity(0.15);
        textColor = DuoColors.yellow;
        break;
      case 'Hard':
        bgColor = DuoColors.red.withOpacity(0.15);
        textColor = DuoColors.red;
        break;
      default:
        bgColor = Colors.grey.withOpacity(0.15);
        textColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        difficulty,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton.icon(
          onPressed: currentIndex > 0 ? _goToPreviousQuestion : null,
          icon: const Icon(Icons.arrow_back),
          label: const Text('Previous'),
          style: ElevatedButton.styleFrom(
            backgroundColor: currentIndex > 0 ? DuoColors.green : Colors.grey,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        ElevatedButton.icon(
          onPressed: currentIndex < widget.questions.length - 1
              ? _goToNextQuestion
              : null,
          icon: const Icon(Icons.arrow_forward),
          label: const Text('Next'),
          style: ElevatedButton.styleFrom(
            backgroundColor: currentIndex < widget.questions.length - 1
                ? DuoColors.green
                : Colors.grey,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}
