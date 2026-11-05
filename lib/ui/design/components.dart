import 'dart:math' as math;

import 'package:aphora/logic/comfort_settings.dart';
import 'package:aphora/logic/speech_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'tokens.dart';

export 'tokens.dart';

// ─────────────────────────────────────────────────────────────────────────
//  Layout
// ─────────────────────────────────────────────────────────────────────────

/// Standard page: safe areas, centred max-width column, consistent gutter.
/// Use [slivers]-free [children] for simple scrolling pages.
class AphScaffold extends StatelessWidget {
  const AphScaffold({
    super.key,
    this.title,
    this.actions,
    this.leading,
    this.showBack = true,
    this.children,
    this.body,
    this.bottom,
    this.padding,
    this.onRefresh,
    this.backgroundColor,
  }) : assert(children != null || body != null);

  final String? title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBack;
  final List<Widget>? children;
  final Widget? body;

  /// Sticky bottom area (primary action bar). Kept above the gesture bar.
  final Widget? bottom;
  final EdgeInsets? padding;
  final Future<void> Function()? onRefresh;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    Widget content = body ??
        ListView(
          padding: padding ??
              const EdgeInsets.fromLTRB(
                AphSpace.gutter,
                AphSpace.xs,
                AphSpace.gutter,
                AphSpace.xxl,
              ),
          children: children!,
        );
    if (onRefresh != null) {
      content = RefreshIndicator(onRefresh: onRefresh!, child: content);
    }
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: title == null && actions == null && leading == null
          ? null
          : AppBar(
              automaticallyImplyLeading: showBack,
              leading: leading,
              title: title == null
                  ? null
                  : Semantics(header: true, child: Text(title!)),
              actions: [...?actions, const SizedBox(width: AphSpace.xxs)],
            ),
      body: SafeArea(
        bottom: bottom == null,
        child: Center(
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: AphSize.maxContentWidth),
            child: content,
          ),
        ),
      ),
      bottomNavigationBar: bottom == null
          ? null
          : SafeArea(
              top: false,
              child: Center(
                heightFactor: 1,
                child: ConstrainedBox(
                  constraints:
                      const BoxConstraints(maxWidth: AphSize.maxContentWidth),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AphSpace.gutter,
                      AphSpace.sm,
                      AphSpace.gutter,
                      AphSpace.md,
                    ),
                    child: bottom,
                  ),
                ),
              ),
            ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.subtitle, this.trailing});

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: AphSpace.lg, bottom: AphSpace.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(title, style: t.titleLarge),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: AphSpace.xxs),
                  Text(subtitle!, style: t.bodyMedium),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class Gap extends StatelessWidget {
  const Gap(this.size, {super.key});
  final double size;
  @override
  Widget build(BuildContext context) => SizedBox(width: size, height: size);
}

// ─────────────────────────────────────────────────────────────────────────
//  Buttons
// ─────────────────────────────────────────────────────────────────────────

enum AphButtonVariant { primary, secondary, ghost, danger }

class AphButton extends StatelessWidget {
  const AphButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = AphButtonVariant.primary,
    this.loading = false,
    this.expand = true,
    this.semanticHint,
  });

  const AphButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.expand = true,
    this.semanticHint,
  }) : variant = AphButtonVariant.secondary;

  const AphButton.ghost({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.expand = false,
    this.semanticHint,
  }) : variant = AphButtonVariant.ghost;

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AphButtonVariant variant;
  final bool loading;
  final bool expand;
  final String? semanticHint;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    final callback = enabled
        ? () {
            HapticFeedback.selectionClick();
            onPressed!();
          }
        : null;

    final fg = switch (variant) {
      AphButtonVariant.primary => AphColors.onPrimary,
      AphButtonVariant.danger => Colors.white,
      AphButtonVariant.secondary => AphColors.ink,
      AphButtonVariant.ghost => AphColors.primary,
    };

    final child = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading)
          SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: fg),
          )
        else if (icon != null)
          Icon(icon, size: 24),
        if (loading || icon != null) const SizedBox(width: AphSpace.sm),
        Flexible(
          child: Text(
            loading ? 'Please wait…' : label,
            textAlign: TextAlign.center,
            overflow: TextOverflow.visible,
          ),
        ),
      ],
    );

    final Widget button = switch (variant) {
      AphButtonVariant.primary => FilledButton(
          onPressed: callback,
          child: child,
        ),
      AphButtonVariant.danger => FilledButton(
          onPressed: callback,
          style: FilledButton.styleFrom(backgroundColor: AphColors.danger),
          child: child,
        ),
      AphButtonVariant.secondary => OutlinedButton(
          onPressed: callback,
          style: OutlinedButton.styleFrom(
            backgroundColor: AphColors.surface,
          ),
          child: child,
        ),
      AphButtonVariant.ghost => TextButton(onPressed: callback, child: child),
    };

    return Semantics(
      button: true,
      enabled: enabled,
      hint: semanticHint,
      excludeSemantics: false,
      child: expand ? SizedBox(width: double.infinity, child: button) : button,
    );
  }
}

