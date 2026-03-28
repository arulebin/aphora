import 'package:flutter/material.dart';

class therapistPage extends StatelessWidget {
  const therapistPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Aphasia Therapist Connect"),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Therapist Profile Card
            Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 35,
                      backgroundImage:
                          AssetImage('assets/therapist.jpg'),
                    ),
                    const SizedBox(width: 15),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text("Dr. Meera Nair",
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                        SizedBox(height: 5),
                        Text("Speech & Aphasia Specialist"),
                        Text("Experience: 8+ years"),
                      ],
                    )
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Action Buttons
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              physics: const NeverScrollableScrollPhysics(),
              children: [

                _buildFeatureCard(
                  context,
                  icon: Icons.video_call,
                  title: "Start Video Call",
                  color: Colors.blue,
                  onTap: () {
                    // Add video call logic
                  },
                ),

                _buildFeatureCard(
                  context,
                  icon: Icons.chat,
                  title: "Chat",
                  color: Colors.green,
                  onTap: () {
                    // Add chat logic
                  },
                ),

                _buildFeatureCard(
                  context,
                  icon: Icons.calendar_month,
                  title: "Book Session",
                  color: Colors.orange,
                  onTap: () {
                    // Booking logic
                  },
                ),

                _buildFeatureCard(
                  context,
                  icon: Icons.mic,
                  title: "Upload Speech",
                  color: Colors.purple,
                  onTap: () {
                    // Upload audio logic
                  },
                ),

                _buildFeatureCard(
                  context,
                  icon: Icons.analytics,
                  title: "Progress Report",
                  color: Colors.teal,
                  onTap: () {
                    // Show reports
                  },
                ),

                _buildFeatureCard(
                  context,
                  icon: Icons.warning,
                  title: "Emergency Help",
                  color: Colors.red,
                  onTap: () {
                    // Emergency contact
                  },
                ),
              ],
            ),

            const SizedBox(height: 25),

            // Tips Section
            const Text(
              "Daily Tips",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: const [
                    ListTile(
                      leading: Icon(Icons.check_circle, color: Colors.teal),
                      title: Text("Practice simple words daily"),
                    ),
                    ListTile(
                      leading: Icon(Icons.check_circle, color: Colors.teal),
                      title: Text("Use visual cues while speaking"),
                    ),
                    ListTile(
                      leading: Icon(Icons.check_circle, color: Colors.teal),
                      title: Text("Repeat words slowly and clearly"),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(BuildContext context,
      {required IconData icon,
      required String title,
      required Color color,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            gradient: LinearGradient(
              colors: [color.withOpacity(0.7), color],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 35, color: Colors.white),
              const SizedBox(height: 10),
              Text(title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}