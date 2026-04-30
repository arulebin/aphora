import 'package:aphora/data/learning/question_data.dart';
import 'package:aphora/logic/locator.dart';
import 'package:aphora/logic/speech_service.dart';
import 'package:aphora/main.dart';
import 'package:aphora/ui/widgets/clinical_app_bar.dart';
import 'package:flutter/material.dart';

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

  int score = 0;
  bool _isListening = false;
  PronunciationAnalysis? _lastResult;

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
    super.dispose();
  }

  String get _languageCode =>
      widget.mode == VisualQuestionMode.hard ? 'en-US' : 'ta-IN';

  String _expectedFor(QuestionData q) =>
      widget.mode == VisualQuestionMode.hard ? q.englishPhrase : q.tamilPhrase;

  void _playAudio() async {
    final question = widget.questions[currentIndex];
    final text = _expectedFor(question);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Playing audio... Check your volume is on.'),
        duration: Duration(seconds: 1),
      ),
    );
    await _speechService.speakText(text, language: _languageCode);
  }

  Future<void> _startListening() async {
    final question = widget.questions[currentIndex];
    final expected = _expectedFor(question);

    setState(() {
      _isListening = true;
      _lastResult = null;
    });

    try {
      final spoken = await _speechService.startListening(
        language: _languageCode,
        maxDuration: 10,
      );
      if (!mounted) return;

      final result = TextEvaluator.analyze(expected, spoken);

      setState(() {
        _isListening = false;
        _lastResult = result;
      });

      if (result.isCorrect && !answeredQuestions[currentIndex]) {
        setState(() {
          score++;
          answeredQuestions[currentIndex] = true;
        });
      }

      // Persist the attempt for analytics regardless of outcome.
      await Locator.userDatabaseService.recordExerciseResult(
        taskId: 'q_${question.id}_${widget.mode.name}',
        accuracy: result.similarity,
        fluency: result.similarity,
      );

      if (!mounted) return;
      _showResultSnackbar(result);

      if (result.isCorrect) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) _goToNextQuestion();
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isListening = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _showResultSnackbar(PronunciationAnalysis result) {
    final ok = result.isCorrect;
    final missed = result.mispronouncedLetters.take(4).join(' ');
    final detail = ok
        ? 'Accuracy ${result.similarity.toStringAsFixed(1)}%'
        : missed.isEmpty
            ? 'Accuracy ${result.similarity.toStringAsFixed(1)}%'
            : 'Accuracy ${result.similarity.toStringAsFixed(1)}% — work on: $missed';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: ok ? const Color(0xFF10B981) : Colors.red,
        duration: const Duration(seconds: 3),
        content: Row(
          children: [
            Icon(
              ok ? Icons.check_circle : Icons.cancel,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ok ? 'Correct! +1 Point' : 'Try Again',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    detail,
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
      });
    }
  }

  void _goToPreviousQuestion() {
    if (currentIndex > 0) {
      setState(() {
        currentIndex--;
        _lastResult = null;
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

  Widget _buildResultCard(PronunciationAnalysis result) {
    final ok = result.isCorrect;
    final color = ok ? DuoColors.green : DuoColors.red;
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
                ok ? Icons.check_circle : Icons.error_outline,
                color: color,
              ),
              const SizedBox(width: 8),
              Text(
                ok ? 'Correct!' : 'Needs improvement',
                style: TextStyle(fontWeight: FontWeight.bold, color: color),
              ),
              const Spacer(),
              Text(
                '${result.similarity.toStringAsFixed(0)}%',
                style: TextStyle(fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
          if (result.actualNormalized.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'You said: "${result.actualNormalized}"',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ),
          if (result.mispronouncedLetters.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Work on: ${result.mispronouncedLetters.take(6).join(" ")}',
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
            onPressed: _isListening ? null : _playAudio,
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
          onPressed: _isListening ? null : _startListening,
          icon: Icon(_isListening ? Icons.graphic_eq : Icons.mic),
          label: Text(_isListening ? 'Listening…' : 'Record'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _isListening ? Colors.grey : Colors.red,
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
