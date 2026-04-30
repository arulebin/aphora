// Sentence data for Hard Level - Basic sentences for speech therapy
// Each sentence has English and Tamil translations

class SentenceData {
  final int id;
  final String englishSentence;
  final String tamilSentence;
  final String category;
  final String difficulty;
  final String? translation; // Additional explanation

  SentenceData({
    required this.id,
    required this.englishSentence,
    required this.tamilSentence,
    required this.category,
    required this.difficulty,
    this.translation,
  });
}

// 12 Basic Sentences for Hard Level
final List<SentenceData> allSentences = [
  // Category 1: Greetings & Basic Conversation (4 sentences)
  SentenceData(
    id: 1,
    englishSentence: 'Hello, how are you?',
    tamilSentence: 'வணக்கம், நீ எப்படி இருக்கிறாய்?',
    category: 'Greetings',
    difficulty: 'Hard',
    translation: 'Greeting - Asking how someone is',
  ),
  SentenceData(
    id: 2,
    englishSentence: 'My name is John.',
    tamilSentence: 'என் பெயர் ஜான்.',
    category: 'Introduction',
    difficulty: 'Hard',
    translation: 'Introducing yourself by name',
  ),
  SentenceData(
    id: 3,
    englishSentence: 'Nice to meet you.',
    tamilSentence: 'உனை சந்திப்பது மகிழ்ச்சி.',
    category: 'Greetings',
    difficulty: 'Hard',
    translation: 'Expressing pleasure at meeting someone',
  ),
  SentenceData(
    id: 4,
    englishSentence: 'What is your name?',
    tamilSentence: 'உன் பெயர் என்ன?',
    category: 'Greetings',
    difficulty: 'Hard',
    translation: 'Asking for someone\'s name',
  ),

  // Category 2: Daily Activities (3 sentences)
  SentenceData(
    id: 5,
    englishSentence: 'I am eating food.',
    tamilSentence: 'நான் சாப்பாடு சாப்பிடுகிறேன்.',
    category: 'Daily Activities',
    difficulty: 'Hard',
    translation: 'Describing eating action',
  ),
  SentenceData(
    id: 6,
    englishSentence: 'Can you help me please?',
    tamilSentence: 'தயவு செய்து என்னை உதவ முடியுமா?',
    category: 'Requests',
    difficulty: 'Hard',
    translation: 'Politely asking for help',
  ),
  SentenceData(
    id: 7,
    englishSentence: 'I am going to the doctor.',
    tamilSentence: 'நான் மருத்துவரிடம் போகிறேன்.',
    category: 'Daily Activities',
    difficulty: 'Hard',
    translation: 'Describing going to doctor',
  ),

  // Category 3: Health & Wellness (3 sentences)
  SentenceData(
    id: 8,
    englishSentence: 'I am not feeling well.',
    tamilSentence: 'நான் நன்றாக உணர்வதில்லை.',
    category: 'Health',
    difficulty: 'Hard',
    translation: 'Expressing illness or discomfort',
  ),
  SentenceData(
    id: 9,
    englishSentence: 'Please give me water.',
    tamilSentence: 'தயவு செய்து எனக்கு தண்ணீர் தந்து.',
    category: 'Requests',
    difficulty: 'Hard',
    translation: 'Requesting water politely',
  ),
  SentenceData(
    id: 10,
    englishSentence: 'Do you speak English?',
    tamilSentence: 'நீ ஆங்கிலம் பேசுகிறாயா?',
    category: 'Communication',
    difficulty: 'Hard',
    translation: 'Asking if someone speaks English',
  ),

  // Category 4: Emergency & Important (2 sentences)
  SentenceData(
    id: 11,
    englishSentence: 'Call an ambulance now.',
    tamilSentence: 'இப்போது 救救车 அழைக்கவும்.',
    category: 'Emergency',
    difficulty: 'Hard',
    translation: 'Emergency request for ambulance',
  ),
  SentenceData(
    id: 12,
    englishSentence: 'Where is the nearest hospital?',
    tamilSentence: 'அருகில் உள்ள மருத்துவமனை எங்கே உள்ளது?',
    category: 'Directions',
    difficulty: 'Hard',
    translation: 'Asking for hospital location',
  ),
];

// Helper functions
List<SentenceData> getAllSentences() {
  return allSentences;
}

List<SentenceData> getSentencesByCategory(String category) {
  return allSentences.where((s) => s.category == category).toList();
}

List<String> getAllSentenceCategories() {
  final categories = <String>{};
  for (var sentence in allSentences) {
    categories.add(sentence.category);
  }
  return categories.toList();
}
