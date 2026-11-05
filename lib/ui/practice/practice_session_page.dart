import 'dart:async';

import 'package:aphora/data/intake/intake_questions.dart' show StartLevel;
import 'package:aphora/data/learning/letter_training_data.dart';
import 'package:aphora/data/aphora_api_service.dart' show AphoraApiException;
import 'package:aphora/data/learning/packs/condition_packs.dart';
import 'package:aphora/data/learning/practice_catalog.dart';
import 'package:aphora/data/models/practice_record.dart';
import 'package:aphora/logic/comfort_settings.dart';
import 'package:aphora/logic/family_voice_store.dart';
import 'package:aphora/logic/language_service.dart';
import 'package:aphora/data/models/oral_records.dart';
import 'package:aphora/logic/baseline_scoring.dart';
import 'package:aphora/logic/locator.dart';
import 'package:aphora/logic/self_baseline_feedback.dart';
import 'package:aphora/logic/practice_rewards.dart';
import 'package:aphora/logic/speech_service.dart';
import 'package:aphora/logic/voice_recorder.dart';
import 'package:aphora/ui/design/components.dart';
import 'package:aphora/ui/practice/kid_rewards.dart';
import 'package:aphora/ui/practice/practice_safety.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Opens a practice session after the pack's safety step (oral-cancer
/// pack: safety line / care-team confirmation). Returns when the person
/// leaves the summary, or at once if they did not confirm.
Future<void> openPractice(
  BuildContext context,
  PracticeKind kind, {
  List<PracticeItem>? items,
}) async {
  if (!await ensurePracticeSafety(context)) return;
  if (!context.mounted) return;
  await Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => PracticeSessionPage(kind: kind, items: items),
    ),
  );
}

/// The single exercise engine: prompt → listen → score → feedback, for
/// every speaking task in the app. Content and wording come from the
/// signed-in person's condition pack unless [pack] / [items] are given.
class PracticeSessionPage extends StatefulWidget {
  const PracticeSessionPage({
    super.key,
    required this.kind,
    this.items,
    this.pack,
    this.level,
  });

  final PracticeKind kind;
  final List<PracticeItem>? items;

  /// Defaults to `ConditionPacks.current`.
  final ConditionPack? pack;

