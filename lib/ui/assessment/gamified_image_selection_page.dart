import 'package:flutter/material.dart';
import 'package:aphora/logic/language_service.dart';
import 'package:aphora/main.dart';
import 'dart:math';

class WordImagePair {
  final String english;
  final String tamil;
  final String imagePath;

  const WordImagePair({
    required this.english,
    required this.tamil,
    required this.imagePath,
  });
}

const List<WordImagePair> allQuestions = [
  WordImagePair(english: 'Water', tamil: 'தண்ணீர்', imagePath: 'assets/images/questions/1_water.png'),
  WordImagePair(english: 'Food', tamil: 'உணவு', imagePath: 'assets/images/questions/2_food.png'),
  WordImagePair(english: 'Child', tamil: 'குழந்தை', imagePath: 'assets/images/questions/3_child.png'),
  WordImagePair(english: 'Drink', tamil: 'குடி', imagePath: 'assets/images/questions/4_drink.png'),
  WordImagePair(english: 'Medicine', tamil: 'மருந்து', imagePath: 'assets/images/questions/5_medicine.png'),
  WordImagePair(english: 'Tablet', tamil: 'மாத்திரை', imagePath: 'assets/images/questions/6_tablet.png'),
  WordImagePair(english: 'Sleep', tamil: 'தூங்கு', imagePath: 'assets/images/questions/7_sleep.png'),
  WordImagePair(english: 'Milk', tamil: 'பால்', imagePath: 'assets/images/questions/9_milk.png'),
  WordImagePair(english: 'Soup', tamil: 'சூப்', imagePath: 'assets/images/questions/10_soup.png'),
  WordImagePair(english: 'Woman', tamil: 'பெண்', imagePath: 'assets/images/questions/11_woman.png'),
  WordImagePair(english: 'Man', tamil: 'ஆண்', imagePath: 'assets/images/questions/12_man.png'),
  WordImagePair(english: 'Boy', tamil: 'சிறுவன்', imagePath: 'assets/images/questions/13_boy.png'),
  WordImagePair(english: 'Girl', tamil: 'சிறுமி', imagePath: 'assets/images/questions/14_girl.png'),
  WordImagePair(english: 'Doctor', tamil: 'மருத்துவர்', imagePath: 'assets/images/questions/17_doctor.png'),
  WordImagePair(english: 'Walk', tamil: 'நட', imagePath: 'assets/images/questions/19_walk.png'),
  WordImagePair(english: 'Go', tamil: 'செல்', imagePath: 'assets/images/questions/20_go.png'),
];

class GamifiedImageSelectionPage extends StatefulWidget {
  const GamifiedImageSelectionPage({super.key});

  @override
  State<GamifiedImageSelectionPage> createState() => _GamifiedImageSelectionPageState();
}

class _GamifiedImageSelectionPageState extends State<GamifiedImageSelectionPage> {
  final int totalQuestions = 10;
  late List<WordImagePair> selectedQuestions;
  int currentQuestionIndex = 0;
  int _score = 0;
  
  List<WordImagePair> currentOptions = [];
  WordImagePair? selectedOption;
  bool isAnswerRevealed = false;

  @override
  void initState() {
    super.initState();
    _startQuiz();
  }

  void _startQuiz() {
    final random = Random();
    var listCopy = List<WordImagePair>.from(allQuestions);
    listCopy.shuffle(random);
    selectedQuestions = listCopy.take(totalQuestions).toList();
    _setupQuestion();
  }

  void _setupQuestion() {
    final random = Random();
    WordImagePair correctPair = selectedQuestions[currentQuestionIndex];
    
    // Choose 3 extra random wrong options
    var wrongOptions = allQuestions.where((q) => q.english != correctPair.english).toList();
    wrongOptions.shuffle(random);
    
    currentOptions = [correctPair, ...wrongOptions.take(3)];
    currentOptions.shuffle(random);
    
    setState(() {
      selectedOption = null;
      isAnswerRevealed = false;
    });
  }

