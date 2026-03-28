import 'package:aphora/logic/locator.dart';
import 'package:aphora/main.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class UserInfoPage extends StatefulWidget {
  final String phone;
  final String password;

  const UserInfoPage({Key? key, required this.phone, required this.password})
    : super(key: key);

  @override
  _UserInfoPageState createState() => _UserInfoPageState();
}

class _UserInfoPageState extends State<UserInfoPage> {
  final nameController = TextEditingController();
  final ageController = TextEditingController();

  String gender = 'Male';
  String role = 'patient';
  String aphasiaType = 'Broca';
  String severity = 'mild';

  // For role selection card UI
  final roles = [
    {'value': 'patient', 'label': 'Patient', 'icon': Icons.person_outline},
    {
      'value': 'caregiver',
      'label': 'Caregiver',
      'icon': Icons.favorite_outline,
    },
  ];

  final severities = [
    {'value': 'mild', 'label': 'Mild', 'color': DuoColors.green},
    {'value': 'moderate', 'label': 'Moderate', 'color': DuoColors.yellow},
    {'value': 'severe', 'label': 'Severe', 'color': DuoColors.red},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DuoColors.surface,
      appBar: AppBar(
        backgroundColor: DuoColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: DuoColors.textLight,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text('Set up your profile', style: DuoTextStyles.body),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              const StepDots(total: 3, current: 2),
              const SizedBox(height: 28),

              // Avatar + name area
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: DuoColors.greenLight,
                        shape: BoxShape.circle,
                        border: Border.all(color: DuoColors.green, width: 3),
                      ),
                      child: const Icon(
                        Icons.person,
                        color: DuoColors.green,
                        size: 40,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: DuoColors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Text('Your details', style: DuoTextStyles.heading),
              const SizedBox(height: 4),
              Text('Tell us a bit about yourself.', style: DuoTextStyles.label),
              const SizedBox(height: 16),

              DuoTextField(
                controller: nameController,
                label: 'Full name',
                prefixIcon: Icons.badge_outlined,
              ),

              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: DuoTextField(
                      controller: ageController,
                      label: 'Age',
                      prefixIcon: Icons.cake_outlined,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 4,
                    child: DuoDropdown(
                      value: gender,
                      items: ['Male', 'Female', 'Other'],
                      onChanged: (v) => setState(() => gender = v!),
                      label: 'Gender',
                      icon: Icons.wc_outlined,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              Text('I am a...', style: DuoTextStyles.heading),
              const SizedBox(height: 12),

              // Role card selector
              Row(
                children: roles.map((r) {
                  final selected = role == r['value'];
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => role = r['value'] as String),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: selected ? DuoColors.greenLight : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: selected
                                ? DuoColors.green
                                : DuoColors.border,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: selected
                                  ? DuoColors.greenDark
                                  : DuoColors.border,
                              offset: const Offset(0, 3),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Icon(
                              r['icon'] as IconData,
                              color: selected
                                  ? DuoColors.green
                                  : DuoColors.textLight,
                              size: 28,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              r['label'] as String,
                              style: DuoTextStyles.label.copyWith(
                                color: selected
                                    ? DuoColors.greenDark
                                    : DuoColors.textLight,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),
              Text('Aphasia details', style: DuoTextStyles.heading),
              const SizedBox(height: 4),
              Text(
                'This helps us personalise your lessons.',
                style: DuoTextStyles.label,
              ),
              const SizedBox(height: 12),

              DuoDropdown(
                value: aphasiaType,
                items: ['Broca', 'Wernicke', 'Global'],
                onChanged: (v) => setState(() => aphasiaType = v!),
                label: 'Aphasia type',
                icon: Icons.psychology_outlined,
              ),

              const SizedBox(height: 16),
              Text(
                'Severity',
                style: DuoTextStyles.label.copyWith(fontSize: 13),
              ),
              const SizedBox(height: 10),

              // Severity pill selector
              Row(
                children: severities.map((s) {
                  final selected = severity == s['value'];
                  final c = s['color'] as Color;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => severity = s['value'] as String),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: selected ? c.withOpacity(0.15) : Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: selected ? c : DuoColors.border,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: selected
                                  ? c.withOpacity(0.4)
                                  : DuoColors.border,
                              offset: const Offset(0, 3),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                        child: Text(
                          s['label'] as String,
                          style: DuoTextStyles.label.copyWith(
                            color: selected ? c : DuoColors.textLight,
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 36),
              DuoButton(
                label: "LET'S START LEARNING!",
                onPressed: () async {
                  final name = nameController.text.trim();
                  final age = int.tryParse(ageController.text.trim()) ?? 0;

                  if (name.isEmpty || age == 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please fill all details correctly.'),
                      ),
                    );
                    return;
                  }

                  try {
                    final user = await Locator.userDatabaseService.signUp(
                      phone: widget.phone,
                      password: widget.password,
                      name: name,
                      age: age,
                      gender: gender,
                      aphasiaType: aphasiaType,
                      severityLevel: severity,
                    );

                    if (user != null) {
                      context.push('/home');
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Failed to create account. Please try again.',
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(e.toString())));
                  }
                },
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
