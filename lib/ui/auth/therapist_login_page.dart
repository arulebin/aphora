import 'package:aphora/data/database_service/user_database_service.dart';
import 'package:aphora/logic/locator.dart';
import 'package:aphora/ui/auth/auth_shell.dart';
import 'package:aphora/ui/design/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

/// Therapist sign-in and explicit registration (no more silent
/// auto-creation on a failed login).
class TherapistLoginPage extends StatefulWidget {
  const TherapistLoginPage({super.key});

  @override
  State<TherapistLoginPage> createState() => _TherapistLoginPageState();
}

class _TherapistLoginPageState extends State<TherapistLoginPage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  bool _register = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final db = Locator.userDatabaseService;
    try {
      if (_register) {
        await db.registerTherapist(
          phone: normalisePhone(_phone.text),
          password: _password.text,
          name: _name.text.trim(),
        );
      } else {
        await db.loginTherapist(
          phone: normalisePhone(_phone.text),
          password: _password.text,
        );
      }
      if (mounted) context.go('/therapist_dashboard');
    } on AuthFailure catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      title: 'Therapist portal',
      subtitle: 'Follow each child’s home practice and meet their family on video.',
      footer: [
        Center(
          child: AphButton.ghost(
            label: 'Back to parent sign in',
            icon: Icons.arrow_back_rounded,
            onPressed: () => context.go('/login'),
          ),
        ),
      ],
      children: [
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: false, label: Text('Sign in'), icon: Icon(Icons.login_rounded)),
            ButtonSegment(value: true, label: Text('Register'), icon: Icon(Icons.person_add_rounded)),
          ],
          selected: {_register},
          onSelectionChanged: (s) => setState(() {
            _register = s.first;
            _error = null;
          }),
          style: const ButtonStyle(
            minimumSize: WidgetStatePropertyAll(Size(0, 52)),
          ),
        ),
        const Gap(AphSpace.lg),
        Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_register) ...[
                AphTextField(
                  controller: _name,
                  label: 'Full name',
                  hint: 'Dr. Priya Raman',
                  icon: Icons.badge_rounded,
                  textCapitalization: TextCapitalization.words,
                  validator: (v) =>
                      (v ?? '').trim().length < 2 ? 'Please enter your name.' : null,
                ),
                const Gap(AphSpace.md),
              ],
              AphTextField(
                controller: _phone,
                label: 'Mobile number',
                icon: Icons.phone_rounded,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]')),
                  LengthLimitingTextInputFormatter(12),
                ],
                validator: validatePhone,
              ),
              const Gap(AphSpace.md),
              AphTextField(
                controller: _password,
                label: 'Password',
                icon: Icons.lock_rounded,
                obscure: true,
                textInputAction: TextInputAction.done,
                validator: validatePassword,
                onSubmitted: (_) => _submit(),
              ),
              if (_error != null) ...[
                const Gap(AphSpace.md),
                FeedbackBanner(tone: FeedbackTone.error, title: _error!),
              ],
              const Gap(AphSpace.lg),
              AphButton(
                label: _register ? 'Create therapist account' : 'Sign in',
                icon: _register ? Icons.check_rounded : Icons.login_rounded,
                loading: _loading,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
