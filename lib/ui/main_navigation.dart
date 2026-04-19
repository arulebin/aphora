import 'package:aphora/logic/locator.dart';
import 'package:aphora/main.dart';
import 'package:aphora/ui/home_page.dart';
import 'package:aphora/ui/TherapistPage.dart';
import 'package:flutter/material.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildPageBody() {
    switch (_selectedIndex) {
      case 0:
        return const HomePageContent();
      case 1:
        return const TherapistPageContent();
      case 2:
        return const ProfilePageContent();
      default:
        return const HomePageContent();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: _buildPageBody(),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_4),
            label: 'Therapist',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: DuoColors.green,
        unselectedItemColor: DuoColors.textLight,
        onTap: _onItemTapped,
        backgroundColor: DuoColors.card,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

/// Content widget for Home Page (without Scaffold)
class HomePageContent extends StatefulWidget {
  const HomePageContent({super.key});

  @override
  State<HomePageContent> createState() => _HomePageContentState();
}

class _HomePageContentState extends State<HomePageContent> {
  @override
  void initState() {
    super.initState();
    Locator.userDatabaseService.currentUser.addListener(_updateUI);
  }

  void _updateUI() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    Locator.userDatabaseService.currentUser.removeListener(_updateUI);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Return the body content from HomePage without Scaffold
    return HomePage();
  }
}

/// Content widget for Therapist Page (without Scaffold)
class TherapistPageContent extends StatelessWidget {
  const TherapistPageContent({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: const [
            TherapistPage(),
          ],
        ),
      ),
    );
  }
}

/// Content widget for Profile Page (without Scaffold)
class ProfilePageContent extends StatelessWidget {
  const ProfilePageContent({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Locator.userDatabaseService.currentUser.value;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: DuoColors.greenLight,
            child: Icon(Icons.person, size: 50, color: DuoColors.green),
          ),
          const SizedBox(height: 10),
          Text(
            user?.name ?? 'User',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text(user?.email ?? '', style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildProfileItem("Gender", user?.gender ?? ''),
                  const Divider(),
                  _buildProfileItem("Age", user?.age.toString() ?? ''),
                  const Divider(),
                  _buildProfileItem("Aphasia Type", user?.aphasiaType ?? ''),
                  const Divider(),
                  _buildProfileItem("Severity", user?.severityLevel ?? ''),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(value),
        ],
      ),
    );
  }
}
