import 'dart:async';
import 'dart:io' show Platform;

import 'package:characters/characters.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

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

  /// Synthesize [text] to a WAV file on disk and return its path.
  ///
  /// Used by the assessment flow to produce a reference audio clip on
  /// the fly so we don't need a pre-recorded reference for every word
  /// in the dataset. Returns `null` on platforms where file synthesis
  /// isn't supported (web, or if the TTS engine refuses).
  Future<String?> synthesizeToFile(
    String text, {
    String language = 'ta-IN',
  }) async {
    if (text.trim().isEmpty) return null;
    if (kIsWeb) return null;

    try {
      await _flutterTts.setLanguage(language);
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setVolume(1.0);

      final fileName =
          'tts_ref_${DateTime.now().millisecondsSinceEpoch}.wav';

      // Android: write into the app documents dir; flutter_tts resolves
      // relative names against that directory.
      // iOS: must use an absolute path inside the app sandbox.
      String? targetPath;
      try {
        if (Platform.isIOS) {
          final dir = await getApplicationDocumentsDirectory();
          targetPath = '${dir.path}/$fileName';
        }
      } catch (_) {
        targetPath = null;
      }

      final result = await _flutterTts.synthesizeToFile(
        text,
        targetPath ?? fileName,
      );

      if (result == 1) {
        if (targetPath != null) return targetPath;
        // Resolve the Android documents dir to give back a real path.
        try {
          final dir = await getApplicationDocumentsDirectory();
          return '${dir.path}/$fileName';
        } catch (_) {
          return fileName;
        }
      }
      return null;
    } catch (e) {
      print('synthesizeToFile failed: $e');
      return null;
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

/// Detailed result of comparing what the patient said against the
/// expected phrase. The list of [mispronouncedLetters] is what drives
/// the targeted training drill.
class PronunciationAnalysis {
  /// 0-100 character-level similarity (Levenshtein on grapheme clusters).
  final double similarity;

  /// True only when [actual] matches [expected] perfectly after normalization.
  final bool isPerfect;

  /// Unique grapheme clusters from [expected] that appear to have been
  /// substituted, missed, or otherwise mispronounced. Whitespace is
  /// excluded. Order preserves the order of appearance in [expected].
  final List<String> mispronouncedLetters;

  final String expectedNormalized;
  final String actualNormalized;

  const PronunciationAnalysis({
    required this.similarity,
    required this.isPerfect,
    required this.mispronouncedLetters,
    required this.expectedNormalized,
    required this.actualNormalized,
  });

  /// Treat scores \u2265 95% with no missed letters as a clean pass.
  bool get isCorrect => isPerfect || (similarity >= 95 && mispronouncedLetters.isEmpty);

  /// Whether to trigger the per-letter training drill. Even one
  /// mispronounced letter qualifies \u2014 that's the whole point.
  bool get needsTraining => mispronouncedLetters.isNotEmpty;
}

/// Evaluates similarity between two texts.
///
/// All comparisons operate on **grapheme clusters** (`Characters`) so
/// Tamil combining marks like \u0BC8, \u0BC1, \u0BCD are treated as part of the
/// preceding letter rather than independent characters.
class TextEvaluator {
  /// Backwards-compatible: returns a 0-100 similarity score only.
  /// Delegates to [analyze] so the legacy entry point benefits from
  /// the grapheme-aware comparison too.
  static double calculateSimilarity(String expected, String actual) {
    return analyze(expected, actual).similarity;
  }

  static String _normalize(String text) {
    return text
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ')
        // Strip punctuation but keep Tamil block (\u0B80\u2013\u0BFF), ASCII
        // letters and digits, and spaces.
        .replaceAll(RegExp(r'[^a-z0-9\u0B80-\u0BFF\s]'), '');
  }

  /// Run a full character-level analysis between [expected] and [actual]
  /// and return the list of letters in [expected] that don't have a
  /// matching counterpart in [actual].
  static PronunciationAnalysis analyze(String expected, String actual) {
    final normExpected = _normalize(expected);
    final normActual = _normalize(actual);

    if (normExpected.isEmpty || normActual.isEmpty) {
      return PronunciationAnalysis(
        similarity: 0.0,
        isPerfect: false,
        mispronouncedLetters: const [],
        expectedNormalized: normExpected,
        actualNormalized: normActual,
      );
    }

    if (normExpected == normActual) {
      return PronunciationAnalysis(
        similarity: 100.0,
        isPerfect: true,
        mispronouncedLetters: const [],
        expectedNormalized: normExpected,
        actualNormalized: normActual,
      );
    }

    // Grapheme-cluster aware tokenization (correct for Tamil).
    final expectedChars = normExpected.characters.toList();
    final actualChars = normActual.characters.toList();

    final ops = _alignmentOps(expectedChars, actualChars);

    // A grapheme is "mispronounced" if it was substituted or deleted
    // in the alignment from expected \u2192 actual.
    final mispronounced = <String>[];
    final seen = <String>{};
    for (final op in ops) {
      if (op.kind == _OpKind.substitute || op.kind == _OpKind.delete) {
        final g = op.expectedChar;
        if (g != null && g.trim().isNotEmpty && seen.add(g)) {
          mispronounced.add(g);
        }
      }
    }

    final maxLen = expectedChars.length > actualChars.length
        ? expectedChars.length
        : actualChars.length;
    final edits = ops.where((o) => o.kind != _OpKind.match).length;
    final similarity = maxLen == 0
        ? 0.0
        : ((maxLen - edits) / maxLen * 100).clamp(0.0, 100.0);

    return PronunciationAnalysis(
      similarity: similarity.toDouble(),
      isPerfect: false,
      mispronouncedLetters: mispronounced,
      expectedNormalized: normExpected,
      actualNormalized: normActual,
    );
  }

  /// Levenshtein backtrace, returning the edit operations that turn
  /// [expected] into [actual]. Used to identify which expected
  /// graphemes were substituted or deleted.
  static List<_EditOp> _alignmentOps(
    List<String> expected,
    List<String> actual,
  ) {
    final n = expected.length;
    final m = actual.length;
    final dp = List.generate(n + 1, (_) => List<int>.filled(m + 1, 0));
    for (int i = 0; i <= n; i++) {
      dp[i][0] = i;
    }
    for (int j = 0; j <= m; j++) {
      dp[0][j] = j;
    }
    for (int i = 1; i <= n; i++) {
      for (int j = 1; j <= m; j++) {
        if (expected[i - 1] == actual[j - 1]) {
          dp[i][j] = dp[i - 1][j - 1];
        } else {
          final del = dp[i - 1][j] + 1;
          final ins = dp[i][j - 1] + 1;
          final sub = dp[i - 1][j - 1] + 1;
          dp[i][j] = del < ins ? (del < sub ? del : sub) : (ins < sub ? ins : sub);
        }
      }
    }

    final ops = <_EditOp>[];
    int i = n;
    int j = m;
    while (i > 0 || j > 0) {
      if (i > 0 && j > 0 && expected[i - 1] == actual[j - 1]) {
        ops.add(_EditOp(_OpKind.match, expected[i - 1], actual[j - 1]));
        i--;
        j--;
      } else if (i > 0 && j > 0 && dp[i][j] == dp[i - 1][j - 1] + 1) {
        ops.add(_EditOp(_OpKind.substitute, expected[i - 1], actual[j - 1]));
        i--;
        j--;
      } else if (i > 0 && dp[i][j] == dp[i - 1][j] + 1) {
        ops.add(_EditOp(_OpKind.delete, expected[i - 1], null));
        i--;
      } else if (j > 0 && dp[i][j] == dp[i][j - 1] + 1) {
        ops.add(_EditOp(_OpKind.insert, null, actual[j - 1]));
        j--;
      } else {
        break;
      }
    }

    return ops.reversed.toList(growable: false);
  }
}

enum _OpKind { match, substitute, insert, delete }

class _EditOp {
  final _OpKind kind;
  final String? expectedChar;
  final String? actualChar;
  const _EditOp(this.kind, this.expectedChar, this.actualChar);
}