/// Labelled round icon action (e.g. “Video call”). Always shows text —
/// icon-only buttons are hard for people with language impairment.
class LabeledIconAction extends StatelessWidget {
  const LabeledIconAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = AphColors.primary,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AphRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AphSpace.xs,
            horizontal: AphSpace.xxs,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: AphSpace.xs),
              Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
//  Cards
// ─────────────────────────────────────────────────────────────────────────

class AphCard extends StatelessWidget {
  const AphCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AphSpace.lg - 4),
    this.color = AphColors.surface,
    this.borderColor = AphColors.border,
    this.onTap,
    this.semanticLabel,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color color;
  final Color borderColor;
  final VoidCallback? onTap;

  /// When set, the card is announced as one button with this label.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AphRadius.lg);
    final body = Padding(padding: padding, child: child);
    final hc = ComfortSettings.instance.highContrast.value;
    Widget card = DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: radius,
        border: Border.all(
          color: hc ? AphColors.ink : borderColor,
          width: hc ? 1.5 : 1,
        ),
        boxShadow: color == AphColors.surface ? AphShadow.card : null,
      ),
      child: onTap == null
          ? body
          : Material(
              type: MaterialType.transparency,
              child: InkWell(
                borderRadius: radius,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onTap!();
                },
                child: ConstrainedBox(
                  constraints:
                      const BoxConstraints(minHeight: AphSize.minTap),
                  child: body,
                ),
              ),
            ),
    );
    if (onTap != null || semanticLabel != null) {
      card = Semantics(
        button: onTap != null,
        label: semanticLabel,
        excludeSemantics: semanticLabel != null,
        child: card,
      );
    }
    return card;
  }
}

