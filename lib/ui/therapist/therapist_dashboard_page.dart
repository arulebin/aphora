import 'package:aphora/data/learning/child_profile.dart';
import 'package:aphora/data/models/booking_model.dart';
import 'package:aphora/data/models/therapist_model.dart';
import 'package:aphora/data/models/usermodel.dart';
import 'package:aphora/logic/locator.dart';
import 'package:aphora/ui/care/care_team_page.dart';
import 'package:aphora/ui/design/components.dart';
import 'package:aphora/ui/therapist/patient_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// Therapist home: share code, session requests (accept / decline — the
/// old app had no way to respond), and the caseload with recent scores.
class TherapistDashboardPage extends StatefulWidget {
  const TherapistDashboardPage({super.key});

  @override
  State<TherapistDashboardPage> createState() => _TherapistDashboardPageState();
}

class _TherapistDashboardPageState extends State<TherapistDashboardPage> {
  final _db = Locator.userDatabaseService;
  late Future<List<UserModel>> _patients = _load();

  TherapistModel? get _therapist => _db.currentTherapist.value;

  Future<List<UserModel>> _load() async {
    final th = _therapist;
    if (th == null) return const [];
    return _db.getTherapistPatients(th.code);
  }

  Future<void> _refresh() async {
    setState(() {
      _patients = _load();
    });
    await _patients;
  }

  @override
  Widget build(BuildContext context) {
    final th = _therapist;
    final t = Theme.of(context).textTheme;
    if (th == null) {
      return AphScaffold(
        children: [
          EmptyState(
            icon: Icons.lock_outline_rounded,
            title: 'Please sign in again',
            action: AphButton(
              label: 'Go to sign in',
              expand: false,
              onPressed: () => context.go('/therapist'),
            ),
          ),
        ],
      );
    }
    return AphScaffold(
      title: 'Caseload',
      showBack: false,
      onRefresh: _refresh,
      actions: [
        IconButton(
          tooltip: 'Sign out',
          icon: const Icon(Icons.logout_rounded),
          onPressed: () async {
            final ok = await confirmDialog(
              context,
              title: 'Sign out?',
              message: 'You can sign back in with your phone and password.',
              confirm: 'Sign out',
            );
            if (!ok) return;
            await _db.logout();
            if (context.mounted) context.go('/login');
          },
        ),
      ],
      children: [
        Text('Hello, ${th.name}', style: t.headlineMedium),
        const Gap(AphSpace.md),
        AphCard(
          color: AphColors.primarySoft,
          borderColor: AphColors.primary.withValues(alpha: 0.25),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Your code for families', style: t.titleSmall),
                    const Gap(AphSpace.xxs),
                    SelectableText(
                      th.code,
                      style: t.displaySmall?.copyWith(
                        color: AphColors.primaryPressed,
                        letterSpacing: 4,
                      ),
                    ),
                    Text('Parents enter this in the Care team tab.',
                        style: t.bodySmall),
                  ],
                ),
              ),
              IconButton.filled(
                tooltip: 'Copy code',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: th.code));
                  showAphSnack(context, 'Code copied', tone: FeedbackTone.success);
                },
                icon: const Icon(Icons.copy_rounded),
              ),
            ],
          ),
        ),
        StreamBuilder<List<BookingModel>>(
          stream: Locator.bookingDatabaseService.getBookingsForTherapist(th.code),
          builder: (context, snap) {
            final list = (snap.data ?? const <BookingModel>[])
                .where((b) =>
                    b.isUpcoming &&
                    (b.status == 'pending' || b.status == 'confirmed'))
                .toList();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SectionHeader(
                  'Upcoming sessions',
                  subtitle: snap.hasError
                      ? 'Could not load bookings.'
                      : list.isEmpty
                          ? 'No requests right now.'
                          : '${list.where((b) => b.status == 'pending').length} waiting for your answer',
                ),
                for (final b in list)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AphSpace.sm),
                    child: BookingTile(
                      booking: b,
                      title: b.patientName,
                      actions: [
                        if (b.status == 'pending') ...[
                          AphButton.ghost(
                            label: 'Decline',
                            icon: Icons.close_rounded,
                            onPressed: () => Locator.bookingDatabaseService
                                .setStatus(b.id, 'declined'),
                          ),
                          FilledButton.icon(
                            onPressed: () => Locator.bookingDatabaseService
                                .setStatus(b.id, 'confirmed'),
                            icon: const Icon(Icons.check_rounded),
                            label: const Text('Confirm'),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(0, 48),
                            ),
                          ),
                        ] else
                          AphButton.ghost(
                            label: 'Mark done',
                            icon: Icons.task_alt_rounded,
                            onPressed: () => Locator.bookingDatabaseService
                                .setStatus(b.id, 'completed'),
                          ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
        SectionHeader('Children'),
        FutureBuilder<List<UserModel>>(
          future: _patients,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Padding(
                padding: EdgeInsets.all(AphSpace.xl),
                child: LoadingState(),
              );
            }
            if (snap.hasError) return ErrorState(onRetry: _refresh);
            final patients = snap.data!;
            if (patients.isEmpty) {
              return const EmptyState(
                icon: Icons.groups_rounded,
                title: 'No linked children yet',
                message: 'Share your code. Children appear here as soon as a parent links.',
              );
            }
            return Column(
              children: [
                for (final p in patients)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AphSpace.sm),
                    child: _PatientTile(
                      patient: p,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PatientDetailPage(
                              patient: p,
                              therapistCode: th.code,
                            ),
                          ),
                        );
                        _refresh();
                      },
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

class _PatientTile extends StatelessWidget {
  const _PatientTile({required this.patient, required this.onTap});
  final UserModel patient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final week = patient.recentActivityCounts(days: 7).fold<int>(0, (a, b) => a + b);
    final active = DateFormat('d MMM').format(patient.updatedAt);
    return AphCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AphSpace.md),
      semanticLabel:
          '${patient.name}. $week exercises this week. Average ${patient.averageAccuracy.round()}.',
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: AphColors.primarySoft,
            child: Text(
              patient.name.isEmpty ? '?' : patient.name.characters.first.toUpperCase(),
              style: t.titleLarge?.copyWith(color: AphColors.primary),
            ),
          ),
          const Gap(AphSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(patient.name, style: t.titleMedium),
                Text(
                  '${ChildProfile.concern(patient.aphasiaType)} · '
                  '${ChildProfile.clarity(patient.severityLevel)} · '
                  'active $active',
                  style: t.bodySmall,
                ),
                const Gap(AphSpace.xxs),
                Wrap(
                  spacing: AphSpace.xs,
                  runSpacing: AphSpace.xxs,
                  children: [
                    StatusPill(
                      label: '$week this week',
                      icon: Icons.bar_chart_rounded,
                      color: week == 0 ? AphColors.warning : AphColors.primary,
                      soft: week == 0 ? AphColors.warningSoft : AphColors.primarySoft,
                    ),
                    if (patient.totalAttempts > 0)
                      ScoreBadge(score: patient.averageAccuracy),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AphColors.inkSubtle),
        ],
      ),
    );
  }
}
