import 'package:flutter/material.dart';
import 'package:aphora/data/learning/question_data.dart';
import 'package:aphora/main.dart';
import 'package:aphora/ui/widgets/clinical_app_bar.dart';
import 'package:aphora/logic/speech_service.dart';

class VisualQuestionPage extends StatefulWidget {
  final List<QuestionData> questions;
  final String category;

  const VisualQuestionPage({
    super.key,
    required this.questions,
    required this.category,
  });

  @override
  _VisualQuestionPageState createState() => _VisualQuestionPageState();
}

class _VisualQuestionPageState extends State<VisualQuestionPage> {
  late int currentIndex;
  late List<bool> answeredQuestions;
  late SpeechService _speechService;
  int score = 0;
  String lastSpokenText = "";
  double lastAccuracy = 0.0;
  bool showResult = false;

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

  void _playAudio() async {
    final question = widget.questions[currentIndex];
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Playing audio... Check your volume is on.'),
        duration: Duration(seconds: 1),
      ),
    );
    await _speechService.speakText(question.tamilPhrase, language: 'ta-IN');
  }

  void _startListening() async {
    try {
      print('DEBUG: Starting to listen for speech...');
      final recognized = await _speechService.startListening(
        language: 'ta-IN',
        maxDuration: 10,
      );

      print('DEBUG: Recognized text: "$recognized"');

      if (mounted) {
        // Evaluate the response
        _evaluateAnswer(recognized);
      }
    } catch (e) {
      print('DEBUG: Error in speech recognition: ${e.toString()}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _evaluateAnswer(String spokenText) {
    final question = widget.questions[currentIndex];
    
    print('DEBUG: Evaluating answer');
    print('DEBUG: Spoken text: "$spokenText"');
    print('DEBUG: Question English: "${question.englishPhrase}"');
    print('DEBUG: Question Tamil: "${question.tamilPhrase}"');
    
    // Compare with both English and Tamil phrases and use the better match
    final accuracyEnglish = TextEvaluator.calculateSimilarity(
      question.englishPhrase.toLowerCase(),
      spokenText.toLowerCase(),
    );
    
    final accuracyTamil = TextEvaluator.calculateSimilarity(
      question.tamilPhrase.toLowerCase(),
      spokenText.toLowerCase(),
    );

    print('DEBUG: Calculated accuracy (English): $accuracyEnglish%');
    print('DEBUG: Calculated accuracy (Tamil): $accuracyTamil%');
    
    // Use the better accuracy (max of the two)
    final accuracy = accuracyEnglish > accuracyTamil ? accuracyEnglish : accuracyTamil;
    
    print('DEBUG: Final accuracy (best match): $accuracy%');
    print('DEBUG: Is accuracy >= 70? ${accuracy >= 70}');

    setState(() {
      lastSpokenText = spokenText;
      lastAccuracy = accuracy;
      showResult = true;
    });

    if (accuracy >= 70) {
      print('DEBUG: Answer is CORRECT - checking if should award points');
      print('DEBUG: answeredQuestions[${currentIndex}] = ${answeredQuestions[currentIndex]}');
      
      // Correct answer - add 1 point
      if (!answeredQuestions[currentIndex]) {
        print('DEBUG: Awarding +1 point');
        setState(() {
          score++;
          answeredQuestions[currentIndex] = true;
        });
        print('DEBUG: New score: $score');
      } else {
        print('DEBUG: Question already answered - not awarding duplicate points');
      }

      // Show success dialog
      _showSuccessDialog(question, accuracy, spokenText);
    } else {
      print('DEBUG: Answer is INCORRECT');
      // Wrong answer - show retry dialog
      _showRetryDialog(question, accuracy, spokenText);
    }
  }

  void _showSuccessDialog(QuestionData question, double accuracy, String spokenText) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Color(0xFF10B981), size: 28),
            SizedBox(width: 8),
            Text('Correct!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You said: "$spokenText"',
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Text(
              'The word is: "${question.englishPhrase}" (${question.tamilPhrase})',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: Color(0xFF10B981),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Accuracy:', style: TextStyle(fontWeight: FontWeight.w500)),
                  Text(
                    '${accuracy.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF10B981),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Icon(Icons.star, color: Color(0xFF10B981)),
                  const SizedBox(width: 8),
                  Text(
                    '+1 Point',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF10B981),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Future.delayed(const Duration(milliseconds: 300), () {
                if (mounted) {
                  _goToNextQuestion();
                }
              });
            },
            child: const Text('Next Question'),
          ),
        ],
      ),
    );
  }

  void _showRetryDialog(QuestionData question, double accuracy, String spokenText) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info, color: Color(0xFFF59E0B), size: 28),
            SizedBox(width: 8),
            Text('Try Again'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You said: "$spokenText"',
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Text(
              'Expected: "${question.englishPhrase}" (${question.tamilPhrase})',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: Color(0xFF10B981),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Accuracy:', style: TextStyle(fontWeight: FontWeight.w500)),
                  Text(
                    '${accuracy.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFF59E0B),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.trending_up, color: Colors.grey),
                  SizedBox(width: 8),
                  Text(
                    'Need 70% to pass',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                showResult = false;
                lastSpokenText = "";
              });
            },
            child: const Text('Retry'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Future.delayed(const Duration(milliseconds: 300), () {
                if (mounted) {
                  _goToNextQuestion();
                }
              });
            },
            child: const Text('Skip'),
          ),
        ],
      ),
    );
  }

  void _goToNextQuestion() {
    if (currentIndex < widget.questions.length - 1) {
      setState(() {
        answeredQuestions[currentIndex] = true;
        currentIndex++;
        showResult = false;
        lastSpokenText = "";
      });
    } else {
      _showCompletionDialog();
    }
  }

  void _goToPreviousQuestion() {
    if (currentIndex > 0) {
      setState(() {
        currentIndex--;
        showResult = false;
        lastSpokenText = "";
      });
    }
  }

  void _showCompletionDialog() {
    final percentageScore = ((score / widget.questions.length) * 100).toStringAsFixed(1);
    final correctAnswers = answeredQuestions.where((a) => a).length;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.celebration, color: Color(0xFF10B981), size: 28),
            SizedBox(width: 8),
            Text('Session Complete!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Score Display
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    'Score: $score / ${widget.questions.length}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$percentageScore% Accuracy',
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Performance Breakdown
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 32),
                      const SizedBox(height: 8),
                      Text(
                        correctAnswers.toString(),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text('Correct', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  Column(
                    children: [
                      Icon(
                        Icons.cancel,
                        color: const Color(0xFFEF4444),
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        (widget.questions.length - correctAnswers).toString(),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text('Incorrect', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Performance Badge
            if (double.parse(percentageScore) >= 80)
              Column(
                children: [
                  const Icon(Icons.star, color: Color(0xFFF59E0B), size: 40),
                  const SizedBox(height: 8),
                  const Text(
                    'Excellent Performance! 🎉',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF10B981),
                      fontSize: 14,
                    ),
                  ),
                ],
              )
            else if (double.parse(percentageScore) >= 60)
              Column(
                children: [
                  const Icon(Icons.thumb_up, color: Color(0xFF3B82F6), size: 40),
                  const SizedBox(height: 8),
                  const Text(
                    'Good effort! Keep practicing.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              )
            else
              Column(
                children: [
                  const Icon(Icons.lightbulb, color: Color(0xFFF59E0B), size: 40),
                  const SizedBox(height: 8),
                  const Text(
                    'Keep practicing to improve!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Finish'),
          ),
        ],
      ),
    );
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
              // Score Display
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

              // Progress Indicator
              _buildProgressIndicator(progress),
              const SizedBox(height: 30),

              // Question Counter
              Text(
                'Question ${currentIndex + 1} of ${widget.questions.length}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: DuoColors.textLight,
                ),
              ),
              const SizedBox(height: 20),

              // Large Image Display
              _buildImageDisplay(question),
              const SizedBox(height: 40),

              // English Phrase
              Text(
                question.englishPhrase,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: DuoColors.text,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Tamil Phrase
              Text(
                question.tamilPhrase,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: DuoColors.blue,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Difficulty Badge
              _buildDifficultyBadge(question.difficulty),
              const SizedBox(height: 40),

              // Audio and Microphone Control Buttons
              _buildControlButtons(),
              const SizedBox(height: 30),

              // Navigation Buttons
              _buildNavigationButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Audio Button - Hear the Tamil pronunciation
        ElevatedButton.icon(
          onPressed: _playAudio,
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

        // Microphone Button - Record user's speech
        ElevatedButton.icon(
          onPressed: _startListening,
          icon: const Icon(Icons.mic),
          label: const Text('Record'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
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
        SizedBox(height: 12),
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
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: _buildImageContent(question),
      ),
    );
  }

  Widget _buildImageContent(QuestionData question) {
    // Try to load from assets, if fails show placeholder
    try {
      return Image.asset(
        question.imagePath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildImagePlaceholder(question);
        },
      );
    } catch (e) {
      return _buildImagePlaceholder(question);
    }
  }

  Widget _buildImagePlaceholder(QuestionData question) {
    // Fallback UI with emoji/icon representation
    final icons = {
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
        child: Text(
          icon,
          style: TextStyle(fontSize: 100),
        ),
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
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
        // Previous Button
        ElevatedButton.icon(
          onPressed: currentIndex > 0 ? _goToPreviousQuestion : null,
          icon: Icon(Icons.arrow_back),
          label: Text('Previous'),
          style: ElevatedButton.styleFrom(
            backgroundColor: currentIndex > 0 ? DuoColors.green : Colors.grey,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        // Next Button
        ElevatedButton.icon(
          onPressed:
              currentIndex < widget.questions.length - 1 ? _goToNextQuestion : null,
          icon: Icon(Icons.arrow_forward),
          label: Text('Next'),
          style: ElevatedButton.styleFrom(
            backgroundColor:
                currentIndex < widget.questions.length - 1 ? DuoColors.green : Colors.grey,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}
