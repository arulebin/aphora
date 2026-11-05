import 'package:aphora/data/learning/packs/condition_packs.dart';
import 'package:aphora/data/learning/practice_catalog.dart';
import 'package:aphora/data/models/practice_record.dart';
import 'package:aphora/data/models/usermodel.dart';
import 'package:aphora/logic/language_service.dart';
import 'package:aphora/logic/locator.dart';
import 'package:aphora/ui/design/components.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Score trend, totals and recent sessions for the signed-in child.
/// Also reused by the therapist's patient view via [ProgressBody].
class ProgressPage extends StatefulWidget {
  const ProgressPage({super.key});

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  Future<(List<AttemptRecord>, List<SessionRecord>)>? _future;
  int _lastAttempts = -1;

  void _load(UserModel user) {
    _lastAttempts = user.totalAttempts;
    final db = Locator.userDatabaseService;
    _future = Future.wait([
      db.getRecentAttempts(user.uid),
      db.getRecentSessions(user.uid),
    ]).then((r) => (
          r[0] as List<AttemptRecord>,
          r[1] as List<SessionRecord>,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<UserModel?>(
      valueListenable: Locator.userDatabaseService.currentUser,
      builder: (context, user, _) {
        if (user == null) {
          return const Scaffold(body: LoadingState());
        }
        // Reload when new attempts were recorded elsewhere in the app.
        if (_future == null || user.totalAttempts != _lastAttempts) {
          _load(user);
        }
        return AphScaffold(
          title: tr('Progress', 'வளர்ச்சி'),
          showBack: false,
          onRefresh: () async => setState(() => _load(user)),
          children: [
            ProgressBody(user: user, future: _future!, onRetry: () => setState(() => _load(user))),
          ],
        );
      },
    );
  }
}

class ProgressBody extends StatelessWidget {
  const ProgressBody({
    super.key,
    required this.user,
    required this.future,
    required this.onRetry,
    this.forTherapist = false,
  });

  final UserModel user;
  final Future<(List<AttemptRecord>, List<SessionRecord>)> future;
  final VoidCallback onRetry;
  final bool forTherapist;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final mastered = user.completedExercises.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AphSpace.sm,
          crossAxisSpacing: AphSpace.sm,
          childAspectRatio: 1.35,
          children: [
            StatTile(
              value: '${user.averageAccuracy.round()}',
              label: tr('Average score', 'சராசரி மதிப்பெண்'),
              icon: Icons.track_changes_rounded,
            ),
            StatTile(
              value: '${user.streakDays}',
              label: tr('Day streak', 'நாள் தொடர்'),
              icon: Icons.local_fire_department_rounded,
              color: AphColors.accent,
            ),
            StatTile(
              value: '${user.sessionsCompleted}',
              label: tr('Sessions finished', 'முடிந்த அமர்வுகள்'),
              icon: Icons.event_available_rounded,
              color: AphColors.info,
            ),
            StatTile(
              value: '$mastered',
              label: tr('Different items tried', 'முயன்ற உருப்படிகள்'),
              icon: Icons.auto_awesome_rounded,
              color: AphColors.letters,
            ),
          ],
        ),
        FutureBuilder<(List<AttemptRecord>, List<SessionRecord>)>(
          future: future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Padding(
                padding: EdgeInsets.all(AphSpace.xl),
                child: LoadingState(),
              );
            }
            if (snap.hasError) {
              return ErrorState(onRetry: onRetry);
            }
            final (attempts, sessions) = snap.data!;
            final scores = attempts.map((a) => a.score).toList();
            final firstHalf = scores.take(scores.length ~/ 2);
            final secondHalf = scores.skip(scores.length ~/ 2);
            double avg(Iterable<double> v) =>
                v.isEmpty ? 0 : v.reduce((a, b) => a + b) / v.length;
            final delta = scores.length >= 6
                ? avg(secondHalf) - avg(firstHalf)
                : null;
            final byCat = <String, List<double>>{};
            for (final a in attempts) {
              byCat.putIfAbsent(a.category, () => []).add(a.score);
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SectionHeader(
                  tr('Score trend', 'மதிப்பெண் போக்கு'),
                  subtitle: tr('Last ${scores.length} answers', 'கடைசி ${scores.length} பதில்கள்'),
                ),
                AphCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (delta != null) ...[
                        Row(
                          children: [
                            Icon(
                              delta >= 0
                                  ? Icons.trending_up_rounded
                                  : Icons.trending_down_rounded,
                              color: delta >= 0
                                  ? AphColors.success
                                  : AphColors.warning,
                            ),
                            const Gap(AphSpace.xs),
                            Expanded(
                              child: Text(
                                delta >= 0
                                    ? tr('Up ${delta.round()} points vs. earlier answers',
                                        'முந்தைய பதில்களை விட ${delta.round()} புள்ளிகள் உயர்வு')
                                    : tr('Down ${(-delta).round()} points — tiredness is normal; keep sessions short',
                                        '${(-delta).round()} புள்ளிகள் குறைவு — சோர்வு இயல்பு; அமர்வுகளைச் சிறிதாக வையுங்கள்'),
                                style: t.titleSmall,
                              ),
                            ),
                          ],
                        ),
                        const Gap(AphSpace.md),
                      ],
                      TrendChart(values: scores),
                    ],
                  ),
                ),
                if (byCat.isNotEmpty) ...[
                  SectionHeader(tr('By exercise', 'பயிற்சி வாரியாக')),
                  AphCard(
                    child: Column(
                      children: [
                        for (final (i, e) in byCat.entries.indexed) ...[
                          if (i > 0) const Gap(AphSpace.md),
                          MeterRow(label: _catName(e.key, user), value: avg(e.value)),
                        ],
                      ],
                    ),
                  ),
                ],
                SectionHeader(tr('Recent sessions', 'சமீபத்திய அமர்வுகள்')),
                if (sessions.isEmpty)
                  EmptyState(
                    icon: Icons.history_rounded,
                    title: tr('No sessions yet', 'இன்னும் அமர்வுகள் இல்லை'),
                    message: forTherapist
                        ? 'Sessions appear here once the child finishes an exercise.'
                        : tr('Finish an exercise and it will appear here.',
                            'ஒரு பயிற்சியை முடித்தால் இங்கே தோன்றும்.'),
                  )
                else
                  AphCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AphSpace.md,
                      vertical: AphSpace.xs,
                    ),
                    child: Column(
                      children: [
                        for (final (i, s) in sessions.indexed) ...[
                          if (i > 0) const Divider(),
                          _SessionRow(s: s),
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

  /// Same names as the Practice tab, so "By exercise" matches the tiles.
  static String _catName(String c, UserModel user) {
    final pack = ConditionPacks.forUser(user);
    for (final k in PracticeKind.values) {
      if (k.id == c) return pack.title(k);
    }
    return switch (c) {
      'picture' => pack.matchTitle,
      _ => c,
    };
  }
}

class _SessionRow extends StatelessWidget {
  const _SessionRow({required this.s});
  final SessionRecord s;

  static String _helper(String? name) => name?.isNotEmpty == true
      ? tr('with $name', '$name உடன்')
      : tr('with a helper', 'உதவியாளருடன்');

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AphSpace.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.title, style: t.titleMedium),
                    Text(
                      '${DateFormat('d MMM, h:mm a', appDateLocale).format(s.createdAt)} · '
                      '${tr('${s.itemCount} items', '${s.itemCount} கேள்விகள்')}'
                      '${s.assisted ? ' · ${_helper(s.helperName)}' : ''}',
                      style: t.bodySmall,
                    ),
                  ],
                ),
              ),
              if (s.itemCount > 0) ScoreBadge(score: s.averageScore),
            ],
          ),
          if (s.note != null && s.note!.isNotEmpty) ...[
            const Gap(AphSpace.xs),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.sticky_note_2_outlined,
                    size: 20, color: AphColors.inkMuted),
                const Gap(AphSpace.xs),
                Expanded(child: Text(s.note!, style: t.bodyMedium)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
