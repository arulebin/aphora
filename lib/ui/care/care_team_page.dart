import 'package:aphora/data/models/booking_model.dart';
import 'package:aphora/data/models/therapist_model.dart';
import 'package:aphora/data/models/usermodel.dart';
import 'package:aphora/logic/language_service.dart';
import 'package:aphora/logic/locator.dart';
import 'package:aphora/ui/design/components.dart';
import 'package:aphora/ui/video_call/videocall_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Patient side of the therapist relationship: link by code, book
/// sessions, join the private video room, see booking status.
class CareTeamPage extends StatefulWidget {
  const CareTeamPage({super.key});

  @override
  State<CareTeamPage> createState() => _CareTeamPageState();
}

class _CareTeamPageState extends State<CareTeamPage> {
  final _users = Locator.userDatabaseService;
  final _code = TextEditingController();
  TherapistModel? _therapist;
  String? _loadedFor;
  bool _loading = false;
  bool _linking = false;
  String? _codeError;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _loadTherapist(UserModel user) async {
    _loadedFor = user.linkedCaregiverId;
    if (!user.hasTherapist) {
      setState(() => _therapist = null);
      return;
    }
    setState(() => _loading = true);
    final t = await _users.getTherapistByCode(user.linkedCaregiverId!);
    if (!mounted) return;
    setState(() {
      _therapist = t;
      _loading = false;
    });
  }

