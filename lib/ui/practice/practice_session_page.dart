import 'dart:async';

import 'package:aphora/data/learning/practice_catalog.dart';
import 'package:aphora/data/models/practice_record.dart';
import 'package:aphora/logic/comfort_settings.dart';
import 'package:aphora/logic/language_service.dart';
import 'package:aphora/logic/locator.dart';
import 'package:aphora/logic/speech_service.dart';
import 'package:aphora/logic/voice_recorder.dart';
import 'package:aphora/ui/design/components.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Opens a practice session. Returns when the person leaves the summary.
Future<void> openPractice(
  BuildContext context,
  PracticeKind kind, {
  List<PracticeItem>? items,
}) {
  return Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => PracticeSessionPage(kind: kind, items: items),
    ),
  );
}

/// The single exercise engine: prompt → listen → score → feedback, for
/// every speaking task in the app.
class PracticeSessionPage extends StatefulWidget {
  const PracticeSessionPage({super.key, required this.kind, this.items});

  final PracticeKind kind;
  final List<PracticeItem>? items;

  @override
  State<PracticeSessionPage> createState() => _PracticeSessionPageState();
}

enum _Phase { handoff, prompt, summary }

class _Result {
  _Result({
    required this.score,
    required this.spoken,
    required this.method,
    this.serverFeedback,
    this.tricky = const [],
  });
  final double score;
  final String spoken;
  final String method;
  final String? serverFeedback;
  final List<String> tricky;
}

class _PracticeSessionPageState extends State<PracticeSessionPage> {
  final _speech = SpeechService.shared;
  final _recorder = VoiceRecorder();
  final _player = AudioPlayer();
  final _typed = TextEditingController();
  final _note = TextEditingController();
  final _started = DateTime.now();

  late final List<PracticeItem> _items =
      widget.items ?? PracticeCatalog.items(widget.kind);
  late _Phase _phase =
      ComfortSettings.instance.assistedMode.value ? _Phase.handoff : _Phase.prompt;

  int _index = 0;
  MicState _mic = MicState.idle;
  int _cue = 0; // naming hint ladder: 0 none, 1 meaning, 2 first sound, 3 word
  bool _typing = false;
  _Result? _current;
  String? _error;
  final Map<int, _Result> _best = {};
  final Set<String> _trickyAll = {};

  bool _serverAvailable = false;
  Timer? _autoStop;
  bool _saving = false;
  bool _saved = false;

  bool get _isAssessment => widget.kind == PracticeKind.assessment;
  bool get _assisted => ComfortSettings.instance.assistedMode.value;
  PracticeItem get _item => _items[_index];
  bool get _wordVisible => !_item.hideTarget || _cue >= 3;

  @override
  void initState() {
    super.initState();
    _checkServer();
  }

  Future<void> _checkServer() async {
    if (!_items.any((i) => i.referenceAudio != null)) return;
    final ok = await Locator.aphoraApiService.isReachable() &&
        await _recorder.canRecordWav();
    if (mounted) setState(() => _serverAvailable = ok);
  }

  @override
  void dispose() {
    _autoStop?.cancel();
    _speech.dispose();
    _recorder.dispose();
    _player.dispose();
    _typed.dispose();
    _note.dispose();
    super.dispose();
  }

  // ── Listening & scoring ──────────────────────────────────────────────

  bool get _useServer => _serverAvailable && _item.referenceAudio != null;

  Future<void> _onMic() async {
    if (_mic == MicState.processing) return;
    if (_mic == MicState.listening) {
      _useServer ? await _stopRecording() : await _speech.stopListening();
      return;
    }
    setState(() {
      _error = null;
      _current = null;
    });
    _useServer ? await _startRecording() : await _listenOnDevice();
  }

  Future<void> _listenOnDevice() async {
    setState(() => _mic = MicState.listening);
    final spoken = await _speech.startListening(language: _item.locale);
    if (!mounted) return;
    if (spoken.isEmpty) {
      setState(() {
        _mic = MicState.idle;
        _error = _speech.failureMessage();
      });
      return;
    }
    _score(spoken, method: 'device');
  }