  /// 1–3; defaults to the person's practice level.
  final int? level;

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
    this.cer,
  });
  final double score;
  final double? cer;
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

  late final ConditionPack _pack = widget.pack ?? ConditionPacks.current;

  /// Children's wording (parent mode, stars). Adults get a calm
  /// "well done", a score and helper/carer wording.
  late final bool _child = widget.pack?.forChildren ?? ConditionPacks.currentChildWording;

  late final List<PracticeItem> _items = widget.items ??
      _pack.items(
        widget.kind,
        level: widget.level ?? ConditionPacks.currentLevel,
        language: LanguageService.currentLanguage,
      );

  String get _title => _pack.title(widget.kind);
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

  /// Hints (cueing-ladder rungs) used per answered hidden-word item.
  final Map<int, int> _hintsUsed = {};

  /// The last attempt earned a new star (drives the star burst).
  bool _newStar = false;
  final _family = FamilyVoiceStore.instance;

  bool _serverAvailable = false;
  Timer? _autoStop;
  bool _saving = false;
  bool _saved = false;

  bool get _isAssessment => widget.kind == PracticeKind.assessment;

  /// Oral-cancer pack: progress against the person's own starting point,
  /// shown as band messages only.
  bool get _selfBaseline => _pack.selfBaselineScoring;

  /// A pure measure (monthly clarity check): no hints, no spoken model.
  bool get _measure => _isAssessment && _pack.checkUpIsMeasure;

  /// Earlier attempts (loaded) plus this session's, for [_selfBaseline].
  final List<OralAttempt> _history = [];
  final List<OralAttempt> _sessionAttempts = [];
  ProgressBand? _band;
  IntelligibilityResult? _clarity;
  ProgressBand? _clarityBand;

  Future<void> _loadHistory() async {
    try {
      final users = Locator.userDatabaseService;
      final uid = users.currentUser.value?.uid;
      if (uid == null) return;
      final records = await users.getRecentAttempts(uid, limit: 500);
      if (!mounted) return;
      // Older attempts first, then anything already said this session.
      _history.insertAll(0, SelfBaselineFeedback.fromRecords(records)
          .where((a) => a.at.isBefore(_started)));
    } catch (_) {/* offline or no services: start from this session */}
  }
  bool get _assisted => ComfortSettings.instance.assistedMode.value;
  PracticeItem get _item => _items[_index];
  bool get _wordVisible => !_item.hideTarget || _cue >= 3;

  /// Amma/Appa recorded this item in Family Voice.
  bool _hasFamily(PracticeItem i) => _family.has(i.voiceKey);

  /// A reference recording the server can score against: the parent's
  /// (in "Copy the voice") or a bundled fluent speaker.
  bool _hasReference(PracticeItem i) =>
      i.referenceAudio != null ||
      (widget.kind == PracticeKind.phonetic && _hasFamily(i));

  int get _stars => PracticeRewards.stars(_best.values.map((r) => r.score));

  @override
  void initState() {
    super.initState();
    _checkServer();
    if (_selfBaseline) _loadHistory();
    if (_phase == _Phase.prompt) _onItemShown();
  }

  /// When the word is on screen and Amma/Appa recorded it, play their
  /// voice straight away (instead of the phone reading the word).
  void _onItemShown() {
    if (!ComfortSettings.instance.autoReadAloud.value || _measure) return;
    if (_item.hideTarget || !_hasFamily(_item)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _playModel();
    });
  }

  Future<void> _checkServer() async {
    if (!_items.any(_hasReference)) return;
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

  bool get _useServer => _serverAvailable && _hasReference(_item);

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
      final item = _item;
      final api = Locator.aphoraApiService;
      // Parent's own recording first (Family Voice), else the bundled one.
      final family = widget.kind == PracticeKind.phonetic
          ? await _family.bytesFor(item.voiceKey)
          : null;
      final language = item.locale.split('-').first;
      final r = family != null
          ? await api.evaluate(
              referenceBytes: family,
              referenceFilename: FamilyVoiceStore.fileNameFor(item.voiceKey),
              userAudioBytes: bytes,
              referenceText: item.target,
              language: language,
            )
          : item.referenceAudio != null
              ? await api.evaluateAgainstAsset(
                  referenceAssetPath: item.referenceAudio!,
                  userAudioBytes: bytes,
                  referenceText: item.target,
                  language: language,
                )
              : throw AphoraApiException('No reference recording for this item.');
      _commit(_Result(
        score: r.combinedAccuracy,
        spoken: r.userText ?? '',
        method: 'server',
        serverFeedback: r.feedbackMessage,
        cer: r.characterErrorRate,
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
      tricky: best.similarity >= 85
          ? const []
          : fromTarget.mispronouncedLetters.map(displayLetter).toList(),
    ));
  }

  void _commit(_Result r) {
    HapticFeedback.lightImpact();
    final prev = _best[_index];
    final hints = _item.hideTarget ? _cue : 0;
    if (_selfBaseline) {
      final a = SelfBaselineFeedback.attempt(
        itemId: _item.id,
        at: DateTime.now(),
        method: r.method,
        score: r.score,
        cer: r.cer,
        transcript: r.spoken,
      );
      if (a != null) {
        _history.add(a);
        _sessionAttempts.add(a);
      }
      _band = SelfBaselineFeedback.bandFor(_item.id, _history);
    }
    setState(() {
      _mic = MicState.idle;
      _current = r;
      _newStar = _child &&
          PracticeRewards.isCorrect(r.score) &&
          (prev == null || !PracticeRewards.isCorrect(prev.score));
      if (prev == null || r.score > prev.score) _best[_index] = r;
      _trickyAll.addAll(r.tricky);
      if (_item.hideTarget) {
        // Hints only build up within an item, so keep the highest.
        _hintsUsed.update(_index, (h) => h > hints ? h : hints,
            ifAbsent: () => hints);
      }
    });
    // Persist each attempt; failures are non-fatal (offline queue in
    // Firestore will retry).
    _persist(() => Locator.userDatabaseService
        .recordExerciseResult(
          taskId: _item.id,
          accuracy: r.score,
          category: widget.kind.id,
          target: _item.target,
          spoken: r.spoken,
          method: r.method,
          assisted: _assisted,
          hintsUsed: hints,
          cer: r.cer,
        ));
    final band = ScoreBand.of(r.score);
    if (ComfortSettings.instance.autoReadAloud.value && !_measure) {
      _speech.speakText(_selfBaseline && _band != null
          ? SelfBaselineFeedback.messageFor(_band!, LanguageService.currentLanguage).title
          : _praise(band, r.score));
    }
  }

  /// Runs a save in the background; a failure never breaks the session.
  static void _persist(Future<Object?> Function() save) {
    try {
      save().catchError((_) => null);
    } catch (_) {/* services not set up (widget tests) */}
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
    final family = await _family.pathFor(_item.voiceKey);
    if (family != null) {
      try {
        await _speech.stopSpeaking();
        await _player.stop();
        await _player.play(DeviceFileSource(family));
        return;
      } catch (_) {/* fall through */}
    }
    final ref = _item.referenceAudio;
    if (ref != null) {
      try {
        await _player.stop();
        await _player.play(AssetSource(ref.replaceFirst('assets/', '')));
        return;
      } catch (_) {/* fall through to TTS */}
    }
    // Paced phrases: word by word, with a pause after each.
    await _speech.speakText(_item.chunks?.join(', ') ?? _item.target,
        language: _item.locale);
  }

  // ── Navigation ───────────────────────────────────────────────────────

  void _next() {
    if (_index >= _items.length - 1) {
      if (_measure) {
        final language = LanguageService.currentLanguage;
        _clarity = SelfBaselineFeedback.clarity(_sessionAttempts, _items, language);
        _clarityBand = SelfBaselineFeedback.clarityBand(
            ConditionPacks.currentUser?.oralClarityTests ?? const [], _clarity!);
      }
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
      _newStar = false;
    });
    _onItemShown();
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
        title: _title,
        itemCount: _best.length,
        averageScore: _average,
        minutes: minutes,
        assisted: _assisted,
        helperName: _assisted ? ComfortSettings.instance.helperName.value : null,
        note: _note.text.trim().isEmpty ? null : _note.text.trim(),
        createdAt: DateTime.now(),
      ));
      if (_isAssessment && _pack.checkUpSetsLevel) {
        await Locator.userDatabaseService.savePreAssessment(
          score: _average,
          recommendedFocus: PracticeCatalog.focusFor(_average),
        );
      }
      if (_measure && _clarity != null) {
        await Locator.userDatabaseService
            .saveClarityTest(ClarityTest.fromResult(_clarity!, DateTime.now()));
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
    if (_items.isEmpty) {
      return AphScaffold(
        title: _title,
        children: [
          EmptyState(
            icon: Icons.inbox_rounded,
            title: tr('Nothing to practise here yet', 'இங்கே இன்னும் பயிற்சி இல்லை'),
            message: tr('Try another exercise from the Practice tab.',
                'பயிற்சி தாவலில் வேறு ஒன்றை முயலுங்கள்.'),
          ),
        ],
      );
    }
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

  /// Parent / carer mode start screen: one short line for the helper.
  Widget _buildHandoff(BuildContext context) {
    final t = Theme.of(context).textTheme;
    String name;
    try {
      name = Locator.userDatabaseService.currentUser.value?.name ?? '';
    } catch (_) {
      name = '';
    }
    if (!_child) return _buildAdultHandoff(context, name.split(' ').first);
    return AphScaffold(
      title: _title,
      bottom: AphButton(
        key: const ValueKey('session_start'),
        label: tr('Start', 'தொடங்கு'),
        icon: Icons.play_arrow_rounded,
        onPressed: () {
          setState(() => _phase = _Phase.prompt);
          _onItemShown();
        },
      ),
      children: [
        const Gap(AphSpace.xl),
        const Center(
          child: Text('👩‍👧', style: TextStyle(fontSize: 96)),
        ),
        const Gap(AphSpace.lg),
        Text(
          name.isEmpty
              ? tr('Practise together with your child', 'குழந்தையுடன் சேர்ந்து பயிற்சி செய்யுங்கள்')
              : tr('Practise together with $name', '$name உடன் சேர்ந்து பயிற்சி செய்யுங்கள்'),
          style: t.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const Gap(AphSpace.sm),
        Text(
          tr('Say it together, then let your child try. '
                  '${_items.length} items, about ${widget.kind.minutes} minutes.',
              'சேர்ந்து சொல்லுங்கள், பிறகு குழந்தையைச் சொல்ல விடுங்கள். '
                  '${_items.length} கேள்விகள், சுமார் ${widget.kind.minutes} நிமிடம்.'),
          style: t.bodyLarge,
          textAlign: TextAlign.center,
        ),
        const Gap(AphSpace.xs),
        Text(
          tr('${_items.length} pictures · about ${widget.kind.minutes} minutes',
              '${_items.length} படங்கள் · சுமார் ${widget.kind.minutes} நிமிடம்'),
          style: t.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Carer mode start screen for an adult: calm, no cartoons.
  Widget _buildAdultHandoff(BuildContext context, String name) {
    final t = Theme.of(context).textTheme;
    final minutes = _pack.minutes(widget.kind);
    return AphScaffold(
      title: _title,
      bottom: AphButton(
        key: const ValueKey('session_start'),
        label: tr('Start', 'தொடங்கு'),
        icon: Icons.play_arrow_rounded,
        onPressed: () {
          setState(() => _phase = _Phase.prompt);
          _onItemShown();
        },
      ),
      children: [
        const Gap(AphSpace.xl),
        const Center(
          child: Icon(Icons.people_alt_rounded,
              size: 88, color: AphColors.primary),
        ),
        const Gap(AphSpace.lg),
        Text(
          name.isEmpty
              ? tr('Practise together with a helper', 'உதவியாளருடன் சேர்ந்து பயிற்சி செய்யுங்கள்')
              : tr('Practise together with $name', '$name உடன் சேர்ந்து பயிற்சி செய்யுங்கள்'),
          style: t.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const Gap(AphSpace.sm),
        Text(
          tr('Helper: say it together first if needed, then give time to try alone. '
                  'No rush — pauses are fine.',
              'உதவியாளர்: தேவைப்பட்டால் முதலில் சேர்ந்து சொல்லுங்கள், பிறகு தனியாகச் சொல்ல நேரம் கொடுங்கள். '
                  'அவசரம் வேண்டாம் — இடைவெளி பரவாயில்லை.'),
          style: t.bodyLarge,
          textAlign: TextAlign.center,
        ),
        const Gap(AphSpace.xs),
        Text(
          tr('${_items.length} items · about $minutes minutes',
              '${_items.length} கேள்விகள் · சுமார் $minutes நிமிடம்'),
          style: t.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPrompt(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final item = _item;
    final instruction = item.instruction ??
        (item.hideTarget
            ? tr('What is this? Say its name.', 'இது என்ன? அதன் பெயரைச் சொல்லுங்கள்.')
            : tr('Listen, then say:', 'கேட்டு, பிறகு சொல்லுங்கள்:'));
    final r = _current;
    final answered = r != null;
    final kid = _assisted && _child; // parent mode: big picture, few words
    final family = _hasFamily(item);
    // The blank sentence is read with the instruction ("Finish the
    // sentence: I drink a cup of …").
    final spokenPrompt = item.hideTarget && item.prompt != null
        ? ' ${item.prompt!.replaceAll('___', '…')}'
        : '';

    return AphScaffold(
      title: _title,
      leading: IconButton(
        tooltip: tr('Close', 'மூடு'),
        icon: const Icon(Icons.close_rounded),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      actions: [
        if (_useServer && !kid)
          Padding(
            padding: const EdgeInsets.only(right: AphSpace.xs),
            child: Center(
              child: StatusPill(
                label: tr('Voice match', 'குரல் பொருத்தம்'),
                icon: Icons.graphic_eq_rounded,
              ),
            ),
          ),
        if (_child) Center(child: StarCounter(stars: _stars)),
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
        if (_pack.restCue case final rest?) ...[
          const Gap(AphSpace.xs),
          Row(
            key: const ValueKey('rest_cue'),
            children: [
              const Icon(Icons.pan_tool_rounded, size: 18, color: AphColors.warning),
              const Gap(AphSpace.xs),
              Expanded(
                child: Text(rest,
                    style: t.bodyMedium?.copyWith(color: AphColors.warning)),
              ),
            ],
          ),
        ],
        const Gap(AphSpace.lg),
        Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  kid
                      ? tr('Say it together, then let your child try.',
                          'சேர்ந்து சொல்லுங்கள், பிறகு குழந்தையைச் சொல்ல விடுங்கள்.')
                      : instruction,
                  style: kid
                      ? t.bodyLarge?.copyWith(color: AphColors.inkMuted)
                      : t.titleLarge,
                ),
              ),
            ),
            ReadAloudButton(
              key: ValueKey('ra_${item.id}_$_cue'),
              // A measure never speaks the answer first.
              text: _wordVisible && !family && !_measure
                  ? '$instruction$spokenPrompt ${item.chunks?.join(', ') ?? item.target}'
                  : '$instruction$spokenPrompt',
              language: item.locale,
              compact: true,
              // Family voice plays the word itself (see _onItemShown).
              autoPlay: !(family && _wordVisible),
            ),
          ],
        ),
        const Gap(AphSpace.md),
        _PromptCard(
          item: item,
          wordVisible: _wordVisible,
          cue: _cue,
          onPlay: _playModel,
          familyVoice: family,
          big: kid,
          child: _child,
          noModel: _measure,
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
                // Kept in parent mode too: phone speech recognition often
                // mishears children, so the parent types what the child said.
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
        ] else if (kid)
          KidRewardCard(
            key: ValueKey('reward_${item.id}_${identityHashCode(r)}'),
            correct: PracticeRewards.isCorrect(r.score),
            newStar: _newStar,
          )
        else if (_selfBaseline)
          _SelfBaselineCard(
            key: ValueKey('band_${item.id}_${identityHashCode(r)}'),
            band: _measure ? null : _band,
          )
        else ...[
          if (_newStar && _child) ...[
            Center(child: StarBurst(key: ValueKey('burst_${identityHashCode(r)}'), size: 96)),
            const Gap(AphSpace.sm),
          ],
          _ResultCard(result: r, item: item, praise: _praise(ScoreBand.of(r.score), r.score)),
        ],
      ],
    );
  }

  Widget _buildSummary(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final avg = _average;
    final band = ScoreBand.of(avg);
    final focus = PracticeCatalog.focusFor(avg);
    final level = StartLevel.fromLegacyFocus(focus) ?? 2;
    final tricky = _trickyAll.take(3).toList();
    final hintsAvg = HintStats.average(_hintsUsed.values);

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
        if (_selfBaseline)
          _SelfBaselineCard(
            key: const ValueKey('summary_band'),
            band: _measure
                ? _clarityBand
                : _best.isEmpty
                    ? null
                    : BaselineScoring.summarise(_history, since: _started).band,
            measured: _measure,
          )
        else if (_assisted && _child)
          StarsEarned(stars: _stars)
        else ...[
          Center(child: ScoreRing(score: avg, size: 160)),
          const Gap(AphSpace.md),
          Text(
            band.label,
            textAlign: TextAlign.center,
            style: t.headlineMedium?.copyWith(color: band.color),
          ),
          if (_child) ...[
            const Gap(AphSpace.xs),
            Text(
              _stars == 1
                  ? tr('⭐ 1 star earned', '⭐ 1 நட்சத்திரம் கிடைத்தது')
                  : tr('⭐ $_stars stars earned', '⭐ $_stars நட்சத்திரங்கள் கிடைத்தன'),
              key: const ValueKey('summary_stars'),
              textAlign: TextAlign.center,
              style: t.titleMedium?.copyWith(color: AphColors.accent),
            ),
          ],
        ],
        const Gap(AphSpace.xs),
        Text(
          _best.isEmpty
              ? tr('No answers this time — that’s okay.', 'இந்த முறை பதில்கள் இல்லை — பரவாயில்லை.')
              : _selfBaseline
                  ? tr('You practised ${_best.length} items today. Every attempt helps.',
                      'இன்று ${_best.length} பயிற்சிகள் செய்தீர்கள். ஒவ்வொரு முயற்சியும் உதவும்.')
                  : _child
                  ? tr(
                      '${_best.length} of ${_items.length} answered. Every try counts — well done for practising together!',
                      '${_items.length} இல் ${_best.length} பதில்கள். ஒவ்வொரு முயற்சியும் முக்கியம் — சேர்ந்து பயிற்சி செய்ததற்கு பாராட்டுகள்!',
                    )
                  : tr(
                      '${_best.length} of ${_items.length} answered. Well done — a little practice every day helps.',
                      '${_items.length} இல் ${_best.length} பதில்கள். நன்றாகச் செய்தீர்கள் — தினமும் கொஞ்சம் பயிற்சி உதவும்.',
                    ),
          textAlign: TextAlign.center,
          style: t.bodyLarge,
        ),
        if (hintsAvg != null) ...[
          const Gap(AphSpace.xs),
          Text(
            tr('Hints per word: ${HintStats.format(hintsAvg)} (fewer = more on their own)',
                'ஒரு சொல்லுக்குக் குறிப்புகள்: ${HintStats.format(hintsAvg)} (குறைவு = தானாகச் சொல்கிறது)'),
            key: const ValueKey('summary_hints'),
            textAlign: TextAlign.center,
            style: t.bodyMedium,
          ),
        ],
        if (_isAssessment && !_measure) ...[
          const Gap(AphSpace.lg),
          FeedbackBanner(
            tone: FeedbackTone.info,
            title: tr('Recommended start', 'பரிந்துரைக்கப்பட்ட தொடக்கம்'),
            message: _pack.checkUpAdvice(level),
          ),
        ],
        if (tricky.isNotEmpty &&
            widget.kind != PracticeKind.drill &&
            _pack.offersSoundDrill) ...[
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
                  pack: widget.pack,
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
                        if (_selfBaseline)
                          const Icon(Icons.check_circle_rounded,
                              color: AphColors.success, semanticLabel: 'Practised')
                        else
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
    this.familyVoice = false,
    this.big = false,
    this.child = true,
    this.noModel = false,
  });

  final PracticeItem item;
  final bool wordVisible;

  /// Measuring: no "Hear it" model.
  final bool noModel;
  final int cue;
  final VoidCallback onPlay;

  /// Amma/Appa recorded this word — the listen button plays them.
  final bool familyVoice;

  /// Parent mode: bigger picture and word, no gloss.
  final bool big;

  /// Children's wording ("Amma/Appa's voice").
  final bool child;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final long = item.target.length > 14;
    final pictureHeight = big ? 260.0 : 200.0;
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
          if (item.icon != null && item.imagePath == null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(AphRadius.md),
              child: Container(
                color: AphColors.surfaceSunken,
                height: 200,
                width: double.infinity,
                alignment: Alignment.center,
                child: Icon(
                  item.icon,
                  size: 132,
                  color: AphColors.inkMuted,
                  semanticLabel: wordVisible
                      ? 'Picture of ${item.meaning ?? item.target}'
                      : 'Picture to name',
                ),
              ),
            ),
            const Gap(AphSpace.md),
          ],
          if (item.prompt != null) ...[
            Text(
              item.prompt!,
              textAlign: TextAlign.center,
              style: t.headlineSmall?.copyWith(color: AphColors.ink),
            ),
            const Gap(AphSpace.sm),
          ],
          if (item.emoji != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(AphRadius.md),
              child: Container(
                color: AphColors.surfaceSunken,
                height: pictureHeight,
                width: double.infinity,
                alignment: Alignment.center,
                child: Semantics(
                  label: wordVisible
                      ? 'Picture of ${item.meaning ?? item.target}'
                      : 'Picture to name',
                  excludeSemantics: true,
                  child: Text(
                    item.emoji!,
                    style: TextStyle(fontSize: big ? 180 : 128, height: 1.1),
                  ),
                ),
              ),
            ),
            const Gap(AphSpace.md),
          ],
          if (wordVisible && item.chunks != null) ...[
            PacedWords(key: ValueKey('paced_${item.id}'), words: item.chunks!),
            if (item.meaning != null) ...[
              const Gap(AphSpace.xs),
              Text(item.meaning!, textAlign: TextAlign.center, style: t.bodyLarge),
            ],
          ] else if (wordVisible) ...[
            Text(
              item.target,
              textAlign: TextAlign.center,
              style: (long
                      ? t.headlineLarge
                      : big
                          ? t.displayLarge
                          : t.displayMedium)
                  ?.copyWith(color: AphColors.ink),
            ),
            if (item.meaning != null && !big) ...[
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
          if (noModel)
            const SizedBox.shrink()
          else if (familyVoice && wordVisible) ...[
            StatusPill(
              label: tr('Family voice', 'குடும்பக் குரல்'),
              icon: Icons.favorite_rounded,
              color: AphColors.accent,
              soft: AphColors.accentSoft,
            ),
            const Gap(AphSpace.xs),
            AphButton.secondary(
              key: const ValueKey('play_family_voice'),
              label: child
                  ? tr('Amma/Appa’s voice', 'அம்மா/அப்பா குரல்')
                  : tr('Family voice', 'குடும்பக் குரல்'),
              icon: Icons.record_voice_over_rounded,
              onPressed: onPlay,
            ),
          ] else if (item.referenceAudio != null && wordVisible)
            AphButton.secondary(
              label: tr('Hear a speaker', 'பேச்சாளரைக் கேளுங்கள்'),
              icon: Icons.volume_up_rounded,
              onPressed: onPlay,
            )
          else if (wordVisible)
            ReadAloudButton(
              text: item.chunks?.join(', ') ?? item.target,
              language: item.locale,
              label: tr('Hear it', 'கேளுங்கள்'),
            ),
        ],
      ),
    );
  }
}

/// "One word at a time": the phrase as separate words; each lights up in
/// turn with a pause, once, and again on "Show the pace".
class PacedWords extends StatefulWidget {
  const PacedWords({super.key, required this.words});
  final List<String> words;

  /// Time per word (word + pause).
  static const step = Duration(milliseconds: 1100);

  @override
  State<PacedWords> createState() => _PacedWordsState();
}

class _PacedWordsState extends State<PacedWords> {
  Timer? _timer;
  int _at = -1;

  @override
  void initState() {
    super.initState();
    _start();
  }

  void _start() {
    _timer?.cancel();
    setState(() => _at = 0);
    _timer = Timer.periodic(PacedWords.step, (t) {
      if (!mounted) return;
      setState(() => _at++);
      if (_at >= widget.words.length) t.cancel();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      children: [
        Semantics(
          label: widget.words.join(', '),
          excludeSemantics: true,
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: AphSpace.xs,
            runSpacing: AphSpace.xs,
            children: [
              for (final (i, w) in widget.words.indexed)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: AphSpace.sm, vertical: AphSpace.xxs),
                  decoration: BoxDecoration(
                    color: i == _at ? AphColors.primarySoft : Colors.transparent,
                    borderRadius: BorderRadius.circular(AphRadius.sm),
                    border: Border.all(
                      color: i == _at ? AphColors.primary : AphColors.border,
                    ),
                  ),
                  child: Text(
                    w,
                    style: t.headlineMedium?.copyWith(
                      color: i == _at ? AphColors.primary : AphColors.ink,
                    ),
                  ),
                ),
            ],
          ),
        ),
        TextButton.icon(
          onPressed: _start,
          icon: const Icon(Icons.replay_rounded),
          label: Text(tr('Show the pace', 'வேகத்தைக் காட்டு')),
        ),
      ],
    );
  }
}

