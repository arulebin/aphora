import 'package:flutter/material.dart';
import 'package:aphora/logic/language_service.dart';
import 'package:aphora/main.dart';

class LanguageSelectionPage extends StatefulWidget {
  final Function(Language) onLanguageSelected;

  const LanguageSelectionPage({
    Key? key,
    required this.onLanguageSelected,
  }) : super(key: key);

  @override
  State<LanguageSelectionPage> createState() => _LanguageSelectionPageState();
}

class _LanguageSelectionPageState extends State<LanguageSelectionPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DuoColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Aphora',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: DuoColors.green,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Select Your Language',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: DuoColors.text,
                      ),
                    ),
                    SizedBox(height: 48),
                    // English Option
                    _buildLanguageCard(
                      context,
                      language: Language.english,
                      title: '🇬🇧 English',
                      description: 'English language',
                      onTap: () {
                        LanguageService.setLanguage(Language.english);
                        widget.onLanguageSelected(Language.english);
                      },
                    ),
                    SizedBox(height: 24),
                    // Tamil Option
                    _buildLanguageCard(
                      context,
                      language: Language.tamil,
                      title: '🇮🇳 தமிழ்',
                      description: 'Tamil language',
                      onTap: () {
                        LanguageService.setLanguage(Language.tamil);
                        widget.onLanguageSelected(Language.tamil);
                      },
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

  Widget _buildLanguageCard(
    BuildContext context, {
    required Language language,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 280,
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: DuoColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: DuoColors.green,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: DuoColors.text,
              ),
            ),
            SizedBox(height: 12),
            Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: DuoColors.green,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Select',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
