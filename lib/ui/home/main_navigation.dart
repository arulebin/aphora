import 'package:aphora/logic/language_service.dart';
import 'package:aphora/ui/care/care_team_page.dart';
import 'package:aphora/ui/home/home_page.dart';
import 'package:aphora/ui/practice/practice_hub_page.dart';
import 'package:aphora/ui/profile/profile_page.dart';
import 'package:aphora/ui/progress/progress_page.dart';
import 'package:flutter/material.dart';

/// Patient shell: five labelled tabs (Material/HIG maximum).
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  /// Lets child pages switch tabs (e.g. "See all exercises" on Today).
  static void goTo(BuildContext context, int tab) =>
      context.findAncestorStateOfType<_MainNavigationState>()?._select(tab);

  static const today = 0, practice = 1, progress = 2, care = 3, profile = 4;

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _index = 0;

  void _select(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack keeps each tab's scroll position and state.
      body: IndexedStack(
        index: _index,
        children: const [
          HomePage(),
          PracticeHubPage(),
          ProgressPage(),
          CareTeamPage(),
          ProfilePage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _select,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.wb_sunny_outlined),
            selectedIcon: const Icon(Icons.wb_sunny_rounded),
            label: tr('Today', 'இன்று'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.record_voice_over_outlined),
            selectedIcon: const Icon(Icons.record_voice_over_rounded),
            label: tr('Practice', 'பயிற்சி'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.insights_outlined),
            selectedIcon: const Icon(Icons.insights_rounded),
            label: tr('Progress', 'முன்னேற்றம்'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.medical_services_outlined),
            selectedIcon: const Icon(Icons.medical_services_rounded),
            label: tr('Care team', 'சிகிச்சை'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline_rounded),
            selectedIcon: const Icon(Icons.person_rounded),
            label: tr('Me', 'நான்'),
          ),
        ],
      ),
    );
  }
}