  Future<void> _startRecording() async {
    final ok = await _recorder.start();
    if (!ok) {
      // Fall back to device recognition for the rest of the session.
      setState(() => _serverAvailable = false);
      await _listenOnDevice();
      return;
    }
    setState(() => _mic = MicState.listening);
    _autoStop = Timer(
      Duration(seconds: ComfortSettings.instance.listenMaxSeconds.value),
      _stopRecording,
    );
  }

  Future<void> _stopRecording() async {
    _autoStop?.cancel();
    if (_mic != MicState.listening) return;
    setState(() => _mic = MicState.processing);
    final bytes = await _recorder.stop();
    if (!mounted) return;
    if (bytes == null || bytes.length < 8000) {
      setState(() {
        _mic = MicState.idle;
        _error = tr(
          "That was too short to check. Tap the microphone, speak, then tap again.",
          'பதிவு மிகக் குறுகியது. மைக்கைத் தட்டி, பேசி, மீண்டும் தட்டவும்.',
        );
      });
      return;
    }
    try {
      final r = await Locator.aphoraApiService.evaluateAgainstAsset(
        referenceAssetPath: _item.referenceAudio!,
        userAudioBytes: bytes,
        referenceText: _item.target,
        language: _item.locale.split('-').first,
      );
      _commit(_Result(
        score: r.combinedAccuracy,
        spoken: r.userText ?? '',
        method: 'server',
        serverFeedback: r.feedbackMessage,
      ));
    } on Exception catch (e) {
      setState(() {
        _serverAvailable = false;
        _mic = MicState.idle;
        _error = tr(
          'The scoring server is not reachable ($e). Switched to on-phone listening — please try again.',
          'மதிப்பீட்டு சேவையகம் கிடைக்கவில்லை. தொலைபேசியிலேயே கேட்கிறோம் — மீண்டும் முயலவும்.',
        );
      });
    }
  }

  void _score(String spoken, {required String method}) {
    var best = TextEvaluator.analyze(_item.target, spoken);
    for (final alt in _item.alternates) {
      final a = TextEvaluator.analyze(alt, spoken);
      if (a.similarity > best.similarity) best = a;
    }
    final fromTarget = TextEvaluator.analyze(_item.target, spoken);
    // A hint lowers the credit a little, the way therapists score cued
    // responses — but never below the honest similarity floor.
    final penalty = _item.hideTarget ? [0, 5, 10, 20][_cue] : 0;
    _commit(_Result(
      score: (best.similarity - penalty).clamp(0, 100).toDouble(),
      spoken: spoken,
      method: method,
      tricky: best.similarity >= 85 ? const [] : fromTarget.mispronouncedLetters,
    ));
  }

  void _commit(_Result r) {
    HapticFeedback.lightImpact();
    final prev = _best[_index];
    setState(() {
      _mic = MicState.idle;
      _current = r;
      if (prev == null || r.score > prev.score) _best[_index] = r;
      _trickyAll.addAll(r.tricky);
    });
    // Persist each attempt; failures are non-fatal (offline queue in
    // Firestore will retry).
    Locator.userDatabaseService
        .recordExerciseResult(
          taskId: _item.id,
          accuracy: r.score,
          category: widget.kind.id,
          target: _item.target,
          spoken: r.spoken,
          method: r.method,
          assisted: _assisted,
        )
        .catchError((_) => null);
    final band = ScoreBand.of(r.score);
    if (ComfortSettings.instance.autoReadAloud.value) {
      _speech.speakText(_praise(band, r.score));
    }
  }

  void _submitTyped() {
    final text = _typed.text.trim();
    if (text.isEmpty) return;
    FocusScope.of(context).unfocus();
    _score(text, method: 'typed');
    _typed.clear();
    setState(() => _typing = false);
  }

