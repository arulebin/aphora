import 'dart:io' show Directory, File;

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Family Voice: a parent's own recordings of the practice words, kept
/// ONLY on this device (app documents folder, never uploaded to the cloud).
///
/// One WAV per recordable item, named by the item's stable voice key
/// (`PracticeItem.voiceKey`, e.g. `kid_cat_ta`). The set of recorded keys is
/// held in memory so screens and the catalog can ask "is there a family
/// recording?" synchronously.
class FamilyVoiceStore {
  FamilyVoiceStore._();

  /// Store rooted in [dir] — used by tests.
  @visibleForTesting
  FamilyVoiceStore.forDirectory(Directory dir) : _dir = dir;

  static final FamilyVoiceStore instance = FamilyVoiceStore._();

  Directory? _dir;

  /// Keys that have a recording. Listen to rebuild progress counts.
  final recorded = ValueNotifier<Set<String>>(const {});

  /// Recordings need a real file system (not the web build).
  bool get isSupported => !kIsWeb;

  /// Recordings shorter than this are a mis-tap (~0.25 s of 16 kHz mono WAV).
  static const minBytes = 8000;

  /// File-safe form of a key: ids are ASCII already, this is belt and braces.
  static String fileNameFor(String key) =>
      '${key.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]+'), '_')}.wav';

  Future<Directory?> _folder() async {
    if (!isSupported) return null;
    if (_dir == null) {
      final docs = await getApplicationDocumentsDirectory();
      _dir = Directory('${docs.path}/family_voice');
    }
    if (!await _dir!.exists()) await _dir!.create(recursive: true);
    return _dir;
  }

  /// Reads which recordings exist. Safe to call more than once.
  Future<void> load() async {
    try {
      final dir = await _folder();
      if (dir == null) return;
      final keys = <String>{};
      await for (final f in dir.list()) {
        final name = f.uri.pathSegments.last;
        if (f is File && name.endsWith('.wav')) {
          keys.add(name.substring(0, name.length - 4));
        }
      }
      recorded.value = keys;
    } catch (e) {
      debugPrint('Family voice load failed: $e');
    }
  }

  String _id(String key) {
    final f = fileNameFor(key);
    return f.substring(0, f.length - 4);
  }

  bool has(String key) => recorded.value.contains(_id(key));

  /// How many of [keys] have a recording.
  int countRecorded(Iterable<String> keys) => keys.where(has).length;

  /// Path of the recording for [key], or null if there is none.
  Future<String?> pathFor(String key) async {
    if (!has(key)) return null;
    final dir = await _folder();
    if (dir == null) return null;
    final f = File('${dir.path}/${fileNameFor(key)}');
    return await f.exists() ? f.path : null;
  }

  Future<List<int>?> bytesFor(String key) async {
    final p = await pathFor(key);
    if (p == null) return null;
    try {
      return await File(p).readAsBytes();
    } catch (_) {
      return null;
    }
  }

  /// Saves (or replaces) the recording for [key]. Returns false if the
  /// recording is too short or the write failed.
  Future<bool> save(String key, List<int> wavBytes) async {
    if (wavBytes.length < minBytes) return false;
    try {
      final dir = await _folder();
      if (dir == null) return false;
      await File(
        '${dir.path}/${fileNameFor(key)}',
      ).writeAsBytes(wavBytes, flush: true);
      recorded.value = {...recorded.value, _id(key)};
      return true;
    } catch (e) {
      debugPrint('Family voice save failed: $e');
      return false;
    }
  }

  Future<void> delete(String key) async {
    try {
      final dir = await _folder();
      if (dir == null) return;
      final f = File('${dir.path}/${fileNameFor(key)}');
      if (await f.exists()) await f.delete();
    } catch (e) {
      debugPrint('Family voice delete failed: $e');
    }
    recorded.value = {...recorded.value}..remove(_id(key));
  }
}
