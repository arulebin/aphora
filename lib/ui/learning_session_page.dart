import 'package:aphora/logic/speech_service.dart';
import 'package:aphora/main.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Generic learning session page for Letters, Words, or Sentences
class LearningSessionPage extends StatefulWidget {
  final String sessionType; // 'letters', 'words', or 'sentences'
  final double preAssessmentScore;

  const LearningSessionPage({
    super.key,
    required this.sessionType,
    required this.preAssessmentScore,
  });

  @override
  State<LearningSessionPage> createState() => _LearningSessionPageState();
}

class _LearningSessionPageState extends State<LearningSessionPage> {
  late SpeechService _speechService;
  int _currentItemIndex = 0;
  List<Map<String, dynamic>> _items = [];
  bool _isListening = false;
  String _recognizedText = '';
  bool _isCorrect = false;
  bool _showFeedback = false;

  // Tamil test data
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
    {'tamil': 'பாल்', 'english': 'Ball'},
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
    _loadItems();
  }

  void _loadItems() {
    switch (widget.sessionType) {
      case 'letters':
        _items = _tamilLetters;
        break;
      case 'words':
        _items = _tamilWords;
        break;
      case 'sentences':
        _items = _tamilSentences;
        break;
      default:
        _items = [];
    }
  }

  String _getSessionTitle() {
    switch (widget.sessionType) {
      case 'letters':
        return 'Learn Letters';
      case 'words':
        return 'Learn Words';
      case 'sentences':
        return 'Learn Sentences';
      default:
        return 'Learning Session';
    }
  }

  void _speakCurrentItem() async {
    if (_items.isEmpty) return;
    
    final item = _items[_currentItemIndex];
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Playing audio... Check your volume is on.'),
        duration: Duration(seconds: 2),
      ),
    );
    
    await _speechService.speakText(
      item['tamil'],
      language: 'ta-IN',
    );
  }

  void _startListening() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Listening... Speak now!'),
        duration: Duration(seconds: 3),
      ),
    );

    setState(() {
      _isListening = true;
      _recognizedText = '';
      _showFeedback = false;
    });

    final result = await _speechService.startListening();

    setState(() {
      _isListening = false;
      _recognizedText = result;
      _evaluateAnswer();
      _showFeedback = true;
    });
  }

  void _evaluateAnswer() {
    if (_items.isEmpty) return;
    
    final item = _items[_currentItemIndex];
    final targetTamil = item['tamil'].toString().toLowerCase().trim();
    final recognizedLower = _recognizedText.toLowerCase().trim();

    // Simple matching (can be enhanced with similarity calculation)
    _isCorrect = targetTamil == recognizedLower;
  }

  void _nextItem() {
    if (_currentItemIndex < _items.length - 1) {
      setState(() {
        _currentItemIndex++;
        _recognizedText = '';
        _showFeedback = false;
        _isCorrect = false;
      });
    } else {
      // End of session
      _showSessionComplete();
    }
  }

  void _showSessionComplete() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Session Complete!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Items Learned: ${_items.length}'),
            const SizedBox(height: 16),
            const Text('Great job! Keep practicing to improve your skills.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/home');
            },
            child: const Text('Go to Home'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _currentItemIndex = 0;
                _recognizedText = '';
                _showFeedback = false;
              });
            },
            child: const Text('Restart'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _speechService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Loading...'),
          backgroundColor: DuoColors.green,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final item = _items[_currentItemIndex];
    final progress = (_currentItemIndex + 1) / _items.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(_getSessionTitle()),
        backgroundColor: DuoColors.green,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              DuoColors.green.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: Colors.grey[300],
                  valueColor: const AlwaysStoppedAnimation<Color>(DuoColors.green),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Item ${_currentItemIndex + 1} of ${_items.length}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 32),

              // Content card
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Tamil text
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          item['tamil'],
                          style: const TextStyle(
                            fontSize: 64,
                            fontWeight: FontWeight.bold,
                            color: DuoColors.greenDark,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // English meaning
                      Text(
                        item['english'],
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      const SizedBox(height: 32),

                      // Action buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Hear button
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: DuoColors.green,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _speakCurrentItem,
                            icon: const Icon(Icons.volume_up),
                            label: const Text('Hear'),
                          ),

                          // Record button
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isListening ? Colors.red : Colors.blue,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _isListening ? null : _startListening,
                            icon: Icon(_isListening ? Icons.stop : Icons.mic),
                            label: Text(_isListening ? 'Recording...' : 'Record'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Feedback section
              if (_showFeedback) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _isCorrect
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isCorrect ? Colors.green : Colors.red,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _isCorrect ? Icons.check_circle : Icons.close,
                            color: _isCorrect ? Colors.green : Colors.red,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isCorrect ? 'Correct!' : 'Try Again',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _isCorrect ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'You said: $_recognizedText',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Next button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DuoColors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _showFeedback ? _nextItem : null,
                  child: Text(
                    _currentItemIndex == _items.length - 1
                        ? 'Complete Session'
                        : 'Next Item',
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
}