  String _praise(ScoreBand band, double score) {
    if (score >= 85) return tr('Excellent!', 'மிகச் சிறப்பு!');
    if (score >= 70) return tr('Well done!', 'நன்றாகச் செய்தீர்கள்!');
    if (score >= 45) return tr('Nearly there. Try once more.', 'கிட்டத்தட்ட சரி. மீண்டும் முயலுங்கள்.');
    return tr("Good effort. Let's listen again and try.", 'நல்ல முயற்சி. மீண்டும் கேட்டு முயலுங்கள்.');
  }

  Future<void> _playModel() async {
    final ref = _item.referenceAudio;
    if (ref != null) {
      try {
        await _player.stop();
        await _player.play(AssetSource(ref.replaceFirst('assets/', '')));
        return;
      } catch (_) {/* fall through to TTS */}
    }
    await _speech.speakText(_item.target, language: _item.locale);
  }

  // ── Navigation ───────────────────────────────────────────────────────

  void _next() {
    if (_index >= _items.length - 1) {
      setState(() => _phase = _Phase.summary);
      // In assisted mode we wait for the helper's note before saving.
      if (!_assisted) _saveSession();
      return;
    }
    setState(() {
      _index++;
      _current = null;
      _error = null;
      _cue = 0;
      _typing = false;
    });
  }

  void _skip() {
    _next();
  }

  double get _average {
    if (_isAssessment) {
      // Skipped items count as 0 in a placement test.
      final total = _best.values.fold<double>(0, (a, r) => a + r.score);
      return _items.isEmpty ? 0 : total / _items.length;
    }
    if (_best.isEmpty) return 0;
    return _best.values.fold<double>(0, (a, r) => a + r.score) / _best.length;
  }

