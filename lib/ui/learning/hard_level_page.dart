import 'package:flutter/material.dart';
import 'package:aphora/logic/speech_service.dart';
import 'package:aphora/data/learning/sentence_data.dart';
import 'package:aphora/ui/widgets/clinical_app_bar.dart';

class HardLevelPage extends StatefulWidget {
  const HardLevelPage({Key? key}) : super(key: key);

  @override
  State<HardLevelPage> createState() => _HardLevelPageState();
}

class _HardLevelPageState extends State<HardLevelPage> {
  late SpeechService _speechService;
  late List<SentenceData> sentences;
  int currentIndex = 0;
  int score = 0;
  bool isRecording = false;
  bool showResult = false;
  String lastSpokenText = '';
  double lastAccuracy = 0.0;
  List<int> answeredQuestions = [];

  @override
  void initState() {
    super.initState();
    _speechService = SpeechService();
    sentences = getAllSentences();
  }

  SentenceData get currentSentence => sentences[currentIndex];

  void _startListening() async {
    if (!isRecording) {
      setState(() {
        isRecording = true;
        showResult = false;
        lastSpokenText = '';
        lastAccuracy = 0.0;
      });

      final result = await _speechService.startListening(language: 'en-IN');
      if (result.isNotEmpty) {
        setState(() {
          lastSpokenText = result;
          isRecording = false;
        });
        _evaluateAnswer(result);
      } else {
        setState(() {
          isRecording = false;
        });
      }
    }
  }

  void _evaluateAnswer(String spokenText) {
    // Compare with both English and Tamil sentences
    final accuracyEnglish = TextEvaluator.calculateSimilarity(
      currentSentence.englishSentence.toLowerCase(),
      spokenText.toLowerCase(),
    );
    final accuracyTamil = TextEvaluator.calculateSimilarity(
      currentSentence.tamilSentence.toLowerCase(),
      spokenText.toLowerCase(),
    );

    // Use the better accuracy score
    final accuracy = accuracyEnglish > accuracyTamil ? accuracyEnglish : accuracyTamil;

    debugPrint('Spoken: "$spokenText"');
    debugPrint('English Accuracy: $accuracyEnglish');
    debugPrint('Tamil Accuracy: $accuracyTamil');
    debugPrint('Final Accuracy: $accuracy');

    setState(() {
      lastAccuracy = accuracy;
      showResult = true;
    });

    // Lower threshold for sentences (60% instead of 70%)
    if (accuracy >= 0.60) {
      if (!answeredQuestions.contains(currentIndex)) {
        setState(() {
          score++;
          answeredQuestions.add(currentIndex);
        });
      }
      _showSuccessDialog(accuracy);
    } else {
      _showRetryDialog(accuracy);
    }
  }

