import 'package:aphora/main.dart';
import 'package:flutter/material.dart';

class TaskDetailPage extends StatefulWidget {
  final Map<String, dynamic> task;

  const TaskDetailPage({Key? key, required this.task}) : super(key: key);

  @override
  State<TaskDetailPage> createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends State<TaskDetailPage> {
  bool isRecording = false;
  String recordingDuration = "00:00";
  String userAnswer = "";
  bool hasRecorded = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DuoColors.surface,
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: Text(
          "Pronunciation Practice",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        backgroundColor: DuoColors.green,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Close Button at top
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(width: 40),
                  Expanded(
                    child: Center(
                      child: Container(
                        width: 60,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.close, size: 28, color: Colors.grey[700]),
                  ),
                ],
              ),

              SizedBox(height: 30),

              // 💬 Instruction Text
              Text(
                "Traduza esta frase",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: DuoColors.text,
                ),
              ),

              SizedBox(height: 30),

              // 👤 Character Avatar with Speech Bubble
              Center(
                child: Column(
                  children: [
                    // Character Avatar
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: DuoColors.blue,
                        boxShadow: [
                          BoxShadow(
                            color: DuoColors.blue.withOpacity(0.3),
                            blurRadius: 20,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          '👤',
                          style: TextStyle(fontSize: 80),
                        ),
                      ),
                    ),

                    SizedBox(height: 20),

                    // Speech Bubble
                    Container(
                      constraints: BoxConstraints(maxWidth: 280),
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: DuoColors.card,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Play Button
                          Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: DuoColors.blue,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.play_arrow,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  "Tap to listen",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 12),

                          // The phrase text
                          Text(
                            widget.task['phrase'],
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: DuoColors.text,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 40),

              // 🎤 Recording Section
              Center(
                child: Column(
                  children: [
                    Text(
                      "Your Recording",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: DuoColors.text,
                      ),
                    ),
                    SizedBox(height: 20),

                    // Microphone Button
                    GestureDetector(
                      onTapDown: (_) => _startRecording(),
                      onTapUp: (_) => _stopRecording(),
                      onTapCancel: () => _stopRecording(),
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isRecording ? DuoColors.red : DuoColors.green,
                          boxShadow: [
                            BoxShadow(
                              color: (isRecording ? DuoColors.red : DuoColors.green)
                                  .withOpacity(0.3),
                              blurRadius: 20,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.mic,
                              color: Colors.white,
                              size: 40,
                            ),
                            SizedBox(height: 6),
                            if (isRecording)
                              Text(
                                recordingDuration,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 12),

                    Text(
                      isRecording ? "Recording..." : "Press & Hold to Record",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),

                    if (hasRecorded) ...[
                      SizedBox(height: 20),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: DuoColors.greenLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle, color: DuoColors.green, size: 20),
                            SizedBox(width: 8),
                            Text(
                              "Recording saved",
                              style: TextStyle(
                                color: DuoColors.green,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              SizedBox(height: 40),

              // 🔊 Play Recording Button (if recorded)
              if (hasRecorded)
                Center(
                  child: GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Playing your recording...'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: DuoColors.blue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.play_arrow, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            "Play Recording",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              SizedBox(height: 60),

              // ✅ Continue Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DuoColors.green,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    if (!hasRecorded) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Please record your answer first'),
                          backgroundColor: DuoColors.red,
                        ),
                      );
                      return;
                    }

                    // Show feedback dialog
                    _showFeedbackDialog();
                  },
                  child: Text(
                    "CONTINUAR",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
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

  void _startRecording() {
    setState(() {
      isRecording = true;
      recordingDuration = "00:00";
    });

    // Simulate recording duration
    Future.delayed(Duration(seconds: 1), () {
      if (mounted && isRecording) {
        setState(() {
          recordingDuration = "00:01";
        });
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Recording started'),
        duration: Duration(milliseconds: 500),
      ),
    );
  }

  void _stopRecording() {
    if (isRecording) {
      setState(() {
        isRecording = false;
        hasRecorded = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Recording stopped'),
          duration: Duration(milliseconds: 500),
        ),
      );
    }
  }

  void _showFeedbackDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: DuoColors.green,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 50,
                ),
              ),
              SizedBox(height: 20),
              Text(
                "Excelente!",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: DuoColors.text,
                ),
              ),
              SizedBox(height: 12),
              Text(
                "Great pronunciation!",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DuoColors.green,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  child: Text("NEXT"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
