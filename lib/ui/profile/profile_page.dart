import 'package:aphora/data/learning/child_profile.dart';
import 'package:aphora/data/models/usermodel.dart';
import 'package:aphora/logic/family_voice_store.dart';
import 'package:aphora/logic/language_service.dart';
import 'package:aphora/logic/locator.dart';
import 'package:aphora/ui/design/components.dart';
import 'package:aphora/ui/profile/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// "Me" tab: profile details, comfort settings, sign out.
/// (Previously a linked parent had no way to sign out at all.)
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<UserModel?>(
      valueListenable: Locator.userDatabaseService.currentUser,
      builder: (context, user, _) {
        final t = Theme.of(context).textTheme;
        return AphScaffold(
          title: tr('Me', 'நான்'),
          showBack: false,
          children: [
            AphCard(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: AphColors.primarySoft,
                    child: Text(
                      (user?.name.isNotEmpty ?? false)
                          ? user!.name.characters.first.toUpperCase()
                          : '?',
                      style: t.headlineMedium?.copyWith(color: AphColors.primary),
                    ),
                  ),
                  const Gap(AphSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user?.name ?? '', style: t.titleLarge),
                        Text(user?.phoneNumber ?? '', style: t.bodyMedium),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (user != null) ...[
              SectionHeader(tr('About your child', 'உங்கள் குழந்தையைப் பற்றி')),
              AphCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: AphSpace.md,
                  vertical: AphSpace.xs,
                ),
                child: Column(
                  children: [
                    _Info(tr('Age', 'வயது'), user.age > 0 ? '${user.age}' : '—'),
                    const Divider(),
                    _Info(tr('Child', 'குழந்தை'), ChildProfile.gender(user.gender)),
                    const Divider(),
                    _Info(tr('Main worry', 'முக்கியக் கவலை'),
                        ChildProfile.concern(user.aphasiaType)),
                    const Divider(),
                    _Info(tr('Speech clarity', 'பேச்சுத் தெளிவு'),
                        ChildProfile.clarity(user.severityLevel)),
                    const Divider(),
                    _Info(
                      tr('Check-up score', 'மதிப்பீட்டு மதிப்பெண்'),
                      user.preAssessmentScore == null
                          ? tr('Not taken yet', 'இன்னும் எடுக்கவில்லை')
                          : '${user.preAssessmentScore!.round()} / 100',
                    ),
                  ],
                ),
              ),
            ],
            const ComfortSettingsSection(),
            const Gap(AphSpace.xl),
            AphButton.secondary(
              label: tr('Sign out', 'வெளியேறு'),
              icon: Icons.logout_rounded,
              onPressed: () async {
                final ok = await confirmDialog(
                  context,
                  title: tr('Sign out?', 'வெளியேறவா?'),
                  message: tr('Your progress stays saved. You will need your phone number and password to sign in again.',
                      'உங்கள் முன்னேற்றம் சேமிக்கப்பட்டிருக்கும்.'),
                  confirm: tr('Sign out', 'வெளியேறு'),
                );
                if (!ok) return;
                await Locator.userDatabaseService.logout();
                if (context.mounted) context.go('/login');
              },
            ),
            const Gap(AphSpace.sm),
            AphButton.ghost(
              label: tr('Delete account and data', 'கணக்கையும் தரவையும் நீக்கு'),
              icon: Icons.delete_forever_rounded,
              onPressed: () async {
                final ok = await confirmDialog(
                  context,
                  title: tr('Delete everything?', 'அனைத்தையும் நீக்கவா?'),
                  message: tr(
                      "This permanently deletes your child's profile, all practice results and the Family Voice recordings on this phone. It cannot be undone.",
                      'குழந்தையின் சுயவிவரம், அனைத்துப் பயிற்சி முடிவுகள், இந்தத் தொலைபேசியில் உள்ள குடும்பக் குரல் பதிவுகள் நிரந்தரமாக நீக்கப்படும். திரும்பப் பெற முடியாது.'),
                  confirm: tr('Delete', 'நீக்கு'),
                );
                if (!ok) return;
                try {
                  await Locator.userDatabaseService.deleteUser();
                  await FamilyVoiceStore.instance.deleteAll();
                  if (context.mounted) context.go('/login');
                } catch (e) {
                  if (context.mounted) {
                    showAphSnack(
                      context,
                      tr('Could not delete. Sign out, sign in again, then try once more.',
                          'நீக்க முடியவில்லை. வெளியேறி மீண்டும் உள்நுழைந்து முயற்சிக்கவும்.'),
                      tone: FeedbackTone.error,
                    );
                  }
                }
              },
            ),
            const Gap(AphSpace.md),
            Text(
              tr('Vernacura · everyday speech practice at home',
                  'வெர்னகுரா · வீட்டிலேயே தினமும் பேச்சுப் பயிற்சி'),
              textAlign: TextAlign.center,
              style: t.bodySmall,
            ),
          ],
        );
      },
    );
  }
}

class _Info extends StatelessWidget {
  const _Info(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AphSpace.sm),
        child: Row(
          children: [
            Expanded(child: Text(label, style: t.bodyMedium)),
            Flexible(
              child: Text(value, style: t.titleMedium, textAlign: TextAlign.end),
            ),
          ],
        ),
      ),
    );
  }
}
