import 'package:aphora/firebase_options.dart';
import 'package:aphora/logic/comfort_settings.dart';
import 'package:aphora/logic/family_voice_store.dart';
import 'package:aphora/logic/locator.dart';
import 'package:aphora/ui/auth/language_selection_page.dart';
import 'package:aphora/ui/auth/login_page.dart';
import 'package:aphora/ui/auth/signup_page.dart';
import 'package:aphora/ui/auth/therapist_login_page.dart';
import 'package:aphora/ui/auth/user_info_page.dart';
import 'package:aphora/ui/design/theme.dart';
import 'package:aphora/ui/home/main_navigation.dart';
import 'package:aphora/ui/intake/intake_page.dart';
import 'package:aphora/ui/therapist/therapist_dashboard_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';

/// Build with `--dart-define=USE_FIREBASE_EMULATOR=true` to run against the
/// local Firebase emulators (end-to-end tests). Over USB, `adb reverse` maps
/// the phone's 127.0.0.1 ports to this PC, so no live data is touched.
const _useEmulator = bool.fromEnvironment('USE_FIREBASE_EMULATOR');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (_useEmulator) {
    // No automatic 127.0.0.1 → 10.0.2.2 rewrite: that only works inside the
    // Android emulator; on a USB phone `adb reverse` serves 127.0.0.1.
    await FirebaseAuth.instance
        .useAuthEmulator('127.0.0.1', 9099, automaticHostMapping: false);
    FirebaseFirestore.instance
        .useFirestoreEmulator('127.0.0.1', 8080, automaticHostMapping: false);
  }
  // Tamil month/weekday names for DateFormat(…, appDateLocale).
  await initializeDateFormatting();
  await ComfortSettings.instance.load();
  // Family Voice recordings live on the device; read which exist.
  await FamilyVoiceStore.instance.load();
  Locator.setUpServices();

  final restored = await Locator.userDatabaseService.restoreSession();
  final users = Locator.userDatabaseService;
  final String initial;
  if (!ComfortSettings.instance.onboarded.value) {
    initial = '/welcome';
  } else if (restored && users.currentUser.value != null) {
    initial = '/home';
  } else if (restored && users.currentTherapist.value != null) {
    initial = '/therapist_dashboard';
  } else {
    initial = '/login';
  }
  runApp(AphoraApp(initialLocation: initial));
}

GoRouter _createRouter(String initialLocation) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const LanguageSelectionPage(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(path: '/signup', builder: (context, state) => const SignUpPage()),
      GoRoute(
        path: '/userinfo',
        builder: (context, state) {
          final extras = state.extra as Map<String, dynamic>? ?? {};
          return UserInfoPage(
            phone: extras['phone'] as String? ?? '',
            password: extras['password'] as String? ?? '',
          );
        },
      ),
      GoRoute(
        path: '/intake',
        builder: (context, state) {
          final extras = state.extra as Map<String, dynamic>? ?? {};
          return IntakePage(
            who: extras['who'] as String?,
            age: extras['age'] as int? ?? 0,
            fromSignUp: extras['fromSignUp'] as bool? ?? false,
          );
        },
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const MainNavigation(),
      ),
      GoRoute(
        path: '/therapist',
        builder: (context, state) => const TherapistLoginPage(),
      ),
      GoRoute(
        path: '/therapist_dashboard',
        builder: (context, state) => const TherapistDashboardPage(),
      ),
    ],
  );
}

class AphoraApp extends StatefulWidget {
  const AphoraApp({super.key, required this.initialLocation});
  final String initialLocation;

  @override
  State<AphoraApp> createState() => _AphoraAppState();
}

class _AphoraAppState extends State<AphoraApp> {
  late final GoRouter _router = _createRouter(widget.initialLocation);

  @override
  void initState() {
    super.initState();
    ComfortSettings.instance.language.addListener(_relabel);
  }

  @override
  void dispose() {
    ComfortSettings.instance.language.removeListener(_relabel);
    super.dispose();
  }

  /// Strings come from `tr()`, which isn't an InheritedWidget, so a language
  /// switch marks every element dirty. State (navigation stack, scroll,
  /// form input) is preserved — only build() re-runs.
  void _relabel() {
    void mark(Element e) {
      e.markNeedsBuild();
      e.visitChildren(mark);
    }

    if (mounted) (context as Element).visitChildren(mark);
  }

  @override
  Widget build(BuildContext context) {
    final comfort = ComfortSettings.instance;
    return ListenableBuilder(
      listenable: Listenable.merge([
        comfort.textScale,
        comfort.reduceMotion,
        comfort.highContrast,
        comfort.language,
      ]),
      builder: (context, _) => MaterialApp.router(
        title: 'Vernacura',
        debugShowCheckedModeBanner: false,
        theme: comfort.highContrast.value
            ? AphTheme.highContrast()
            : AphTheme.light(),
        routerConfig: _router,
        builder: (context, child) {
          // Apply the in-app "Larger text" on top of the OS setting, and
          // honour "Reduce motion" app-wide.
          final mq = MediaQuery.of(context);
          final osScale = mq.textScaler.scale(1);
          return MediaQuery(
            data: mq.copyWith(
              textScaler: TextScaler.linear(
                (osScale * comfort.textScale.value).clamp(1.0, 2.2),
              ),
              disableAnimations:
                  mq.disableAnimations || comfort.reduceMotion.value,
            ),
            child: child!,
          );
        },
      ),
    );
  }
}
