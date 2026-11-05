import 'dart:io' show File;

import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// Records one spoken answer as 16 kHz mono WAV — the exact format the
/// scoring server's librosa loader decodes without ffmpeg. (The old flow
/// never recorded at all; and AAC/webm uploads fail server-side.)
class VoiceRecorder {
  final AudioRecorder _rec = AudioRecorder();

  static const _config = RecordConfig(
    encoder: AudioEncoder.wav,
    sampleRate: 16000,
    numChannels: 1,
    autoGain: true,
    noiseSuppress: true,
  );

  /// True when this platform can produce WAV and the mic is permitted.
  Future<bool> canRecordWav() async {
    try {
      return await _rec.hasPermission() &&
          await _rec.isEncoderSupported(AudioEncoder.wav);
    } catch (_) {
      return false;
    }
  }

  Future<bool> start() async {
    try {
      if (!await _rec.hasPermission()) return false;
      final path = kIsWeb
          ? ''
          : '${(await getTemporaryDirectory()).path}/answer_${DateTime.now().millisecondsSinceEpoch}.wav';
      await _rec.start(_config, path: path);
      return true;
    } catch (e) {
      debugPrint('Recorder start failed: $e');
      return false;
    }
  }

  /// Stops and returns the WAV bytes, or null on failure.
  Future<List<int>?> stop() async {
    try {
      final path = await _rec.stop();
      if (path == null) return null;
      if (kIsWeb) {
        final res = await http.get(Uri.parse(path));
        return res.statusCode == 200 ? res.bodyBytes : null;
      }
      final file = File(path);
      final bytes = await file.readAsBytes();
      try {
        await file.delete();
      } catch (_) {}
      return bytes;
    } catch (e) {
      debugPrint('Recorder stop failed: $e');
      return null;
    }
  }

  Stream<double> levels() => _rec
      .onAmplitudeChanged(const Duration(milliseconds: 120))
      .map((a) => ((a.current + 50) / 50).clamp(0.0, 1.0));

  Future<void> dispose() async {
    try {
      await _rec.dispose();
    } catch (_) {}
  }
}
