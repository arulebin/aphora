import 'package:aphora/data/models/pre_assessment_model.dart';
import 'package:aphora/logic/speech_service.dart';
import 'package:aphora/main.dart';
import 'package:flutter/material.dart';

class PreAssessmentTestPage extends StatefulWidget {
  const PreAssessmentTestPage({super.key});

  @override
  State<PreAssessmentTestPage> createState() => _PreAssessmentTestPageState();
}

class _PreAssessmentTestPageState extends State<PreAssessmentTestPage> {
  late SpeechService _speechService;
  late List<PreAssessmentQuestion> _questions;
  late TextEditingController _spellingController;

  int _currentQuestionIndex = 0;
  List<PreAssessmentResult> _results = [];
  bool _isListening = false;
  String _recognizedText = '';
  bool _showResult = false;
  double _currentAccuracy = 0.0;

  // Tamil test data with different difficulty levels
  final List<Map<String, dynamic>> _tamilLetters = [
    {'tamil': 'அ', 'english': 'A'},
    {'tamil': 'ஆ', 'english': 'AA'},
    {'tamil': 'இ', 'english': 'I'},
    {'tamil': 'ஈ', 'english': 'II'},
    {'tamil': 'உ', 'english': 'U'},
    {'tamil': 'ஊ', 'english': 'UU'},
    {'tamil': 'எ', 'english': 'E'},
    {'tamil': 'ஏ', 'english': 'EE'},
    {'tamil': 'ஐ', 'english': 'AI'},
    {'tamil': 'ஒ', 'english': 'O'},
  ];

  final List<Map<String, dynamic>> _tamilWords = [
    {'tamil': 'மல்லி', 'english': 'Jasmine'},
    {'tamil': 'பூ', 'english': 'Flower'},
    {'tamil': 'மரம்', 'english': 'Tree'},
    {'tamil': 'பூனை', 'english': 'Cat'},
    {'tamil': 'நாய்', 'english': 'Dog'},
    {'tamil': 'வீடு', 'english': 'House'},
    {'tamil': 'கதை', 'english': 'Story'},
    {'tamil': 'பெயர்', 'english': 'Name'},
    {'tamil': 'நகை', 'english': 'Jewelry'},
    {'tamil': 'பாল்', 'english': 'Ball'},
  ];

  final List<Map<String, dynamic>> _tamilSentences = [
    {'tamil': 'வணக்கம்.', 'english': 'Hello.'},
    {'tamil': 'நீ யாரு?', 'english': 'Who are you?'},
    {'tamil': 'என் பெயர் ராம்.', 'english': 'My name is Ram.'},
    {'tamil': 'இது நல்ல நாள்.', 'english': 'This is a good day.'},
    {'tamil': 'எப்படி இருக்கீ?', 'english': 'How are you?'},
    {'tamil': 'நான் நன்றாக உள்ளேன்.', 'english': 'I am fine.'},
    {'tamil': 'இதை நான் விரும்புகிறேன்.', 'english': 'I like this.'},
    {'tamil': 'நீ வருகிறாயா?', 'english': 'Will you come?'},
    {'tamil': 'உன்னை நான் நன்றாக அறிவேன்.', 'english': 'I know you well.'},
    {'tamil': 'நன்றி ஆ.', 'english': 'Thank you.'},
  ];

  @override
  void initState() {
    super.initState();
    _speechService = SpeechService();
    _spellingController = TextEditingController();
    _initializeQuestions();
  }

  void _initializeQuestions() {
    _questions = [];

    // Add 10 letters
    for (int i = 0; i < 10; i++) {
      _questions.add(
        PreAssessmentQuestion(
          id: 'letter_$i',
          category: 'letter',
          tamil: _tamilLetters[i]['tamil'],
          english: _tamilLetters[i]['english'],
          difficulty: 1,
        ),
      );
    }

    // Add 10 words
    for (int i = 0; i < 10; i++) {
      _questions.add(
        PreAssessmentQuestion(
          id: 'word_$i',
          category: 'word',
          tamil: _tamilWords[i]['tamil'],
          english: _tamilWords[i]['english'],
          difficulty: 5,
        ),
      );
    }

    // Add 10 sentences
    for (int i = 0; i < 10; i++) {
      _questions.add(
        PreAssessmentQuestion(
          id: 'sentence_$i',
          category: 'sentence',
          tamil: _tamilSentences[i]['tamil'],
          english: _tamilSentences[i]['english'],
          difficulty: 8,
        ),
      );
    }
  }

  void _speakCurrentQuestion() async {
    final question = _questions[_currentQuestionIndex];
    await _speechService.speakText(question.tamil, language: 'ta-IN');
  }

