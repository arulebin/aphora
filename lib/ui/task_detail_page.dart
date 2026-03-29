import 'package:aphora/logic/locator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:aphora/logic/language_service.dart';
import 'dart:io' show Platform;
import 'dart:js' as js;

class TaskDetailPage extends StatefulWidget {
  final Map<String, dynamic> task;

  const TaskDetailPage({super.key, required this.task});

  @override
  State<TaskDetailPage> createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends State<TaskDetailPage> {
  final FlutterTts flutterTts = FlutterTts();
  late stt.SpeechToText speech;

  bool isListening = false;
  bool _isNavigating = false;
  String spokenText = "Tap mic and start speaking";

  @override
  void initState() {
    super.initState();
    speech = stt.SpeechToText();
    initTTS();
  }

  bool _isWeb() {
    try {
      return !Platform.isAndroid &&
          !Platform.isIOS &&
          !Platform.isWindows &&
          !Platform.isLinux &&
          !Platform.isMacOS;
    } catch (e) {
      return true;
    }
  }

  // 🔊 Initialize TTS with selected language
  void initTTS() async {
    if (_isWeb()) return;

    String languageCode = LanguageService.currentLanguage == Language.english
        ? "en-US"
        : "ta-IN";
    await flutterTts.setLanguage(languageCode);
    await flutterTts.setSpeechRate(0.4);
    await flutterTts.setPitch(1.0);
  }

  // 🔊 Speak Text with proper language
  void speakText() async {
    if (_isWeb()) {
      _speakTextWeb(widget.task['phrase']);
    } else {
      try {
        await flutterTts.stop();
        await flutterTts.speak(widget.task['phrase']);
      } catch (e) {
        print('Error speaking: $e');
      }
    }
  }

  void _speakTextWeb(String text) {
    try {
      js.context.callMethod('speechWeb', [text]);
    } catch (e) {
      print('Web TTS error: $e');
    }
  }

  // 🎤 Start Listening with proper language
  void startListening() async {
    bool available = await speech.initialize();

    if (available) {
      if (mounted) {
        setState(() => isListening = true);
      }

      String languageCode = LanguageService.currentLanguage == Language.english
          ? "en-US"
          : "ta-IN";

      speech.listen(
        localeId: languageCode,
        onResult: (result) {
          if (mounted) {
            setState(() {
              spokenText = result.recognizedWords;
            });
            _checkCompletion();
          }
        },
      );
    }
  }

  void _checkCompletion() {
    String expected = widget.task['phrase'].toString().toLowerCase().replaceAll(
      RegExp(r'[^\w\s]'),
      '',
    );
    String actual = spokenText.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '');

    if (actual.isNotEmpty &&
        (actual == expected ||
            actual.contains(expected) ||
            expected.contains(actual) &&
                actual.length > expected.length * 0.8)) {
      // Update backend if user is logged in
      final currentUser = Locator.userDatabaseService.currentUser.value;
      if (currentUser != null) {
        final taskId = widget.task['id'].toString();
        if (!currentUser.completedExercises.contains(taskId)) {
          currentUser.completedExercises.add(taskId);
          currentUser.progressScore += 10; // add some progress
          Locator.userDatabaseService.updateUser(currentUser);
        }
      }

      // Mark as completed
      if (!_isNavigating) {
        _isNavigating = true;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Great job! Task completed.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Add a slight delay so user can see their success
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pop(context, true);
          }
        });
      }
    }
  }

  // 🛑 Stop Listening
  void stopListening() {
    speech.stop();
    if (mounted) {
      setState(() => isListening = false);
    }
  }

  @override
  void dispose() {
    if (!_isWeb()) {
      flutterTts.stop();
    }
    speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;

    return Scaffold(
      appBar: AppBar(title: Text("Task Detail")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 📘 Phrase
            Text(
              task['phrase'],
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            SizedBox(height: 30),

            // 🔊 Tap to Listen
            ElevatedButton.icon(
              onPressed: speakText,
              icon: Icon(Icons.volume_up),
              label: Text("Tap to Listen"),
            ),

            SizedBox(height: 40),

            // 🎤 Mic Button
            Center(
              child: GestureDetector(
                onTap: () {
                  isListening ? stopListening() : startListening();
                },
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: isListening ? Colors.red : Colors.green,
                  child: Icon(
                    isListening ? Icons.mic : Icons.mic_none,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            SizedBox(height: 30),

            // 📝 Spoken Text Output
            Text("You said:", style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text(
              spokenText,
              style: TextStyle(fontSize: 18, color: Colors.blue),
            ),
          ],
        ),
      ),
    );
  }
}
