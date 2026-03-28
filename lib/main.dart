import 'package:aphora/logic/locator.dart';
import 'package:aphora/ui/home_page.dart';
import 'package:aphora/ui/login_page.dart';
import 'package:aphora/ui/signup_page.dart';
import 'package:aphora/ui/user_info_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Locator.setUpServices();
  await Firebase.initializeApp();
  runApp(MyApp());
}

final GoRouter _router = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => LoginPage()),
    GoRoute(path: '/signup', builder: (context, state) => SignUpPage()),
    GoRoute(
      path: '/userinfo',
      builder: (context, state) {
        final extras = state.extra as Map<String, dynamic>? ?? {};
        return UserInfoPage(
          phone: extras['phone'] ?? '',
          password: extras['password'] ?? '',
        );
      },
    ),
    GoRoute(path: '/home', builder: (context, state) => HomePage()),
  ],
);

// ─────────────────────────────────────────
//  DESIGN TOKENS  (Duolingo-inspired)
// ─────────────────────────────────────────
class DuoColors {
  static const green = Color(0xFF58CC02);
  static const greenDark = Color(0xFF46A302);
  static const greenLight = Color(0xFFD7F5B2);
  static const yellow = Color(0xFFFFD900);
  static const blue = Color(0xFF1CB0F6);
  static const red = Color(0xFFFF4B4B);
  static const surface = Color(0xFFF7F7F7);
  static const card = Colors.white;
  static const text = Color(0xFF3C3C3C);
  static const textLight = Color(0xFF777777);
  static const border = Color(0xFFE5E5E5);
  static const disabled = Color(0xFFAFAFAF);
}

class DuoTextStyles {
  static const display = TextStyle(
    fontFamily: 'Nunito',
    fontSize: 32,
    fontWeight: FontWeight.w900,
    color: DuoColors.text,
    letterSpacing: -0.5,
  );
  static const heading = TextStyle(
    fontFamily: 'Nunito',
    fontSize: 22,
    fontWeight: FontWeight.w800,
    color: DuoColors.text,
  );
  static const body = TextStyle(
    fontFamily: 'Nunito',
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: DuoColors.text,
  );
  static const label = TextStyle(
    fontFamily: 'Nunito',
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: DuoColors.textLight,
    letterSpacing: 0.5,
  );
  static const button = TextStyle(
    fontFamily: 'Nunito',
    fontSize: 16,
    fontWeight: FontWeight.w800,
    color: Colors.white,
    letterSpacing: 0.5,
  );
}

// ─────────────────────────────────────────
//  REUSABLE WIDGETS
// ─────────────────────────────────────────

/// The iconic Duolingo "chunky" button with a bottom border shadow
class DuoButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final Color color;
  final Color shadowColor;
  final Color textColor;
  final bool outlined;

  const DuoButton({
    Key? key,
    required this.label,
    required this.onPressed,
    this.color = DuoColors.green,
    this.shadowColor = DuoColors.greenDark,
    this.textColor = Colors.white,
    this.outlined = false,
  }) : super(key: key);

  @override
  State<DuoButton> createState() => _DuoButtonState();
}

class _DuoButtonState extends State<DuoButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        margin: EdgeInsets.only(
          top: _pressed ? 4 : 0,
          bottom: _pressed ? 0 : 4,
        ),
        decoration: BoxDecoration(
          color: widget.outlined ? Colors.white : widget.color,
          border: Border.all(
            color: widget.outlined ? DuoColors.border : widget.color,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: _pressed
              ? []
              : [
                  BoxShadow(
                    color: widget.outlined
                        ? DuoColors.border
                        : widget.shadowColor,
                    offset: const Offset(0, 4),
                    blurRadius: 0,
                  ),
                ],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: Center(
            child: Text(
              widget.label,
              style: DuoTextStyles.button.copyWith(
                color: widget.outlined ? DuoColors.text : widget.textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Duolingo-style text field
class DuoTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscureText;
  final TextInputType keyboardType;
  final IconData? prefixIcon;

  const DuoTextField({
    Key? key,
    required this.controller,
    required this.label,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.prefixIcon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DuoColors.border, width: 2),
        boxShadow: const [
          BoxShadow(
            color: DuoColors.border,
            offset: Offset(0, 3),
            blurRadius: 0,
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: DuoTextStyles.body,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: DuoTextStyles.label,
          prefixIcon: prefixIcon != null
              ? Icon(prefixIcon, color: DuoColors.textLight, size: 20)
              : null,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
          border: InputBorder.none,
          floatingLabelStyle: DuoTextStyles.label.copyWith(
            color: DuoColors.green,
          ),
        ),
      ),
    );
  }
}

/// Duolingo-style dropdown
class DuoDropdown extends StatelessWidget {
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final String label;
  final IconData? icon;

  const DuoDropdown({
    Key? key,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.label,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DuoColors.border, width: 2),
        boxShadow: const [
          BoxShadow(
            color: DuoColors.border,
            offset: Offset(0, 3),
            blurRadius: 0,
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        items: items
            .map(
              (item) => DropdownMenuItem(
                value: item,
                child: Text(item, style: DuoTextStyles.body),
              ),
            )
            .toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: DuoTextStyles.label,
          prefixIcon: icon != null
              ? Icon(icon, color: DuoColors.textLight, size: 20)
              : null,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 4,
          ),
          border: InputBorder.none,
          floatingLabelStyle: DuoTextStyles.label.copyWith(
            color: DuoColors.green,
          ),
        ),
        borderRadius: BorderRadius.circular(16),
        icon: const Icon(
          Icons.keyboard_arrow_down_rounded,
          color: DuoColors.textLight,
        ),
        isExpanded: true,
        dropdownColor: Colors.white,
      ),
    );
  }
}

/// The owl mascot - drawn in pure Flutter/Canvas
// class DuoOwl extends StatelessWidget {
//   final double size;
//   const DuoOwl({Key? key, this.size = 120}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       width: size,
//       height: size,
//       child: CustomPaint(painter: _OwlPainter()),
//     );
//   }
// }

/// Progress dots for onboarding steps
class StepDots extends StatelessWidget {
  final int total;
  final int current;
  const StepDots({Key? key, required this.total, required this.current})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active ? DuoColors.green : DuoColors.border,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────
//  APP SHELL
// ─────────────────────────────────────────
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
      theme: ThemeData(
        fontFamily: 'Nunito',
        scaffoldBackgroundColor: DuoColors.surface,
        colorScheme: ColorScheme.fromSeed(seedColor: DuoColors.green),
        useMaterial3: true,
      ),
    );
  }
}

// class _SocialButton extends StatelessWidget {
//   final String label;
//   final IconData icon;
//   final Color color;

//   const _SocialButton({
//     required this.label,
//     required this.icon,
//     required this.color,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: DuoColors.border, width: 2),
//         boxShadow: const [
//           BoxShadow(
//             color: DuoColors.border,
//             offset: Offset(0, 3),
//             blurRadius: 0,
//           ),
//         ],
//       ),
//       child: Material(
//         color: Colors.transparent,
//         child: InkWell(
//           borderRadius: BorderRadius.circular(14),
//           onTap: () {},
//           child: SizedBox(
//             height: 52,
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Icon(icon, color: color, size: 28),
//                 const SizedBox(width: 10),
//                 Text(label, style: DuoTextStyles.body),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
