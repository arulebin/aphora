import 'package:aphora/logic/locator.dart';
import 'package:aphora/ui/assessment/assessment_page.dart';
import 'package:aphora/ui/home/home_page.dart';
import 'package:aphora/ui/therapist/TherapistPage.dart';
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
        return const AssessmentPageContent();
      case 2:
        return const TherapistPageContent();
      case 3:
        return const ProfilePageContent();
      default:
        return const HomePageContent();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: _buildPageBody(),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_outlined),
            activeIcon: Icon(Icons.analytics),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            activeIcon: Icon(Icons.assignment),
            label: 'Assessment',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.medical_services_outlined),
            activeIcon: Icon(Icons.medical_services),
            label: 'Therapist',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF1E88E5),
        unselectedItemColor: const Color(0xFF94A3B8),
        onTap: _onItemTapped,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        elevation: 10,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
      ),
    );
  }
}

/// Content widget for Home Page (without Scaffold)
class HomePageContent extends StatelessWidget {
  const HomePageContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const HomePage();
  }
}

/// Content widget for Assessment Page
class AssessmentPageContent extends StatelessWidget {
  const AssessmentPageContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const AssessmentPage();
  }
}

/// Content widget for Therapist Page (without Scaffold)
class TherapistPageContent extends StatelessWidget {
  const TherapistPageContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const TherapistPage();
  }
}

/// Content widget for Profile Page (without Scaffold)
class ProfilePageContent extends StatelessWidget {
  const ProfilePageContent({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Locator.userDatabaseService.currentUser.value;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: SafeArea(
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: const Color(0xFFE0F2FE),
              child: const Icon(Icons.person, size: 50, color: Color(0xFF0369A1)),
            ),
            const SizedBox(height: 16),
            Text(
              user?.name ?? 'User',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            Text(user?.email ?? '', style: const TextStyle(color: Color(0xFF64748B))),
            const SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    _buildProfileItem("Gender", user?.gender ?? ''),
                    const Divider(color: Color(0xFFF1F5F9)),
                    _buildProfileItem("Age", user?.age.toString() ?? ''),
                    const Divider(color: Color(0xFFF1F5F9)),
                    _buildProfileItem("Aphasia Type", user?.aphasiaType ?? ''),
                    const Divider(color: Color(0xFFF1F5F9)),
                    _buildProfileItem("Severity", user?.severityLevel ?? ''),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF334155))),
          Text(value, style: const TextStyle(color: Color(0xFF64748B))),
        ],
      ),
    );
  }
}