  void _checkAnswer() {
    if (selectedOption == null) return;

    setState(() {
      isAnswerRevealed = true;
    });
    
    WordImagePair correctPair = selectedQuestions[currentQuestionIndex];
    bool isCorrect = selectedOption!.english == correctPair.english;
    
    if (isCorrect) {
      _score++;
    }

    _showResultBottomSheet(isCorrect);
  }

  void _showResultBottomSheet(bool isCorrect) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: isCorrect ? TrioColors.greenLight : TrioColors.redLight,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isCorrect ? Icons.check_rounded : Icons.close_rounded,
                        color: isCorrect ? DuoColors.green : DuoColors.red,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        isCorrect ? 'Correct!' : 'Incorrect!',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isCorrect ? DuoColors.greenDark : TrioColors.redDark,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isCorrect ? DuoColors.green : DuoColors.red,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    if (currentQuestionIndex < totalQuestions - 1) {
                      setState(() {
                        currentQuestionIndex++;
                      });
                      _setupQuestion();
                    } else {
                      _showFinalScore();
                    }
                  },
                  child: const Text('CONTINUE', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showFinalScore() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text(
            'Quiz Completed!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.emoji_events, color: Color(0xFFFFD700), size: 80),
              const SizedBox(height: 16),
              Text(
                'You scored $_score out of $totalQuestions',
                style: const TextStyle(fontSize: 20),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: DuoColors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () {
                  Navigator.pop(context); // close dialog
                  Navigator.pop(context); // close page
                },
                child: const Text('Back to Assessment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (selectedQuestions.isEmpty) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    WordImagePair currentItem = selectedQuestions[currentQuestionIndex];
    bool isTamil = LanguageService.currentLanguage == Language.tamil;
    String displayWord = isTamil ? currentItem.tamil : currentItem.english;

    return Scaffold(
      backgroundColor: DuoColors.surface,
      appBar: AppBar(
        title: Text(isTamil ? 'படத்தை கண்டுபிடி' : 'Match the Image', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: DuoColors.text,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Progress Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: DuoColors.disabled),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: (currentQuestionIndex) / totalQuestions,
                        minHeight: 12,
                        backgroundColor: DuoColors.border,
                        valueColor: const AlwaysStoppedAnimation<Color>(DuoColors.green),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
              ),
            ),
            
            // Question text
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
              child: Text(
                isTamil ? 'படத்தில் உள்ள "$displayWord" எது?' : 'Which of these is "$displayWord"?',
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: DuoColors.text),
                textAlign: TextAlign.center,
              ),
            ),
            
            // Image Options Grid
            Expanded(
              child: GridView.count(
                padding: const EdgeInsets.all(16),
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.9,
                children: currentOptions.map((option) {
                  bool isSelected = selectedOption == option;
                  final color = isSelected ? DuoColors.blue : Colors.white;
                  final borderColor = isSelected ? const Color(0xFF1899D6) : DuoColors.border;

                  return GestureDetector(
                    onTap: isAnswerRevealed ? null : () {
                      setState(() {
                        selectedOption = option;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: color.withOpacity(isSelected ? 0.1 : 1.0),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor, width: isSelected ? 3 : 2),
                        boxShadow: [
                          if (!isSelected)
                            BoxShadow(
                              color: DuoColors.border,
                              offset: const Offset(0, 4),
                            ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            option.imagePath,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            
            // Check button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: selectedOption == null ? DuoColors.border : DuoColors.green,
                  foregroundColor: selectedOption == null ? DuoColors.disabled : Colors.white,
                  elevation: selectedOption == null ? 0 : 4,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: isAnswerRevealed || selectedOption == null ? null : _checkAnswer,
                child: const Text('CHECK', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Additional colors if needed
class TrioColors {
  static const redLight = Color(0xFFFFDFE0);
  static const redDark = Color(0xFFEA2B2B);
  static const greenLight = Color(0xFFD7FFB8);
}
