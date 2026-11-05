import 'package:aphora/data/intake/condition.dart';
import 'package:aphora/data/intake/intake_questions.dart';
import 'package:aphora/data/learning/packs/condition_packs.dart';
import 'package:aphora/data/learning/practice_catalog.dart';
import 'package:aphora/logic/intake_engine.dart';
import 'package:aphora/logic/language_service.dart';
import 'package:aphora/logic/locator.dart';
import 'package:aphora/ui/design/components.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Opens the questionnaire from inside the app (Today card, "Retake" on Me).
/// Returns when it is finished or closed.
Future<void> openIntake(BuildContext context) {
  final user = Locator.userDatabaseService.currentUser.value;
  return context.push('/intake', extra: {
    'age': user?.age ?? 0,
  });
}

/// The intake questionnaire: one question per screen, rendered from
/// [IntakeQuestionnaire] (data), scored by [IntakeEngine] (rules), then a
/// result screen. Used right after sign-up and from Today / Me.
class IntakePage extends StatefulWidget {
  const IntakePage({
    super.key,
    this.who,
    this.age = 0,
    this.fromSignUp = false,
  });

  /// "Who is this for?", already answered on sign-up step 2.
  final String? who;

  /// Age in years from the profile (0 = unknown → asked as a band).
  final int age;

  /// After sign-up the page cannot go back to the form (the account
  /// exists); it offers "Skip for now" instead and ends on Today.
  final bool fromSignUp;

  @override
  State<IntakePage> createState() => _IntakePageState();
}

class _IntakePageState extends State<IntakePage> {
  late Answers _answers = {
    if (widget.who != null) 'who': widget.who!,
    if (widget.age > 0) 'age': '${widget.age}',
  };
  late final Set<String> _given = {if (widget.who != null) 'who'};
  int _pos = 0;
  IntakeResult? _result;
  bool _saving = false;
  String? _error;

  List<IntakeQuestion> get _seq => IntakeEngine.visible(_answers)
      .where((q) => !_given.contains(q.id))
      .toList();

  void _choose(IntakeQuestion q, String value) => setState(() {
        _answers = IntakeEngine.prune({..._answers, q.id: value});
      });

  void _next() {
    final seq = _seq;
    if (_pos + 1 >= seq.length) {
      setState(() => _result = IntakeEngine.evaluate(_answers));
    } else {
      setState(() => _pos++);
    }
  }

  void _back() {
    if (_result != null) {
      setState(() {
        _result = null;
        _error = null;
      });
    } else if (_pos > 0) {
      setState(() => _pos--);
    } else if (!widget.fromSignUp && context.canPop()) {
      context.pop();
    }
  }