  Future<void> _link() async {
    if (_code.text.trim().length != 6) {
      setState(() => _codeError =
          tr('The code has 6 letters or numbers.', 'குறியீட்டில் 6 எழுத்துகள்/எண்கள் உள்ளன.'));
      return;
    }
    setState(() {
      _linking = true;
      _codeError = null;
    });
    try {
      final t = await _users.linkTherapist(_code.text);
      if (!mounted) return;
      if (t == null) {
        setState(() => _codeError = tr(
            'No therapist has this code. Please check it with your therapist.',
            'இந்தக் குறியீட்டுடன் சிகிச்சையாளர் இல்லை.'));
      } else {
        _code.clear();
        showAphSnack(context, tr('Linked with ${t.name}', '${t.name} உடன் இணைக்கப்பட்டது'),
            tone: FeedbackTone.success);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _codeError = tr('Could not link. Check your internet.',
            'இணைக்க முடியவில்லை.'));
      }
    } finally {
      if (mounted) setState(() => _linking = false);
    }
  }

  Future<void> _book(UserModel user) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 60)),
      helpText: tr('Choose a day', 'நாளைத் தேர்ந்தெடுக்கவும்'),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 0),
      helpText: tr('Choose a time', 'நேரத்தைத் தேர்ந்தெடுக்கவும்'),
      initialEntryMode: TimePickerEntryMode.dial,
    );
    if (time == null || !mounted) return;
    final when =
        DateTime(date.year, date.month, date.day, time.hour, time.minute);
    if (when.isBefore(DateTime.now())) {
      showAphSnack(context, tr('Please choose a time in the future.', 'எதிர்கால நேரத்தைத் தேர்ந்தெடுக்கவும்.'),
          tone: FeedbackTone.warning);
      return;
    }
    try {
      await Locator.bookingDatabaseService.createBooking(BookingModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        patientId: user.uid,
        patientName: user.name,
        therapistId: user.linkedCaregiverId!,
        dateTime: when,
      ));
      if (mounted) {
        showAphSnack(
          context,
          tr('Requested ${DateFormat('EEE d MMM, h:mm a', appDateLocale).format(when)}. Your therapist will confirm.',
              '${DateFormat('d MMM, h:mm a', appDateLocale).format(when)} கோரப்பட்டது.'),
          tone: FeedbackTone.success,
        );
      }
    } catch (_) {
      if (mounted) {
        showAphSnack(context, tr('Could not book. Please try again.', 'பதிவு செய்ய முடியவில்லை.'),
            tone: FeedbackTone.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<UserModel?>(
      valueListenable: _users.currentUser,
      builder: (context, user, _) {
        if (user == null) return const Scaffold(body: LoadingState());
        if (_loadedFor != user.linkedCaregiverId) {
          WidgetsBinding.instance
              .addPostFrameCallback((_) => _loadTherapist(user));
        }
        return AphScaffold(
          title: tr('Care team', 'சிகிச்சைக் குழு'),
          showBack: false,
          children: [
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(AphSpace.xl),
                child: LoadingState(),
              )
            else if (!user.hasTherapist || _therapist == null)
              ..._unlinked(context)
            else
              ..._linked(context, user, _therapist!),
          ],
        );
      },
    );
  }

  List<Widget> _unlinked(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return [
      const EmptyState(
        icon: Icons.handshake_rounded,
        title: 'Connect with your therapist',
        message:
            'Your speech therapist can follow your practice, leave notes, and meet you on video.',
      ),
      AphCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AphTextField(
              controller: _code,
              label: tr('Therapist code', 'சிகிச்சையாளர் குறியீடு'),
              hint: 'AB12CD',
              helper: tr('Ask your therapist for their 6-character code.',
                  'உங்கள் சிகிச்சையாளரிடம் 6-எழுத்து குறியீட்டைக் கேளுங்கள்.'),
              icon: Icons.vpn_key_rounded,
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.done,
              inputFormatters: [
                LengthLimitingTextInputFormatter(6),
                FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
                TextInputFormatter.withFunction(
                  (_, v) => v.copyWith(text: v.text.toUpperCase()),
                ),
              ],
              onSubmitted: (_) => _link(),
            ),
            if (_codeError != null) ...[
              const Gap(AphSpace.sm),
              FeedbackBanner(tone: FeedbackTone.error, title: _codeError!),
            ],
            const Gap(AphSpace.md),
            AphButton(
              label: tr('Link therapist', 'இணை'),
              icon: Icons.link_rounded,
              loading: _linking,
              onPressed: _link,
            ),
          ],
        ),
      ),
      const Gap(AphSpace.md),
      Text(
        tr('Practising without a therapist is fine too — everything in the app works on its own.',
            'சிகிச்சையாளர் இல்லாமலும் பயிற்சி செய்யலாம்.'),
        style: t.bodyMedium,
        textAlign: TextAlign.center,
      ),
    ];
  }

  List<Widget> _linked(BuildContext context, UserModel user, TherapistModel th) {
    final t = Theme.of(context).textTheme;
    return [
      AphCard(
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: AphColors.primarySoft,
                  child: Text(
                    th.name.isEmpty ? '?' : th.name.characters.first.toUpperCase(),
                    style: t.headlineSmall?.copyWith(color: AphColors.primary),
                  ),
                ),
                const Gap(AphSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(th.name, style: t.titleLarge),
                      Text(tr('Speech & language therapist', 'பேச்சு சிகிச்சையாளர்'),
                          style: t.bodyMedium),
                    ],
                  ),
                ),
              ],
            ),
            const Gap(AphSpace.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: LabeledIconAction(
                    icon: Icons.videocam_rounded,
                    label: tr('Video call', 'வீடியோ அழைப்பு'),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => VideoCallPage(
                          channelName: 'aphora_${th.code}_${user.uid}',
                          peerName: th.name,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: LabeledIconAction(
                    icon: Icons.event_rounded,
                    label: tr('Book session', 'அமர்வு பதிவு'),
                    onTap: () => _book(user),
                  ),
                ),
                if (th.phone.isNotEmpty)
                  Expanded(
                    child: LabeledIconAction(
                      icon: Icons.copy_rounded,
                      label: tr('Copy phone', 'எண்ணை நகலெடு'),
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: th.phone));
                        showAphSnack(context, tr('Phone number copied', 'எண் நகலெடுக்கப்பட்டது'));
                      },
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
      if ((user.therapistNote ?? '').isNotEmpty) ...[
        const Gap(AphSpace.md),
        FeedbackBanner(
          tone: FeedbackTone.info,
          title: tr('Note from ${th.name}', '${th.name} குறிப்பு'),
          message: user.therapistNote,
        ),
      ],
      SectionHeader(tr('Sessions', 'அமர்வுகள்')),
      StreamBuilder<List<BookingModel>>(
        stream: Locator.bookingDatabaseService.getBookingsForPatient(user.uid),
        builder: (context, snap) {
          if (snap.hasError) {
            return ErrorState(onRetry: () => setState(() {}));
          }
          if (!snap.hasData) {
            return const Padding(
              padding: EdgeInsets.all(AphSpace.lg),
              child: LoadingState(),
            );
          }
          final upcoming = snap.data!
              .where((b) => b.isUpcoming && b.status != 'cancelled')
              .toList();
          if (upcoming.isEmpty) {
            return EmptyState(
              icon: Icons.event_available_rounded,
              title: tr('No upcoming sessions', 'வரவிருக்கும் அமர்வுகள் இல்லை'),
              action: AphButton.secondary(
                label: tr('Book a session', 'அமர்வைப் பதிவு செய்'),
                icon: Icons.add_rounded,
                expand: false,
                onPressed: () => _book(user),
              ),
            );
          }
          return Column(
            children: [
              for (final b in upcoming)
                Padding(
                  padding: const EdgeInsets.only(bottom: AphSpace.sm),
                  child: BookingTile(
                    booking: b,
                    title: DateFormat('EEEE d MMMM', appDateLocale).format(b.dateTime),
                    onCancel: () async {
                      final ok = await confirmDialog(
                        context,
                        title: tr('Cancel this session?', 'இந்த அமர்வை ரத்து செய்யவா?'),
                        message: DateFormat('EEE d MMM, h:mm a', appDateLocale).format(b.dateTime),
                        confirm: tr('Cancel session', 'ரத்து செய்'),
                        cancel: tr('Keep', 'வைத்திரு'),
                        destructive: true,
                      );
                      if (ok) {
                        await Locator.bookingDatabaseService
                            .setStatus(b.id, 'cancelled');
                      }
                    },
                  ),
                ),
            ],
          );
        },
      ),
      const Gap(AphSpace.lg),
      Center(
        child: AphButton.ghost(
          label: tr('Unlink therapist', 'இணைப்பை நீக்கு'),
          icon: Icons.link_off_rounded,
          onPressed: () async {
            final ok = await confirmDialog(
              context,
              title: tr('Unlink ${th.name}?', '${th.name} இணைப்பை நீக்கவா?'),
              message: tr('They will no longer see your progress.',
                  'அவர்கள் இனி உங்கள் முன்னேற்றத்தைப் பார்க்க மாட்டார்கள்.'),
              confirm: tr('Unlink', 'நீக்கு'),
              destructive: true,
            );
            if (ok) await _users.unlinkTherapist();
          },
        ),
      ),
    ];
  }
}

