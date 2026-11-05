import 'dart:math';

import 'package:aphora/data/learning/kids_words.dart';
import 'package:aphora/data/models/practice_record.dart';
import 'package:aphora/logic/comfort_settings.dart';
import 'package:aphora/logic/language_service.dart';
import 'package:aphora/logic/locator.dart';
import 'package:aphora/logic/speech_service.dart';
import 'package:aphora/ui/design/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Listening comprehension: hear (and see) a word, tap the matching picture.
/// No speaking needed, so it suits children who are not talking yet.
class PictureMatchPage extends StatefulWidget {
  const PictureMatchPage({super.key, this.rounds = 10});
  final int rounds;

  @override
  State<PictureMatchPage> createState() => _PictureMatchPageState();
}

class _Round {
  _Round(this.answer, this.options);
  final KidWord answer;
  final List<KidWord> options;
}

class _PictureMatchPageState extends State<PictureMatchPage> {
  final _rng = Random();
  final _started = DateTime.now();
  late final List<_Round> _rounds = _build();
  int _index = 0;
  int? _picked;
  int _correct = 0;
  bool _done = false;
  bool _showWord = true;

  bool get _ta => LanguageService.currentLanguage == Language.tamil;
  _Round get _round => _rounds[_index];
  String _word(KidWord q) => _ta ? q.ta : q.en;

  List<_Round> _build() {
    final pool = List<KidWord>.from(kidWords)..shuffle(_rng);
    return [
      for (final answer in pool.take(widget.rounds))
        _Round(
          answer,
          ([
            answer,
            ...(kidWords.where((q) =>
                    q.id != answer.id && q.category != answer.category).toList()
                  ..shuffle(_rng))
                .take(3),
          ]..shuffle(_rng)),
        ),
    ];
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _say());
  }

  @override
  void dispose() {
    SpeechService.shared.stopSpeaking();
    super.dispose();
  }

  void _say() {
    if (ComfortSettings.instance.autoReadAloud.value) {
      SpeechService.shared.speakText(_word(_round.answer));
    }
  }

  void _pick(int i) {
    if (_picked != null) return;
    final right = _round.options[i].id == _round.answer.id;
    right ? HapticFeedback.lightImpact() : HapticFeedback.heavyImpact();
    setState(() {
      _picked = i;
      if (right) _correct++;
    });
    Locator.userDatabaseService
        .recordExerciseResult(
          taskId: 'match_${_round.answer.id}',
          accuracy: right ? 100 : 0,
          category: 'picture',
          target: _word(_round.answer),
          spoken: _word(_round.options[i]),
          method: 'tap',
          assisted: ComfortSettings.instance.assistedMode.value,
        )
        .catchError((_) => null);
  }

  Future<void> _next() async {
    if (_index == _rounds.length - 1) {
      setState(() => _done = true);
      final score = _correct * 100 / _rounds.length;
      try {
        await Locator.userDatabaseService.recordSession(SessionRecord(
          kind: 'picture',
          title: 'Picture match',
          itemCount: _rounds.length,
          averageScore: score,
          minutes: (DateTime.now().difference(_started).inSeconds / 60).ceil(),
          assisted: ComfortSettings.instance.assistedMode.value,
          helperName: ComfortSettings.instance.helperName.value,
          createdAt: DateTime.now(),
        ));
        await ComfortSettings.instance
            .markPlanDone(dayKey(DateTime.now()), 'picture');
      } catch (_) {}
      return;
    }
    setState(() {
      _index++;
      _picked = null;
    });
    _say();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    if (_done) {
      final score = _correct * 100 / _rounds.length;
      return AphScaffold(
        title: tr('Picture match', 'படப் பொருத்தம்'),
        showBack: false,
        bottom: AphButton(
          label: tr('Done', 'முடிந்தது'),
          icon: Icons.check_rounded,
          onPressed: () => Navigator.pop(context),
        ),
        children: [
          const Gap(AphSpace.xl),
          Center(child: ScoreRing(score: score, size: 160)),
          const Gap(AphSpace.md),
          Text(
            tr('$_correct of ${_rounds.length} pictures matched',
                '${_rounds.length} இல் $_correct படங்கள் சரி'),
            textAlign: TextAlign.center,
            style: t.headlineSmall,
          ),
        ],
      );
    }

    final answered = _picked != null;
    final right =
        answered && _round.options[_picked!].id == _round.answer.id;
    return AphScaffold(
      title: tr('Picture match', 'படப் பொருத்தம்'),
      actions: [
        IconButton(
          tooltip: _showWord
              ? tr('Hide the written word', 'எழுத்தை மறை')
              : tr('Show the written word', 'எழுத்தைக் காட்டு'),
          icon: Icon(_showWord
              ? Icons.visibility_off_rounded
              : Icons.visibility_rounded),
          onPressed: () => setState(() => _showWord = !_showWord),
        ),
      ],
      bottom: answered
          ? AphButton(
              label: _index == _rounds.length - 1
                  ? tr('Finish', 'முடி')
                  : tr('Next', 'அடுத்து'),
              icon: Icons.arrow_forward_rounded,
              onPressed: _next,
            )
          : null,
      children: [
        StepProgress(current: _index + 1, total: _rounds.length),
        const Gap(AphSpace.lg),
        Text(tr('Tap the picture for:', 'இதற்கான படத்தைத் தட்டவும்:'),
            style: t.titleLarge),
        const Gap(AphSpace.sm),
        Row(
          children: [
            Expanded(
              child: Text(
                _showWord ? _word(_round.answer) : '• • •',
                style: t.displaySmall,
              ),
            ),
            ReadAloudButton(
              key: ValueKey(_index),
              text: _word(_round.answer),
              compact: true,
            ),
          ],
        ),
        const Gap(AphSpace.md),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AphSpace.sm,
          crossAxisSpacing: AphSpace.sm,
          children: [
            for (var i = 0; i < _round.options.length; i++)
              _Option(
                q: _round.options[i],
                index: i,
                state: !answered
                    ? _OptState.idle
                    : _round.options[i].id == _round.answer.id
                        ? _OptState.correct
                        : i == _picked
                            ? _OptState.wrong
                            : _OptState.dim,
                label: answered ? _word(_round.options[i]) : null,
                onTap: () => _pick(i),
              ),
          ],
        ),
        if (answered) ...[
          const Gap(AphSpace.md),
          FeedbackBanner(
            tone: right ? FeedbackTone.success : FeedbackTone.info,
            title: right
                ? tr('Correct!', 'சரி!')
                : tr('Not quite', 'சரியில்லை'),
            message: right
                ? null
                : tr('The right picture is marked with a tick.',
                    'சரியான படம் டிக் குறியுடன் உள்ளது.'),
          ),
        ],
      ],
    );
  }
}

