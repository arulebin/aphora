import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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
    _initializeTTS();
  }

  Future<void> _initializeTTS() async {
    try {
      // Initialize TTS engine - rely on default system TTS to prevent DeadObjectException
      // on certain Android devices that fail when forcing 'com.google.android.tts'
      /*
      try {
        await _flutterTts.setEngine('com.google.android.tts');
        print('TTS Engine set to: com.google.android.tts');
      } catch (e) {
        print('Google TTS not available: $e, using default engine');
      }
      */
      
      // Set default language
      await _flutterTts.setLanguage('ta-IN');
      print('TTS Language set to: ta-IN');
      
      // Set audio attributes for better volume
      await _flutterTts.setVolume(1.0); // Max volume (0.0 - 1.0)
      await _flutterTts.setSpeechRate(0.5); // Slower rate for clarity (0.0 - 2.0)
      await _flutterTts.setPitch(1.0); // Normal pitch (0.5 - 2.0)
      
      // Set speaking queue mode to flush (immediately play)
      // Note: setQueueMode is not available on web, so wrap in try-catch
      try {
        await _flutterTts.setQueueMode(1); // 1 = flush queue
        print('TTS Queue mode: FLUSH (immediate playback)');
      } catch (e) {
        print('Note: setQueueMode not available on this platform: $e');
      }
      
      print('TTS Initialized successfully - volume:1.0, rate:0.5, pitch:1.0');
      
    } catch (e) {
      print('Error initializing TTS: $e');
    }
  }

  Future<void> _initializeSpeech() async {
    try {
      bool available = await _speechToText.initialize(
        onError: (error) {
          // Browser STT routes audio to Google's servers; ad-blockers, lack of
          // HTTPS, or DNS filtering surface as `network` errors here. Complete
          // gracefully with an empty result instead of completeError — the
          // latter races the timeout chain and bubbles as an Uncaught Error.
          print('Speech Recognition Error: $error');
          if (_isListening && !(_listeningCompleter?.isCompleted ?? false)) {
            _isListening = false;
            _listeningCompleter?.complete('');
          }
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
      if (text.isEmpty) {
        print('Cannot speak empty text');
        return;
      }

      print('═════════════════════════════════════════════');
      print('SPEAK REQUEST: "$text"');
      print('Language: $language');
      print('═════════════════════════════════════════════');
      
      // Set language
      await _flutterTts.setLanguage(language);
      print('✓ Language set to: $language');
      
      // Ensure volume is at max - CRITICAL FOR AUDIO
      await _flutterTts.setVolume(1.0);
      print('✓ Volume set to: 1.0 (MAXIMUM)');
      
      // Set speech rate for clarity
      await _flutterTts.setSpeechRate(0.5);
      print('✓ Speech rate set to: 0.5 (CLEAR & SLOW)');
      
      // Set pitch
      await _flutterTts.setPitch(1.0);
      print('✓ Pitch set to: 1.0 (NORMAL)');
      
      // Set queue mode to flush (play immediately)
      // Note: setQueueMode is not available on web, so wrap in try-catch
      try {
        await _flutterTts.setQueueMode(1);
        print('✓ Queue mode: FLUSH (immediate playback)');
      } catch (e) {
        print('Note: setQueueMode not available on this platform');
      }
      
      // Stop any previous speech to avoid conflicts
      try {
        await _flutterTts.stop();
        print('✓ Stopped any previous speech');
      } catch (e) {
        print('Note: Could not stop previous speech: $e');
      }
      
      // Give a small delay between stop and start
      await Future.delayed(const Duration(milliseconds: 200));
      
      // Speak the text - THIS IS THE CRITICAL CALL
      print('🔊 Initiating speech synthesis...');
      final result = await _flutterTts.speak(text);
      
      print('Speech synthesis result code: $result');
      print('Result meaning: ${_interpretResultCode(result)}');

      // On web, flutter_tts.speak() returns null (the browser SpeechSynthesis
      // API is fire-and-forget). Treat null as success on web. Only -1 is a
      // real failure on any platform.
      if (result == 1 || (kIsWeb && result == null)) {
        print('✅ SUCCESS: Speaking started for: "$text"');
      } else if (result == 0) {
        print('⚠️  Speech synthesis returned 0 (may still be playing)');
      } else if (result == -1) {
        print('❌ ERROR: Failed to start speaking. Result code: $result');
      } else {
        print('Speech synthesis returned: $result (treating as success)');
      }
      print('═════════════════════════════════════════════');
    } catch (e) {
      print('❌ EXCEPTION during speakText: $e');
      print('Stack trace:');
      print(StackTrace.current);
      print('═════════════════════════════════════════════');
    }
  }
  
  String _interpretResultCode(dynamic code) {
    if (code == 1) return 'SUCCESS (1): Speech initiated';
    if (code == 0) return 'NEUTRAL (0): Unknown/May be playing';
    if (code == -1) return 'ERROR (-1): Synthesis failed';
    return 'UNKNOWN ($code): Unrecognized code';
  }

  Future<String> startListening({String language = 'ta-IN', int maxDuration = 10}) async {
    // Ensure initialization is complete
    if (!_speechToText.isAvailable) {
      print('Speech to text not available, reinitializing...');
      await _initializeSpeech();
      if (!_speechToText.isAvailable) {
        print('Speech to text still not available');
        return '';
      }
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
      List<stt.LocaleName> locales = [];
      try {
        locales = await _speechToText.locales();
        print('Available locales: ${locales.map((l) => l.localeId).toList()}');
      } catch (e) {
        print('Error getting locales: $e');
      }

      // Try different language codes for Tamil
      String effectiveLanguage = language;
      if (locales.isNotEmpty && !locales.any((l) => l.localeId == language)) {
        // Fallback options for Tamil
        if (locales.any((l) => l.localeId.startsWith('ta'))) {
          effectiveLanguage = locales.firstWhere((l) => l.localeId.startsWith('ta')).localeId;
        } else if (locales.any((l) => l.localeId == 'en-IN')) {
          effectiveLanguage = 'en-IN'; // Fallback to Indian English
        } else if (locales.isNotEmpty) {
          effectiveLanguage = locales.first.localeId; // Use first available
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
        onSoundLevelChange: (level) {
          print('Sound level: $level');
        },
      );

      // Wait with timeout
      final result = await _listeningCompleter!.future
          .timeout(
            Duration(seconds: maxDuration + 2),
            onTimeout: () {
              print('Listening timeout, returning: $_recognizedText');
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
      print('Returning result: $result');
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
