import 'dart:math' as math;

import 'package:aphora/logic/language_service.dart';
import 'package:aphora/ui/design/components.dart';
import 'package:flutter/material.dart';

/// Child-facing rewards: plain Flutter animations, no packages. All of them
/// jump straight to the end state when the OS / comfort settings ask for
/// reduced motion.

bool _still(BuildContext context) => MediaQuery.of(context).disableAnimations;

/// "⭐ 3" in the app bar; pops when the count goes up.
class StarCounter extends StatelessWidget {
  const StarCounter({super.key, required this.stars});
  final int stars;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: tr('$stars stars', '$stars நட்சத்திரங்கள்'),
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF4CC),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('⭐', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 4),
            AnimatedSwitcher(
              duration: _still(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 350),
              transitionBuilder: (child, a) =>
                  ScaleTransition(scale: a, child: child),
              child: Text(
                '$stars',
                key: ValueKey(stars),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AphColors.ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A big star that springs in while small stars fly outward and fade.
class StarBurst extends StatefulWidget {
  const StarBurst({super.key, this.size = 140});
  final double size;

  @override
  State<StarBurst> createState() => _StarBurstState();
}

class _StarBurstState extends State<StarBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_c.isAnimating || _c.isCompleted) return;
    _still(context) ? _c.value = 1 : _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return SizedBox(
      width: s * 2,
      height: s * 1.5,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final pop = Curves.elasticOut.transform(
            (_c.value / 0.7).clamp(0.0, 1.0),
          );
          final fly = Curves.easeOut.transform(_c.value);
          return Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              for (var i = 0; i < 8; i++)
                Transform.translate(
                  offset: Offset.fromDirection(
                    i * math.pi / 4 + math.pi / 8,
                    s * 0.75 * fly,
                  ),
                  child: Opacity(
                    opacity:
                        (1 - fly).clamp(0.0, 1.0) * (_c.value == 1 ? 0 : 1),
                    child: Text('✨', style: TextStyle(fontSize: s * 0.22)),
                  ),
                ),
              Transform.scale(
                scale: pop,
                child: Text('⭐', style: TextStyle(fontSize: s * 0.8)),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Parent mode result: no numbers, just a star and a cheer, or a gentle
/// "try again".
class KidRewardCard extends StatelessWidget {
  const KidRewardCard({
    super.key,
    required this.correct,
    required this.newStar,
  });

  final bool correct;

  /// First correct attempt on this picture: show the star burst.
  final bool newStar;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Semantics(
      liveRegion: true,
      child: AphCard(
        color: correct ? const Color(0xFFFFF8E1) : AphColors.surface,
        child: Column(
          children: [
            if (correct && newStar)
              const StarBurst()
            else
              Text(correct ? '⭐' : '💪', style: const TextStyle(fontSize: 96)),
            const Gap(AphSpace.xs),
            Text(
              correct
                  ? tr(
                      'Super! You got a star!',
                      'சூப்பர்! நட்சத்திரம் கிடைத்தது!',
                    )
                  : tr("Let's say it again!", 'மீண்டும் சொல்லலாம்!'),
              textAlign: TextAlign.center,
              style: t.headlineMedium?.copyWith(
                color: correct ? AphColors.accent : AphColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Session end in parent mode: "You earned N stars", stars popping in one
/// after another.
class StarsEarned extends StatefulWidget {
  const StarsEarned({super.key, required this.stars});
  final int stars;

  @override
  State<StarsEarned> createState() => _StarsEarnedState();
}

class _StarsEarnedState extends State<StarsEarned>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: 400 + 180 * widget.stars.clamp(1, 12)),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_c.isAnimating || _c.isCompleted) return;
    _still(context) ? _c.value = 1 : _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final n = widget.stars;
    final shown = n.clamp(0, 12);
    return Column(
      children: [
        Text(
          n == 0
              ? tr('Well tried!', 'நல்ல முயற்சி!')
              : n == 1
              ? tr('You earned 1 star!', '1 நட்சத்திரம் கிடைத்தது!')
              : tr('You earned $n stars!', '$n நட்சத்திரங்கள் கிடைத்தன!'),
          key: const ValueKey('stars_earned'),
          textAlign: TextAlign.center,
          style: t.headlineMedium?.copyWith(color: AphColors.accent),
        ),
        const Gap(AphSpace.md),
        if (n == 0)
          const Text('🌱', style: TextStyle(fontSize: 96))
        else
          AnimatedBuilder(
            animation: _c,
            builder: (context, _) => Wrap(
              alignment: WrapAlignment.center,
              spacing: 4,
              runSpacing: 4,
              children: [
                for (var i = 0; i < shown; i++)
                  Transform.scale(
                    scale: Curves.elasticOut.transform(
                      Interval(
                        i / (shown + 1),
                        math.min(1.0, (i + 2) / (shown + 1)),
                      ).transform(_c.value),
                    ),
                    child: Text(
                      '⭐',
                      style: TextStyle(fontSize: shown > 6 ? 44 : 64),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
