import 'package:aphora/data/intake/intake_questions.dart';
import 'package:aphora/data/learning/oral/oral_rehab_pack.dart';
import 'package:aphora/data/learning/packs/condition_packs.dart';
import 'package:aphora/logic/language_service.dart';
import 'package:aphora/logic/locator.dart';
import 'package:aphora/ui/design/components.dart';
import 'package:flutter/material.dart';

/// Label of the hold confirmation button.
String get careTeamSaidYes =>
    tr('My surgeon / care team said I can start', 'என் அறுவை மருத்துவர் / மருத்துவக் குழு தொடங்கலாம் என்றார்கள்');

/// Runs the pack's safety step before practice. Returns true when practice
/// may open. Packs without one (children's, aphasia) return true at once.
///
/// * notice — the safety line once, "I understand".
/// * hold — intake hold flags (pain, < 6 weeks after surgery,
///   radiotherapy): practice stays closed until the person confirms their
///   surgeon / care team said yes. The confirmation is stored with a time
///   (`users/{uid}.oralSafety`).
Future<bool> ensurePracticeSafety(BuildContext context) async {
  final user = ConditionPacks.currentUser;
  final pack = ConditionPacks.forUser(user);
  final safety = pack.safetyFor(user);
  if (safety == PracticeSafety.clear) return true;
  final hold = safety == PracticeSafety.hold;
  final flags = [
    for (final id in user?.intake?.redFlags ?? const <String>[])
      if (OralRehabPack.holdFlags.contains(id))
        if (RedFlag.byId(id) case final f?) f.message.text,
  ];
  final ok = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      final t = Theme.of(context).textTheme;
      return AlertDialog(
        key: const ValueKey('safety_dialog'),
        icon: Icon(
          hold ? Icons.health_and_safety_rounded : Icons.info_outline_rounded,
          color: hold ? AphColors.warning : AphColors.info,
          size: 40,
        ),
        title: Text(hold
            ? tr('Please check with your care team first', 'முதலில் உங்கள் மருத்துவக் குழுவிடம் கேளுங்கள்')
            : tr('Before you start', 'தொடங்கும் முன்')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(pack.safetyLine ?? '', style: t.bodyLarge),
              for (final f in flags) ...[
                const Gap(AphSpace.sm),
                Text('• $f', style: t.bodyMedium),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(hold ? tr('Not yet', 'இன்னும் இல்லை') : tr('Not now', 'இப்போது வேண்டாம்')),
          ),
          FilledButton(
            key: const ValueKey('safety_confirm'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(hold ? careTeamSaidYes : tr('I understand', 'புரிந்தது')),
          ),
        ],
      );
    },
  );
  if (ok != true) return false;
  try {
    // Stored locally at once; the server write may finish later.
    Locator.userDatabaseService.confirmOralSafety(hold: hold).catchError((_) {});
  } catch (_) {/* services not set up (tests) */}
  return true;
}
