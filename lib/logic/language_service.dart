enum Language { english, tamil }

class LanguageService {
  static Language _currentLanguage = Language.english;

  static Language get currentLanguage => _currentLanguage;

  static void setLanguage(Language language) {
    _currentLanguage = language;
  }

  static String getLanguageName() {
    return _currentLanguage == Language.english ? "English" : "தமிழ்";
  }

  // Translation strings
  static const Map<Language, Map<String, String>> _translations = {
    Language.english: {
      'app_title': 'Aphora',
      'hello': 'Hello',
      'how_are_you': 'How are you?',
      'welcome': 'Welcome to Aphora',
      'select_language': 'Select Language',
      'english': 'English',
      'tamil': 'Tamil',
      'pronunciation_practice': 'Pronunciation Practice',
      'tap_to_listen': 'Tap to listen',
      'start_recording': 'Start Recording',
      'stop_recording': 'Stop Recording',
      'translate_phrase': 'Translate this phrase',
      'your_answer': 'Your answer',
      'submit': 'Submit',
      'next': 'Next',
      'previous': 'Previous',
      'home': 'Home',
      'login': 'Login',
      'signup': 'Sign Up',
      'email': 'Email',
      'password': 'Password',
      'phone': 'Phone',
      'name': 'Name',
      'user_info': 'User Information',
      'therapist': 'Therapist',
      'settings': 'Settings',
      'logout': 'Logout',
      'cancel': 'Cancel',
      'save': 'Save',
      'delete': 'Delete',
      'edit': 'Edit',
      'loading': 'Loading...',
      'error': 'Error',
      'success': 'Success',
      'task_list': 'Task List',
      'task_detail': 'Task Detail',
      'video_call': 'Video Call',
      'word_naming': 'Word Naming',
      'lesson': 'Lesson',
      'easy': 'Easy',
      'medium': 'Medium',
      'hard': 'Hard',
      // Tasks
      'task_1_phrase': 'Hello, how are you?',
      'task_2_phrase': 'My name is John',
      'task_3_phrase': 'I would like to order a coffee',
      'task_4_phrase': 'Can you help me find the nearest hospital?',
      'task_5_phrase': 'I am learning English to improve my career',
      'task_6_phrase': 'Could you please repeat that more slowly?',
    },
    Language.tamil: {
      'app_title': 'அபோரா',
      'hello': 'வணக்கம்',
      'how_are_you': 'நீ எப்படி இருக்கிறாய்?',
      'welcome': 'அபோராவில் வரவேற்கிறோம்',
      'select_language': 'மொழி தேர்ந்தெடுக்கவும்',
      'english': 'ஆங்கிலம்',
      'tamil': 'தமிழ்',
      'pronunciation_practice': 'உச்சரணை பயிற்சி',
      'tap_to_listen': 'கேட்க தட்டவும்',
      'start_recording': 'பதிவு செய்ய தொடங்குங்கள்',
      'stop_recording': 'பதிவு செய்ய நிறுத்தவும்',
      'translate_phrase': 'இந்த சொற்றொடரை மொழிபெயர்க்கவும்',
      'your_answer': 'உங்கள் பதில்',
      'submit': 'சமர்ப்பிக்கவும்',
      'next': 'அடுத்தது',
      'previous': 'முந்தைய',
      'home': 'முகப்பு',
      'login': 'உள்நுழைய',
      'signup': 'பதிவு செய்யவும்',
      'email': 'மின்னஞ்சல்',
      'password': 'கடவுச்சொல்',
      'phone': 'தொலைபேசி',
      'name': 'பெயர்',
      'user_info': 'பயனர் தகவல்',
      'therapist': 'சிகிச்சையாளர்',
      'settings': 'அமைப்புகள்',
      'logout': 'வெளியேறவும்',
      'cancel': 'ரத்து செய்யவும்',
      'save': 'சேமிக்கவும்',
      'delete': 'நீக்கவும்',
      'edit': 'திருத்தவும்',
      'loading': 'ஏற்றுகிறது...',
      'error': 'பிழை',
      'success': 'வெற்றி',
      'task_list': 'பணிப்பட்டியல்',
      'task_detail': 'பணியின் விவரம்',
      'video_call': 'வீடியோ அழைப்பு',
      'word_naming': 'சொல் பெயரிடுதல்',
      'lesson': 'பாடம்',
      'easy': 'சுலபம்',
      'medium': 'நடுத்தர',
      'hard': 'கடினம்',
      // Tasks
      'task_1_phrase': 'வணக்கம், நீ எப்படி இருக்கிறாய்?',
      'task_2_phrase': 'என் பெயர் ஜான்',
      'task_3_phrase': 'நான் ஒரு காபி ஆர்டர் செய்ய விரும்புகிறேன்',
      'task_4_phrase': 'நீ எனக்கு மிக அருகிலான ஆஸ்பத்திரி கண்டுபிடிக்க உதவ முடியுமா?',
      'task_5_phrase': 'நான் என் ক்যாரியரை மேம்படுத்த ஆங்கிலம் கற்று வருகிறேன்',
      'task_6_phrase': 'நீ தயவு செய்து அதை மிகவும் மெதுவாக மீண்டும் சொல்ல முடியுமா?',
    },
  };

  static String translate(String key) {
    return _translations[_currentLanguage]?[key] ?? key;
  }

  static String get(String key) {
    return translate(key);
  }

  // Get difficulty level in current language
  static String getDifficultyInLanguage(String difficulty) {
    String key = difficulty.toLowerCase();
    return get(key);
  }

  // Get task phrase in current language
  static String getTaskPhrase(int taskId) {
    String key = 'task_${taskId}_phrase';
    return get(key);
  }
}
