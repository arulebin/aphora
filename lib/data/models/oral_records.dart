import 'package:aphora/logic/baseline_scoring.dart';

/// The person confirmed the safety line (`users/{uid}.oralSafety`).
/// [hold]: they confirmed that their surgeon / care team said they may
/// start, despite a hold flag from the intake (pain, < 6 weeks after
/// surgery, radiotherapy ongoing).
class SafetyConfirmation {
  const SafetyConfirmation({required this.at, required this.hold});

  final DateTime at;
  final bool hold;

  Map<String, dynamic> toMap() => {'confirmedAt': at.toIso8601String(), 'hold': hold};

  static SafetyConfirmation? tryFromMap(Object? raw) {
    if (raw is! Map) return null;
    final at = DateTime.tryParse(raw['confirmedAt']?.toString() ?? '');
    if (at == null) return null;
    return SafetyConfirmation(at: at, hold: raw['hold'] == true);
  }
}

/// One monthly clarity (intelligibility) check, stored in the list
/// `users/{uid}.oralClarityTests`. The first complete one is the starting
/// point.
class ClarityTest {
  const ClarityTest({
    required this.at,
    required this.understood,
    required this.attempted,
    required this.total,
    this.missed = const [],
  });

  factory ClarityTest.fromResult(IntelligibilityResult r, DateTime at) => ClarityTest(
        at: at,
        understood: r.understood,
        attempted: r.attempted,
        total: r.total,
        missed: r.missed,
      );

  final DateTime at;
  final int understood;
  final int attempted;
  final int total;
  final List<String> missed;

  IntelligibilityResult get result => IntelligibilityResult(
        understood: understood,
        attempted: attempted,
        total: total,
        missed: missed,
      );

  double get percent => result.percent;
  bool get isComplete => result.isComplete;

  Map<String, dynamic> toMap() => {
        'at': at.toIso8601String(),
        'understood': understood,
        'attempted': attempted,
        'total': total,
        'missed': missed,
      };

  static ClarityTest? tryFromMap(Object? raw) {
    if (raw is! Map) return null;
    final at = DateTime.tryParse(raw['at']?.toString() ?? '');
    if (at == null) return null;
    int n(Object? v) => (v as num?)?.toInt() ?? 0;
    return ClarityTest(
      at: at,
      understood: n(raw['understood']),
      attempted: n(raw['attempted']),
      total: n(raw['total']),
      missed: [for (final m in (raw['missed'] as List?) ?? const []) '$m'],
    );
  }

  /// The first complete test, or null.
  static ClarityTest? startingPoint(List<ClarityTest> tests) {
    final sorted = [...tests]..sort((a, b) => a.at.compareTo(b.at));
    for (final t in sorted) {
      if (t.isComplete) return t;
    }
    return null;
  }

  /// The most recent test, or null.
  static ClarityTest? latest(List<ClarityTest> tests) {
    if (tests.isEmpty) return null;
    return ([...tests]..sort((a, b) => a.at.compareTo(b.at))).last;
  }
}
