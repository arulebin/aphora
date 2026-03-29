import 'package:aphora/logic/locator.dart';
import 'package:aphora/main.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = Locator.userDatabaseService.currentUser.value;

    return Scaffold(
      backgroundColor: DuoColors.surface,
      appBar: AppBar(
        title: Text(
          "My Profile",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: DuoColors.green,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: DuoColors.greenLight,
              child: Icon(Icons.person, size: 50, color: DuoColors.green),
            ),
            SizedBox(height: 10),
            Text(
              user?.name ?? 'User',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(user?.email ?? '', style: TextStyle(color: Colors.grey)),
            SizedBox(height: 20),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildProfileItem("Gender", user?.gender ?? ''),
                    Divider(),
                    _buildProfileItem("Age", user?.age.toString() ?? ''),
                    Divider(),
                    _buildProfileItem("Aphasia Type", user?.aphasiaType ?? ''),
                    Divider(),
                    _buildProfileItem("Severity", user?.severityLevel ?? ''),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            if (user?.linkedCaregiverId == null ||
                user!.linkedCaregiverId!.isEmpty)
              Card(
                color: Colors.orange[50],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Have a Therapist?",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Enter your therapist's referral code to link your account.",
                      ),
                      SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () {
                          _showLinkTherapistDialog(context);
                        },
                        child: Text("Link Therapist"),
                      ),
                    ],
                  ),
                ),
              )
            else
              Card(
                color: Colors.green[50],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ListTile(
                  leading: Icon(Icons.verified, color: Colors.green),
                  title: Text("Linked to Therapist"),
                  subtitle: Text("ID: ${user.linkedCaregiverId}"),
                ),
              ),

            SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              onPressed: () async {
                await Locator.userDatabaseService.logout();
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Text(
                  "Logout",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileItem(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontSize: 16, color: Colors.grey[700])),
          Text(
            value,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _showLinkTherapistDialog(BuildContext context) {
    TextEditingController _controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Link Therapist"),
          content: TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: "Enter Therapist Code",
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                final user = Locator.userDatabaseService.currentUser.value;
                final code = _controller.text.trim();

                if (user != null && code.isNotEmpty) {
                  // Validate therapist code exists
                  final appState = ScaffoldMessenger.of(context);
                  final therapist = await Locator.userDatabaseService
                      .getTherapistByCode(code);

                  if (therapist != null) {
                    final updated = user.copyWith(linkedCaregiverId: code);
                    Locator.userDatabaseService.updateUser(updated);
                    Locator.userDatabaseService.currentUser.value = updated;
                    if (context.mounted) {
                      Navigator.pop(context);
                      appState.showSnackBar(
                        SnackBar(
                          content: Text(
                            "Linked to ${therapist.name} successfully!",
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } else {
                    if (context.mounted) {
                      appState.showSnackBar(
                        const SnackBar(
                          content: Text("Invalid Therapist Code"),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
              child: Text("Link"),
            ),
          ],
        );
      },
    );
  }
}
