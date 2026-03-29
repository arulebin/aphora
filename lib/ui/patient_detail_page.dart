import 'package:aphora/data/models/usermodel.dart';
import 'package:aphora/main.dart';
import 'package:aphora/ui/videocall_page.dart';
import 'package:flutter/material.dart';

class PatientDetailPage extends StatelessWidget {
  final UserModel patient;

  const PatientDetailPage({super.key, required this.patient});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DuoColors.surface,
      appBar: AppBar(
        title: Text(
          "Patient Profile",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.purple,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: DuoColors.blue.withOpacity(0.2),
              child: const Icon(Icons.person, size: 50, color: DuoColors.blue),
            ),
            const SizedBox(height: 16),
            Text(patient.name, style: DuoTextStyles.heading),
            Text(
              'Contact: ${patient.phoneNumber}',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),

            // Video Call / Chat Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildActionBtn(
                  context,
                  icon: Icons.video_call,
                  label: "Video Call",
                  color: Colors.purple,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const VideoCallPage(channelName: "demo_channel"),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 16),
                _buildActionBtn(
                  context,
                  icon: Icons.chat,
                  label: "Message",
                  color: DuoColors.blue,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Messaging coming soon")),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Patient Medical Info
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Clinical Information',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const Divider(),
                    _buildInfoRow(
                      'Age & Gender',
                      '${patient.age} / ${patient.gender}',
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow('Aphasia Type', patient.aphasiaType),
                    const SizedBox(height: 8),
                    _buildInfoRow('Severity', patient.severityLevel),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Patient Progress Stats
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Application Progress',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const Divider(),
                    _buildInfoRow(
                      'Progress Score',
                      '${patient.progressScore} pts',
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      'Completed Exercises',
                      '${patient.completedExercises.length} tasks',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 16)),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildActionBtn(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      icon: Icon(icon),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      onPressed: onTap,
    );
  }
}
