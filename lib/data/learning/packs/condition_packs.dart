import 'package:aphora/data/intake/condition.dart';
import 'package:aphora/data/learning/packs/aphasia_pack.dart';
import 'package:aphora/data/learning/packs/condition_pack.dart';
import 'package:aphora/data/learning/packs/kids_pack.dart';
import 'package:aphora/data/models/usermodel.dart';
import 'package:aphora/logic/locator.dart';
import 'package:flutter/foundation.dart';

export 'package:aphora/data/learning/packs/condition_pack.dart';

/// Which [ConditionPack] serves which condition.
///
/// The person's condition is `UserModel.activeCondition` (the therapist's
/// choice, else the intake result) and their level is
/// `UserModel.practiceLevel` (therapist → check-up/intake → 2).
abstract final class ConditionPacks {
  static const kids = KidsPack();
  static const aphasia = AphasiaPack();

  /// Built-in packs. INTEGRATION POINT for the oral-cancer pack: add
  /// `Condition.oralCancerRehab: OralCancerPack(),` here (or call
  /// [register] at start-up). Its "exercises are being prepared" notice
  /// then disappears by itself ([contentPending]).
  static final Map<Condition, ConditionPack> _packs = {
    Condition.childSpeechDelay: kids,
    Condition.adultAphasia: aphasia,
  };

  /// Adds or replaces the pack for `pack.condition`.
  static void register(ConditionPack pack) => _packs[pack.condition] = pack;

  @visibleForTesting
  static void unregister(Condition c) {
    if (c == Condition.childSpeechDelay || c == Condition.adultAphasia) return;
    _packs.remove(c);
  }

  static bool hasPack(Condition c) => _packs.containsKey(c);

  /// The pack for [c]; conditions without one use the general (children's)
  /// set, as before the packs existed.
  static ConditionPack of(Condition c) => _packs[c] ?? kids;

  /// A known condition whose own exercises are not built yet: the app says
  /// so instead of pretending. `unknown` just uses the general set.
  static bool contentPending(Condition c) =>
      c != Condition.unknown && !hasPack(c);

  static ConditionPack forUser(UserModel? user) =>
      of(user?.activeCondition ?? Condition.unknown);

  /// Children's wording (parent mode, stars) for this person. Adults whose
  /// pack is still pending get the general set but adult wording.
  static bool childWording(UserModel? user) =>
      user?.isChild ?? forUser(user).forChildren;

  static UserModel? get _user {
    try {
      return Locator.userDatabaseService.currentUser.value;
    } catch (_) {
      return null; // services not set up (widget tests)
    }
  }

  /// The signed-in person's pack, level and intake focus.
  static ConditionPack get current => forUser(_user);
  static int get currentLevel => _user?.practiceLevel ?? 2;
  static List<String> get currentFocus => _user?.intake?.focus ?? const [];
  static bool get currentChildWording => childWording(_user);
}
