class PreAssessmentQuestion {
  final String id;
  final String category; // 'letter', 'word', 'sentence'
  final String tamil; // Tamil text
  final String english; // English translation
  final int difficulty; // 1-10 based on severity level

  PreAssessmentQuestion({
    required this.id,
    required this.category,
    required this.tamil,
    required this.english,
    required this.difficulty,
  });
}

class PreAssessmentResult {
  final String questionId;
  final String category;
  final String tamilText;
  final String userSpoken;
  final bool isCorrect;
  final double accuracy;
  final DateTime timestamp;

  PreAssessmentResult({
    required this.questionId,
    required this.category,
    required this.tamilText,
    required this.userSpoken,
    required this.isCorrect,
    required this.accuracy,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'questionId': questionId,
      'category': category,
      'tamilText': tamilText,
      'userSpoken': userSpoken,
      'isCorrect': isCorrect,
      'accuracy': accuracy,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
