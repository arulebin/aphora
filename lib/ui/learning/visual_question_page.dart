import 'package:flutter/material.dart';
import 'package:aphora/data/learning/question_data.dart';
import 'package:aphora/main.dart';
import 'package:aphora/ui/widgets/clinical_app_bar.dart';

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

  @override
  void initState() {
    super.initState();
    currentIndex = 0;
    answeredQuestions = List.filled(widget.questions.length, false);
  }

  void _goToNextQuestion() {
    if (currentIndex < widget.questions.length - 1) {
      setState(() {
        answeredQuestions[currentIndex] = true;
        currentIndex++;
      });
    }
  }

  void _goToPreviousQuestion() {
    if (currentIndex > 0) {
      setState(() {
        currentIndex--;
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
              // Progress Indicator
              _buildProgressIndicator(progress),
              SizedBox(height: 30),

              // Question Counter
              Text(
                'Question ${currentIndex + 1} of ${widget.questions.length}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: DuoColors.textLight,
                ),
              ),
              SizedBox(height: 20),

              // Large Image Display
              _buildImageDisplay(question),
              SizedBox(height: 40),

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
              SizedBox(height: 16),

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
              SizedBox(height: 12),

              // Difficulty Badge
              _buildDifficultyBadge(question.difficulty),
              SizedBox(height: 40),

              // Navigation Buttons
              _buildNavigationButtons(),
            ],
          ),
        ),
      ),
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
