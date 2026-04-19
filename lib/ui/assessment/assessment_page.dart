import 'package:aphora/logic/language_service.dart';
import 'package:aphora/logic/locator.dart';
import 'package:aphora/ui/widgets/clinical_app_bar.dart';
import 'package:aphora/ui/profile/settings_page.dart';
import 'package:aphora/ui/learning/task_list_page.dart';
import 'package:aphora/ui/profile/profile_page.dart';
import 'package:aphora/ui/therapist/patient_bookings_page.dart';
import 'package:aphora/ui/learning/phonetic_test_page.dart';
import 'package:aphora/ui/video_call/videocall_page.dart';
import 'package:aphora/ui/assessment/pre_assessment_test_page.dart';
import 'package:aphora/data/models/booking_model.dart';
import 'package:aphora/data/models/therapist_model.dart';
import 'package:flutter/material.dart';

class AssessmentPage extends StatefulWidget {
  const AssessmentPage({super.key});

  @override
  _AssessmentPageState createState() => _AssessmentPageState();
}

class _AssessmentPageState extends State<AssessmentPage> {
  TherapistModel? _linkedTherapist;

  @override
  void initState() {
    super.initState();
    Locator.userDatabaseService.currentUser.addListener(_updateUI);
    _fetchTherapist();
  }

  void _fetchTherapist() async {
    final user = Locator.userDatabaseService.currentUser.value;
    if (user != null &&
        user.linkedCaregiverId != null &&
        user.linkedCaregiverId!.isNotEmpty) {
      final therapist = await Locator.userDatabaseService.getTherapistByCode(
        user.linkedCaregiverId!,
      );
      if (mounted) {
        setState(() {
          _linkedTherapist = therapist;
        });
      }
    }
  }

  @override
  void dispose() {
    Locator.userDatabaseService.currentUser.removeListener(_updateUI);
    super.dispose();
  }

  void _updateUI() {
    if (mounted) setState(() {});
    _fetchTherapist();
  }

  void _showBookingDialog(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: const Color(0xFF1E88E5),
            colorScheme: const ColorScheme.light(primary: Color(0xFF1E88E5)),
          ),
          child: child!,
        );
      },
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: const TimeOfDay(hour: 10, minute: 0),
        builder: (context, child) {
          return Theme(
            data: ThemeData.light().copyWith(
              primaryColor: const Color(0xFF1E88E5),
              colorScheme: const ColorScheme.light(primary: Color(0xFF1E88E5)),
            ),
            child: child!,
          );
        },
      );

      if (time != null && mounted) {
        final user = Locator.userDatabaseService.currentUser.value;
        if (user != null && _linkedTherapist != null) {
          final bookingDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );

          final newBooking = BookingModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            patientId: user.uid,
            patientName: user.name,
            therapistId: _linkedTherapist!.code,
            dateTime: bookingDateTime,
          );

          await Locator.bookingDatabaseService.createBooking(newBooking);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  "Session booked for ${date.month}/${date.day}/${date.year} at ${time.format(context)}",
                ),
                backgroundColor: const Color(0xFF1E88E5),
              ),
            );
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Locator.userDatabaseService.currentUser.value;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: ClinicalAppBar(
        title: "Clinical Assessment",
        showBackButton: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsPage(
                    onLanguageChanged: (Language p1) {
                      LanguageService.setLanguage(p1);
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Assessment & Therapy",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 6),
              const Text(
                "Manage your speech evaluations and daily exercises.",
                style: TextStyle(color: Color(0xFF64748B), fontSize: 15),
              ),
              const SizedBox(height: 24),

              // Pre-Assessment Card
              _buildActionCard(
                title: "Pre-Assessment Test",
                subtitle: "Evaluate your speech abilities (letters, words, sentences)",
                icon: Icons.assignment_outlined,
                color: const Color(0xFFF59E0B),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PreAssessmentTestPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Therapy Card
              _buildActionCard(
                title: "Start Therapy",
                subtitle: "Begin your personalized speech session",
                icon: Icons.play_circle_outline,
                color: const Color(0xFF1E88E5),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TaskListPage(category: "Pronunciation"),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),

              const Text(
                "Daily Exercises",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 16),

              _buildExerciseTile(
                "Pronunciation Practice",
                "Pronunciation",
                Icons.record_voice_over_outlined,
              ),
              const SizedBox(height: 8),
              _buildExerciseTile(
                "Word Naming",
                "Word Naming",
                Icons.text_fields_outlined,
              ),
              const SizedBox(height: 8),
              _buildExerciseTile(
                "Conversation Mode",
                "Conversation",
                Icons.chat_bubble_outline,
              ),
              const SizedBox(height: 8),
              _buildPhoneticSoundTaskTile(),
              
              const SizedBox(height: 32),
              const Text(
                "Therapist Session",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 16),
              
              if (user?.linkedCaregiverId == null || user!.linkedCaregiverId!.isEmpty)
                _buildUnlinkedTherapistCard()
              else
                _buildLinkedTherapistCard(user.linkedCaregiverId!),
                
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFFCBD5E1)),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseTile(String title, String category, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF1E88E5)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500, color: Color(0xFF334155))),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFFCBD5E1)),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TaskListPage(category: category),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPhoneticSoundTaskTile() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        leading: const Icon(Icons.mic_none_outlined, color: Color(0xFF1E88E5)),
        title: const Text("Phonetic Sound Test", style: TextStyle(fontWeight: FontWeight.w500, color: Color(0xFF334155))),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFFCBD5E1)),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PhoneticTestPage()),
          );
        },
      ),
    );
  }

  Widget _buildUnlinkedTherapistCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), style: BorderStyle.solid),
      ),
      child: Column(
        children: [
          const Icon(Icons.link_off, color: Color(0xFF94A3B8), size: 32),
          const SizedBox(height: 12),
          const Text(
            "No Therapist Linked",
            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF334155), fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            "Connect with your speech therapist to track your progress together.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfilePage()),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1E88E5),
                side: const BorderSide(color: Color(0xFF1E88E5)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text("Link Therapist"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkedTherapistCard(String id) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Color(0xFFF0FDF4),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.medical_services_outlined, color: Color(0xFF16A34A), size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _linkedTherapist?.name ?? "Your Therapist",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "ID: $id",
                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTherapistAction(
                Icons.video_call_outlined,
                "Video Call",
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const VideoCallPage(channelName: "demo_channel"),
                    ),
                  );
                },
              ),
              _buildTherapistAction(Icons.chat_bubble_outline, "Chat", () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Chat feature coming soon!")),
                );
              }),
              _buildTherapistAction(
                Icons.calendar_month_outlined,
                "Book Session",
                () => _showBookingDialog(context),
              ),
              _buildTherapistAction(
                Icons.event_note_outlined,
                "Bookings",
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PatientBookingsPage(),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTherapistAction(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFF1E88E5), size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF475569)),
            ),
          ],
        ),
      ),
    );
  }
}