/// Oral-cancer pack feedback: only the progress band, never a number or
/// "wrong". [band] null = no message (the clarity check measures
/// silently, item by item).
class _SelfBaselineCard extends StatelessWidget {
  const _SelfBaselineCard({super.key, required this.band, this.measured = false});
  final ProgressBand? band;

  /// Summary of the monthly clarity check.
  final bool measured;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final b = band;
    final m = b == null
        ? (
            title: measured
                ? tr('Check saved', 'பரிசோதனை சேமிக்கப்பட்டது')
                : tr('Thank you — saved', 'நன்றி — சேமிக்கப்பட்டது'),
            detail: tr('Go on to the next one when you are ready.',
                'தயாரானதும் அடுத்ததுக்குச் செல்லுங்கள்.'),
          )
        : SelfBaselineFeedback.messageFor(b, LanguageService.currentLanguage);
    final (icon, color, soft) = switch (b) {
      ProgressBand.clearer => (Icons.trending_up_rounded, AphColors.success, AphColors.successSoft),
      ProgressBand.harderToday => (Icons.bedtime_rounded, AphColors.info, AphColors.infoSoft),
      ProgressBand.settingStartingPoint => (Icons.flag_rounded, AphColors.primary, AphColors.primarySoft),
      _ => (Icons.check_circle_rounded, AphColors.primary, AphColors.primarySoft),
    };
    return Semantics(
      liveRegion: true,
      child: AphCard(
        color: soft,
        borderColor: color.withValues(alpha: 0.35),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 32),
            const Gap(AphSpace.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(m.title, style: t.titleLarge?.copyWith(color: color)),
                  const Gap(AphSpace.xxs),
                  Text(m.detail, style: t.bodyLarge),
                ],
              ),
            ),
          ],
        ),
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
