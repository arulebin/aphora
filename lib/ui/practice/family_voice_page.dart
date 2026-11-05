import 'dart:async';

import 'package:aphora/data/learning/packs/condition_packs.dart';
import 'package:aphora/data/learning/practice_catalog.dart';
import 'package:aphora/logic/family_voice_store.dart';
import 'package:aphora/logic/language_service.dart';
import 'package:aphora/logic/voice_recorder.dart';
import 'package:aphora/ui/design/components.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

/// Family Voice: Amma/Appa (or, for an adult, a family member or carer)
/// record the practice words in their own voice. Practice then plays that
/// voice instead of the phone's, and "Copy the voice" scores against it.
/// Recordings never leave the phone. What can be recorded comes from the
/// person's condition pack (`ConditionPack.familyVoiceSets`).
class FamilyVoicePage extends StatefulWidget {
  const FamilyVoicePage({super.key});

  @override
  State<FamilyVoicePage> createState() => _FamilyVoicePageState();
}

class _FamilyVoicePageState extends State<FamilyVoicePage> {
  final _store = FamilyVoiceStore.instance;
  final _recorder = VoiceRecorder();
  final _player = AudioPlayer();

  late final ConditionPack _pack = ConditionPacks.current;
  late final bool _child = ConditionPacks.currentChildWording;
  late final List<VoiceSet> _sets =
      _pack.familyVoiceSets(language: LanguageService.currentLanguage);
  late String _set = _sets.first.id;
  String? _recordingKey;
  String? _savingKey;
  String? _playingKey;
  Timer? _autoStop;

  /// Longest single recording — one word or a short phrase.
  static const _maxSeconds = 6;

