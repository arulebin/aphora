import 'package:aphora/main.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class WordNamingPage extends StatefulWidget {
  final String word;
  final String? definition;
  final String? exampleSentence;
  final int currentWordIndex;
  final int totalWords;
  final VoidCallback? onCorrect;

  const WordNamingPage({
    Key? key,
    required this.word,
    this.definition,
    this.exampleSentence,
    this.currentWordIndex = 1,
    this.totalWords = 10,
    this.onCorrect,
  }) : super(key: key);

  @override
  State<WordNamingPage> createState() => _WordNamingPageState();
}

class _WordNamingPageState extends State<WordNamingPage>
    with TickerProviderStateMixin {
  bool isRecording = false;
  int recordingDuration = 0;
  Timer? _recordingTimer;
  bool isPlayingAudio = false;
  bool hasRecorded = false;
  String? recordedText;

  late AnimationController _micAnimationController;
  late Animation<double> _micScaleAnimation;

  @override
  void initState() {
    super.initState();
    _micAnimationController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );

    _micScaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _micAnimationController, curve: Curves.elasticInOut),
    );

    _micAnimationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _micAnimationController.dispose();
    super.dispose();
  }

  void _startRecording() {
    setState(() {
      isRecording = true;
      recordingDuration = 0;
      hasRecorded = true;
    });

    _recordingTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        recordingDuration++;
      });

      // Auto-stop after 10 seconds
      if (recordingDuration >= 10) {
        _stopRecording();
      }
    });
  }

  void _stopRecording() {
    _recordingTimer?.cancel();
    setState(() {
      isRecording = false;
    });
  }

  String _formatDuration(int seconds) {
    int minutes = seconds ~/ 60;
    int secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _playAudio() {
    setState(() {
      isPlayingAudio = true;
    });

    // Simulate audio playback
    Future.delayed(Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          isPlayingAudio = false;
        });
      }
    });
  }

  void _submitAnswer() {
    // Simulate checking if pronunciation is correct
    // This will be replaced with actual API call
    _showCorrectDialog();
  }

  void _showCorrectDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: EdgeInsets.all(30),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Success Animation
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: DuoColors.green.withOpacity(0.2),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.check_circle,
                      size: 60,
                      color: DuoColors.green,
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'Excelente!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: DuoColors.text,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Sua pronúncia está correta!',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 30),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _moveToNextWord();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DuoColors.green,
                          padding: EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Próxima',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _moveToNextWord() {
    // This will navigate to the next word or complete the lesson
    if (widget.onCorrect != null) {
      widget.onCorrect!();
    }
    // You can also use Navigator to go to next page
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return true;
      },
      child: Scaffold(
        backgroundColor: DuoColors.surface,
        appBar: AppBar(
          automaticallyImplyLeading: true,
          title: Text(
            "Pronúncia da Palavra",
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
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Progress Indicator
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Palavra ${widget.currentWordIndex}/${widget.totalWords}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Container(
                        width: 150,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: widget.currentWordIndex / widget.totalWords,
                            backgroundColor: Colors.grey[300],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              DuoColors.green,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 40),

                // Instruction Text
                Text(
                  'Pronuncie a palavra:',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),

                SizedBox(height: 30),

                // Word Display Card
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 40),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Large Word Display
                      Text(
                        widget.word.toUpperCase(),
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: DuoColors.green,
                          letterSpacing: 2,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      SizedBox(height: 20),

                      // Play Audio Button
                      GestureDetector(
                        onTap: _playAudio,
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: DuoColors.blue.withOpacity(0.1),
                            border: Border.all(
                              color: DuoColors.blue,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              isPlayingAudio
                                  ? Icons.volume_up
                                  : Icons.volume_down,
                              size: 32,
                              color: DuoColors.blue,
                            ),
                          ),
                        ),
                      ),

                      if (widget.definition != null) ...[
                        SizedBox(height: 25),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: DuoColors.greenLight.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: DuoColors.greenLight,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Significado:',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[700],
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                widget.definition!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: DuoColors.text,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      if (widget.exampleSentence != null) ...[
                        SizedBox(height: 15),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: DuoColors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: DuoColors.blue.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Exemplo:',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[700],
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                widget.exampleSentence!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: DuoColors.text,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                SizedBox(height: 50),

                // Recording Status and Mic Button
                if (!isRecording && !hasRecorded) ...[
                  Text(
                    'Toque no microfone para começar',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 30),
                ],

                if (isRecording) ...[
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 15),
                    decoration: BoxDecoration(
                      color: DuoColors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: DuoColors.red,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: DuoColors.red,
                              ),
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Gravando...',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: DuoColors.red,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          _formatDuration(recordingDuration),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: DuoColors.text,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 30),
                ] else if (hasRecorded) ...[
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 15),
                    decoration: BoxDecoration(
                      color: DuoColors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: DuoColors.green,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: DuoColors.green,
                              size: 20,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Gravação concluída',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: DuoColors.green,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          _formatDuration(recordingDuration),
                          style: TextStyle(
                            fontSize: 16,
                            color: DuoColors.text,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        isRecording = false;
                        hasRecorded = false;
                        recordingDuration = 0;
                      });
                    },
                    child: Text(
                      'Gravar novamente',
                      style: TextStyle(
                        fontSize: 14,
                        color: DuoColors.blue,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  SizedBox(height: 30),
                ],

                // Mic Button
                ScaleTransition(
                  scale: isRecording ? _micScaleAnimation : AlwaysStoppedAnimation(1.0),
                  child: GestureDetector(
                    onTap: () {
                      if (isRecording) {
                        _stopRecording();
                      } else {
                        _startRecording();
                      }
                    },
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isRecording ? DuoColors.red : DuoColors.green,
                        boxShadow: [
                          BoxShadow(
                            color: (isRecording ? DuoColors.red : DuoColors.green)
                                .withOpacity(0.4),
                            blurRadius: 20,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          isRecording ? Icons.stop : Icons.mic,
                          size: 50,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 50),

                // Submit Button (only show if recorded)
                if (hasRecorded)
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _submitAnswer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DuoColors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 8,
                      ),
                      child: Text(
                        'Verificar',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