enum _OptState { idle, correct, wrong, dim }

class _Option extends StatelessWidget {
  const _Option({
    required this.q,
    required this.index,
    required this.state,
    required this.onTap,
    this.label,
  });

  final KidWord q;
  final int index;
  final _OptState state;
  final VoidCallback onTap;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final (border, badge) = switch (state) {
      _OptState.correct => (AphColors.success, Icons.check_circle_rounded),
      _OptState.wrong => (AphColors.danger, Icons.cancel_rounded),
      _ => (AphColors.border, null),
    };
    return Semantics(
      button: true,
      label: label == null
          ? 'Picture ${index + 1}'
          : '$label${state == _OptState.correct ? ', correct' : state == _OptState.wrong ? ', your choice, not correct' : ''}',
      excludeSemantics: true,
      child: Opacity(
        opacity: state == _OptState.dim ? 0.55 : 1,
        child: Material(
          color: AphColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AphRadius.lg),
            side: BorderSide(
              color: border,
              width: state == _OptState.idle ? 1 : 3,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: state == _OptState.idle ? onTap : null,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.all(AphSpace.sm),
                    child: Column(
                      children: [
                        Expanded(
                          child: FittedBox(
                            child: Text(q.emoji, style: const TextStyle(fontSize: 96)),
                          ),
                        ),
                        if (label != null)
                          Text(
                            label!,
                            style: Theme.of(context).textTheme.titleSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ),
                if (badge != null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Icon(badge, color: border, size: 32),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
