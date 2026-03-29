import 'package:aphora/logic/language_service.dart';
import 'package:aphora/logic/locator.dart';
import 'package:aphora/main.dart';
import 'package:aphora/ui/TherapistPage.dart'
    show AphasiaTherapistPage, therapistPage, TherapistPage;
import 'package:aphora/ui/settings_page.dart';
import 'package:aphora/ui/task_list_page.dart';
import 'package:aphora/ui/profile_page.dart';
import 'package:aphora/ui/patient_bookings_page.dart';
import 'package:aphora/ui/videocall_page.dart';
import 'package:aphora/data/models/booking_model.dart';
import 'package:aphora/data/models/therapist_model.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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
    // If the widget is still mounted, trigger a rebuild to update progress scores
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
            primaryColor: DuoColors.green,
            colorScheme: ColorScheme.light(primary: DuoColors.green),
            buttonTheme: const ButtonThemeData(
              textTheme: ButtonTextTheme.primary,
            ),
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
              primaryColor: DuoColors.green,
              colorScheme: ColorScheme.light(primary: DuoColors.green),
              buttonTheme: const ButtonThemeData(
                textTheme: ButtonTextTheme.primary,
              ),
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
                backgroundColor: DuoColors.green,
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
    final int completedExercisesCount = user?.completedExercises.length ?? 0;
    // Simple dynamic calculation for demo purposes:
    final int totalTasks =
        14; // 6 (Pronunciation) + 5 (Word naming) + 3 (Conversation)
    final double completionPercent = totalTasks > 0
        ? (completedExercisesCount / totalTasks) * 100
        : 0.0;
    final int sessions = user?.sessionsCompleted ?? 0;

    return Scaffold(
      backgroundColor: Color(0xFFF5F7FB),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Center(
          child: Text(
            "APHORA",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: Colors.white),
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
          IconButton(
            icon: Icon(Icons.person, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfilePage()),
              );
            },
          ),
        ],
        elevation: 0,
        backgroundColor: DuoColors.green,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 👋 Welcome Section
              Text(
                "Hello, ${Locator.userDatabaseService.currentUser.value?.name ?? 'User'}👋",
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
                  color: const Color.fromARGB(255, 137, 247, 53),
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
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                TaskListPage(category: "Pronunciation"),
                          ),
                        );
                      },
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
                  progressCard(
                    "Completion",
                    "${completionPercent.toStringAsFixed(0)}%",
                  ),
                  progressCard(
                    "Score",
                    "${user?.progressScore.toStringAsFixed(0) ?? '0'}",
                  ),
                  progressCard("Exercises", "$completedExercisesCount"),
                ],
              ),

              SizedBox(height: 20),

              // 🧠 Exercises Section
              Text(
                "Daily Exercises",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),

              Column(
                children: [
                  exerciseTile(
                    context,
                    "Pronunciation Practice",
                    "Pronunciation",
                    Icons.record_voice_over,
                  ),
                  exerciseTile(
                    context,
                    "Word Naming",
                    "Word Naming",
                    Icons.text_fields,
                  ),
                  exerciseTile(
                    context,
                    "Conversation Mode",
                    "Conversation",
                    Icons.chat,
                  ),
                ],
              ),
              SizedBox(height: 20),
              Text(
                "Therapist Session",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              if (user?.linkedCaregiverId == null ||
                  user!.linkedCaregiverId!.isEmpty)
                Card(
                  color: Colors.orange[50],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          "You don't have a linked therapist.",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProfilePage(),
                              ),
                            );
                          },
                          child: Text("Link a Therapist"),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: DuoColors.greenLight,
                              child: Icon(
                                Icons.medical_services,
                                color: DuoColors.green,
                              ),
                            ),
                            SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _linkedTherapist?.name ?? "Your Therapist",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  "ID: ${user.linkedCaregiverId}",
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildTherapistAction(
                              Icons.video_call,
                              "Video Call",
                              () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const VideoCallPage(
                                      channelName: "demo_channel",
                                    ),
                                  ),
                                );
                              },
                            ),
                            _buildTherapistAction(Icons.chat, "Chat", () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Chat feature coming soon!"),
                                ),
                              );
                            }),
                            _buildTherapistAction(
                              Icons.calendar_month,
                              "Book Session",
                              () => _showBookingDialog(context),
                            ),
                            _buildTherapistAction(
                              Icons.event_note,
                              "Bookings",
                              () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const PatientBookingsPage(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTherapistAction(
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: Colors.blue.withOpacity(0.1),
            child: Icon(icon, color: Colors.blue),
          ),
          SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 12)),
        ],
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

  Widget exerciseTile(
    BuildContext context,
    String title,
    String category,
    IconData icon,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: Colors.indigo),
        title: Text(title),
        trailing: Icon(Icons.arrow_forward_ios, size: 16),
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
}
