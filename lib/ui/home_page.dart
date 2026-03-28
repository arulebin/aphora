import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FB),
      appBar: AppBar(
        title: Text("APHORA"),
        elevation: 0,
        backgroundColor: Colors.indigo,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 👋 Welcome Section
            Text(
              "Hello, User 👋",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 5),
            Text(
              "Let’s improve your speech today",
              style: TextStyle(color: Colors.grey[600]),
            ),

            SizedBox(height: 20),

            // 🚀 Start Therapy Card
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.indigo,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Start Therapy",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Begin your personalized speech session",
                    style: TextStyle(color: Colors.white70),
                  ),
                  SizedBox(height: 15),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.indigo,
                    ),
                    onPressed: () {},
                    child: Text("Start Now"),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),

            // 📊 Progress Section
            Text(
              "Your Progress",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                progressCard("Accuracy", "82%"),
                progressCard("Fluency", "75%"),
                progressCard("Sessions", "12"),
              ],
            ),

            SizedBox(height: 20),

            // 🧠 Exercises Section
            Text(
              "Daily Exercises",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),

            Expanded(
              child: ListView(
                children: [
                  exerciseTile(
                    "Pronunciation Practice",
                    Icons.record_voice_over,
                  ),
                  exerciseTile("Word Naming", Icons.text_fields),
                  exerciseTile("Conversation Mode", Icons.chat),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 📊 Progress Card Widget
  Widget progressCard(String title, String value) {
    return Container(
      width: 100,
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
      ),
      child: Column(
        children: [
          Text(title, style: TextStyle(color: Colors.grey)),
          SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // 🧠 Exercise Tile Widget
  Widget exerciseTile(String title, IconData icon) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: Colors.indigo),
        title: Text(title),
        trailing: Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {},
      ),
    );
  }
}
