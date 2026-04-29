import 'package:flutter/material.dart';
import 'package:aphora/data/learning/question_data.dart';
import 'package:aphora/main.dart';
import 'package:aphora/ui/widgets/clinical_app_bar.dart';
import 'package:aphora/logic/speech_service.dart';

class MediumLevelPage extends StatefulWidget {
  final List<QuestionData>? questions;
  final String category;

  const MediumLevelPage({
    super.key,
    this.questions,
    this.category = "Medium Level - Image Description",
  });

  @override
  _MediumLevelPageState createState() => _MediumLevelPageState();
}

class _MediumLevelPageState extends State<MediumLevelPage> {
  late int currentIndex;
  late List<bool> answeredQuestions;
  late SpeechService _speechService;
  int score = 0;
  late List<QuestionData> questions;
  bool isListening = false;
  String spokenText = "";
  String lastRecognized = "";
  double accuracy = 0.0;
  bool showResult = false;

  @override
  void initState() {
    super.initState();
    currentIndex = 0;
    questions = widget.questions ?? allQuestions;
    answeredQuestions = List.filled(questions.length, false);
    _speechService = SpeechService();
  }

  @override
  void dispose() {
    _speechService.dispose();
    super.dispose();
  }

  void _startListening() async {
    try {
      setState(() {
        isListening = true;
        spokenText = "Listening...";
        showResult = false;
      });

      final recognized = await _speechService.startListening(
        language: 'ta-IN',
        maxDuration: 10,
      );

      if (mounted) {
        setState(() {
          lastRecognized = recognized;
        });
        _evaluateAnswer(recognized);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isListening = false;
          spokenText = "Error: ${e.toString()}";
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  void _evaluateAnswer(String spokenText) {
    final question = questions[currentIndex];
    
    // Calculate similarity with English phrase
    final accuracyEnglish = TextEvaluator.calculateSimilarity(
      question.englishPhrase.toLowerCase(),
      spokenText.toLowerCase(),
    );

    // Also check Tamil phrase for reference
    final accuracyTamil = TextEvaluator.calculateSimilarity(
      question.tamilPhrase.toLowerCase(),
      spokenText.toLowerCase(),
    );

    // Use the better of the two
    final finalAccuracy = accuracyEnglish > accuracyTamil ? accuracyEnglish : accuracyTamil;

    setState(() {
      this.spokenText = spokenText;
      accuracy = finalAccuracy;
      showResult = true;
      isListening = false;
    });

    if (finalAccuracy >= 70) {
      // Correct answer
      setState(() {
        score++;
        answeredQuestions[currentIndex] = true;
      });

      _showSuccessDialog(question, finalAccuracy);
    } else {
      _showRetryDialog(question, finalAccuracy);
    }
  }

  void _showSuccessDialog(QuestionData question, double accuracy) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Color(0xFF10B981)),
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
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              'The word is: "${question.englishPhrase}" (${question.tamilPhrase})',
              style: const TextStyle(fontWeight: FontWeight.w500, color: Color(0xFF10B981)),
            ),
            const SizedBox(height: 8),
            Text(
              'Accuracy: ${accuracy.toStringAsFixed(1)}%',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Text(
              '+1 Point',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF10B981),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _goToNextQuestion();
            },
            child: const Text('Next'),
          ),
        ],
      ),
    );
  }

  void _showRetryDialog(QuestionData question, double accuracy) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info, color: Color(0xFFF59E0B)),
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
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              'The word is: "${question.englishPhrase}" (${question.tamilPhrase})',
              style: const TextStyle(fontWeight: FontWeight.w500, color: Color(0xFF10B981)),
            ),
            const SizedBox(height: 8),
            Text(
              'Accuracy: ${accuracy.toStringAsFixed(1)}% (Need 70%)',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            const Text(
              'Listen carefully and try again!',
              style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                showResult = false;
                spokenText = "";
              });
            },
            child: const Text('Retry'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _goToNextQuestion();
            },
            child: const Text('Next'),
          ),
        ],
      ),
    );
  }

  void _goToNextQuestion() {
    if (currentIndex < questions.length - 1) {
      setState(() {
        currentIndex++;
        spokenText = "";
        lastRecognized = "";
        accuracy = 0.0;
        showResult = false;
      });
    } else {
      _showCompletionDialog();
    }
  }

  void _goToPreviousQuestion() {
    if (currentIndex > 0) {
      setState(() {
        currentIndex--;
        spokenText = "";
        lastRecognized = "";
        accuracy = 0.0;
        showResult = false;
      });
    }
  }

  void _showCompletionDialog() {
    final percentageScore = ((score / questions.length) * 100).toStringAsFixed(1);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.celebration, color: Color(0xFF10B981)),
            SizedBox(width: 8),
            Text('Session Complete!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Score: $score / ${questions.length}',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '$percentageScore% Accuracy',
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            if (score >= questions.length * 0.8)
              const Column(
                children: [
                  Icon(Icons.star, color: Color(0xFFF59E0B), size: 32),
                  SizedBox(height: 8),
                  Text(
                    'Excellent work!',
                    style: TextStyle(fontWeight: FontWeight.w500, color: Color(0xFF10B981)),
                  ),
                ],
              )
            else if (score >= questions.length * 0.6)
              const Column(
                children: [
                  Icon(Icons.thumb_up, color: Color(0xFF3B82F6), size: 32),
                  SizedBox(height: 8),
                  Text(
                    'Good effort! Keep practicing.',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              )
            else
              const Column(
                children: [
                  Icon(Icons.tips_and_updates, color: Color(0xFFF59E0B), size: 32),
                  SizedBox(height: 8),
                  Text(
                    'Keep practicing to improve!',
                    style: TextStyle(fontWeight: FontWeight.w500),
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
    final question = questions[currentIndex];
    final progressPercentage = ((currentIndex + 1) / questions.length) * 100;

    return Scaffold(
      appBar: const ClinicalAppBar(title: "Medium Level - Image Description"),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Progress Bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progress',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                      Text(
                        '${currentIndex + 1}/${questions.length}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: DuoColors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progressPercentage / 100,
                    minHeight: 10,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(DuoColors.green),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${progressPercentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Score Display
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF10B981), width: 1),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.star, color: Color(0xFF10B981), size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'Score: $score / ${questions.length}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Image Display - Large and Centered
              Container(
                height: 300,
                width: 300,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey[300]!, width: 2),
                ),
                child: Center(
                  child: _buildImageOrEmoji(question),
                ),
              ),
              const SizedBox(height: 40),

              // Instructions
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF3B82F6), width: 1),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Instructions:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3B82F6),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '1. Look at the image carefully\n2. Click the microphone button\n3. Say the name of the object\n4. Your answer will be compared with the correct word',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Spoken Text and Accuracy Display
              if (showResult && spokenText.isNotEmpty)
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: accuracy >= 70
                            ? const Color(0xFF10B981).withOpacity(0.1)
                            : const Color(0xFFF59E0B).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: accuracy >= 70
                              ? const Color(0xFF10B981)
                              : const Color(0xFFF59E0B),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                accuracy >= 70 ? Icons.check_circle : Icons.info,
                                color: accuracy >= 70
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFF59E0B),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                accuracy >= 70 ? 'Correct!' : 'Not quite right',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: accuracy >= 70
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFFF59E0B),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'You said: "$spokenText"',
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Expected: "${question.englishPhrase}" (${question.tamilPhrase})',
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                              color: Color(0xFF10B981),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Accuracy: ${accuracy.toStringAsFixed(1)}%',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              if (accuracy < 70)
                                const Text(
                                  'Need 70%',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),

              // Microphone Button
              GestureDetector(
                onTap: isListening ? null : _startListening,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: isListening ? Colors.orange : DuoColors.green,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (isListening ? Colors.orange : DuoColors.green)
                            .withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Center(
                    child: isListening
                        ? const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.mic, color: Colors.white, size: 48),
                              SizedBox(height: 4),
                              Text(
                                'Listening...',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          )
                        : const Icon(Icons.mic, color: Colors.white, size: 56),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Navigation Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Previous Button
                  ElevatedButton.icon(
                    onPressed: currentIndex > 0 ? _goToPreviousQuestion : null,
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Previous'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: currentIndex > 0 ? DuoColors.green : Colors.grey,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Next Button
                  ElevatedButton.icon(
                    onPressed: currentIndex < questions.length - 1
                        ? _goToNextQuestion
                        : _showCompletionDialog,
                    icon: Icon(currentIndex < questions.length - 1
                        ? Icons.arrow_forward
                        : Icons.check),
                    label: Text(currentIndex < questions.length - 1 ? 'Next' : 'Finish'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DuoColors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageOrEmoji(QuestionData question) {
    return Image.asset(
      question.imagePath,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        // Fallback - show emoji based on category
        String emoji = _getCategoryEmoji(question.category);
        return Center(
          child: Text(
            emoji,
            style: const TextStyle(fontSize: 120),
          ),
        );
      },
    );
  }

  String _getCategoryEmoji(String category) {
    final emojiMap = {
      'Basic Needs': '🍎',
      'People': '👤',
      'Actions': '🚶',
      'Body Parts': '🦾',
      'Common Objects': '🛏️',
    };
    return emojiMap[category] ?? '❓';
  }
}
