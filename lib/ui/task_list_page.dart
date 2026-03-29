import 'package:aphora/logic/locator.dart';
import 'package:aphora/main.dart';
import 'package:aphora/ui/task_detail_page.dart';
import 'package:aphora/logic/language_service.dart';
import 'package:flutter/material.dart';

class TaskListPage extends StatefulWidget {
  final String category;

  const TaskListPage({Key? key, this.category = "Pronunciation"})
    : super(key: key);

  @override
  _TaskListPageState createState() => _TaskListPageState();
}

class _TaskListPageState extends State<TaskListPage> {
  // We'll generate different tasks based on category
  late List<Map<String, dynamic>> baseTasks;

  @override
  void initState() {
    super.initState();
    _initTasks();
    _loadProgress();
  }

  void _initTasks() {
    if (widget.category == "Word Naming") {
      baseTasks = [
        {
          'id': 'word_1',
          'english_phrase': 'Apple',
          'difficulty': 'Easy',
          'icon': '🍎',
          'completed': false,
        },
        {
          'id': 'word_2',
          'english_phrase': 'Book',
          'difficulty': 'Easy',
          'icon': '📖',
          'completed': false,
        },
        {
          'id': 'word_3',
          'english_phrase': 'Computer',
          'difficulty': 'Medium',
          'icon': '💻',
          'completed': false,
        },
        {
          'id': 'word_4',
          'english_phrase': 'Elephant',
          'difficulty': 'Hard',
          'icon': '🐘',
          'completed': false,
        },
        {
          'id': 'word_5',
          'english_phrase': 'Flower',
          'difficulty': 'Easy',
          'icon': '🌸',
          'completed': false,
        },
      ];
    } else if (widget.category == "Conversation") {
      baseTasks = [
        {
          'id': 'conv_1',
          'english_phrase': 'How was your day today?',
          'difficulty': 'Medium',
          'icon': '🗣️',
          'completed': false,
        },
        {
          'id': 'conv_2',
          'english_phrase': 'Can you tell me about your family?',
          'difficulty': 'Hard',
          'icon': '👨‍👩‍👧',
          'completed': false,
        },
        {
          'id': 'conv_3',
          'english_phrase': 'What is your favorite food?',
          'difficulty': 'Easy',
          'icon': '🍕',
          'completed': false,
        },
      ];
    } else {
      // Default / Pronunciation Practice
      baseTasks = [
        {
          'id': 'pron_1',
          'english_phrase': 'Hello, how are you?',
          'difficulty': 'Easy',
          'icon': '👋',
          'completed': false,
        },
        {
          'id': 'pron_2',
          'english_phrase': 'My name is John',
          'difficulty': 'Easy',
          'icon': '👤',
          'completed': false,
        },
        {
          'id': 'pron_3',
          'english_phrase': 'I would like to order a coffee',
          'difficulty': 'Medium',
          'icon': '☕',
          'completed': false,
        },
        {
          'id': 'pron_4',
          'english_phrase': 'Can you help me find the nearest hospital?',
          'difficulty': 'Medium',
          'icon': '🏥',
          'completed': false,
        },
        {
          'id': 'pron_5',
          'english_phrase': 'I am learning English to improve my career',
          'difficulty': 'Hard',
          'icon': '📚',
          'completed': false,
        },
        {
          'id': 'pron_6',
          'english_phrase': 'Could you please repeat that more slowly?',
          'difficulty': 'Hard',
          'icon': '🎧',
          'completed': false,
        },
      ];
    }
  }

  // Get tasks with language-specific phrases
  List<Map<String, dynamic>> getLocalizedTasks() {
    return baseTasks.map((task) {
      // If LanguageService doesn't have translation for dynamic IDs, we fallback to english_phrase
      String phrase;
      try {
        phrase = LanguageService.getTaskPhrase(task['id']);
      } catch (e) {
        phrase = task['english_phrase'];
      }

      return {
        ...task,
        'phrase': phrase,
        'difficulty_label': task['difficulty'], // Or translate if needed
      };
    }).toList();
  }

  void _loadProgress() {
    final currentUser = Locator.userDatabaseService.currentUser.value;
    if (currentUser != null) {
      setState(() {
        for (var task in baseTasks) {
          if (currentUser.completedExercises.contains(task['id'].toString())) {
            task['completed'] = true;
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizedTasks = getLocalizedTasks();

    return Scaffold(
      backgroundColor: DuoColors.surface,
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: Text(
          widget.category,
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
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 📊 Progress Bar
              _buildProgressBar(context, localizedTasks),
              SizedBox(height: 30),

              // 🎯 Tasks List
              _buildTasksList(context, localizedTasks),

              SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // Progress Bar Widget
  Widget _buildProgressBar(
    BuildContext context,
    List<Map<String, dynamic>> tasks,
  ) {
    final completedTasks = tasks
        .where((task) => task['completed'] == true)
        .length;
    final progress = completedTasks / tasks.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: DuoColors.text,
              ),
            ),
            Text(
              '${completedTasks}/${tasks.length}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: DuoColors.green,
              ),
            ),
          ],
        ),
        SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 12,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(DuoColors.green),
          ),
        ),
      ],
    );
  }

  // Tasks List Widget
  Widget _buildTasksList(
    BuildContext context,
    List<Map<String, dynamic>> tasks,
  ) {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: _buildTaskCard(context, task, index),
        );
      },
    );
  }

  // Individual Task Card
  Widget _buildTaskCard(
    BuildContext context,
    Map<String, dynamic> task,
    int index,
  ) {
    Color difficultyColor;
    switch (task['difficulty']) {
      case 'Easy':
        difficultyColor = DuoColors.green;
        break;
      case 'Medium':
        difficultyColor = DuoColors.yellow;
        break;
      case 'Hard':
        difficultyColor = DuoColors.red;
        break;
      default:
        difficultyColor = Colors.grey;
    }

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => TaskDetailPage(task: task)),
        );
        if (result == true) {
          setState(() {
            baseTasks[index]['completed'] = true;
          });
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: DuoColors.card,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Icon Circle
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: difficultyColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(task['icon'], style: TextStyle(fontSize: 32)),
                ),
              ),
              SizedBox(width: 16),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task['phrase'],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: DuoColors.text,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 6),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: difficultyColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        task['difficulty_label'] ?? task['difficulty'],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: difficultyColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Completion Status
              if (task['completed'])
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: DuoColors.green,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check, color: Colors.white, size: 24),
                )
              else
                Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
