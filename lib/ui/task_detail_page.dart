import 'package:aphora/logic/locator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:aphora/logic/language_service.dart';
import 'dart:io' show Platform;
import 'dart:js' as js;
import 'dart:math' as math;

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

  int _levenshteinDistance(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    int v0Len = s2.length + 1;
    List<int> v0 = List<int>.filled(v0Len, 0);
    List<int> v1 = List<int>.filled(v0Len, 0);

    for (int i = 0; i < v0Len; i++) v0[i] = i;

    for (int i = 0; i < s1.length; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < s2.length; j++) {
        int cost = (s1[i] == s2[j]) ? 0 : 1;
        v1[j + 1] = math.min(v1[j] + 1, math.min(v0[j + 1] + 1, v0[j] + cost));
      }
      for (int j = 0; j < v0Len; j++) v0[j] = v1[j];
    }
    return v1[s2.length];
  }

  void _checkCompletion() {
    String expected = widget.task['phrase'].toString().toLowerCase().replaceAll(
      RegExp(r'[^\w\s]'),
      '',
    );
    String actual = spokenText.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '');

    if (actual.isEmpty || actual == "tap mic and start speaking") return;

    List<String> expectedWords = expected
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();
    List<String> actualWords = actual
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();

    int matches = 0;
    List<String> actualWordsCopy = List.from(actualWords);
    for (String w in expectedWords) {
      String? bestMatch;
      int lowestDist = 999;

      for (String a in actualWordsCopy) {
        int dist = _levenshteinDistance(w, a);
        if (dist < lowestDist) {
          lowestDist = dist;
          bestMatch = a;
        }
      }

      // Tolerance rules for matching to account for Aphasia speech quirks / accents.
      int threshold = (w.length <= 4) ? 1 : 2;

      if (bestMatch != null &&
          (lowestDist <= threshold ||
              bestMatch.contains(w) ||
              w.contains(bestMatch))) {
        matches++;
        actualWordsCopy.remove(bestMatch);
      }
    }

    double accuracy = expectedWords.isEmpty
        ? 0
        : matches / expectedWords.length;

    // Calculate the length ratio to catch guessing.
    double lengthRatio =
        actualWords.length / (expectedWords.isEmpty ? 1 : expectedWords.length);

    // Be more forgiving: 70% accuracy, and allow 50% fewer to 2x more words (to account for speech restarting or stuttering).
    if ((actual == expected) ||
        (accuracy >= 0.70 && lengthRatio <= 2.5 && lengthRatio >= 0.4)) {
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
            Spacer(),
            Center(
              child: TextButton.icon(
                onPressed: () {
                  stopListening();
                  setState(() {
                    spokenText = "Tap mic and start speaking";
                    _isNavigating = false;
                  });
                },
                icon: Icon(Icons.refresh),
                label: Text("Reset"),
                style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
