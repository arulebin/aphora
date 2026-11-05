import 'dart:async';

import 'package:aphora/logic/comfort_settings.dart';
import 'package:aphora/logic/language_service.dart';
import 'package:characters/characters.dart';
import 'package:flutter/foundation.dart' show ValueNotifier, debugPrint, kIsWeb;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Why a listening attempt ended without words.
enum ListenFailure { none, unavailable, permissionDenied, noSpeech, error }

/// One app-wide speech engine.
///
/// `speech_to_text` is a platform singleton whose `initialize()` only
/// registers callbacks on the *first* call. The old code created a new
/// SpeechService per page, so every page after the first never received
/// "done"/"error" events and sat on "Listening…" until a 12 s timeout.
/// Now there is exactly one instance; each listen() routes events to the
/// current attempt's completer.
class SpeechService {
  SpeechService._() {
    _ready = _init();
  }

  static final SpeechService shared = SpeechService._();

  /// Integration tests only: when set before the app starts, listening
  /// returns this callback's text instead of using the microphone, and the
  /// platform recogniser is never initialised (so no permission dialog).
  static Future<String> Function()? debugListenOverride;

  /// Kept for older call sites: always returns the shared instance.
  factory SpeechService() => shared;

  static String get appLanguageCode => appSpeechLocale;

  final stt.SpeechToText _stt = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  late final Future<void> _ready;

  bool _sttAvailable = false;
  bool _isListening = false;
  String _recognizedText = '';
  Completer<String>? _completer;
  ListenFailure lastFailure = ListenFailure.none;
  List<stt.LocaleName>? _locales;

  /// Live partial transcript while listening (for on-screen captions).
  final partial = ValueNotifier<String>('');

  /// 0–1 input level while listening (for a level meter).
  final soundLevel = ValueNotifier<double>(0);

  bool get isListening => _isListening;
  String get recognizedText => _recognizedText;

  Future<void> _init() async {
    try {
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      if (!kIsWeb) {
        try {
          await _tts.setQueueMode(1);
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('TTS init failed: $e');
    }
    await _initStt();
  }

  Future<void> _initStt() async {
    if (debugListenOverride != null) {
      _sttAvailable = true;
      return;
    }
    try {
      _sttAvailable = await _stt.initialize(
        // Without this the plugin asks for "Nearby devices" (Bluetooth)
        // permission the first time practice starts — alarming for a parent
        // or an older user, and the app never uses Bluetooth headsets.
        options: [stt.SpeechToText.androidNoBluetooth],
        onError: (error) {
          debugPrint('STT error: ${error.errorMsg}');
          lastFailure = error.errorMsg.contains('permission')
              ? ListenFailure.permissionDenied
              : (error.errorMsg.contains('no_match') ||
                      error.errorMsg.contains('speech_timeout'))
                  ? ListenFailure.noSpeech
                  : ListenFailure.error;
          _finish();
        },
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') _finish();
        },
      );
    } catch (e) {
      debugPrint('STT init failed: $e');
      _sttAvailable = false;
    }
  }

  void _finish() {
    if (_isListening && !(_completer?.isCompleted ?? true)) {
      _isListening = false;
      _completer!.complete(_recognizedText);
    }
  }

  // ── Text to speech ────────────────────────────────────────────────────

  Future<void> speakText(String text, {String? language, double? rate}) async {
    if (text.trim().isEmpty) return;
    await _ready;
    try {
      await _tts.stop();
      await _tts.setLanguage(language ?? appSpeechLocale);
      await _tts.setSpeechRate(
        rate ?? ComfortSettings.instance.speechRate.value,
      );
      await _tts.speak(text);
    } catch (e) {
      debugPrint('TTS speak failed: $e');
    }
  }

  Future<void> stopSpeaking() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }

  // ── Speech to text ────────────────────────────────────────────────────

