import 'package:aphora/data/learning/packs/condition_packs.dart';
import 'package:aphora/data/learning/practice_catalog.dart';
import 'package:aphora/data/models/usermodel.dart';
import 'package:aphora/logic/comfort_settings.dart';
import 'package:aphora/logic/language_service.dart';
import 'package:aphora/logic/locator.dart';
import 'package:aphora/ui/design/components.dart';
import 'package:aphora/ui/home/main_navigation.dart';
import 'package:aphora/ui/intake/intake_page.dart';
import 'package:aphora/ui/practice/picture_match_page.dart';
import 'package:aphora/ui/practice/practice_session_page.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// One step of today's plan. `kind == null` means picture match.
class PlanStep {
  const PlanStep(this.id, this.kind, this.title, this.minutes, this.icon);
  final String id;
  final PracticeKind? kind;
  final String title;
  final int minutes;
  final IconData icon;

  /// About 10 minutes from the person's pack, at their level (therapist's
  /// choice, else check-up / intake).
  static List<PlanStep> forUser(UserModel? user) {
    final pack = ConditionPacks.forUser(user);
    final ids = pack.plan(
      level: user?.practiceLevel ?? 2,
      focus: user?.intake?.focus ?? const [],
    );
    return [
      for (final id in ids)
        if (id == ConditionPack.pictureMatchId)
          PlanStep(id, null, pack.matchTitle, 3, Icons.grid_view_rounded)
        else
          for (final kind in PracticeKind.values)
            if (kind.id == id)
              PlanStep(id, kind, pack.title(kind), pack.minutes(kind),
                  pack.icon(kind)),
    ];
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _users = Locator.userDatabaseService;

  Future<void> _open(PlanStep step) async {
    if (step.kind == null) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PictureMatchPage()),
      );
    } else {
      await openPractice(context, step.kind!);
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<UserModel?>(
      valueListenable: _users.currentUser,
      builder: (context, user, _) {
        final t = Theme.of(context).textTheme;
        final today = dayKey(DateTime.now());
        final done = ComfortSettings.instance.planDone(today);
        final plan = PlanStep.forUser(user);
        final remaining = plan.where((s) => !done.contains(s.id)).toList();
        final mins = remaining.fold<int>(0, (a, s) => a + s.minutes);
        final firstName = (user?.name ?? '').split(' ').first;
        final hour = DateTime.now().hour;
        final greeting = hour < 12
            ? tr('Good morning', 'காலை வணக்கம்')
            : hour < 17
                ? tr('Good afternoon', 'மதிய வணக்கம்')
                : tr('Good evening', 'மாலை வணக்கம்');

        return AphScaffold(
          onRefresh: () async {
            await _users.refreshCurrentUser();
          },
          children: [
            const Gap(AphSpace.md),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('EEEE, d MMMM', appDateLocale).format(DateTime.now()),
                        style: t.bodyMedium,
                      ),
                      const Gap(AphSpace.xxs),
                      Semantics(
                        header: true,
                        child: Text(
                          firstName.isEmpty ? greeting : '$greeting, $firstName',
                          style: t.headlineLarge,
                        ),
                      ),
                    ],
                  ),
                ),
                if ((user?.streakDays ?? 0) > 0)
                  StatusPill(
                    label: tr('${user!.streakDays}-day streak',
                        '${user.streakDays} நாள் தொடர்'),
                    icon: Icons.local_fire_department_rounded,
                    color: AphColors.accent,
                    soft: AphColors.accentSoft,
                  ),
              ],
            ),
            if (ComfortSettings.instance.assistedMode.value) ...[
              const Gap(AphSpace.md),
              FeedbackBanner(
                tone: FeedbackTone.info,
                title: tr('Assisted mode is on', 'உதவி முறை இயக்கத்தில்'),
                message: tr(
                  'Sessions start with a hand-over step and end with a helper note.',
                  'அமர்வுகள் ஒப்படைப்பு படியுடன் தொடங்கி உதவியாளர் குறிப்புடன் முடிகின்றன.',
                ),
              ),
            ],
            if ((user?.therapistNote ?? '').isNotEmpty) ...[
              const Gap(AphSpace.md),
              AphCard(
                color: AphColors.infoSoft,
                borderColor: AphColors.info.withValues(alpha: 0.3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.medical_services_rounded,
                        color: AphColors.info, size: 28),
                    const Gap(AphSpace.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tr('From your therapist', 'உங்கள் சிகிச்சையாளரிடமிருந்து'),
                              style: t.titleMedium?.copyWith(color: AphColors.info)),
                          const Gap(AphSpace.xxs),
                          Text(user!.therapistNote!, style: t.bodyLarge),
                        ],
                      ),
                    ),
                    ReadAloudButton(text: user.therapistNote!, compact: true),
                  ],
                ),
              ),
            ],
            if (user != null && user.intake == null) ...[
              const Gap(AphSpace.md),
              ActionTile(
                key: const ValueKey('today_intake'),
                icon: Icons.quiz_rounded,
                title: tr('Answer a few questions to tailor the exercises',
                    'பயிற்சிகளைப் பொருத்தமாக்கச் சில கேள்விகளுக்குப் பதில் சொல்லுங்கள்'),
                subtitle: tr(
                  'About 3 minutes, one question at a time. You can listen to each one.',
                  'சுமார் 3 நிமிடம், ஒரு நேரத்தில் ஒரு கேள்வி. ஒவ்வொன்றையும் கேட்கலாம்.',
                ),
                onTap: () async {
                  await openIntake(context);
                  if (mounted) setState(() {});
                },
              ),
            ],
            if (user != null &&
                ConditionPacks.forUser(user).hasCheckUp &&
                ConditionPacks.forUser(user).checkUpDue(user)) ...[
              const Gap(AphSpace.md),
              ActionTile(
                icon: Icons.assignment_rounded,
                title: ConditionPacks.forUser(user).checkUpIsMeasure
                    ? ConditionPacks.forUser(user).title(PracticeKind.assessment)
                    : tr('Start with a speech check-up', 'பேச்சு மதிப்பீட்டுடன் தொடங்குங்கள்'),
                subtitle: ConditionPacks.forUser(user).checkUpIsMeasure
                    ? tr('About 5 minutes, once a month. The same 20 items show how your speech is changing.',
                        'மாதம் ஒருமுறை, சுமார் 5 நிமிடம். அதே 20 சொற்கள் உங்கள் பேச்சு எப்படி மாறுகிறது என்று காட்டும்.')
                    : ConditionPacks.childWording(user)
                    ? tr(
                        'About ${PracticeKind.assessment.minutes} minutes. It helps us choose the right exercises for your child.',
                        'சுமார் ${PracticeKind.assessment.minutes} நிமிடம். உங்கள் குழந்தைக்கு ஏற்ற பயிற்சிகளைத் தேர்ந்தெடுக்க உதவும்.',
                      )
                    : tr(
                        'About ${PracticeKind.assessment.minutes} minutes. It helps choose a good starting level.',
                        'சுமார் ${PracticeKind.assessment.minutes} நிமிடம். சரியான தொடக்க நிலையைத் தேர்ந்தெடுக்க உதவும்.',
                      ),
                color: AphColors.accent,
                softColor: AphColors.accentSoft,
                onTap: () async {
                  await openPractice(context, PracticeKind.assessment);
                  if (mounted) setState(() {});
                },
              ),
            ],
            SectionHeader(
              tr("Today's plan", 'இன்றைய திட்டம்'),
              subtitle: remaining.isEmpty
                  ? tr('All done for today — wonderful work.',
                      'இன்றைக்கு எல்லாம் முடிந்தது — அருமை.')
                  : tr('${remaining.length} exercises · about $mins minutes',
                      '${remaining.length} பயிற்சிகள் · சுமார் $mins நிமிடங்கள்'),
            ),
            AphCard(
              padding: const EdgeInsets.all(AphSpace.md),
              child: Column(
                children: [
                  for (final (i, step) in plan.indexed) ...[
                    if (i > 0) const Divider(height: AphSpace.md),
                    _PlanRow(
                      step: step,
                      done: done.contains(step.id),
                      onTap: () => _open(step),
                    ),
                  ],
                  const Gap(AphSpace.md),
                  if (remaining.isNotEmpty)
                    AphButton(
                      label: tr('Start: ${remaining.first.title}',
                          'தொடங்கு: ${remaining.first.title}'),
                      icon: Icons.play_arrow_rounded,
                      onPressed: () => _open(remaining.first),
                    )
                  else
                    AphButton.secondary(
                      label: tr('Practise more', 'மேலும் பயிற்சி'),
                      icon: Icons.add_rounded,
                      onPressed: () =>
                          MainNavigation.goTo(context, MainNavigation.practice),
                    ),
                ],
              ),
            ),
            SectionHeader(tr('This week', 'இந்த வாரம்')),
            _WeekCard(user: user),
          ],
        );
      },
    );
  }
}

