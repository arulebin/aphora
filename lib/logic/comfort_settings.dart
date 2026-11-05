import 'package:aphora/logic/language_service.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Per-device accessibility ("comfort") preferences.
///
/// Stored locally with shared_preferences because they describe the
/// *device + person holding it* (a volunteer's phone may be used for
/// several patients), and they must apply before anyone signs in.
class ComfortSettings {
  ComfortSettings._();
  static final ComfortSettings instance = ComfortSettings._();

  SharedPreferences? _prefs;

  /// Extra text scale on top of the OS setting: 1.0, 1.15, 1.3, 1.5.
  final textScale = ValueNotifier<double>(1.0);

  /// TTS rate. flutter_tts: 0.5 is normal on Android; 0.35 is "slow".
  final speechRate = ValueNotifier<double>(0.45);

  /// Speak prompts automatically when an exercise opens.
  final autoReadAloud = ValueNotifier<bool>(true);

  /// Disable pulses / transitions regardless of OS setting.
  final reduceMotion = ValueNotifier<bool>(false);

  /// Darker borders and text, stronger focus.
  final highContrast = ValueNotifier<bool>(false);

  /// How long a pause ends a spoken answer. Non-fluent (Broca's) speech has
  /// long pauses, so the default is generous.
  final listenPauseSeconds = ValueNotifier<int>(4);

  /// Max length of one spoken answer.
  final listenMaxSeconds = ValueNotifier<int>(20);

  /// Caregiver / community-health-volunteer assisted mode: adds a
  /// "practise together" hand-over step and a session log at the end.
  final assistedMode = ValueNotifier<bool>(false);

  /// Name of the helper running assisted sessions on this device.
  final helperName = ValueNotifier<String>('');

  /// Has the first-run welcome (language choice) been completed?
  final onboarded = ValueNotifier<bool>(false);

  final language = ValueNotifier<Language>(Language.tamil);

  Listenable get any => Listenable.merge([
        textScale,
        speechRate,
        autoReadAloud,
        reduceMotion,
        highContrast,
        listenPauseSeconds,
        listenMaxSeconds,
        assistedMode,
        helperName,
        onboarded,
        language,
      ]);

  Future<void> load() async {
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (_) {
      return; // Private mode / storage blocked — keep defaults.
    }
    final p = _prefs!;
    textScale.value = p.getDouble('textScale') ?? textScale.value;
    speechRate.value = p.getDouble('speechRate') ?? speechRate.value;
    autoReadAloud.value = p.getBool('autoReadAloud') ?? autoReadAloud.value;
    reduceMotion.value = p.getBool('reduceMotion') ?? reduceMotion.value;
    highContrast.value = p.getBool('highContrast') ?? highContrast.value;
    listenPauseSeconds.value =
        p.getInt('listenPauseSeconds') ?? listenPauseSeconds.value;
    listenMaxSeconds.value =
        p.getInt('listenMaxSeconds') ?? listenMaxSeconds.value;
    assistedMode.value = p.getBool('assistedMode') ?? assistedMode.value;
    helperName.value = p.getString('helperName') ?? helperName.value;
    onboarded.value = p.getBool('onboarded') ?? onboarded.value;
    final lang = p.getString('language');
    language.value = lang == 'english' ? Language.english : Language.tamil;
    LanguageService.setLanguage(language.value);

    void bind<T>(ValueNotifier<T> n, String key) {
      n.addListener(() {
        final v = n.value;
        if (v is double) p.setDouble(key, v);
        if (v is int) p.setInt(key, v);
        if (v is bool) p.setBool(key, v);
        if (v is String) p.setString(key, v);
      });
    }

    bind(textScale, 'textScale');
    bind(speechRate, 'speechRate');
    bind(autoReadAloud, 'autoReadAloud');
    bind(reduceMotion, 'reduceMotion');
    bind(highContrast, 'highContrast');
    bind(listenPauseSeconds, 'listenPauseSeconds');
    bind(listenMaxSeconds, 'listenMaxSeconds');
    bind(assistedMode, 'assistedMode');
    bind(helperName, 'helperName');
    bind(onboarded, 'onboarded');
    language.addListener(() {
      LanguageService.setLanguage(language.value);
      p.setString('language', language.value.name);
    });
  }

  /// Local, per-day record of which daily-plan items are done.
  Set<String> planDone(String dayKey) =>
      (_prefs?.getStringList('plan_$dayKey') ?? const <String>[]).toSet();

  Future<void> markPlanDone(String dayKey, String itemId) async {
    final done = planDone(dayKey)..add(itemId);
    await _prefs?.setStringList('plan_$dayKey', done.toList());
  }
}

String dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