  @override
  void initState() {
    super.initState();
    _store.load();
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _playingKey = null);
    });
  }

  @override
  void dispose() {
    _autoStop?.cancel();
    _recorder.dispose();
    _player.dispose();
    super.dispose();
  }

  VoiceSet get _current =>
      _sets.firstWhere((s) => s.id == _set, orElse: () => _sets.first);

  List<PracticeItem> get _items => _current.items;

  String _progressLabel(int done, int total) => _current.progress(done, total);

  Future<void> _startRecording(PracticeItem item) async {
    if (_recordingKey != null || _savingKey != null) return;
    await _player.stop();
    final ok = await _recorder.start();
    if (!mounted) return;
    if (!ok) {
      showAphSnack(
        context,
        tr(
          'Please allow the microphone to record your voice.',
          'உங்கள் குரலைப் பதிவு செய்ய மைக்ரோஃபோனை அனுமதிக்கவும்.',
        ),
        tone: FeedbackTone.warning,
      );
      return;
    }
    setState(() {
      _recordingKey = item.voiceKey;
      _playingKey = null;
    });
    _autoStop = Timer(const Duration(seconds: _maxSeconds), _stopRecording);
  }

  Future<void> _stopRecording() async {
    _autoStop?.cancel();
    final key = _recordingKey;
    if (key == null) return;
    setState(() {
      _recordingKey = null;
      _savingKey = key;
    });
    final bytes = await _recorder.stop();
    final saved = bytes != null && await _store.save(key, bytes);
    if (!mounted) return;
    setState(() => _savingKey = null);
    if (saved) {
      await _play(key);
    } else {
      showAphSnack(
        context,
        tr(
          'That was too short. Tap record, say the word, then tap stop.',
          'பதிவு மிகக் குறுகியது. பதிவைத் தட்டி, சொல்லைச் சொல்லி, நிறுத்தைத் தட்டவும்.',
        ),
        tone: FeedbackTone.warning,
      );
    }
  }

  Future<void> _play(String key) async {
    final path = await _store.pathFor(key);
    if (path == null) return;
    try {
      await _player.stop();
      await _player.play(DeviceFileSource(path));
      if (mounted) setState(() => _playingKey = key);
    } catch (_) {
      if (mounted) setState(() => _playingKey = null);
    }
  }

  Future<void> _delete(PracticeItem item) async {
    final ok = await confirmDialog(
      context,
      title: tr('Delete this recording?', 'இந்தப் பதிவை நீக்கவா?'),
      message: tr(
        'Practice will use the phone’s voice for “${item.target}” again.',
        '“${item.target}” க்கு மீண்டும் தொலைபேசியின் குரல் பயன்படும்.',
      ),
      confirm: tr('Delete', 'நீக்கு'),
      cancel: tr('Keep', 'வைத்திரு'),
      destructive: true,
    );
    if (!ok) return;
    await _player.stop();
    await _store.delete(item.voiceKey);
    if (mounted) setState(() => _playingKey = null);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    if (!_store.isSupported) {
      return AphScaffold(
        title: tr('Family Voice', 'குடும்பக் குரல்'),
        children: [
          EmptyState(
            icon: Icons.phone_android_rounded,
            title: tr(
              'Available in the phone app',
              'தொலைபேசி செயலியில் மட்டும்',
            ),
            message: tr(
              'Recordings are kept on the phone, so this needs the Android or iOS app.',
              'பதிவுகள் தொலைபேசியிலேயே இருக்கும்; Android/iOS செயலி தேவை.',
            ),
          ),
        ],
      );
    }
    return ValueListenableBuilder<Set<String>>(
      valueListenable: _store.recorded,
      builder: (context, _, _) {
        final items = _items;
        final done = _store.countRecorded(items.map((i) => i.voiceKey));
        return AphScaffold(
          title: tr('Family Voice', 'குடும்பக் குரல்'),
          children: [
            Text(
              _child
                  ? tr(
                      'Record each word in your own voice. Your child will hear Amma or Appa instead of the phone.',
                      'ஒவ்வொரு சொல்லையும் உங்கள் குரலில் பதிவு செய்யுங்கள். குழந்தை தொலைபேசிக் குரலுக்குப் பதிலாக அம்மா/அப்பா குரலைக் கேட்கும்.',
                    )
                  : tr(
                      'Record each word in a familiar voice — yours or a family member’s. Practice then plays that voice instead of the phone.',
                      'ஒவ்வொரு சொல்லையும் பழக்கமான குரலில் — உங்கள் குரலிலோ குடும்பத்தினர் குரலிலோ — பதிவு செய்யுங்கள். பயிற்சியில் தொலைபேசிக் குரலுக்குப் பதிலாக அந்தக் குரல் ஒலிக்கும்.',
                    ),
              style: t.bodyLarge,
            ),
            const Gap(AphSpace.sm),
            Align(
              alignment: Alignment.centerLeft,
              child: StatusPill(
                label: tr(
                  'Stays on this phone — never uploaded',
                  'இந்தத் தொலைபேசியிலேயே இருக்கும் — பதிவேற்றப்படாது',
                ),
                icon: Icons.lock_rounded,
              ),
            ),
            const Gap(AphSpace.md),
            ChoiceGroup<String>(
              label: tr('What to record', 'எதைப் பதிவு செய்வது'),
              value: _set,
              onChanged: _recordingKey == null
                  ? (v) => setState(() => _set = v)
                  : (_) {},
              options: [for (final s in _sets) (s.id, s.label, s.icon)],
            ),
            const Gap(AphSpace.md),
            Semantics(
              liveRegion: true,
              child: Text(
                _progressLabel(done, items.length),
                key: const ValueKey('fv_progress'),
                style: t.titleMedium,
              ),
            ),
            const Gap(AphSpace.xs),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: items.isEmpty ? 0 : done / items.length,
                minHeight: 10,
                backgroundColor: AphColors.surfaceSunken,
                color: AphColors.success,
              ),
            ),
            const Gap(AphSpace.md),
            AphCard(
              padding: const EdgeInsets.symmetric(
                horizontal: AphSpace.sm,
                vertical: AphSpace.xxs,
              ),
              child: Column(
                children: [
                  for (final (i, item) in items.indexed) ...[
                    if (i > 0) const Divider(height: 1),
                    _row(context, item),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  static bool _hasPicture(PracticeItem i) =>
      i.emoji != null || i.imagePath != null || i.icon != null;

  Widget _row(BuildContext context, PracticeItem item) {
    final t = Theme.of(context).textTheme;
    final key = item.voiceKey;
    final has = _store.has(key);
    final recording = _recordingKey == key;
    final saving = _savingKey == key;
    final busy = _recordingKey != null || _savingKey != null;

    Widget trailing;
    if (recording) {
      trailing = FilledButton.icon(
        style: FilledButton.styleFrom(backgroundColor: AphColors.danger),
        onPressed: _stopRecording,
        icon: const Icon(Icons.stop_rounded),
        label: Text(tr('Stop', 'நிறுத்து')),
      );
    } else if (saving) {
      trailing = const Padding(
        padding: EdgeInsets.all(AphSpace.sm),
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 3),
        ),
      );
    } else if (has) {
      trailing = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: tr('Play', 'கேள்'),
            onPressed: busy ? null : () => _play(key),
            icon: Icon(
              _playingKey == key
                  ? Icons.volume_up_rounded
                  : Icons.play_arrow_rounded,
            ),
            color: AphColors.primary,
          ),
          IconButton(
            tooltip: tr('Record again', 'மீண்டும் பதிவு செய்'),
            onPressed: busy ? null : () => _startRecording(item),
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: tr('Delete', 'நீக்கு'),
            onPressed: busy ? null : () => _delete(item),
            icon: const Icon(Icons.delete_outline_rounded),
            color: AphColors.danger,
          ),
        ],
      );
    } else {
      trailing = OutlinedButton.icon(
        onPressed: busy ? null : () => _startRecording(item),
        icon: const Icon(Icons.mic_rounded),
        label: Text(tr('Record', 'பதிவு')),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AphSpace.xs),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: item.emoji != null
                ? Text(
                    item.emoji!,
                    style: const TextStyle(fontSize: 30),
                    textAlign: TextAlign.center,
                  )
                : item.imagePath != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(AphRadius.sm),
                        child: Image.asset(
                          item.imagePath!,
                          height: 40,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const Icon(
                              Icons.image_rounded,
                              color: AphColors.inkSubtle),
                        ),
                      )
                    : item.icon != null
                        ? Icon(item.icon, size: 30, color: AphColors.inkMuted)
                        : Icon(
                            has
                                ? Icons.check_circle_rounded
                                : Icons.circle_outlined,
                            color: has ? AphColors.success : AphColors.inkSubtle,
                          ),
          ),
          const Gap(AphSpace.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.target, style: t.titleMedium),
                if (recording)
                  Text(
                    tr(
                      'Recording… say it now',
                      'பதிவாகிறது… இப்போது சொல்லுங்கள்',
                    ),
                    style: t.bodySmall?.copyWith(color: AphColors.danger),
                  )
                else if (item.meaning != null)
                  Text(item.meaning!, style: t.bodySmall),
                if (has && _hasPicture(item) && !recording)
                  Row(
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 14,
                        color: AphColors.success,
                      ),
                      const Gap(AphSpace.xxs),
                      Text(
                        tr('Recorded', 'பதிவானது'),
                        style: t.bodySmall?.copyWith(color: AphColors.success),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}