class _PlanRow extends StatelessWidget {
  const _PlanRow({required this.step, required this.done, required this.onTap});
  final PlanStep step;
  final bool done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      label: '${step.title}, about ${step.minutes} minutes, ${done ? 'done' : 'not done yet'}',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AphRadius.md),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Row(
            children: [
              Icon(
                done ? Icons.check_circle_rounded : step.icon,
                color: done ? AphColors.success : AphColors.primary,
                size: 30,
              ),
              const Gap(AphSpace.md),
              Expanded(
                child: Text(
                  step.title,
                  style: t.titleMedium?.copyWith(
                    decoration: done ? TextDecoration.lineThrough : null,
                    color: done ? AphColors.inkMuted : AphColors.ink,
                  ),
                ),
              ),
              Text(
                done ? tr('Done', 'முடிந்தது') : '${step.minutes} min',
                style: t.bodySmall,
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: AphColors.inkSubtle),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeekCard extends StatelessWidget {
  const _WeekCard({required this.user});
  final UserModel? user;

  /// Short weekday under each bar. Tamil uses the narrow form (ஞா, தி, செ…)
  /// because cutting code units would split a letter from its vowel sign;
  /// English keeps two letters (Mo, Tu) so Tue/Thu stay distinct.
  static String _dayLabel(DateTime d) => appDateLocale == 'ta'
      ? DateFormat('EEEEE', 'ta').format(d)
      : DateFormat('E', 'en').format(d).characters.take(2).toString();

  @override
  Widget build(BuildContext context) {
    final counts = user?.recentActivityCounts(days: 7) ?? List.filled(7, 0);
    final now = DateTime.now();
    final labels = [
      for (var i = 6; i >= 0; i--)
        _dayLabel(now.subtract(Duration(days: i))),
    ];
    return AphCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _Mini(
                  value: '${counts.fold<int>(0, (a, b) => a + b)}',
                  label: tr('exercises', 'பயிற்சிகள்'),
                ),
              ),
              Expanded(
                child: _Mini(
                  value: '${user?.streakDays ?? 0}',
                  label: tr('day streak', 'நாள் தொடர்'),
                ),
              ),
              Expanded(
                child: ConditionPacks.forUser(user).selfBaselineScoring
                    // Oral-cancer pack: no scores for the person.
                    ? _Mini(
                        value: '${user?.sessionsCompleted ?? 0}',
                        label: tr('sessions', 'அமர்வுகள்'),
                      )
                    : _Mini(
                        value: '${(user?.averageAccuracy ?? 0).round()}',
                        label: tr('avg score', 'சராசரி'),
                      ),
              ),
            ],
          ),
          const Gap(AphSpace.lg),
          WeekBars(counts: counts, labels: labels),
        ],
      ),
    );
  }
}

class _Mini extends StatelessWidget {
  const _Mini({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Semantics(
      label: '$value $label',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: t.headlineMedium),
          Text(label, style: t.bodySmall),
        ],
      ),
    );
  }
}