  void _leave() {
    if (!widget.fromSignUp && context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  Future<void> _save() async {
    final users = Locator.userDatabaseService;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final record = await IntakeEngine.record(
        _answers,
        name: users.currentUser.value?.name ?? '',
        now: DateTime.now(),
      );
      await users.saveIntake(record, IntakeEngine.evaluate(_answers));
      if (mounted) _leave();
    } catch (_) {
      if (mounted) {
        setState(() => _error = tr(
              'Could not save your answers. Check the internet and try again.',
              'பதில்களைச் சேமிக்க முடியவில்லை. இணையத்தைச் சரிபார்த்து மீண்டும் முயலுங்கள்.',
            ));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final atStart = _result == null && _pos == 0;
    return PopScope(
      canPop: atStart && !widget.fromSignUp,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: _result == null ? _question(context) : _resultView(context),
    );
  }

  List<Widget>? get _actions => widget.fromSignUp
      ? [
          TextButton(
            onPressed: () => context.go('/home'),
            child: Text(tr('Skip for now', 'இப்போது வேண்டாம்')),
          ),
        ]
      : null;

  Widget _question(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final seq = _seq;
    if (seq.isEmpty) {
      // Nothing to ask (should not happen) — go straight to the result.
      WidgetsBinding.instance.addPostFrameCallback((_) => _next());
      return const Scaffold(body: LoadingState());
    }
    final pos = _pos.clamp(0, seq.length - 1);
    final q = seq[pos];
    final selected = _answers[q.id];
    final isLast = pos == seq.length - 1;
    final spoken = [
      q.prompt.text,
      if (q.helper != null) q.helper!.text,
      ...q.options.map((o) => o.label.text),
    ].join('. ');

    return AphScaffold(
      title: tr('A few questions', 'சில கேள்விகள்'),
      showBack: false,
      actions: _actions,
      bottom: Row(
        children: [
          if (pos > 0 || !widget.fromSignUp) ...[
            Expanded(
              child: AphButton.secondary(
                label: tr('Back', 'பின் செல்'),
                icon: Icons.arrow_back_rounded,
                onPressed: _back,
              ),
            ),
            const Gap(AphSpace.sm),
          ],
          Expanded(
            child: AphButton(
              label: isLast
                  ? tr('See the result', 'முடிவைப் பார்')
                  : tr('Next', 'அடுத்து'),
              icon: isLast ? Icons.check_rounded : Icons.arrow_forward_rounded,
              onPressed: selected == null ? null : _next,
            ),
          ),
        ],
      ),
      children: [
        StepProgress(current: pos + 1, total: seq.length),
        const Gap(AphSpace.lg),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(q.prompt.text, style: t.headlineSmall),
              ),
            ),
            const Gap(AphSpace.sm),
            ReadAloudButton(
              key: ValueKey('read_${q.id}'),
              text: spoken,
              label: tr('Listen', 'கேளுங்கள்'),
              compact: true,
              autoPlay: true,
            ),
          ],
        ),
        if (q.helper != null) ...[
          const Gap(AphSpace.xs),
          Text(q.helper!.text, style: t.bodyLarge),
        ],
        const Gap(AphSpace.lg),
        for (final o in q.options)
          Padding(
            padding: const EdgeInsets.only(bottom: AphSpace.sm),
            child: _AnswerTile(
              option: o,
              selected: o.value == selected,
              onTap: () => _choose(q, o.value),
            ),
          ),
      ],
    );
  }

  Widget _resultView(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final r = _result!;
    final flags = [
      for (final id in r.redFlags)
        if (RedFlag.byId(id) != null) RedFlag.byId(id)!,
    ];
    final focus = [
      for (final id in r.focus)
        if (FocusArea.byId(id) != null) FocusArea.byId(id)!,
    ];
    final spoken = [
      r.condition.label,
      StartLevel.label(r.startLevel).text,
      ...focus.map((f) => f.label.text),
      ...flags.map((f) => f.message.text),
    ].join('. ');

    return AphScaffold(
      title: tr('Your starting plan', 'உங்கள் தொடக்கத் திட்டம்'),
      showBack: false,
      bottom: Row(
        children: [
          Expanded(
            child: AphButton.secondary(
              label: tr('Back', 'பின் செல்'),
              icon: Icons.arrow_back_rounded,
              onPressed: _saving ? null : _back,
            ),
          ),
          const Gap(AphSpace.sm),
          Expanded(
            child: AphButton(
              label: tr('Save and continue', 'சேமித்துத் தொடரவும்'),
              icon: Icons.check_rounded,
              loading: _saving,
              onPressed: _save,
            ),
          ),
        ],
      ),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: ReadAloudButton(text: spoken, label: tr('Listen', 'கேளுங்கள்')),
        ),
        if (flags.isNotEmpty) ...[
          SectionHeader(
            r.practiceOnHold
                ? tr('Please do this first', 'முதலில் இதைச் செய்யுங்கள்')
                : tr('Please also check', 'இதையும் கவனியுங்கள்'),
          ),
          for (final f in flags)
            Padding(
              padding: const EdgeInsets.only(bottom: AphSpace.sm),
              child: FeedbackBanner(
                tone: f.level == RedFlagLevel.referral
                    ? FeedbackTone.warning
                    : FeedbackTone.error,
                title: f.message.text,
              ),
            ),
        ],
        const Gap(AphSpace.md),
        AphCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tr('Programme', 'பயிற்சித் திட்டம்'), style: t.labelLarge),
              Text(r.condition.label, style: t.titleLarge),
              const Divider(height: AphSpace.lg),
              Text(tr('Start at', 'தொடக்க நிலை'), style: t.labelLarge),
              Text(StartLevel.label(r.startLevel).text, style: t.titleMedium),
              const Divider(height: AphSpace.lg),
              Text(tr('Focus on', 'கவனம் செலுத்த வேண்டியவை'), style: t.labelLarge),
              const Gap(AphSpace.xxs),
              for (final f in focus)
                Padding(
                  padding: const EdgeInsets.only(top: AphSpace.xxs),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          color: AphColors.primary, size: 22),
                      const Gap(AphSpace.xs),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(f.label.text, style: t.titleMedium),
                            if (r.condition == Condition.childSpeechDelay)
                              Text(
                                tr('Exercise: ${_exerciseName(f.practice)}',
                                    'பயிற்சி: ${_exerciseName(f.practice)}'),
                                style: t.bodyMedium,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        if (ConditionPacks.contentPending(r.condition)) ...[
          const Gap(AphSpace.md),
          FeedbackBanner(
            tone: FeedbackTone.info,
            title: tr('Your exercises are being prepared',
                'உங்களுக்கான பயிற்சிகள் தயாராகி வருகின்றன'),
            message: tr(
              'For now you can use the general practice set. Your answers are saved and shared with the therapist you link.',
              'இப்போதைக்குப் பொதுப் பயிற்சிகளைப் பயன்படுத்தலாம். உங்கள் பதில்கள் சேமிக்கப்பட்டு, நீங்கள் இணைக்கும் சிகிச்சையாளருடன் பகிரப்படும்.',
            ),
          ),
        ],
        if (_error != null) ...[
          const Gap(AphSpace.md),
          FeedbackBanner(tone: FeedbackTone.error, title: _error!),
        ],
        const Gap(AphSpace.lg),
        Text(
          tr('This is a screening questionnaire, not a diagnosis. Only a doctor or speech therapist can diagnose.',
              'இது ஒரு முன்கட்டப் பரிசோதனைக் கேள்வித்தாள் மட்டுமே, நோயறிதல் அல்ல. மருத்துவர் அல்லது பேச்சு சிகிச்சையாளர் மட்டுமே நோயைக் கண்டறிய முடியும்.'),
          style: t.bodySmall,
        ),
      ],
    );
  }

  static String _exerciseName(String practice) {
    if (practice == 'picture') return tr('Picture match', 'படப் பொருத்தம்');
    for (final k in PracticeKind.values) {
      if (k.name == practice) return k.title;
    }
    return practice;
  }
}

/// One big, full-width answer: emoji (or a radio mark), the label, a tick
/// when chosen.
class _AnswerTile extends StatelessWidget {
  const _AnswerTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final IntakeOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: AphCard(
        onTap: onTap,
        semanticLabel: option.label.text,
        color: selected ? AphColors.primarySoft : AphColors.surface,
        borderColor: selected ? AphColors.primary : AphColors.borderStrong,
        padding: const EdgeInsets.symmetric(
          horizontal: AphSpace.md,
          vertical: AphSpace.md,
        ),
        child: Row(
          children: [
            if (option.emoji != null)
              ExcludeSemantics(
                child: Text(option.emoji!, style: const TextStyle(fontSize: 30)),
              )
            else
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected ? AphColors.primary : AphColors.inkMuted,
                size: 28,
              ),
            const Gap(AphSpace.md),
            Expanded(
              child: Text(
                option.label.text,
                style: t.titleMedium?.copyWith(
                  color: selected ? AphColors.primaryPressed : AphColors.ink,
                ),
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded,
                  color: AphColors.primary, size: 28),
          ],
        ),
      ),
    );
  }
}