  Future<void> _saveSession() async {
    if (_saved || _best.isEmpty) return;
    setState(() => _saving = true);
    try {
      final minutes =
          (DateTime.now().difference(_started).inSeconds / 60).ceil();
      await Locator.userDatabaseService.recordSession(SessionRecord(
        kind: widget.kind.id,
        title: widget.kind.title,
        itemCount: _best.length,
        averageScore: _average,
        minutes: minutes,
        assisted: _assisted,
        helperName: _assisted ? ComfortSettings.instance.helperName.value : null,
        note: _note.text.trim().isEmpty ? null : _note.text.trim(),
        createdAt: DateTime.now(),
      ));
      if (_isAssessment) {
        await Locator.userDatabaseService.savePreAssessment(
          score: _average,
          recommendedFocus: PracticeCatalog.focusFor(_average),
        );
      }
      await ComfortSettings.instance
          .markPlanDone(dayKey(DateTime.now()), widget.kind.id);
      _saved = true;
    } catch (_) {
      if (mounted) {
        showAphSnack(
          context,
          tr('Could not save this session. Check your internet connection.',
              'இந்த அமர்வைச் சேமிக்க முடியவில்லை.'),
          tone: FeedbackTone.error,
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<bool> _confirmLeave() async {
    if (_phase == _Phase.summary || _best.isEmpty) return true;
    return confirmDialog(
      context,
      title: tr('Stop practising?', 'பயிற்சியை நிறுத்தவா?'),
      message: tr(
        'Answers you already gave are saved.',
        'நீங்கள் ஏற்கனவே சொன்ன பதில்கள் சேமிக்கப்பட்டுள்ளன.',
      ),
      confirm: tr('Stop', 'நிறுத்து'),
      cancel: tr('Keep going', 'தொடரவும்'),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _best.isEmpty || (_phase == _Phase.summary && _saved),
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (_phase == _Phase.summary) {
          await _saveSession();
          if (context.mounted) Navigator.of(context).pop();
          return;
        }
        if (await _confirmLeave() && context.mounted) {
          if (_best.isNotEmpty) await _saveSession();
          if (context.mounted) Navigator.of(context).pop();
        }
      },
      child: switch (_phase) {
        _Phase.handoff => _buildHandoff(context),
        _Phase.prompt => _buildPrompt(context),
        _Phase.summary => _buildSummary(context),
      },
    );
  }

  Widget _buildHandoff(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final name = Locator.userDatabaseService.currentUser.value?.name ?? '';
    return AphScaffold(
      title: widget.kind.title,
      bottom: AphButton(
        label: tr('Start', 'தொடங்கு'),
        icon: Icons.play_arrow_rounded,
        onPressed: () => setState(() => _phase = _Phase.prompt),
      ),
      children: [
        const Gap(AphSpace.xl),
        const Icon(Icons.front_hand_rounded,
            size: 72, color: AphColors.accent),
        const Gap(AphSpace.lg),
        Text(
          name.isEmpty
              ? tr('Hand the phone to the patient', 'தொலைபேசியை நோயாளியிடம் கொடுங்கள்')
              : tr('Hand the phone to $name', 'தொலைபேசியை $name இடம் கொடுங்கள்'),
          style: t.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const Gap(AphSpace.sm),
        Text(
          tr(
            'Sit beside them. Let them try first — help only if they ask, or after two tries. '
                '${_items.length} items, about ${widget.kind.minutes} minutes.',
            'அருகில் அமருங்கள். முதலில் அவர்களே முயலட்டும் — இரண்டு முயற்சிகளுக்குப் பிறகே உதவுங்கள்.',
          ),
          style: t.bodyLarge,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPrompt(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final item = _item;
    final instruction = item.hideTarget
        ? tr('What is this? Say its name.', 'இது என்ன? அதன் பெயரைச் சொல்லுங்கள்.')
        : tr('Listen, then say:', 'கேட்டு, பிறகு சொல்லுங்கள்:');
    final r = _current;
    final answered = r != null;

    return AphScaffold(
      title: widget.kind.title,
      leading: IconButton(
        tooltip: tr('Close', 'மூடு'),
        icon: const Icon(Icons.close_rounded),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      actions: [
        if (_serverAvailable && item.referenceAudio != null)
          const Padding(
            padding: EdgeInsets.only(right: AphSpace.xs),
            child: Center(
              child: StatusPill(
                label: 'Voice match',
                icon: Icons.graphic_eq_rounded,
              ),
            ),
          ),
      ],
      bottom: answered
          ? Row(
              children: [
                if (!_isAssessment) ...[
                  Expanded(
                    child: AphButton.secondary(
                      label: tr('Try again', 'மீண்டும்'),
                      icon: Icons.replay_rounded,
                      onPressed: () => setState(() {
                        _current = null;
                        _error = null;
                      }),
                    ),
                  ),
                  const Gap(AphSpace.sm),
                ],
                Expanded(
                  child: AphButton(
                    label: _index == _items.length - 1
                        ? tr('Finish', 'முடி')
                        : tr('Next', 'அடுத்து'),
                    icon: Icons.arrow_forward_rounded,
                    onPressed: _next,
                  ),
                ),
              ],
            )
          : null,
      children: [
        StepProgress(current: _index + 1, total: _items.length),
        const Gap(AphSpace.lg),
        Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(instruction, style: t.titleLarge),
              ),
            ),
            ReadAloudButton(
              key: ValueKey('ra_${item.id}_$_cue'),
              text: _wordVisible ? '$instruction ${item.target}' : instruction,
              language: item.locale,
              compact: true,
              autoPlay: true,
            ),
          ],
        ),
        const Gap(AphSpace.md),
        _PromptCard(
          item: item,
          wordVisible: _wordVisible,
          cue: _cue,
          onPlay: _playModel,
        ),
        if (item.hideTarget && !answered && _cue < 3) ...[
          const Gap(AphSpace.sm),
          Align(
            child: AphButton.ghost(
              label: switch (_cue) {
                0 => tr('Give me a hint', 'குறிப்பு வேண்டும்'),
                1 => tr('Show the first sound', 'முதல் ஒலியைக் காட்டு'),
                _ => tr('Show the word', 'சொல்லைக் காட்டு'),
              },
              icon: Icons.lightbulb_outline_rounded,
              onPressed: () {
                setState(() => _cue++);
                if (_cue == 2) {
                  _speech.speakText(item.firstSound, language: item.locale);
                } else if (_cue == 3) {
                  _playModel();
                }
              },
            ),
          ),
        ],
        const Gap(AphSpace.lg),
        if (!answered) ...[
          Center(
            child: MicButton(
              state: _mic,
              onPressed: _onMic,
              idleLabel: tr('Tap and speak', 'தட்டி பேசுங்கள்'),
              listeningLabel: tr('Listening… tap when done', 'கேட்கிறது… முடிந்ததும் தட்டவும்'),
              processingLabel: tr('Checking…', 'சரிபார்க்கிறது…'),
            ),
          ),
          if (_mic == MicState.listening && !_useServer)
            ValueListenableBuilder<String>(
              valueListenable: _speech.partial,
              builder: (_, text, _) => text.isEmpty
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.only(top: AphSpace.sm),
                      child: Text(
                        '“$text”',
                        textAlign: TextAlign.center,
                        style: t.bodyLarge?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: AphColors.inkMuted,
                        ),
                      ),
                    ),
            ),
          if (_error != null) ...[
            const Gap(AphSpace.md),
            FeedbackBanner(
              tone: FeedbackTone.warning,
              title: tr('Let’s try that again', 'மீண்டும் முயலலாம்'),
              message: _error,
            ),
          ],
          const Gap(AphSpace.md),
          if (_typing)
            _TypeAnswer(controller: _typed, onSubmit: _submitTyped)
          else
            Wrap(
              alignment: WrapAlignment.center,
              spacing: AphSpace.sm,
              children: [
                AphButton.ghost(
                  label: tr('Type instead', 'தட்டச்சு செய்'),
                  icon: Icons.keyboard_rounded,
                  onPressed: _mic == MicState.idle
                      ? () => setState(() => _typing = true)
                      : null,
                ),
                AphButton.ghost(
                  label: tr('Skip', 'தவிர்'),
                  icon: Icons.skip_next_rounded,
                  onPressed: _mic == MicState.idle ? _skip : null,
                ),
              ],
            ),
        ] else
          _ResultCard(result: r, item: item, praise: _praise(ScoreBand.of(r.score), r.score)),
      ],
    );
  }

  Widget _buildSummary(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final avg = _average;
    final band = ScoreBand.of(avg);
    final focus = PracticeCatalog.focusFor(avg);
    final tricky = _trickyAll.take(3).toList();

    return AphScaffold(
      title: tr('Session complete', 'அமர்வு முடிந்தது'),
      showBack: false,
      bottom: AphButton(
        label: tr('Done', 'முடிந்தது'),
        icon: Icons.check_rounded,
        loading: _saving,
        onPressed: () async {
          if (!_saved) await _saveSession();
          if (context.mounted) Navigator.of(context).pop();
        },
      ),
      children: [
        const Gap(AphSpace.md),
        Center(child: ScoreRing(score: avg, size: 160)),
        const Gap(AphSpace.md),
        Text(
          band.label,
          textAlign: TextAlign.center,
          style: t.headlineMedium?.copyWith(color: band.color),
        ),
        const Gap(AphSpace.xs),
        Text(
          _best.isEmpty
              ? tr('No answers this time — that’s okay.', 'இந்த முறை பதில்கள் இல்லை — பரவாயில்லை.')
              : tr(
                  '${_best.length} of ${_items.length} answered. Every try helps your brain rebuild these words.',
                  '${_items.length} இல் ${_best.length} பதிலளித்தீர்கள். ஒவ்வொரு முயற்சியும் உதவுகிறது.',
                ),
          textAlign: TextAlign.center,
          style: t.bodyLarge,
        ),
        if (_isAssessment) ...[
          const Gap(AphSpace.lg),
          FeedbackBanner(
            tone: FeedbackTone.info,
            title: tr('Recommended start', 'பரிந்துரைக்கப்பட்ட தொடக்கம்'),
            message: switch (focus) {
              'letters' => tr(
                  'Begin with letter sounds to build a strong base.',
                  'வலுவான அடித்தளத்திற்கு எழுத்து ஒலிகளுடன் தொடங்குங்கள்.'),
              'words' => tr(
                  'You are ready for single words with pictures.',
                  'படங்களுடன் சொற்களுக்கு நீங்கள் தயார்.'),
              _ => tr(
                  'You are ready for everyday sentences.',
                  'அன்றாட வாக்கியங்களுக்கு நீங்கள் தயார்.'),
            },
          ),
        ],
        if (tricky.isNotEmpty && widget.kind != PracticeKind.drill) ...[
          const Gap(AphSpace.lg),
          ActionTile(
            icon: Icons.track_changes_rounded,
            title: tr('Practise tricky sounds', 'கடினமான ஒலிகளைப் பயிற்சி செய்'),
            subtitle: tricky.join('  ·  '),
            color: AphColors.accent,
            softColor: AphColors.accentSoft,
            onTap: () => Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => PracticeSessionPage(
                  kind: PracticeKind.drill,
                  items: PracticeCatalog.drill(tricky),
                ),
              ),
            ),
          ),
        ],
        if (_best.isNotEmpty) ...[
          SectionHeader(tr('Your answers', 'உங்கள் பதில்கள்')),
          AphCard(
            padding: const EdgeInsets.symmetric(
              horizontal: AphSpace.md,
              vertical: AphSpace.xs,
            ),
            child: Column(
              children: [
                for (final e in _best.entries) ...[
                  if (e.key != _best.keys.first) const Divider(),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: AphSpace.sm),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(_items[e.key].target, style: t.titleMedium),
                        ),
                        ScoreBadge(score: e.value.score),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
        if (_assisted) ...[
          SectionHeader(
            tr('Helper log', 'உதவியாளர் குறிப்பு'),
            subtitle: tr(
              'Shared with the therapist. What did you notice?',
              'சிகிச்சையாளருடன் பகிரப்படும்.',
            ),
          ),
          AphTextField(
            controller: _note,
            label: tr('Note (optional)', 'குறிப்பு (விருப்பம்)'),
            hint: tr('e.g. tired today, needed hints for food words',
                'எ.கா. இன்று சோர்வு'),
            maxLines: 3,
            textInputAction: TextInputAction.done,
            textCapitalization: TextCapitalization.sentences,
          ),
        ],
      ],
    );
  }
}

class _PromptCard extends StatelessWidget {
  const _PromptCard({
    required this.item,
    required this.wordVisible,
    required this.cue,
    required this.onPlay,
  });

  final PracticeItem item;
  final bool wordVisible;
  final int cue;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final long = item.target.length > 14;
    return AphCard(
      padding: const EdgeInsets.all(AphSpace.lg),
      child: Column(
        children: [
          if (item.imagePath != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(AphRadius.md),
              child: Container(
                color: AphColors.surfaceSunken,
                height: 200,
                width: double.infinity,
                padding: const EdgeInsets.all(AphSpace.sm),
                child: Image.asset(
                  item.imagePath!,
                  fit: BoxFit.contain,
                  semanticLabel: wordVisible
                      ? 'Picture of ${item.meaning ?? item.target}'
                      : 'Picture to name',
                  errorBuilder: (_, _, _) => const Icon(
                    Icons.image_not_supported_rounded,
                    size: 64,
                    color: AphColors.inkSubtle,
                  ),
                ),
              ),
            ),
            const Gap(AphSpace.md),
          ],
          if (item.emoji != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(AphRadius.md),
              child: Container(
                color: AphColors.surfaceSunken,
                height: 200,
                width: double.infinity,
                alignment: Alignment.center,
                child: Semantics(
                  label: wordVisible
                      ? 'Picture of ${item.meaning ?? item.target}'
                      : 'Picture to name',
                  excludeSemantics: true,
                  child: Text(
                    item.emoji!,
                    style: const TextStyle(fontSize: 128, height: 1.1),
                  ),
                ),
              ),
            ),
            const Gap(AphSpace.md),
          ],
          if (wordVisible) ...[
            Text(
              item.target,
              textAlign: TextAlign.center,
              style: (long ? t.headlineLarge : t.displayMedium)
                  ?.copyWith(color: AphColors.ink),
            ),
            if (item.meaning != null) ...[
              const Gap(AphSpace.xs),
              Text(item.meaning!,
                  textAlign: TextAlign.center, style: t.bodyLarge),
            ],
          ] else ...[
            if (cue >= 1 && item.semanticCue != null)
              Text(
                '${tr('Hint', 'குறிப்பு')}: ${item.semanticCue}',
                textAlign: TextAlign.center,
                style: t.titleMedium?.copyWith(color: AphColors.accent),
              ),
            if (cue >= 2) ...[
              const Gap(AphSpace.xs),
              Text(
                '${tr('It starts with', 'இது இப்படித் தொடங்குகிறது')}  ${item.firstSound}…',
                textAlign: TextAlign.center,
                style: t.headlineSmall,
              ),
            ],
          ],
          const Gap(AphSpace.md),
          ReadAloudButton(
            text: item.target,
            language: item.locale,
            label: item.referenceAudio != null
                ? tr('Hear a speaker', 'பேச்சாளரைக் கேளுங்கள்')
                : tr('Hear it', 'கேளுங்கள்'),
          ),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.result,
    required this.item,
    required this.praise,
  });

  final _Result result;
  final PracticeItem item;
  final String praise;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final band = ScoreBand.of(result.score);
    return Semantics(
      liveRegion: true,
      child: AphCard(
        color: band.soft,
        borderColor: band.color.withValues(alpha: 0.35),
        child: Column(
          children: [
            Row(
              children: [
                ScoreRing(score: result.score, size: 104),
                const Gap(AphSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(band.icon, color: band.color, size: 26),
                          const Gap(AphSpace.xs),
                          Flexible(
                            child: Text(
                              band.label,
                              style: t.headlineSmall
                                  ?.copyWith(color: band.color),
                            ),
                          ),
                        ],
                      ),
                      const Gap(AphSpace.xxs),
                      Text(praise, style: t.bodyLarge),
                    ],
                  ),
                ),
              ],
            ),
            if (result.spoken.isNotEmpty) ...[
              const Gap(AphSpace.md),
              _Line(
                label: tr('We heard', 'நாங்கள் கேட்டது'),
                value: result.spoken,
              ),
            ],
            if (!item.hideTarget || result.score < 70) ...[
              const Gap(AphSpace.xs),
              _Line(label: tr('Target', 'இலக்கு'), value: item.target),
            ],
            if (result.tricky.isNotEmpty) ...[
              const Gap(AphSpace.xs),
              _Line(
                label: tr('Sounds to practise', 'பயிற்சிக்கான ஒலிகள்'),
                value: result.tricky.take(4).join('  ·  '),
              ),
            ],
            if (result.serverFeedback != null &&
                result.serverFeedback!.isNotEmpty) ...[
              const Gap(AphSpace.xs),
              _Line(
                label: tr('Voice match', 'குரல் பொருத்தம்'),
                value: result.serverFeedback!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 120, child: Text(label, style: t.bodyMedium)),
        Expanded(child: Text(value, style: t.titleMedium)),
      ],
    );
  }
}

class _TypeAnswer extends StatelessWidget {
  const _TypeAnswer({required this.controller, required this.onSubmit});
  final TextEditingController controller;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AphTextField(
          controller: controller,
          label: tr('Type what you would say', 'நீங்கள் சொல்வதைத் தட்டச்சு செய்யுங்கள்'),
          helper: tr(
            'Tamil or English letters are both fine.',
            'தமிழ் அல்லது ஆங்கில எழுத்துகள் இரண்டும் சரி.',
          ),
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => onSubmit(),
        ),
        const Gap(AphSpace.sm),
        AphButton(
          label: tr('Check', 'சரிபார்'),
          icon: Icons.check_rounded,
          onPressed: onSubmit,
        ),
      ],
    );
  }
}
