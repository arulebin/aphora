import 'package:flutter/material.dart';

/// Vernacura design tokens.
///
/// Audience: stroke / aphasia survivors (often older, sometimes with
/// one-handed use, low vision or reduced reading ability), their
/// caregivers, and speech therapists. Every value here is chosen for
/// legibility first: all text colours pass WCAG AA (4.5:1) on both
/// [AphColors.background] and [AphColors.surface].
abstract final class AphColors {
  // Brand — a deep, calm clinical teal. 5.5:1 on white.
  static const primary = Color(0xFF0F6E6A);
  static const primaryPressed = Color(0xFF0B5552);
  static const primarySoft = Color(0xFFE3F2EF);
  static const onPrimary = Colors.white;

  // Warm accent used sparingly for encouragement / streaks.
  static const accent = Color(0xFFB4532A); // 5.0:1 on white
  static const accentSoft = Color(0xFFFBEDE5);

  // Surfaces — warm paper rather than clinical blue-white.
  static const background = Color(0xFFF6F5F1);
  static const surface = Colors.white;
  static const surfaceSunken = Color(0xFFEFEDE7);
  static const border = Color(0xFFDDDAD2);
  static const borderStrong = Color(0xFFB9B5AA);

  // Text.
  static const ink = Color(0xFF14232A); // 15:1
  static const inkMuted = Color(0xFF4A5A61); // 7:1
  static const inkSubtle = Color(0xFF66747A); // 4.7:1 — never below this

  // Semantic — always paired with an icon + words, never colour alone.
  static const success = Color(0xFF1E7A3C);
  static const successSoft = Color(0xFFE4F3E8);
  static const warning = Color(0xFF9A5B00);
  static const warningSoft = Color(0xFFFFF1D9);
  static const danger = Color(0xFFB42318);
  static const dangerSoft = Color(0xFFFDE8E6);
  static const info = Color(0xFF1F5FA8);
  static const infoSoft = Color(0xFFE5EEF9);

  // Therapy categories — distinct hues so cards are recognisable at a
  // glance, each with a soft tint for its background.
  static const letters = Color(0xFF6B4FA0);
  static const lettersSoft = Color(0xFFEEE9F7);
  static const words = Color(0xFF0F6E6A);
  static const wordsSoft = Color(0xFFE3F2EF);
  static const sentences = Color(0xFF1F5FA8);
  static const sentencesSoft = Color(0xFFE5EEF9);
  static const naming = Color(0xFFB4532A);
  static const namingSoft = Color(0xFFFBEDE5);
}

/// 4-pt spacing scale. Generous by default (older users, big targets).
abstract final class AphSpace {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;

  /// Horizontal page gutter.
  static const gutter = 20.0;
}

abstract final class AphRadius {
  static const sm = 10.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const pill = 999.0;
}

/// Touch sizes. Material asks 48dp; aphasia users frequently have
/// hemiparesis and use the non-dominant hand, so primary actions are 60dp.
abstract final class AphSize {
  static const minTap = 48.0;
  static const button = 60.0;
  static const micButton = 120.0;
  static const icon = 24.0;
  static const iconLg = 32.0;
  static const maxContentWidth = 560.0;
}

abstract final class AphMotion {
  static const fast = Duration(milliseconds: 150);
  static const base = Duration(milliseconds: 240);
  static const slow = Duration(milliseconds: 360);
  static const curve = Curves.easeOutCubic;

  /// Respect the OS "remove animations" setting.
  static Duration of(BuildContext context, Duration d) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false ? Duration.zero : d;
}

abstract final class AphShadow {
  static const card = [
    BoxShadow(color: Color(0x0F14232A), blurRadius: 2, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x0A14232A), blurRadius: 16, offset: Offset(0, 6)),
  ];
  static const raised = [
    BoxShadow(color: Color(0x1A0F6E6A), blurRadius: 24, offset: Offset(0, 10)),
  ];
}