  void _startListening() async {
    setState(() {
      _isListening = true;
      _recognizedText = '';
    });

    try {
      final recognized = await _speechService.startListening(
        language: 'ta-IN',
        maxDuration: 10,
      );
      
      if (mounted) {
        setState(() {
          _recognizedText = recognized;
          _isListening = false;
        });

        if (_recognizedText.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No speech detected. Please speak clearly and try again.'),
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          // Auto-evaluate if speech was recognized
          _evaluateAnswer();
        }
      }
    } catch (e) {
      print('Error: $e');
      if (mounted) {
        setState(() {
          _isListening = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _evaluateAnswer() {
    if (_recognizedText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not recognize speech. Please try again.')),
      );
      return;
    }

    final question = _questions[_currentQuestionIndex];
    final accuracy =
        TextEvaluator.calculateSimilarity(question.tamil, _recognizedText);
    final isCorrect = accuracy >= 70;

    final result = PreAssessmentResult(
      questionId: question.id,
      category: question.category,
      tamilText: question.tamil,
      userSpoken: _recognizedText,
      isCorrect: isCorrect,
      accuracy: accuracy,
      timestamp: DateTime.now(),
    );

    setState(() {
      _results.add(result);
      _currentAccuracy = accuracy;
      _showResult = true;
    });
  }

  void _evaluateSpelling() {
    if (_spellingController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please type the spelling.')),
      );
      return;
    }

    final question = _questions[_currentQuestionIndex];
    final typedSpelling = _spellingController.text;
    final accuracy =
        TextEvaluator.calculateSimilarity(question.tamil, typedSpelling);
    final isCorrect = accuracy >= 70;

    final result = PreAssessmentResult(
      questionId: question.id,
      category: question.category,
      tamilText: question.tamil,
      userSpoken: typedSpelling,
      isCorrect: isCorrect,
      accuracy: accuracy,
      timestamp: DateTime.now(),
    );

    setState(() {
      _results.add(result);
      _currentAccuracy = accuracy;
      _showResult = true;
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _showResult = false;
        _recognizedText = '';
        _spellingController.clear();
      });
    } else {
      _showTestComplete();
    }
  }

  void _showTestComplete() {
    int correctAnswers = _results.where((r) => r.isCorrect).length;
    double averageAccuracy =
        _results.isEmpty ? 0 : _results.map((r) => r.accuracy).reduce((a, b) => a + b) / _results.length;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Pre-Assessment Complete!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total Questions: ${_results.length}'),
            const SizedBox(height: 10),
            Text('Correct Answers: $correctAnswers'),
            const SizedBox(height: 10),
            Text('Average Accuracy: ${averageAccuracy.toStringAsFixed(1)}%'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _speechService.dispose();
    _spellingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Pre-Assessment Test'),
          backgroundColor: DuoColors.green,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final question = _questions[_currentQuestionIndex];
    final progress = (_currentQuestionIndex + 1) / _questions.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pre-Assessment Test'),
        backgroundColor: DuoColors.green,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Question ${_currentQuestionIndex + 1} of ${_questions.length}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    _getCategoryLabel(question.category),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: DuoColors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(DuoColors.green),
                ),
              ),
              const SizedBox(height: 40),

              // Question display card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    gradient: LinearGradient(
                      colors: [DuoColors.greenLight, Colors.white],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Read and Spell:',
                        style: TextStyle(
                          fontSize: 14,
                          color: DuoColors.textLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        question.tamil,
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: DuoColors.text,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '(${question.english})',
                        style: TextStyle(
                          fontSize: 16,
                          color: DuoColors.textLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Control buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Speaker button
                  ElevatedButton.icon(
                    onPressed: _speakCurrentQuestion,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    icon: const Icon(Icons.volume_up),
                    label: const Text(
                      'Hear',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),

                  // Microphone button
                  ElevatedButton.icon(
                    onPressed: _isListening ? null : _startListening,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isListening ? Colors.grey : Colors.red,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
                    label: Text(
                      _isListening ? 'Listening...' : 'Record',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Spelling Input Field
              if (!_showResult)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Or type the spelling:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: DuoColors.textLight,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _spellingController,
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.done,
                      enableIMEPersonalizedLearning: true,
                      decoration: InputDecoration(
                        hintText: 'Type the word...',
                        helperText: 'Use Tamil keyboard to type',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        suffixIcon: _spellingController.text.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.check_circle),
                                color: DuoColors.green,
                                onPressed: () {
                                  _evaluateSpelling();
                                },
                              ),
                      ),
                      onChanged: (value) {
                        setState(() {});
                      },
                      onSubmitted: (value) {
                        if (value.isNotEmpty) {
                          _evaluateSpelling();
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    if (_spellingController.text.isNotEmpty)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _evaluateSpelling,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: DuoColors.green,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.check),
                          label: const Text(
                            'Submit Spelling',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              const SizedBox(height: 24),

              // Recognition result
              if (_recognizedText.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'You said:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _recognizedText,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),

              // Evaluation result
              if (_showResult)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _currentAccuracy >= 70
                        ? const Color(0xFFE8F5E9)
                        : const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _currentAccuracy >= 70
                          ? DuoColors.green
                          : Colors.orange,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            _currentAccuracy >= 70 ? Icons.check_circle : Icons.info,
                            color: _currentAccuracy >= 70
                                ? DuoColors.green
                                : Colors.orange,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _currentAccuracy >= 70 ? 'Great!' : 'Try Again',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: _currentAccuracy >= 70
                                        ? DuoColors.green
                                        : Colors.orange,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Accuracy: ${_currentAccuracy.toStringAsFixed(1)}%',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),

              // Next button
              if (_showResult)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _nextQuestion,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DuoColors.green,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _currentQuestionIndex == _questions.length - 1
                          ? 'Complete'
                          : 'Next Question',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _getCategoryLabel(String category) {
    switch (category) {
      case 'letter':
        return 'Letter';
      case 'word':
        return 'Word';
      case 'sentence':
        return 'Sentence';
      default:
        return category;
    }
  }
}
