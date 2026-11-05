import 'package:aphora/logic/comfort_settings.dart';
import 'package:aphora/logic/language_service.dart';
import 'package:aphora/ui/design/components.dart';
import 'package:flutter/material.dart';

/// Vernacura mark: a speech bubble holding a V-shaped sound wave, on the
/// brand gradient. Uses the same artwork as the launcher icon.
class AphoraMark extends StatelessWidget {
  const AphoraMark({super.key, this.size = 72});
  final double size;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AphColors.primary, Color(0xFF128C86)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(size * 0.3),
          boxShadow: AphShadow.raised,
        ),
        // Same artwork as the launcher icon: speech bubble with a V-shaped
        // waveform (assets/icon/make_icons.py).
        padding: EdgeInsets.fromLTRB(size * 0.2, size * 0.2, size * 0.2, size * 0.17),
        child: Image.asset('assets/icon/mark.png', fit: BoxFit.contain),
      ),
    );
  }
}

/// Shared layout for sign-in screens: brand header, form card, footer.
class AuthShell extends StatelessWidget {
  const AuthShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
    this.footer,
    this.showBack = false,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;
  final List<Widget>? footer;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return AphScaffold(
      showBack: showBack,
      actions: const [LanguageToggle()],
      children: [
        const Gap(AphSpace.md),
        const Center(child: AphoraMark()),
        const Gap(AphSpace.lg),
        Semantics(
          header: true,
          child: Text(title, style: t.headlineLarge, textAlign: TextAlign.center),
        ),
        const Gap(AphSpace.xs),
        Text(subtitle, style: t.bodyLarge, textAlign: TextAlign.center),
        const Gap(AphSpace.lg),
        AphCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
        if (footer != null) ...[
          const Gap(AphSpace.md),
          ...footer!,
        ],
      ],
    );
  }
}

/// Compact தமிழ் / English switch for the app bar.
class LanguageToggle extends StatelessWidget {
  const LanguageToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = ComfortSettings.instance.language;
    return ValueListenableBuilder(
      valueListenable: lang,
      builder: (context, value, _) {
        final ta = value == Language.tamil;
        return TextButton.icon(
          onPressed: () =>
              lang.value = ta ? Language.english : Language.tamil,
          icon: const Icon(Icons.translate_rounded),
          label: Text(ta ? 'English' : 'தமிழ்'),
        );
      },
    );
  }
}

String? validatePhone(String? v) {
  final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
  if (digits.length != 10) {
    return tr('Enter your 10-digit mobile number.', '10 இலக்க மொபைல் எண்ணை உள்ளிடவும்.');
  }
  return null;
}

String? validatePassword(String? v) {
  if ((v ?? '').length < 6) {
    return tr('Use at least 6 characters.', 'குறைந்தது 6 எழுத்துகள் தேவை.');
  }
  return null;
}

String normalisePhone(String v) => v.replaceAll(RegExp(r'\D'), '');
