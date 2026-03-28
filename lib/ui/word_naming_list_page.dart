import 'package:aphora/main.dart';
import 'package:aphora/ui/word_naming_page.dart';
import 'package:flutter/material.dart';

class WordNamingListPage extends StatelessWidget {
  // Sample words data
  final List<Map<String, dynamic>> words = [
    {
      'word': 'Apple',
      'definition': 'Uma fruta vermelha ou verde',
      'exampleSentence': 'I eat an apple every morning.',
      'icon': '🍎',
    },
    {
      'word': 'Book',
      'definition': 'Um conjunto de páginas com histórias ou informações',
      'exampleSentence': 'I love reading this book.',
      'icon': '📖',
    },
    {
      'word': 'Computer',
      'definition': 'Máquina eletrônica para processar dados',
      'exampleSentence': 'I work on a computer every day.',
      'icon': '💻',
    },
    {
      'word': 'Elephant',
      'definition': 'Grande animal com tromba',
      'exampleSentence': 'The elephant is a gentle giant.',
      'icon': '🐘',
    },
    {
      'word': 'Flower',
      'definition': 'Planta bonita com cores e pétalas',
      'exampleSentence': 'The flower smells beautiful.',
      'icon': '🌸',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DuoColors.surface,
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: Text(
          "Pronuncia de Palavras",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        elevation: 0,
        backgroundColor: DuoColors.green,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 16),
              Text(
                'Escolha uma palavra para começar:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: DuoColors.text,
                ),
              ),
              SizedBox(height: 20),
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: words.length,
                itemBuilder: (context, index) {
                  final word = words[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => WordNamingPage(
                            word: word['word'],
                            definition: word['definition'],
                            exampleSentence: word['exampleSentence'],
                            currentWordIndex: index + 1,
                            totalWords: words.length,
                            onCorrect: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Parabéns! Próxima palavra...'),
                                  backgroundColor: DuoColors.green,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                    child: Container(
                      margin: EdgeInsets.only(bottom: 12),
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.grey[200]!,
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Text(
                            word['icon'],
                            style: TextStyle(fontSize: 40),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  word['word'],
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: DuoColors.text,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  word['definition'],
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: DuoColors.green,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
