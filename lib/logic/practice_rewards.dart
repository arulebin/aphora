import 'package:aphora/data/models/practice_record.dart';

/// Small, pure helpers for the child-facing reward loop and the
/// hints-per-word KPI. Kept free of Flutter so they are unit-tested.
abstract final class PracticeRewards {
  /// Score at which an attempt counts as correct (same threshold as the
  /// server's `isCorrect` and the "Good" score band).
  static const correctScore = 70.0;

  static bool isCorrect(double score) => score >= correctScore;

  /// One star per item the child got right (best attempt ≥ 70).
  static int stars(Iterable<double> bestScores) =>
      bestScores.where(isCorrect).length;
}

/// Hints-per-word: how many rungs of the cueing ladder (meaning hint →
/// first sound → full model) a child needed. Falling over time = the child
/// retrieves words more independently.
abstract final class HintStats {
  /// Average of per-word hint counts; null when there are no words.
  static double? average(Iterable<int> hintsPerWord) {
    final list = hintsPerWord.toList();
    if (list.isEmpty) return null;
    return list.fold<int>(0, (a, b) => a + b) / list.length;
  }

  /// Average hints per word across stored attempts.
  ///
  /// A word practised in one sitting may have several attempts while the
  /// hints build up, so attempts are grouped per word per day and the
  /// highest count in the group is that word's figure. Only attempts where
  /// hints were offered are counted ([hintCategories], or any attempt that
  /// actually used a hint), so plain repeat-after-me words don't dilute it.
  static double? averagePerWord(
    Iterable<AttemptRecord> attempts, {
    Set<String> hintCategories = const {'naming'},
  }) {
    final perWord = <String, int>{};
    for (final a in attempts) {
      if (a.hintsUsed <= 0 && !hintCategories.contains(a.category)) continue;
      final d = a.createdAt;
      final key = '${a.taskId}|${d.year}-${d.month}-${d.day}';
      final prev = perWord[key];
      if (prev == null || a.hintsUsed > prev) perWord[key] = a.hintsUsed;
    }
    return average(perWord.values);
  }

  /// "0.8" — one decimal, for display.
  static String format(double v) => v.toStringAsFixed(1);
}
