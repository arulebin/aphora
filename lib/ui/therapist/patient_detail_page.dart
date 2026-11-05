import 'package:aphora/data/intake/condition.dart';
import 'package:aphora/data/intake/intake_questions.dart';
import 'package:aphora/data/learning/child_profile.dart';
import 'package:aphora/data/models/practice_record.dart';
import 'package:aphora/data/models/usermodel.dart';
import 'package:aphora/logic/locator.dart';
import 'package:aphora/logic/practice_rewards.dart';
import 'package:aphora/ui/design/components.dart';
import 'package:aphora/ui/progress/progress_page.dart';
import 'package:aphora/ui/video_call/videocall_page.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Therapist view of one child: clinical summary, a note the patient
/// sees on their Today screen (replaces the "Messaging coming soon" stub),
/// score trend, recent attempts with what was heard, and helper logs.
class PatientDetailPage extends StatefulWidget {
  const PatientDetailPage({
    super.key,
    required this.patient,
    required this.therapistCode,
  });

  final UserModel patient;
  final String therapistCode;

  @override
  State<PatientDetailPage> createState() => _PatientDetailPageState();
}

class _PatientDetailPageState extends State<PatientDetailPage> {
  final _db = Locator.userDatabaseService;
  late final _note = TextEditingController(text: widget.patient.therapistNote);
  late Future<(List<AttemptRecord>, List<SessionRecord>)> _future = _load();
  bool _savingNote = false;

  /// The patient as last saved here (the plan can change on this page).
  late UserModel _patient = widget.patient;