  void _showSuccessDialog(double accuracy) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 32),
            SizedBox(width: 12),
            Text('Excellent!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You said it correctly!',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Accuracy: ${(accuracy * 100).toStringAsFixed(1)}%',
                    style: TextStyle(fontSize: 14),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'You said: "$lastSpokenText"',
                    style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Should be: "${currentSentence.englishSentence}"',
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Icon(Icons.star, color: Colors.amber, size: 24),
                  SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '+1 Mark',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      Text(
                        'Total: $score/${sentences.length}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                    ],
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
              _nextQuestion();
            },
            child: Text('Next'),
          ),
        ],
      ),
    );
  }

  void _showRetryDialog(double accuracy) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info, color: Colors.orange, size: 32),
            SizedBox(width: 12),
            Text('Try Again'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Not quite right. Let\'s try again!',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Accuracy: ${(accuracy * 100).toStringAsFixed(1)}%',
                    style: TextStyle(fontSize: 14),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'You said: "$lastSpokenText"',
                    style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Should be: "${currentSentence.englishSentence}"',
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      'Tamil: ${currentSentence.tamilSentence}',
                      style: TextStyle(fontSize: 12, color: Colors.blue[900]),
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
                lastSpokenText = '';
                lastAccuracy = 0.0;
              });
            },
            child: Text('Try Again'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _nextQuestion();
            },
            child: Text('Next'),
          ),
        ],
      ),
    );
  }

  void _showCompletionDialog() {
    final percentage = ((score / sentences.length) * 100).toStringAsFixed(1);
    String badge = '';
    Color badgeColor = Colors.grey;

    if (score == sentences.length) {
      badge = '🏆 Perfect!';
      badgeColor = Colors.amber;
    } else if (score >= (sentences.length * 0.8)) {
      badge = '🌟 Excellent!';
      badgeColor = Colors.green;
    } else if (score >= (sentences.length * 0.6)) {
      badge = '👍 Good!';
      badgeColor = Colors.blue;
    } else if (score >= (sentences.length * 0.4)) {
      badge = '📚 Keep Practicing!';
      badgeColor = Colors.orange;
    } else {
      badge = '💪 Keep Trying!';
      badgeColor = Colors.red;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Session Complete!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: badgeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: badgeColor, width: 2),
              ),
              child: Column(
                children: [
                  Text(
                    badge,
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Your Score',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '$score/${sentences.length}',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: badgeColor,
                    ),
                  ),
                  Text(
                    '$percentage%',
                    style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Great effort! You completed the Hard Level.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text('Finish'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetSession();
            },
            child: Text('Try Again'),
          ),
        ],
      ),
    );
  }

  void _nextQuestion() {
    if (currentIndex < sentences.length - 1) {
      setState(() {
        currentIndex++;
        showResult = false;
        lastSpokenText = '';
        lastAccuracy = 0.0;
      });
    } else {
      _showCompletionDialog();
    }
  }

  void _resetSession() {
    setState(() {
      currentIndex = 0;
      score = 0;
      answeredQuestions = [];
      showResult = false;
      lastSpokenText = '';
      lastAccuracy = 0.0;
    });
  }

  @override
  void dispose() {
    _speechService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ClinicalAppBar(title: 'Hard Level - Sentences'),
      body: Column(
        children: [
          // Progress bar
          Container(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Question ${currentIndex + 1}/${sentences.length}',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      'Score: $score',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                LinearProgressIndicator(
                  value: (currentIndex + 1) / sentences.length,
                  minHeight: 8,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              ],
            ),
          ),
          // Main content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  // Instructions
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue, width: 1),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue, size: 24),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Listen to the sentence and speak it clearly into the microphone.',
                            style: TextStyle(fontSize: 13, color: Colors.blue[900]),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),

                  // English sentence
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'English',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          currentSentence.englishSentence,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),

                  // Tamil sentence
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange[300]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tamil',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange[900],
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          currentSentence.tamilSentence,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[900],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),

                  // Result display (if available)
                  if (showResult)
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: lastAccuracy >= 0.60
                            ? Colors.green.withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                lastAccuracy >= 0.60
                                    ? Icons.check_circle
                                    : Icons.info,
                                color: lastAccuracy >= 0.60
                                    ? Colors.green
                                    : Colors.orange,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Accuracy: ${(lastAccuracy * 100).toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: lastAccuracy >= 0.60
                                      ? Colors.green[900]
                                      : Colors.orange[900],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            'You said: "$lastSpokenText"',
                            style: TextStyle(
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  SizedBox(height: 24),

                  // Microphone button
                  Container(
                    alignment: Alignment.center,
                    child: GestureDetector(
                      onTap: isRecording ? null : _startListening,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isRecording ? Colors.red : Colors.blue,
                          boxShadow: [
                            BoxShadow(
                              color: (isRecording ? Colors.red : Colors.blue)
                                  .withOpacity(0.4),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            isRecording ? Icons.mic : Icons.mic_none,
                            color: Colors.white,
                            size: 50,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    isRecording ? 'Listening...' : 'Tap to speak',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
