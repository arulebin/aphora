import 'package:aphora/logic/language_service.dart';
import 'package:aphora/logic/locator.dart';
import 'package:aphora/ui/design/components.dart';
import 'package:flutter/material.dart';

/// Oral-cancer pack: the person's own details, used to fill phrases such
/// as "My name is {name}" or "Please call {son_phone}". Stored on the user
/// doc as `oralPersonal`; empty fields leave those phrases out.
class MyPhrasesPage extends StatefulWidget {
  const MyPhrasesPage({super.key});

  /// Template key → (English label, Tamil label).
  static const fields = <String, (String, String)>{
    'name': ('Your name', 'உங்கள் பெயர்'),
    'address': ('Your address', 'உங்கள் முகவரி'),
    'phone': ('Your phone number', 'உங்கள் தொலைபேசி எண்'),
    'son_phone': ("A family member's phone number", 'குடும்பத்தினர் ஒருவரின் தொலைபேசி எண்'),
    'place': ('A place you often go', 'நீங்கள் அடிக்கடி போகும் இடம்'),
  };

  @override
  State<MyPhrasesPage> createState() => _MyPhrasesPageState();
}

class _MyPhrasesPageState extends State<MyPhrasesPage> {
  late final Map<String, TextEditingController> _c = {
    for (final k in MyPhrasesPage.fields.keys)
      k: TextEditingController(
          text: Locator.userDatabaseService.currentUser.value?.oralPersonal[k] ?? ''),
  };
  bool _saving = false;

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await Locator.userDatabaseService
          .saveOralPersonal({for (final e in _c.entries) e.key: e.value.text});
      if (mounted) {
        showAphSnack(context, tr('Saved — your phrases now use these details.',
            'சேமிக்கப்பட்டது — உங்கள் சொற்றொடர்கள் இவற்றைப் பயன்படுத்தும்.'),
            tone: FeedbackTone.success);
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) {
        showAphSnack(context, tr('Could not save. Check the internet and try again.',
            'சேமிக்க முடியவில்லை. இணையத்தைச் சரிபார்த்து மீண்டும் முயலுங்கள்.'),
            tone: FeedbackTone.error);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AphScaffold(
      title: tr('My phrases', 'என் சொற்றொடர்கள்'),
      bottom: AphButton(
        label: tr('Save', 'சேமி'),
        icon: Icons.save_rounded,
        loading: _saving,
        onPressed: _save,
      ),
      children: [
        Text(
          tr('Practise the things you need to say about yourself — your name, where you live, who to call. Fill in only what you want; it stays in your account.',
              'உங்களைப் பற்றிச் சொல்ல வேண்டியவற்றைப் பயிற்சி செய்யுங்கள் — பெயர், முகவரி, யாரை அழைக்க வேண்டும். விரும்பியதை மட்டும் நிரப்புங்கள்; இது உங்கள் கணக்கில் மட்டும் இருக்கும்.'),
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const Gap(AphSpace.md),
        for (final e in MyPhrasesPage.fields.entries) ...[
          AphTextField(
            controller: _c[e.key]!,
            label: tr(e.value.$1, e.value.$2),
            keyboardType: e.key.contains('phone') ? TextInputType.phone : null,
            textInputAction: TextInputAction.next,
          ),
          const Gap(AphSpace.sm),
        ],
      ],
    );
  }
}
