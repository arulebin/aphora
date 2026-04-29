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

  String get baseUrl => _baseUrl;

  static String _resolveDefaultBaseUrl() {
    if (kIsWeb) {
      return 'http://localhost:8000';
    }
    try {
      if (Platform.isAndroid) {
        // Android emulator loopback to host machine.
        return 'http://10.0.2.2:8000';
      }
    } catch (_) {
      // Platform unavailable (web caught above; ignore otherwise).
    }
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

  /// Evaluate the user's recording against a reference asset.
  ///
  /// [referenceAssetPath] is a Flutter asset path (e.g. `assets/vannakam.wav`).
  /// [userAudioPath] is the on-device path to the recorded user audio.
  Future<EvaluationResult> evaluateAgainstAsset({
    required String referenceAssetPath,
    required String userAudioPath,
    String? referenceText,
  }) async {
    final byteData = await rootBundle.load(referenceAssetPath);
    final refBytes = byteData.buffer.asUint8List();

    final refFilename = referenceAssetPath.split('/').last;
    return evaluate(
      referenceBytes: refBytes,
      referenceFilename: refFilename,
      userAudioPath: userAudioPath,
      referenceText: referenceText,
    );
  }

  Future<EvaluationResult> evaluate({
    required List<int> referenceBytes,
    String referenceFilename = 'reference.wav',
    required String userAudioPath,
    String? referenceText,
  }) async {
    final uri = Uri.parse('$_baseUrl/evaluate');
    final request = http.MultipartRequest('POST', uri);

    request.files.add(
      http.MultipartFile.fromBytes(
        'reference_audio',
        referenceBytes,
        filename: referenceFilename,
      ),
    );

    if (kIsWeb) {
      // On web the recorder returns a blob URL; fetch the bytes first.
      final audioResponse = await http.get(Uri.parse(userAudioPath));
      if (audioResponse.statusCode != 200) {
        throw AphoraApiException(
          'Could not read recorded audio blob.',
          statusCode: audioResponse.statusCode,
        );
      }
      request.files.add(
        http.MultipartFile.fromBytes(
          'user_audio',
          audioResponse.bodyBytes,
          filename: 'user_${DateTime.now().millisecondsSinceEpoch}.wav',
        ),
      );
    } else {
      request.files.add(
        await http.MultipartFile.fromPath('user_audio', userAudioPath),
      );
    }

    if (referenceText != null && referenceText.trim().isNotEmpty) {
      request.fields['reference_text'] = referenceText.trim();
    }

    final streamed = await request.send();
    final body = await streamed.stream.bytesToString();

    if (streamed.statusCode != 200) {
      throw AphoraApiException(
        body.isNotEmpty ? body : 'Evaluation request failed.',
        statusCode: streamed.statusCode,
      );
    }

    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      return EvaluationResult.fromJson(json);
    } catch (e) {
      throw AphoraApiException('Invalid response from API: $e');
    }
  }
}