  Future<(List<AttemptRecord>, List<SessionRecord>)> _load() async {
    final r = await Future.wait([
      _db.getRecentAttempts(widget.patient.uid, limit: 40),
      _db.getRecentSessions(widget.patient.uid),
    ]);
    return (r[0] as List<AttemptRecord>, r[1] as List<SessionRecord>);
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    setState(() => _savingNote = true);
    try {
      await _db.setTherapistNote(widget.patient.uid, _note.text);
      if (mounted) {
        showAphSnack(
            context,
            _patient.isChild
                ? 'Note saved — the parent sees it on their Today screen.'
                : 'Note saved — it shows on their Today screen.',
            tone: FeedbackTone.success);
      }
    } catch (_) {
      if (mounted) {
        showAphSnack(
          context,
          'Could not save the note.',
          tone: FeedbackTone.error,
        );
      }
    } finally {
      if (mounted) setState(() => _savingNote = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _patient;
    final t = Theme.of(context).textTheme;
    return AphScaffold(
      title: p.name,
      onRefresh: () async {
        setState(() {
          _future = _load();
        });
        await _future;
      },
      children: [
        AphCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: AphSpace.xs,
                runSpacing: AphSpace.xs,
                children: [
                  StatusPill(
                    label: p.isChild
                        ? '${p.age} yrs · ${ChildProfile.gender(p.gender)}'
                        : '${p.age} yrs · ${p.gender}',
                  ),
                  StatusPill(
                    label: p.therapistCondition != null
                        ? '${p.activeCondition.therapistLabel} · set by you'
                        : p.intake == null
                            ? 'No intake yet'
                            : p.condition.therapistLabel,
                    icon: Icons.medical_information_rounded,
                    color: AphColors.info,
                    soft: AphColors.infoSoft,
                  ),
                  StatusPill(
                    label: 'Level ${p.practiceLevel}'
                        '${p.therapistLevel != null ? ' · set by you' : ''}',
                    icon: Icons.stairs_rounded,
                  ),
                  if (p.isChild)
                    StatusPill(label: 'Worry: ${ChildProfile.concern(p.aphasiaType)}'),
                  if (p.severityLevel.isNotEmpty)
                    StatusPill(label: ChildProfile.clarity(p.severityLevel)),
                  StatusPill(label: 'Language: ${p.languagePreference}'),
                  if (p.preAssessmentScore != null)
                    StatusPill(
                      label:
                          'Check-up ${p.preAssessmentScore!.round()} '
                          '(${DateFormat('d MMM').format(p.preAssessmentDate ?? p.updatedAt)})',
                      icon: Icons.assignment_rounded,
                      color: AphColors.accent,
                      soft: AphColors.accentSoft,
                    ),
                ],
              ),
              const Gap(AphSpace.md),
              Row(
                children: [
                  Expanded(
                    child: AphButton(
                      label: 'Video call',
                      icon: Icons.videocam_rounded,
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => VideoCallPage(
                            channelName:
                                'aphora_${widget.therapistCode}_${p.uid}',
                            peerName: p.name,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        _IntakeSection(patient: p),
        _PlanSection(
          patient: p,
          onSaved: (c, level) => setState(() {
            _patient = UserModel.fromMap({
              ..._patient.toMap(),
              'therapistCondition': c?.id,
              'therapistLevel': level,
            });
          }),
        ),
        SectionHeader(
          p.isChild ? 'Note for the parent' : 'Note for the patient and carer',
          subtitle: 'Shown on their Today screen and read aloud on request.',
        ),
        AphTextField(
          controller: _note,
          label: 'Home practice guidance',
          hint: 'e.g. Focus on food words this week; allow two hints.',
          maxLines: 3,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.newline,
        ),
        const Gap(AphSpace.sm),
        AphButton.secondary(
          label: 'Save note',
          icon: Icons.save_rounded,
          loading: _savingNote,
          onPressed: _saveNote,
        ),
        SectionHeader('Progress'),
        ProgressBody(
          user: p,
          future: _future,
          forTherapist: true,
          onRetry: () => setState(() {
            _future = _load();
          }),
        ),
        SectionHeader(
          'Recent attempts',
          subtitle: 'What the app heard, newest first',
        ),
        FutureBuilder<(List<AttemptRecord>, List<SessionRecord>)>(
          future: _future,
          builder: (context, snap) {
            if (!snap.hasData) return const SizedBox.shrink();
            final attempts = snap.data!.$1.reversed.take(15).toList();
            if (attempts.isEmpty) {
              return const EmptyState(
                icon: Icons.mic_none_rounded,
                title: 'No attempts recorded yet',
              );
            }
            final hints = HintStats.averagePerWord(snap.data!.$1);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (hints != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AphSpace.sm),
                    child: Text(
                      'Hints per word (What is this?): ${HintStats.format(hints)} '
                      '— lower means more independent naming',
                      style: t.titleSmall,
                    ),
                  ),
                AphCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AphSpace.md,
                    vertical: AphSpace.xs,
                  ),
                  child: Column(
                    children: [
                      for (final (i, a) in attempts.indexed) ...[
                        if (i > 0) const Divider(),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AphSpace.sm,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(a.target, style: t.titleMedium),
                                    Text(
                                      'Heard: ${a.spoken.isEmpty ? '—' : a.spoken}',
                                      style: t.bodyMedium,
                                    ),
                                    Text(
                                      '${DateFormat('d MMM, h:mm a').format(a.createdAt)} · '
                                      '${a.method}${a.assisted ? ' · assisted' : ''}'
                                      '${a.hintsUsed > 0 ? ' · ${a.hintsUsed} hint${a.hintsUsed == 1 ? '' : 's'}' : ''}',
                                      style: t.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              ScoreBadge(score: a.score),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// The therapist's choice of pack and level. Stored as `therapistCondition`
/// / `therapistLevel` (the only fields besides the note that the Firestore
/// rules let a linked therapist change); the app prefers them over the
/// intake result. "Follow the intake" clears them.
class _PlanSection extends StatefulWidget {
  const _PlanSection({required this.patient, required this.onSaved});
  final UserModel patient;
  final void Function(Condition? condition, int? level) onSaved;

  @override
  State<_PlanSection> createState() => _PlanSectionState();
}

class _PlanSectionState extends State<_PlanSection> {
  static const _follow = 'intake';
  late String _pack = widget.patient.therapistCondition?.id ?? _follow;
  late int _level = widget.patient.therapistLevel ?? 0;
  bool _saving = false;

  bool get _changed =>
      _pack != (widget.patient.therapistCondition?.id ?? _follow) ||
      _level != (widget.patient.therapistLevel ?? 0);

  Future<void> _save() async {
    final condition = _pack == _follow ? null : Condition.fromId(_pack);
    final level = _level == 0 ? null : _level;
    setState(() => _saving = true);
    try {
      await Locator.userDatabaseService.setTherapistPlan(
        widget.patient.uid,
        condition: condition,
        level: level,
      );
      widget.onSaved(condition, level);
      if (mounted) {
        showAphSnack(context, 'Practice plan saved — the app uses it from now on.',
            tone: FeedbackTone.success);
      }
    } catch (_) {
      if (mounted) {
        showAphSnack(context, 'Could not save the plan. Check that this patient is linked to you.',
            tone: FeedbackTone.error);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.patient;
    final fromIntake = p.intake == null
        ? 'no intake yet'
        : '${p.condition.therapistLabel}, level ${p.intake!.startLevel}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          'Practice plan',
          subtitle: 'Overrides the intake ($fromIntake). The family sees "Set by therapist".',
        ),
        ChoiceGroup<String>(
          key: const ValueKey('therapist_pack'),
          label: 'Pack',
          value: _pack,
          onChanged: (v) => setState(() => _pack = v),
          options: [
            (_follow, 'Follow the intake', Icons.quiz_rounded),
            for (final c in [
              Condition.childSpeechDelay,
              Condition.adultAphasia,
              Condition.oralCancerRehab,
            ])
              (c.id, c.therapistLabel, null),
          ],
        ),
        const Gap(AphSpace.sm),
        ChoiceGroup<int>(
          key: const ValueKey('therapist_level'),
          label: 'Level',
          helper: 'Level 1: single words and familiar series · 2: words and short phrases · 3: sentences',
          value: _level,
          onChanged: (v) => setState(() => _level = v),
          options: const [
            (0, 'Follow intake / check-up', null),
            (1, 'Level 1', null),
            (2, 'Level 2', null),
            (3, 'Level 3', null),
          ],
        ),
        const Gap(AphSpace.sm),
        AphButton.secondary(
          label: 'Save plan',
          icon: Icons.save_rounded,
          loading: _saving,
          onPressed: _changed ? _save : null,
        ),
      ],
    );
  }
}

/// The intake questionnaire as the therapist sees it: red flags first, then
/// the template summary. Parent report, screening only.
class _IntakeSection extends StatelessWidget {
  const _IntakeSection({required this.patient});
  final UserModel patient;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final intake = patient.intake;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          'Intake summary',
          subtitle: intake == null
              ? null
              : 'Parent/carer report, ${DateFormat('d MMM yyyy').format(intake.completedAt)} · '
                  'screening only, not a diagnosis',
        ),
        if (intake == null)
          Text('No intake questionnaire answered yet.', style: t.bodyLarge)
        else ...[
          for (final id in intake.redFlags)
            if (RedFlag.byId(id) case final f?)
              Padding(
                padding: const EdgeInsets.only(bottom: AphSpace.sm),
                child: FeedbackBanner(
                  tone: f.level == RedFlagLevel.referral
                      ? FeedbackTone.warning
                      : FeedbackTone.error,
                  title: f.message.en,
                ),
              ),
          AphCard(
            child: SelectableText(
              intake.summary.isEmpty ? '—' : intake.summary,
              style: t.bodyLarge,
            ),
          ),
        ],
      ],
    );
  }
}
