// Question data with 50 questions organized by categories
// Each question has an image, Tamil translation, and English phrase

class QuestionData {
  final int id;
  final String category;
  final String englishPhrase;
  final String tamilPhrase;
  final String imagePath;
  final String difficulty;
  final String? description;

  QuestionData({
    required this.id,
    required this.category,
    required this.englishPhrase,
    required this.tamilPhrase,
    required this.imagePath,
    required this.difficulty,
    this.description,
  });
}

// 50 Questions dataset
final List<QuestionData> allQuestions = [
  // Category 1: Basic Needs (10 questions)
  QuestionData(
    id: 1,
    category: 'Basic Needs',
    englishPhrase: 'Water',
    tamilPhrase: 'தண்ணீர்',
    imagePath: 'assets/images/questions/1_water.png',
    difficulty: 'Easy',
  ),
  QuestionData(
    id: 2,
    category: 'Basic Needs',
    englishPhrase: 'Food',
    tamilPhrase: 'சாப்பாடு',
    imagePath: 'assets/images/questions/2_food.png',
    difficulty: 'Easy',
  ),
  QuestionData(
    id: 3,
    category: 'Basic Needs',
    englishPhrase: 'Child',
    tamilPhrase: 'குழந்தை',
    imagePath: 'assets/images/questions/3_child.png',
    difficulty: 'Easy',
  ),
  QuestionData(
    id: 4,
    category: 'Basic Needs',
    englishPhrase: 'Drink',
    tamilPhrase: 'குடி',
    imagePath: 'assets/images/questions/4_drink.png',
    difficulty: 'Easy',
  ),
  QuestionData(
    id: 5,
    category: 'Basic Needs',
    englishPhrase: 'Medicine',
    tamilPhrase: 'மருந்து',
    imagePath: 'assets/images/questions/5_medicine.png',
    difficulty: 'Easy',
  ),
  QuestionData(
    id: 6,
    category: 'Basic Needs',
    englishPhrase: 'Tablet',
    tamilPhrase: 'மாத்திரை',
    imagePath: 'assets/images/questions/6_tablet.png',
    difficulty: 'Easy',
  ),
  QuestionData(
    id: 7,
    category: 'Basic Needs',
    englishPhrase: 'Sleep',
    tamilPhrase: 'தூக்கம்',
    imagePath: 'assets/images/questions/7_sleep.png',
    difficulty: 'Easy',
  ),
  QuestionData(
    id: 8,
    category: 'Basic Needs',
    englishPhrase: 'Sitting',
    tamilPhrase: 'உட்கார்',
    imagePath: 'assets/images/questions/8_sitting.png',
    difficulty: 'Easy',
  ),
  QuestionData(
    id: 9,
    category: 'Basic Needs',
    englishPhrase: 'Milk',
    tamilPhrase: 'பால்',
    imagePath: 'assets/images/questions/9_milk.png',
    difficulty: 'Easy',
  ),
  QuestionData(
    id: 10,
    category: 'Basic Needs',
    englishPhrase: 'Soup',
    tamilPhrase: 'சூப்',
    imagePath: 'assets/images/questions/10_soup.png',
    difficulty: 'Easy',
  ),

  // Category 2: People (8 questions)
  QuestionData(
    id: 11,
    category: 'People',
    englishPhrase: 'Woman',
    tamilPhrase: 'பெண்',
    imagePath: 'assets/images/questions/11_woman.png',
    difficulty: 'Easy',
  ),
  QuestionData(
    id: 12,
    category: 'People',
    englishPhrase: 'Man',
    tamilPhrase: 'ஆண்',
    imagePath: 'assets/images/questions/12_man.png',
    difficulty: 'Easy',
  ),
  QuestionData(
    id: 13,
    category: 'People',
    englishPhrase: 'Boy',
    tamilPhrase: 'பையன்',
    imagePath: 'assets/images/questions/13_boy.png',
    difficulty: 'Easy',
  ),
  QuestionData(
    id: 14,
    category: 'People',
    englishPhrase: 'Girl',
    tamilPhrase: 'பெண் குழந்தை',
    imagePath: 'assets/images/questions/14_girl.png',
    difficulty: 'Easy',
  ),
  QuestionData(
    id: 15,
    category: 'People',
    englishPhrase: 'Sister',
    tamilPhrase: 'தங்கை',
    imagePath: 'assets/images/questions/15_sister.png',
    difficulty: 'Easy',
  ),
  QuestionData(
    id: 16,
    category: 'People',
    englishPhrase: 'Brother',
    tamilPhrase: 'தம்பி',
    imagePath: 'assets/images/questions/16_brother.png',
    difficulty: 'Easy',
  ),
  QuestionData(
    id: 17,
    category: 'People',
    englishPhrase: 'Doctor',
    tamilPhrase: 'மருத்துவர்',
    imagePath: 'assets/images/questions/17_doctor.png',
    difficulty: 'Medium',
  ),
  QuestionData(
    id: 18,
    category: 'People',
    englishPhrase: 'Nurse',
    tamilPhrase: 'செவிலியர்',
    imagePath: 'assets/images/questions/18_nurse.png',
    difficulty: 'Medium',
  ),

  // Category 3: Actions (10 questions)
  QuestionData(
    id: 19,
    category: 'Actions',
    englishPhrase: 'Walk',
    tamilPhrase: 'நட',
    imagePath: 'assets/images/questions/19_walk.png',
    difficulty: 'Medium',
  ),
  QuestionData(
    id: 20,
    category: 'Actions',
    englishPhrase: 'Go',
    tamilPhrase: 'போ',
    imagePath: 'assets/images/questions/20_go.png',
    difficulty: 'Medium',
  ),
  QuestionData(
    id: 21,
    category: 'Actions',
    englishPhrase: 'Come',
    tamilPhrase: 'வா',
    imagePath: 'assets/images/questions/21_come.png',
    difficulty: 'Easy',
  ),
  QuestionData(
    id: 22,
    category: 'Actions',
    englishPhrase: 'Eat',
    tamilPhrase: 'சாப்பிடு',
    imagePath: 'assets/images/questions/22_eat.png',
    difficulty: 'Easy',
  ),
  QuestionData(
    id: 23,
    category: 'Actions',
    englishPhrase: 'Help',
    tamilPhrase: 'உதவி',
    imagePath: 'assets/images/questions/23_help.png',
    difficulty: 'Medium',
  ),
  QuestionData(
    id: 24,
    category: 'Actions',
    englishPhrase: 'Yes',
    tamilPhrase: 'ஆம்',
    imagePath: 'assets/images/questions/24_yes.png',
    difficulty: 'Easy',
  ),
  QuestionData(
    id: 25,
    category: 'Actions',
    englishPhrase: 'No',
    tamilPhrase: 'இல்லை',
    imagePath: 'assets/images/questions/25_no.png',
    difficulty: 'Easy',
  ),
  QuestionData(
    id: 26,
    category: 'Actions',
    englishPhrase: 'Hello',
    tamilPhrase: 'வணக்கம்',
    imagePath: 'assets/images/questions/26_hello.png',
    difficulty: 'Easy',
  ),
  QuestionData(
    id: 27,
    category: 'Actions',
    englishPhrase: 'Thank you',
    tamilPhrase: 'நன்றி',
    imagePath: 'assets/images/questions/27_thankyou.png',
    difficulty: 'Easy',
  ),
  QuestionData(
    id: 28,
    category: 'Actions',
    englishPhrase: 'Please',
    tamilPhrase: 'தயவுசெய்து',
    imagePath: 'assets/images/questions/28_please.png',
    difficulty: 'Easy',
  ),

  // Category 4: Body Parts (8 questions)
  QuestionData(
    id: 29,
    category: 'Body Parts',
    englishPhrase: 'Head',
    tamilPhrase: 'தலை',
    imagePath: 'assets/images/questions/29_head.png',
    difficulty: 'Easy',
  ),
  QuestionData(
    id: 30,
    category: 'Body Parts',
    englishPhrase: 'Hand',
    tamilPhrase: 'கை',
    imagePath: 'assets/images/questions/30_hand.png',
    difficulty: 'Easy',
  ),
  QuestionData(
    id: 31,
    category: 'Body Parts',
    englishPhrase: 'Foot',
    tamilPhrase: 'கால்',
    imagePath: 'assets/images/questions/31_foot.png',
    difficulty: 'Easy',
  ),
  QuestionData(
    id: 32,
    category: 'Body Parts',
    englishPhrase: 'Eye',
    tamilPhrase: 'கண்',
    imagePath: 'assets/images/questions/32_eye.png',
    difficulty: 'Easy',
  ),
  QuestionData(
    id: 33,
    category: 'Body Parts',
    englishPhrase: 'Mouth',
    tamilPhrase: 'வாய்',
    imagePath: 'assets/images/questions/33_mouth.png',
    difficulty: 'Easy',
  ),
  QuestionData(
    id: 34,
    category: 'Body Parts',
    englishPhrase: 'Nose',
    tamilPhrase: 'மூக்கு',
    imagePath: 'assets/images/questions/34_nose.png',
    difficulty: 'Easy',
  ),
  QuestionData(
    id: 35,
    category: 'Body Parts',
    englishPhrase: 'Thumb',
    tamilPhrase: 'பெருவிரல்',
    imagePath: 'assets/images/questions/35_thumb.png',
    difficulty: 'Medium',
  ),
  QuestionData(
    id: 36,
    category: 'Body Parts',
    englishPhrase: 'Arm',
    tamilPhrase: 'புயம்',
    imagePath: 'assets/images/questions/36_arm.png',
    difficulty: 'Medium',
  ),

  // Category 5: Common Objects (6 questions)
  QuestionData(
    id: 37,
    category: 'Common Objects',
    englishPhrase: 'Bed',
    tamilPhrase: 'படுக்கை',
    imagePath: 'assets/images/questions/37_bed.png',
    difficulty: 'Easy',
  ),
  QuestionData(
    id: 38,
    category: 'Common Objects',
    englishPhrase: 'Cup',
    tamilPhrase: 'கோப்பை',
    imagePath: 'assets/images/questions/38_cup.png',
    difficulty: 'Easy',
  ),
  QuestionData(
    id: 39,
    category: 'Common Objects',
    englishPhrase: 'Plate',
    tamilPhrase: 'தட்டு',
    imagePath: 'assets/images/questions/39_plate.png',
    difficulty: 'Easy',
  ),
  QuestionData(
    id: 40,
    category: 'Common Objects',
    englishPhrase: 'Book',
    tamilPhrase: 'புத்தகம்',
    imagePath: 'assets/images/questions/40_book.png',
    difficulty: 'Medium',
  ),
  QuestionData(
    id: 41,
    category: 'Common Objects',
    englishPhrase: 'Door',
    tamilPhrase: 'கதவு',
    imagePath: 'assets/images/questions/41_door.png',
    difficulty: 'Easy',
  ),
  QuestionData(
    id: 42,
    category: 'Common Objects',
    englishPhrase: 'Window',
    tamilPhrase: 'ஜன்னல்',
    imagePath: 'assets/images/questions/42_window.png',
    difficulty: 'Easy',
  ),

  // Category 6: Feelings (8 questions)
  QuestionData(
    id: 43,
    category: 'Feelings',
    englishPhrase: 'Happy',
    tamilPhrase: 'சந்தோஷம்',
    imagePath: 'assets/images/questions/43_happy.png',
    difficulty: 'Easy',
  ),
  QuestionData(
    id: 44,
    category: 'Feelings',
    englishPhrase: 'Sad',
    tamilPhrase: 'கவலை',
    imagePath: 'assets/images/questions/44_sad.png',
    difficulty: 'Easy',
  ),
  QuestionData(
    id: 45,
    category: 'Feelings',
    englishPhrase: 'Pain',
    tamilPhrase: 'வலி',
    imagePath: 'assets/images/questions/45_pain.png',
    difficulty: 'Easy',
  ),
  QuestionData(
    id: 46,
    category: 'Feelings',
    englishPhrase: 'Tired',
    tamilPhrase: 'களைப்பு',
    imagePath: 'assets/images/questions/46_tired.png',
    difficulty: 'Easy',
  ),
  QuestionData(
    id: 47,
    category: 'Feelings',
    englishPhrase: 'Angry',
    tamilPhrase: 'கோபம்',
    imagePath: 'assets/images/questions/47_angry.png',
    difficulty: 'Medium',
  ),
  QuestionData(
    id: 48,
    category: 'Feelings',
    englishPhrase: 'Cold',
    tamilPhrase: 'சளி',
    imagePath: 'assets/images/questions/48_cold.png',
    difficulty: 'Easy',
  ),
  QuestionData(
    id: 49,
    category: 'Feelings',
    englishPhrase: 'Hot',
    tamilPhrase: 'வெப்பம்',
    imagePath: 'assets/images/questions/49_hot.png',
    difficulty: 'Easy',
  ),
  QuestionData(
    id: 50,
    category: 'Feelings',
    englishPhrase: 'Scared',
    tamilPhrase: 'பயம்',
    imagePath: 'assets/images/questions/50_scared.png',
    difficulty: 'Medium',
  ),
];

// Helper function to get questions by category
List<QuestionData> getQuestionsByCategory(String category) {
  return allQuestions.where((q) => q.category == category).toList();
}

// Get all unique categories
List<String> getAllCategories() {
  final categories = <String>{};
  for (var question in allQuestions) {
    categories.add(question.category);
  }
  return categories.toList();
}
