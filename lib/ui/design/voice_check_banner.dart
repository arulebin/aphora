import 'package:aphora/logic/language_service.dart';
import 'package:aphora/logic/speech_service.dart';
import 'package:aphora/ui/design/components.dart';
import 'package:flutter/material.dart';

/// Warns a parent when the phone is missing the Tamil voice or Tamil speech
/// recognition, and opens the voice download screen. Shows nothing when the
/// app is in English or everything is installed. Re-checks when the user
/// comes back to the app (e.g. after installing the voice).
class VoiceCheckBanner extends StatefulWidget {
  const VoiceCheckBanner({super.key});

  @override
  State<VoiceCheckBanner> createState() => _VoiceCheckBannerState();
}

class _VoiceCheckBannerState extends State<VoiceCheckBanner>
    with WidgetsBindingObserver {
  VoiceSupport _support = VoiceSupport.ok;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _check();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _check();
  }

  Future<void> _check() async {
    if (LanguageService.currentLanguage != Language.tamil) {
      if (mounted) setState(() => _support = VoiceSupport.ok);
      return;
    }
    final support = await SpeechService.shared.checkVoiceSupport('ta-IN');
    if (mounted) setState(() => _support = support);
  }

  @override
  Widget build(BuildContext context) {
    if (_support.allGood) return const SizedBox.shrink();
    final speak = !_support.canSpeak;
    return Padding(
      padding: const EdgeInsets.only(bottom: AphSpace.md),
      child: FeedbackBanner(
        tone: FeedbackTone.warning,
        title: speak
            ? tr('Tamil voice is not installed', 'தமிழ் குரல் நிறுவப்படவில்லை')
            : tr('Tamil speech recognition is missing',
                'தமிழ் பேச்சு அறிதல் இல்லை'),
        message: speak
            ? tr(
                'Words may be read in English or not at all. Tap below, choose Tamil and download it, then come back.',
                'சொற்கள் ஆங்கிலத்தில் படிக்கப்படலாம் அல்லது கேட்காமல் போகலாம். கீழே தட்டி, தமிழைத் தேர்ந்தெடுத்து பதிவிறக்குங்கள், பிறகு திரும்பி வாருங்கள்.')
            : tr(
                'The phone may not understand Tamil answers. Add Tamil under speech languages in Google settings, or type answers instead.',
                'தொலைபேசி தமிழ் பதில்களைப் புரிந்துகொள்ளாமல் போகலாம். Google அமைப்புகளில் பேச்சு மொழிகளில் தமிழைச் சேர்க்கவும், அல்லது பதிலைத் தட்டச்சு செய்யவும்.'),
        action: speak
            ? AphButton.secondary(
                label: tr('Install Tamil voice', 'தமிழ் குரலை நிறுவு'),
                icon: Icons.download_rounded,
                expand: false,
                onPressed: () => SpeechService.shared.openVoiceInstaller(),
              )
            : null,
      ),
    );
  }
}
