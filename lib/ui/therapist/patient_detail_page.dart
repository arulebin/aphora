import 'package:aphora/data/models/practice_record.dart';
import 'package:aphora/data/models/usermodel.dart';
import 'package:aphora/logic/locator.dart';
import 'package:aphora/ui/design/components.dart';
import 'package:aphora/ui/progress/progress_page.dart';
import 'package:aphora/ui/video_call/videocall_page.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Therapist view of one patient: clinical summary, a note the patient
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
        showAphSnack(context, 'Note saved — the patient sees it on their Today screen.',
            tone: FeedbackTone.success);
      }
    } catch (_) {
      if (mounted) {
        showAphSnack(context, 'Could not save the note.', tone: FeedbackTone.error);
      }
    } finally {
      if (mounted) setState(() => _savingNote = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.patient;
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
                  StatusPill(label: '${p.age} yrs · ${p.gender}'),
                  StatusPill(label: p.aphasiaType.isEmpty ? 'Type not set' : p.aphasiaType),
                  StatusPill(label: 'Severity: ${p.severityLevel.isEmpty ? '—' : p.severityLevel}'),
                  StatusPill(label: 'Language: ${p.languagePreference}'),
                  if (p.preAssessmentScore != null)
                    StatusPill(
                      label: 'Check-up ${p.preAssessmentScore!.round()} '
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
                            channelName: 'aphora_${widget.therapistCode}_${p.uid}',
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
        SectionHeader(
          'Note for patient & helper',
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
        SectionHeader('Recent attempts', subtitle: 'What the app heard, newest first'),
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
            return AphCard(
              padding: const EdgeInsets.symmetric(
                horizontal: AphSpace.md,
                vertical: AphSpace.xs,
              ),
              child: Column(
                children: [
                  for (final (i, a) in attempts.indexed) ...[
                    if (i > 0) const Divider(),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: AphSpace.sm),
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
                                  '${a.method}${a.assisted ? ' · assisted' : ''}',
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
            );
          },
        ),
      ],
    );
  }
}