/// Shared booking row for patient and therapist views.
class BookingTile extends StatelessWidget {
  const BookingTile({
    super.key,
    required this.booking,
    required this.title,
    this.onCancel,
    this.actions,
  });

  final BookingModel booking;
  final String title;
  final VoidCallback? onCancel;
  final List<Widget>? actions;

  static (String, Color, Color, IconData) statusStyle(String s) => switch (s) {
        'confirmed' => ('Confirmed', AphColors.success, AphColors.successSoft, Icons.check_circle_rounded),
        'declined' => ('Declined', AphColors.danger, AphColors.dangerSoft, Icons.cancel_rounded),
        'cancelled' => ('Cancelled', AphColors.inkMuted, AphColors.surfaceSunken, Icons.block_rounded),
        'completed' => ('Completed', AphColors.info, AphColors.infoSoft, Icons.task_alt_rounded),
        _ => ('Waiting for confirmation', AphColors.warning, AphColors.warningSoft, Icons.schedule_rounded),
      };

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final (label, color, soft, icon) = statusStyle(booking.status);
    return AphCard(
      padding: const EdgeInsets.all(AphSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AphColors.primarySoft,
                  borderRadius: BorderRadius.circular(AphRadius.md),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(DateFormat('d', appDateLocale).format(booking.dateTime),
                        style: t.titleLarge?.copyWith(color: AphColors.primary, height: 1)),
                    Text(DateFormat('MMM', appDateLocale).format(booking.dateTime),
                        style: t.labelSmall?.copyWith(color: AphColors.primary)),
                  ],
                ),
              ),
              const Gap(AphSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: t.titleMedium),
                    Text(DateFormat('h:mm a', appDateLocale).format(booking.dateTime),
                        style: t.bodyMedium),
                    const Gap(AphSpace.xxs),
                    StatusPill(label: label, color: color, soft: soft, icon: icon),
                  ],
                ),
              ),
            ],
          ),
          if (actions != null || onCancel != null) ...[
            const Gap(AphSpace.sm),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: AphSpace.xs,
              children: [
                ...?actions,
                if (onCancel != null)
                  AphButton.ghost(
                    label: 'Cancel',
                    icon: Icons.close_rounded,
                    onPressed: onCancel,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
