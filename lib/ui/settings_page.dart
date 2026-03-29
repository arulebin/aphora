import 'package:flutter/material.dart';
import 'package:aphora/logic/language_service.dart';

class SettingsPage extends StatefulWidget {
  final Function(Language) onLanguageChanged;

  const SettingsPage({
    Key? key,
    required this.onLanguageChanged,
  }) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late Language _selectedLanguage;

  @override
  void initState() {
    super.initState();
    _selectedLanguage = LanguageService.currentLanguage;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(LanguageService.get('settings')),
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              LanguageService.get('select_language'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _buildLanguageOption(
            context,
            language: Language.english,
            title: '🇬🇧 English',
          ),
          _buildLanguageOption(
            context,
            language: Language.tamil,
            title: '🇮🇳 தமிழ்',
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageOption(
    BuildContext context, {
    required Language language,
    required String title,
  }) {
    return RadioListTile<Language>(
      title: Text(title),
      value: language,
      groupValue: _selectedLanguage,
      onChanged: (Language? value) {
        if (value != null) {
          setState(() {
            _selectedLanguage = value;
          });
          LanguageService.setLanguage(value);
          widget.onLanguageChanged(value);
          // Rebuild the app to reflect language changes
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  LanguageService.get('success'),
                ),
              ),
            );
          }
        }
      },
    );
  }
}