/// A list-style navigation card: tinted icon, title, description, chevron.
class ActionTile extends StatelessWidget {
  const ActionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.color = AphColors.primary,
    this.softColor = AphColors.primarySoft,
    this.badge,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Color color;
  final Color softColor;
  final String? badge;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return AphCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AphSpace.md),
      semanticLabel: [title, ?subtitle, ?badge].join('. '),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: softColor,
              borderRadius: BorderRadius.circular(AphRadius.md),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: AphSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: t.titleMedium),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: t.bodyMedium),
                ],
                if (badge != null) ...[
                  const SizedBox(height: AphSpace.xs),
                  StatusPill(label: badge!, color: color, soft: softColor),
                ],
              ],
            ),
          ),
          const SizedBox(width: AphSpace.xs),
          trailing ??
              (onTap == null
                  ? const SizedBox.shrink()
                  : const Icon(
                      Icons.chevron_right_rounded,
                      color: AphColors.inkSubtle,
                      size: 28,
                    )),
        ],
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    this.color = AphColors.primary,
    this.soft = AphColors.primarySoft,
    this.icon,
  });

  final String label;
  final Color color;
  final Color soft;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: soft,
        borderRadius: BorderRadius.circular(AphRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

/// Big number with a label underneath.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
    this.color = AphColors.primary,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return AphCard(
      padding: const EdgeInsets.all(AphSpace.md),
      semanticLabel: '$label: $value',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: AphSpace.sm),
          Text(
            value,
            style: t.headlineMedium?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: t.bodySmall),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
//  Feedback & states
// ─────────────────────────────────────────────────────────────────────────

enum FeedbackTone { success, warning, error, info }

class FeedbackBanner extends StatelessWidget {
  const FeedbackBanner({
    super.key,
    required this.tone,
    required this.title,
    this.message,
    this.action,
  });

  final FeedbackTone tone;
  final String title;
  final String? message;
  final Widget? action;

  static (Color, Color, IconData) styleOf(FeedbackTone tone) => switch (tone) {
        FeedbackTone.success => (
            AphColors.success,
            AphColors.successSoft,
            Icons.check_circle_rounded,
          ),
        FeedbackTone.warning => (
            AphColors.warning,
            AphColors.warningSoft,
            Icons.lightbulb_rounded,
          ),
        FeedbackTone.error => (
            AphColors.danger,
            AphColors.dangerSoft,
            Icons.error_rounded,
          ),
        FeedbackTone.info => (
            AphColors.info,
            AphColors.infoSoft,
            Icons.info_rounded,
          ),
      };

  @override
  Widget build(BuildContext context) {
    final (fg, bg, icon) = styleOf(tone);
    final t = Theme.of(context).textTheme;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(AphSpace.md),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AphRadius.md),
          border: Border.all(color: fg.withValues(alpha: 0.35)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: fg, size: 28),
            const SizedBox(width: AphSpace.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: t.titleMedium?.copyWith(color: fg)),
                  if (message != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      message!,
                      style: t.bodyMedium?.copyWith(color: AphColors.ink),
                    ),
                  ],
                  if (action != null) ...[
                    const SizedBox(height: AphSpace.xs),
                    action!,
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AphSpace.xl,
        horizontal: AphSpace.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: const BoxDecoration(
              color: AphColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 40, color: AphColors.primary),
          ),
          const SizedBox(height: AphSpace.md),
          Text(title, style: t.titleLarge, textAlign: TextAlign.center),
          if (message != null) ...[
            const SizedBox(height: AphSpace.xs),
            Text(message!, style: t.bodyMedium, textAlign: TextAlign.center),
          ],
          if (action != null) ...[
            const SizedBox(height: AphSpace.lg),
            action!,
          ],
        ],
      ),
    );
  }
}

class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    this.title = 'Something went wrong',
    this.message = 'Please check your internet connection and try again.',
    required this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.cloud_off_rounded,
      title: title,
      message: message,
      action: AphButton.secondary(
        label: 'Try again',
        icon: Icons.refresh_rounded,
        onPressed: onRetry,
        expand: false,
      ),
    );
  }
}

class LoadingState extends StatelessWidget {
  const LoadingState({super.key, this.label = 'Loading…'});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        label: label,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: AphSpace.md),
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
//  Forms
// ─────────────────────────────────────────────────────────────────────────

class AphTextField extends StatefulWidget {
  const AphTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.helper,
    this.icon,
    this.keyboardType,
    this.obscure = false,
    this.validator,
    this.textInputAction = TextInputAction.next,
    this.autofillHints,
    this.inputFormatters,
    this.onSubmitted,
    this.textCapitalization = TextCapitalization.none,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? helper;
  final IconData? icon;
  final TextInputType? keyboardType;
  final bool obscure;
  final String? Function(String?)? validator;
  final TextInputAction textInputAction;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onSubmitted;
  final TextCapitalization textCapitalization;
  final int maxLines;

  @override
  State<AphTextField> createState() => _AphTextFieldState();
}

