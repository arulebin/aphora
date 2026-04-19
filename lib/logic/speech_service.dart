import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:async';

class SpeechService {
  late stt.SpeechToText _speechToText;
  late FlutterTts _flutterTts;
  bool _isListening = false;
  String _recognizedText = '';
  Completer<String>? _listeningCompleter;

  SpeechService() {
    _speechToText = stt.SpeechToText();
    _flutterTts = FlutterTts();
    _initializeSpeech();
  }

  Future<void> _initializeSpeech() async {
    try {
      bool available = await _speechToText.initialize(
        onError: (error) {
          print('Speech Recognition Error: $error');
          _listeningCompleter?.completeError(error);
        },
        onStatus: (status) {
          print('Status: $status');
          if (status == 'done' || status == 'notListening') {
            if (_isListening && !(_listeningCompleter?.isCompleted ?? false)) {
              _isListening = false;
              _listeningCompleter?.complete(_recognizedText);
            }
          }
        },
      );
      print('Speech Recognition Available: $available');
    } catch (e) {
      print('Error initializing speech: $e');
    }
  }

  Future<void> speakText(String text, {String language = 'ta-IN'}) async {
    try {
      await _flutterTts.setLanguage(language);
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setPitch(1.0);
      await _flutterTts.speak(text);
      print('Speaking: $text');
    } catch (e) {
      print('Error speaking text: $e');
    }
  }

  Future<String> startListening({String language = 'ta-IN', int maxDuration = 10}) async {
    if (!_speechToText.isAvailable) {
      print('Speech to text not available');
      return '';
    }

    if (_isListening) {
      print('Already listening');
      return _recognizedText;
    }

    try {
      _isListening = true;
      _recognizedText = '';
      _listeningCompleter = Completer<String>();

      // Try to get available locales
      var locales = await _speechToText.locales();
      print('Available locales: ${locales.map((l) => l.localeId).toList()}');

      // Try different language codes for Tamil
      String effectiveLanguage = language;
      if (!locales.any((l) => l.localeId == language)) {
        // Fallback options for Tamil
        if (locales.any((l) => l.localeId.startsWith('ta'))) {
          effectiveLanguage = locales.firstWhere((l) => l.localeId.startsWith('ta')).localeId;
        } else if (locales.any((l) => l.localeId == 'en-IN')) {
          effectiveLanguage = 'en-IN'; // Fallback to Indian English
        }
      }

      print('Using language: $effectiveLanguage');

      await _speechToText.listen(
        onResult: (result) {
          _recognizedText = result.recognizedWords;
          print('Recognized: $_recognizedText (isFinal: ${result.finalResult})');
          
          // Complete immediately if final result
          if (result.finalResult && !(_listeningCompleter?.isCompleted ?? false)) {
            _isListening = false;
            _listeningCompleter?.complete(_recognizedText);
          }
        },
        localeId: effectiveLanguage,
        listenFor: Duration(seconds: maxDuration),
        pauseFor: const Duration(seconds: 2),
      );

      // Wait with timeout
      final result = await _listeningCompleter!.future
          .timeout(
            Duration(seconds: maxDuration + 2),
            onTimeout: () {
              _isListening = false;
              return _recognizedText;
            },
          )
          .catchError((e) {
            print('Error during listening: $e');
            _isListening = false;
            return '';
          });

      await stopListening();
      return result;
    } catch (e) {
      print('Error in startListening: $e');
      _isListening = false;
      return '';
    }
  }

  Future<void> stopListening() async {
    if (_isListening) {
      try {
        await _speechToText.stop();
        _isListening = false;
        print('Stopped listening');
      } catch (e) {
        print('Error stopping: $e');
      }
    }
  }

  bool get isListening => _isListening;
  String get recognizedText => _recognizedText;

  Future<void> dispose() async {
    try {
      await _flutterTts.stop();
      await stopListening();
    } catch (e) {
      print('Error disposing: $e');
    }
  }
}

/// Evaluates similarity between two texts
class TextEvaluator {
  /// Calculate similarity percentage between expected and actual text
  static double calculateSimilarity(String expected, String actual) {
    // Normalize texts
    String normalizeText(String text) {
      return text
          .toLowerCase()
          .trim()
          .replaceAll(RegExp(r'\s+'), ' ')
          .replaceAll(RegExp(r'[^\u0B80-\u0BFF\s]'), ''); // Keep only Tamil chars
    }

    String normalizedExpected = normalizeText(expected);
    String normalizedActual = normalizeText(actual);

    // If texts match exactly
    if (normalizedExpected == normalizedActual) {
      return 100.0;
    }

    // Calculate Levenshtein distance
    int distance = _levenshteinDistance(normalizedExpected, normalizedActual);
    int maxLength = normalizedExpected.length > normalizedActual.length
        ? normalizedExpected.length
        : normalizedActual.length;

    if (maxLength == 0) return 100.0;

    double similarity = ((maxLength - distance) / maxLength) * 100;
    return similarity.clamp(0, 100);
  }

  /// Levenshtein distance algorithm for string similarity
  static int _levenshteinDistance(String s1, String s2) {
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    List<List<int>> dp =
        List.generate(s1.length + 1, (i) => List.filled(s2.length + 1, 0));

    for (int i = 0; i <= s1.length; i++) {
      dp[i][0] = i;
    }
    for (int j = 0; j <= s2.length; j++) {
      dp[0][j] = j;
    }

    for (int i = 1; i <= s1.length; i++) {
      for (int j = 1; j <= s2.length; j++) {
        if (s1[i - 1] == s2[j - 1]) {
          dp[i][j] = dp[i - 1][j - 1];
        } else {
          dp[i][j] = 1 + [dp[i - 1][j], dp[i][j - 1], dp[i - 1][j - 1]].reduce(
              (a, b) => a < b ? a : b);
        }
      }
    }

    return dp[s1.length][s2.length];
  }
}
