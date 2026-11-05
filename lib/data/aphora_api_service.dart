import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;

class EvaluationResult {
  final double combinedAccuracy;
  final String feedbackMessage;
  final double accuracy;
  final double audioSimilarity;
  final String deviationPosition;
  final int? deviationIndex;
  final List<int> mismatchIndices;
  final double dtwDistance;
  final int alignmentPathLength;
  final String? referenceText;
  final String? userText;
  final double? textSimilarity;
  final double? characterErrorRate;
  final double? wordErrorRate;
  final double processingTimeMs;

  EvaluationResult({
    required this.combinedAccuracy,
    required this.feedbackMessage,
    required this.accuracy,
    required this.audioSimilarity,
    required this.deviationPosition,
    required this.deviationIndex,
    required this.mismatchIndices,
    required this.dtwDistance,
    required this.alignmentPathLength,
    required this.referenceText,
    required this.userText,
    required this.textSimilarity,
    required this.characterErrorRate,
    required this.wordErrorRate,
    required this.processingTimeMs,
  });

  bool get isCorrect => combinedAccuracy >= 70;

  factory EvaluationResult.fromJson(Map<String, dynamic> json) {
    return EvaluationResult(
      combinedAccuracy: (json['combined_accuracy'] as num? ?? 0).toDouble(),
      feedbackMessage: json['feedback_message']?.toString() ?? '',
      accuracy: (json['accuracy'] as num? ?? 0).toDouble(),
      audioSimilarity: (json['audio_similarity'] as num? ?? 0).toDouble(),
      deviationPosition: json['deviation_position']?.toString() ?? 'PERFECT',
      deviationIndex: (json['deviation_index'] as num?)?.toInt(),
      mismatchIndices: (json['mismatch_indices'] as List?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const [],
      dtwDistance: (json['dtw_distance'] as num? ?? 0).toDouble(),
      alignmentPathLength: (json['alignment_path_length'] as num? ?? 0).toInt(),
      referenceText: json['reference_text']?.toString(),
      userText: json['user_text']?.toString(),
      textSimilarity: (json['text_similarity'] as num?)?.toDouble(),
      characterErrorRate: (json['character_error_rate'] as num?)?.toDouble(),
      wordErrorRate: (json['word_error_rate'] as num?)?.toDouble(),
      processingTimeMs: (json['processing_time_ms'] as num? ?? 0).toDouble(),
    );
  }
}

class AphoraApiException implements Exception {
  final int? statusCode;
  final String message;
  AphoraApiException(this.message, {this.statusCode});

  @override
  String toString() => 'AphoraApiException($statusCode): $message';
}

/// Client for the Aphora speech evaluation FastAPI backend.
///
/// The backend exposes `POST /evaluate` which accepts two audio files
/// (reference + user) and an optional `reference_text` field, and returns
/// a combined audio + text accuracy score plus detailed metrics.
class AphoraApiService {
  AphoraApiService({String? baseUrl})
      : _baseUrl = baseUrl ?? _resolveDefaultBaseUrl();

  final String _baseUrl;
  bool? _reachable;
  DateTime? _checkedAt;

  String get baseUrl => _baseUrl;

  /// Build with `--dart-define=API_BASE_URL=https://your-host` for real
  /// devices. The fallbacks only work for a server on the dev machine.
  static const _configured = String.fromEnvironment('API_BASE_URL');

  static String _resolveDefaultBaseUrl() {
    if (_configured.isNotEmpty) return _configured;
    if (kIsWeb) return 'http://localhost:8000';
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:8000'; // emulator
    } catch (_) {}
    return 'http://127.0.0.1:8000';
  }

  Future<bool> ping() async {
    try {
      final res = await http
          .get(Uri.parse('$_baseUrl/health'))
          .timeout(const Duration(seconds: 4));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Cached reachability (re-checked every 2 minutes) so exercises can
  /// decide between server scoring and on-device scoring without delay.
  Future<bool> isReachable() async {
    final fresh = _checkedAt != null &&
        DateTime.now().difference(_checkedAt!) < const Duration(minutes: 2);
    if (_reachable != null && fresh) return _reachable!;
    _reachable = await ping();
    _checkedAt = DateTime.now();
    return _reachable!;
  }

  /// Evaluate the user's recording against a bundled reference asset.
  Future<EvaluationResult> evaluateAgainstAsset({
    required String referenceAssetPath,
    required List<int> userAudioBytes,
    String? referenceText,
    String? language,
  }) async {
    final byteData = await rootBundle.load(referenceAssetPath);
    return evaluate(
      referenceBytes: byteData.buffer.asUint8List(),
      referenceFilename: referenceAssetPath.split('/').last,
      userAudioBytes: userAudioBytes,
      referenceText: referenceText,
      language: language,
    );
  }

  Future<EvaluationResult> evaluate({
    required List<int> referenceBytes,
    String referenceFilename = 'reference.wav',
    required List<int> userAudioBytes,
    String userFilename = 'user.wav',
    String? referenceText,
    String? language,
    Duration timeout = const Duration(seconds: 45),
  }) async {
    final request =
        http.MultipartRequest('POST', Uri.parse('$_baseUrl/evaluate'))
          ..files.add(http.MultipartFile.fromBytes(
            'reference_audio',
            referenceBytes,
            filename: referenceFilename,
          ))
          ..files.add(http.MultipartFile.fromBytes(
            'user_audio',
            userAudioBytes,
            filename: userFilename,
          ));
    if (referenceText != null && referenceText.trim().isNotEmpty) {
      request.fields['reference_text'] = referenceText.trim();
    }
    if (language != null) request.fields['language'] = language;

    final http.StreamedResponse streamed;
    final String body;
    try {
      streamed = await request.send().timeout(timeout);
      body = await streamed.stream.bytesToString().timeout(timeout);
    } on TimeoutException {
      _reachable = false;
      throw AphoraApiException('The scoring server took too long to answer.');
    } catch (e) {
      _reachable = false;
      throw AphoraApiException('Could not reach the scoring server.');
    }

    if (streamed.statusCode != 200) {
      throw AphoraApiException(
        _detail(body) ?? 'Evaluation failed (${streamed.statusCode}).',
        statusCode: streamed.statusCode,
      );
    }
    try {
      return EvaluationResult.fromJson(
        jsonDecode(body) as Map<String, dynamic>,
      );
    } catch (e) {
      throw AphoraApiException('The server sent an unexpected answer.');
    }
  }

  /// FastAPI errors look like {"detail": "..."} (or a list for 422s).
  static String? _detail(String body) {
    try {
      final d = (jsonDecode(body) as Map<String, dynamic>)['detail'];
      if (d is String) return d;
      if (d is List && d.isNotEmpty) return d.first['msg']?.toString();
    } catch (_) {}
    return null;
  }
}