class _AphTextFieldState extends State<AphTextField> {
  late bool _hidden = widget.obscure;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Visible label above the field (never placeholder-only).
        Padding(
          padding: const EdgeInsets.only(bottom: AphSpace.xs, left: 2),
          child: Text(widget.label, style: t.titleSmall),
        ),
        TextFormField(
          controller: widget.controller,
          keyboardType: widget.keyboardType,
          obscureText: _hidden,
          validator: widget.validator,
          autovalidateMode: AutovalidateMode.onUnfocus,
          textInputAction: widget.textInputAction,
          autofillHints: widget.autofillHints,
          inputFormatters: widget.inputFormatters,
          onFieldSubmitted: widget.onSubmitted,
          textCapitalization: widget.textCapitalization,
          maxLines: widget.obscure ? 1 : widget.maxLines,
          style: t.bodyLarge,
          decoration: InputDecoration(
            hintText: widget.hint,
            helperText: widget.helper,
            helperMaxLines: 3,
            errorMaxLines: 3,
            prefixIcon: widget.icon == null
                ? null
                : Icon(widget.icon, color: AphColors.inkMuted),
            suffixIcon: widget.obscure
                ? IconButton(
                    tooltip: _hidden ? 'Show password' : 'Hide password',
                    icon: Icon(
                      _hidden
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
                    ),
                    onPressed: () => setState(() => _hidden = !_hidden),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}

/// Large, tappable single-choice chips (gender, severity, role…).
class ChoiceGroup<T> extends StatelessWidget {
  const ChoiceGroup({
    super.key,
    required this.label,
    required this.options,
    required this.value,
    required this.onChanged,
    this.helper,
  });

  final String label;
  final String? helper;
  final List<(T, String, IconData?)> options;
  final T? value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(header: true, child: Text(label, style: t.titleSmall)),
        if (helper != null) ...[
          const SizedBox(height: 2),
          Text(helper!, style: t.bodySmall),
        ],
        const SizedBox(height: AphSpace.xs),
        Wrap(
          spacing: AphSpace.xs,
          runSpacing: AphSpace.xs,
          children: [
            for (final (v, text, icon) in options)
              _ChoiceChip(
                label: text,
                icon: icon,
                selected: v == value,
                onTap: () => onChanged(v),
              ),
          ],
        ),
      ],
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Semantics(
      selected: selected,
      button: true,
      inMutuallyExclusiveGroup: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: selected ? AphColors.primarySoft : AphColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AphRadius.md),
          side: BorderSide(
            color: selected ? AphColors.primary : AphColors.borderStrong,
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AphRadius.md),
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 52, minWidth: 64),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AphSpace.md,
                vertical: AphSpace.sm,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : (icon ?? Icons.circle_outlined),
                    size: 22,
                    color: selected ? AphColors.primary : AphColors.inkMuted,
                  ),
                  const SizedBox(width: AphSpace.xs),
                  // Flexible: long answers ("Started talking late", or
                  // Tamil at large text) wrap inside the chip instead of
                  // overflowing the screen.
                  Flexible(
                    child: Text(
                      label,
                      style: t.labelLarge?.copyWith(
                        color: selected ? AphColors.primaryPressed : AphColors.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
//  Speech-specific
// ─────────────────────────────────────────────────────────────────────────

/// Reads [text] aloud with the device TTS. Shown next to every instruction
/// so people who struggle to read (alexia often co-occurs with aphasia)
/// can still use the app.
class ReadAloudButton extends StatefulWidget {
  const ReadAloudButton({
    super.key,
    required this.text,
    this.language,
    this.label = 'Listen',
    this.compact = false,
    this.autoPlay = false,
  });

  final String text;

  /// BCP-47 code, e.g. 'ta-IN'. Defaults to the app language.
  final String? language;
  final String label;
  final bool compact;

  /// Speak once when first shown, if the user enabled auto read-aloud.
  final bool autoPlay;

  @override
  State<ReadAloudButton> createState() => _ReadAloudButtonState();
}

class _ReadAloudButtonState extends State<ReadAloudButton> {
  bool _speaking = false;

  @override
  void initState() {
    super.initState();
    if (widget.autoPlay && ComfortSettings.instance.autoReadAloud.value) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _speak());
    }
  }

  @override
  void didUpdateWidget(covariant ReadAloudButton old) {
    super.didUpdateWidget(old);
    if (widget.autoPlay &&
        old.text != widget.text &&
        ComfortSettings.instance.autoReadAloud.value) {
      _speak();
    }
  }

  Future<void> _speak() async {
    if (!mounted) return;
    setState(() => _speaking = true);
    await SpeechService.shared.speakText(
      widget.text,
      language: widget.language ?? SpeechService.appLanguageCode,
    );
    // TTS completion isn't reliably reported on all engines; reset after an
    // estimate so the button never looks stuck.
    final ms = (600 + widget.text.characters.length * 90).clamp(900, 7000);
    await Future<void>.delayed(Duration(milliseconds: ms));
    if (mounted) setState(() => _speaking = false);
  }

  @override
  Widget build(BuildContext context) {
    final icon = _speaking ? Icons.graphic_eq_rounded : Icons.volume_up_rounded;
    if (widget.compact) {
      return IconButton.filledTonal(
        tooltip: '${widget.label}: ${widget.text}',
        onPressed: _speak,
        style: IconButton.styleFrom(
          backgroundColor: AphColors.primarySoft,
          foregroundColor: AphColors.primary,
          minimumSize: const Size(52, 52),
        ),
        icon: Icon(icon, size: 26),
      );
    }
    return Semantics(
      button: true,
      label: '${widget.label}. Reads the text aloud.',
      excludeSemantics: true,
      child: OutlinedButton.icon(
        onPressed: _speak,
        icon: Icon(icon, color: AphColors.primary),
        label: Text(widget.label),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 52),
          foregroundColor: AphColors.primary,
          side: const BorderSide(color: AphColors.primary, width: 1.5),
          backgroundColor: AphColors.surface,
        ),
      ),
    );
  }
}