  /// Listens for one answer and returns the transcript ('' if nothing was
  /// understood — check [lastFailure] for why).
  ///
  /// Pause and max duration default to the user's comfort settings, which
  /// are deliberately long: non-fluent aphasic speech has long pauses.
  Future<String> startListening({
    String? language,
    int? maxDuration,
    int? pauseSeconds,
  }) async {
    await _ready;
    lastFailure = ListenFailure.none;
    final fake = debugListenOverride;
    if (fake != null) {
      final heard = (await fake()).trim();
      partial.value = heard;
      if (heard.isEmpty) lastFailure = ListenFailure.noSpeech;
      return heard;
    }
    if (!_sttAvailable) {
      await _initStt();
      if (!_sttAvailable) {
        lastFailure = ListenFailure.unavailable;
        return '';
      }
    }
    if (_isListening) await stopListening();
    await stopSpeaking();

    final settings = ComfortSettings.instance;
    final maxSec = maxDuration ?? settings.listenMaxSeconds.value;
    final pauseSec = pauseSeconds ?? settings.listenPauseSeconds.value;
    final wanted = language ?? appSpeechLocale;

    _isListening = true;
    _recognizedText = '';
    partial.value = '';
    soundLevel.value = 0;
    _completer = Completer<String>();

    try {
      _locales ??= await _stt.locales();
    } catch (_) {
      _locales = const [];
    }
    final locales = _locales!;
    var localeId = wanted;
    if (locales.isNotEmpty && !locales.any((l) => l.localeId == wanted)) {
      final prefix = wanted.split('-').first;
      final match = locales.where((l) => l.localeId.startsWith(prefix));
      if (match.isNotEmpty) localeId = match.first.localeId;
    }

    try {
      await _stt.listen(
        onResult: (r) {
          _recognizedText = r.recognizedWords;
          partial.value = r.recognizedWords;
          if (r.finalResult) _finish();
        },
        localeId: localeId,
        listenFor: Duration(seconds: maxSec),
        pauseFor: Duration(seconds: pauseSec),
        onSoundLevelChange: (level) {
          // Platform levels are roughly -2..10 dB; normalise to 0..1.
          soundLevel.value = ((level + 2) / 12).clamp(0.0, 1.0);
        },
        listenOptions: stt.SpeechListenOptions(
          partialResults: true,
          cancelOnError: true,
          listenMode: stt.ListenMode.dictation,
        ),
      );
    } catch (e) {
      debugPrint('STT listen failed: $e');
      _isListening = false;
      lastFailure = ListenFailure.error;
      return '';
    }

    final result = await _completer!.future.timeout(
      Duration(seconds: maxSec + 3),
      onTimeout: () {
        _isListening = false;
        return _recognizedText;
      },
    );
    await stopListening();
    if (result.trim().isEmpty && lastFailure == ListenFailure.none) {
      lastFailure = ListenFailure.noSpeech;
    }
    soundLevel.value = 0;
    return result.trim();
  }

  Future<void> stopListening() async {
    try {
      await _stt.stop();
    } catch (_) {}
    _finish();
  }

  /// Pages call this on dispose; the shared engine stays alive, we only
  /// stop whatever is in progress.
  Future<void> dispose() async {
    await stopSpeaking();
    if (_isListening) await stopListening();
  }

  /// Human-readable reason for an empty answer.
  String failureMessage() => switch (lastFailure) {
        ListenFailure.unavailable => tr(
            'Speech recognition is not available on this device. You can type the answer instead.',
            'இந்த சாதனத்தில் பேச்சு அறிதல் இல்லை. பதிலை தட்டச்சு செய்யலாம்.',
          ),
        ListenFailure.permissionDenied => tr(
            'Vernacura needs microphone permission. Please allow it in your phone settings.',
            'மைக்ரோஃபோன் அனுமதி தேவை. தொலைபேசி அமைப்புகளில் அனுமதிக்கவும்.',
          ),
        ListenFailure.noSpeech => tr(
            "I didn't hear anything. Hold the phone closer and try again.",
            'எதுவும் கேட்கவில்லை. தொலைபேசியை அருகில் வைத்து மீண்டும் முயலவும்.',
          ),
        _ => tr(
            'Something went wrong while listening. Please try again.',
            'கேட்கும்போது பிழை. மீண்டும் முயலவும்.',
          ),
      };
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