enum MicState { idle, listening, processing }

/// 120dp microphone button. Pulses while listening (unless the user asked
/// for reduced motion), and always states what is happening in words.
class MicButton extends StatefulWidget {
  const MicButton({
    super.key,
    required this.state,
    required this.onPressed,
    this.idleLabel = 'Tap and speak',
    this.listeningLabel = 'Listening… tap to stop',
    this.processingLabel = 'Checking…',
  });

  final MicState state;
  final VoidCallback? onPressed;
  final String idleLabel;
  final String listeningLabel;
  final String processingLabel;

  @override
  State<MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends State<MicButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void didUpdateWidget(covariant MicButton old) {
    super.didUpdateWidget(old);
    _sync();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  void _sync() {
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (widget.state == MicState.listening && !reduce) {
      if (!_pulse.isAnimating) _pulse.repeat();
    } else {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final listening = widget.state == MicState.listening;
    final processing = widget.state == MicState.processing;
    final color = listening ? AphColors.danger : AphColors.primary;
    final label = switch (widget.state) {
      MicState.idle => widget.idleLabel,
      MicState.listening => widget.listeningLabel,
      MicState.processing => widget.processingLabel,
    };
    // The round button and its caption ("Tap and speak") do the same thing:
    // children and parents tap the words as often as the circle.
    final VoidCallback? onTap = widget.onPressed == null
        ? null
        : () {
            HapticFeedback.mediumImpact();
            widget.onPressed!();
          };

    return Semantics(
      button: true,
      enabled: widget.onPressed != null,
      label: label,
      liveRegion: true,
      excludeSemantics: true,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: AphSize.micButton + 48,
            height: AphSize.micButton + 48,
            child: AnimatedBuilder(
              animation: _pulse,
              builder: (context, child) {
                return CustomPaint(
                  painter: _PulsePainter(
                    progress: _pulse.value,
                    color: color,
                    active: listening,
                  ),
                  child: child,
                );
              },
              child: Center(
                child: Material(
                  color: widget.onPressed == null && !listening
                      ? AphColors.surfaceSunken
                      : color,
                  shape: const CircleBorder(),
                  elevation: 0,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onTap,
                    child: SizedBox(
                      width: AphSize.micButton,
                      height: AphSize.micButton,
                      child: Center(
                        child: processing
                            ? const SizedBox(
                                width: 40,
                                height: 40,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 3.5,
                                ),
                              )
                            : Icon(
                                listening
                                    ? Icons.stop_rounded
                                    : Icons.mic_rounded,
                                size: 56,
                                color: widget.onPressed == null
                                    ? AphColors.inkSubtle
                                    : Colors.white,
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(AphRadius.md),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AphSpace.md,
                vertical: AphSpace.xs,
              ),
              child: Text(
                label,
                style: t.titleMedium?.copyWith(
                  color: listening ? AphColors.danger : AphColors.ink,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PulsePainter extends CustomPainter {
  _PulsePainter({
    required this.progress,
    required this.color,
    required this.active,
  });

  final double progress;
  final Color color;
  final bool active;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final base = AphSize.micButton / 2;
    if (!active) {
      canvas.drawCircle(
        c,
        base + 10,
        Paint()..color = color.withValues(alpha: 0.10),
      );
      return;
    }
    for (final offset in [0.0, 0.5]) {
      final p = (progress + offset) % 1.0;
      canvas.drawCircle(
        c,
        base + 24 * p,
        Paint()..color = color.withValues(alpha: 0.22 * (1 - p)),
      );
    }
  }

  @override
  bool shouldRepaint(_PulsePainter old) =>
      old.progress != progress || old.active != active || old.color != color;
}

// ─────────────────────────────────────────────────────────────────────────
//  Scores & progress
// ─────────────────────────────────────────────────────────────────────────

/// Supportive wording for a 0–100 score. Patients see words first, numbers
/// second — a raw “43%” after a stroke is discouraging; “Getting there”
/// is accurate and kind.
class ScoreBand {
  const ScoreBand(this.label, this.color, this.soft, this.icon);
  final String label;
  final Color color;
  final Color soft;
  final IconData icon;

  static ScoreBand of(double score) {
    if (score >= 85) {
      return const ScoreBand(
        'Excellent',
        AphColors.success,
        AphColors.successSoft,
        Icons.verified_rounded,
      );
    }
    if (score >= 70) {
      return const ScoreBand(
        'Good',
        AphColors.success,
        AphColors.successSoft,
        Icons.check_circle_rounded,
      );
    }
    if (score >= 45) {
      return const ScoreBand(
        'Getting there',
        AphColors.warning,
        AphColors.warningSoft,
        Icons.trending_up_rounded,
      );
    }
    return const ScoreBand(
      'Keep practising',
      AphColors.info,
      AphColors.infoSoft,
      Icons.replay_rounded,
    );
  }
}

class ScoreRing extends StatelessWidget {
  const ScoreRing({super.key, required this.score, this.size = 132});

  /// 0–100.
  final double score;
  final double size;

  @override
  Widget build(BuildContext context) {
    final band = ScoreBand.of(score);
    final t = Theme.of(context).textTheme;
    return Semantics(
      label: 'Score ${score.round()} out of 100. ${band.label}.',
      excludeSemantics: true,
      child: SizedBox(
        width: size,
        height: size,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: score.clamp(0, 100) / 100),
          duration: AphMotion.of(context, AphMotion.slow * 2),
          curve: AphMotion.curve,
          builder: (context, v, _) => CustomPaint(
            painter: _RingPainter(v, band.color),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${(v * 100).round()}',
                    style: t.displaySmall?.copyWith(
                      color: AphColors.ink,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  Text('out of 100', style: t.labelSmall),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.value, this.color);
  final double value;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 12.0;
    final rect = (Offset.zero & size).deflate(stroke / 2);
    canvas.drawArc(
      rect,
      0,
      math.pi * 2,
      false,
      Paint()
        ..color = AphColors.surfaceSunken
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * value,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = stroke,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value || old.color != color;
}

/// Compact score: icon + words + number. Never colour alone.
class ScoreBadge extends StatelessWidget {
  const ScoreBadge({super.key, required this.score});
  final double score;

  @override
  Widget build(BuildContext context) {
    final band = ScoreBand.of(score);
    return StatusPill(
      label: '${band.label} · ${score.round()}',
      color: band.color,
      soft: band.soft,
      icon: band.icon,
    );
  }
}

/// “Step 3 of 10” + a bar. Announced to screen readers.
class StepProgress extends StatelessWidget {
  const StepProgress({super.key, required this.current, required this.total});

  /// 1-based.
  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final v = total == 0 ? 0.0 : current / total;
    return Semantics(
      label: 'Step $current of $total',
      excludeSemantics: true,
      child: Row(
        children: [
          Text('$current of $total', style: t.labelMedium),
          const SizedBox(width: AphSpace.sm),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AphRadius.pill),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: v),
                duration: AphMotion.of(context, AphMotion.base),
                builder: (_, value, _) => LinearProgressIndicator(
                  value: value,
                  minHeight: 10,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Labelled horizontal meter with the number shown in text.
class MeterRow extends StatelessWidget {
  const MeterRow({
    super.key,
    required this.label,
    required this.value,
    this.color = AphColors.primary,
  });

  final String label;

  /// 0–100.
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Semantics(
      label: '$label ${value.round()} percent',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: t.titleSmall)),
              Text(
                '${value.round()}%',
                style: t.titleSmall?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: AphSpace.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(AphRadius.pill),
            child: LinearProgressIndicator(
              value: (value / 100).clamp(0, 1),
              minHeight: 10,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Simple accessible trend chart (line + dots) for 0–100 scores.
class TrendChart extends StatelessWidget {
  const TrendChart({
    super.key,
    required this.values,
    this.height = 160,
    this.semanticSummary,
  });

  final List<double> values;
  final double height;
  final String? semanticSummary;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            'No scores yet — finish an exercise to see your trend.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    final avg = values.reduce((a, b) => a + b) / values.length;
    return Semantics(
      label: semanticSummary ??
          'Score trend over ${values.length} attempts. '
              'Latest ${values.last.round()}, average ${avg.round()}.',
      excludeSemantics: true,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(painter: _TrendPainter(values)),
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter(this.values);
  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    const left = 28.0, bottom = 8.0, top = 8.0;
    final w = size.width - left;
    final h = size.height - top - bottom;
    final grid = Paint()
      ..color = AphColors.border
      ..strokeWidth = 1;
    final tp = TextPainter(textDirection: TextDirection.ltr);
    for (final g in [0, 50, 100]) {
      final y = top + h - h * g / 100;
      canvas.drawLine(Offset(left, y), Offset(size.width, y), grid);
      tp.text = TextSpan(
        text: '$g',
        style: const TextStyle(fontSize: 11, color: AphColors.inkSubtle),
      );
      tp.layout();
      tp.paint(canvas, Offset(0, y - tp.height / 2));
    }
    final n = values.length;
    Offset at(int i) => Offset(
          left + (n == 1 ? w / 2 : w * i / (n - 1)),
          top + h - h * values[i].clamp(0, 100) / 100,
        );
    final path = Path()..moveTo(at(0).dx, at(0).dy);
    for (var i = 1; i < n; i++) {
      path.lineTo(at(i).dx, at(i).dy);
    }
    final area = Path.from(path)
      ..lineTo(at(n - 1).dx, top + h)
      ..lineTo(at(0).dx, top + h)
      ..close();
    canvas.drawPath(
      area,
      Paint()..color = AphColors.primary.withValues(alpha: 0.08),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = AphColors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeJoin = StrokeJoin.round,
    );
    for (var i = 0; i < n; i++) {
      canvas.drawCircle(at(i), 4.5, Paint()..color = Colors.white);
      canvas.drawCircle(
        at(i),
        4.5,
        Paint()
          ..color = AphColors.primary
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    }
  }

  @override
  bool shouldRepaint(_TrendPainter old) => old.values != values;
}

/// Seven-day activity bars with day labels and counts in text.
class WeekBars extends StatelessWidget {
  const WeekBars({super.key, required this.counts, required this.labels});

  final List<int> counts;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final maxC = counts.fold<int>(0, math.max);
    final total = counts.fold<int>(0, (a, b) => a + b);
    return Semantics(
      label: '$total exercises in the last 7 days. '
          '${[for (var i = 0; i < counts.length; i++) '${labels[i]} ${counts[i]}'].join(', ')}',
      excludeSemantics: true,
      child: SizedBox(
        height: 132,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < counts.length; i++)
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      counts[i] > 0 ? '${counts[i]}' : '',
                      style: t.labelSmall,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 22,
                      height: maxC == 0
                          ? 6
                          : math.max(6, 80 * counts[i] / maxC).toDouble(),
                      decoration: BoxDecoration(
                        color: counts[i] > 0
                            ? (i == counts.length - 1
                                ? AphColors.accent
                                : AphColors.primary)
                            : AphColors.surfaceSunken,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      labels[i],
                      style: t.labelSmall?.copyWith(
                        fontWeight: i == counts.length - 1
                            ? FontWeight.w800
                            : FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Convenience to show a consistent snackbar.
void showAphSnack(
  BuildContext context,
  String message, {
  FeedbackTone tone = FeedbackTone.info,
}) {
  final (_, _, icon) = FeedbackBanner.styleOf(tone);
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: AphSpace.sm),
            Expanded(child: Text(message)),
          ],
        ),
        duration: const Duration(seconds: 4),
      ),
    );
}

Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirm = 'Yes',
  String cancel = 'Cancel',
  bool destructive = false,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(cancel),
        ),
        FilledButton(
          style: destructive
              ? FilledButton.styleFrom(backgroundColor: AphColors.danger)
              : null,
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirm),
        ),
      ],
    ),
  );
  return ok ?? false;
}
