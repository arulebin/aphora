import 'package:aphora/main.dart';
import 'package:aphora/ui/task_detail_page.dart';
import 'package:flutter/material.dart';

class TaskListPage extends StatelessWidget {
  // Sample tasks data - replace with real data from your backend
  final List<Map<String, dynamic>> tasks = [
    {
      'id': 1,
      'phrase': 'Hello, how are you?',
      'difficulty': 'Easy',
      'icon': '👋',
      'completed': false,
    },
    {
      'id': 2,
      'phrase': 'My name is John',
      'difficulty': 'Easy',
      'icon': '👤',
      'completed': false,
    },
    {
      'id': 3,
      'phrase': 'I would like to order a coffee',
      'difficulty': 'Medium',
      'icon': '☕',
      'completed': false,
    },
    {
      'id': 4,
      'phrase': 'Can you help me find the nearest hospital?',
      'difficulty': 'Medium',
      'icon': '🏥',
      'completed': false,
    },
    {
      'id': 5,
      'phrase': 'I am learning English to improve my career',
      'difficulty': 'Hard',
      'icon': '📚',
      'completed': false,
    },
    {
      'id': 6,
      'phrase': 'Could you please repeat that more slowly?',
      'difficulty': 'Hard',
      'icon': '🎧',
      'completed': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DuoColors.surface,
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: Text(
          "Lesson",
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
              _buildProgressBar(context),
              SizedBox(height: 30),

              // 🎯 Tasks List
              _buildTasksList(context),

              SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // Progress Bar Widget
  Widget _buildProgressBar(BuildContext context) {
    final completedTasks = tasks.where((task) => task['completed'] == true).length;
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
  Widget _buildTasksList(BuildContext context) {
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
  Widget _buildTaskCard(BuildContext context, Map<String, dynamic> task, int index) {
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
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TaskDetailPage(task: task),
          ),
        );
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
                  child: Text(
                    task['icon'],
                    style: TextStyle(fontSize: 32),
                  ),
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
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: difficultyColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        task['difficulty'],
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
                  child: Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 24,
                  ),
                )
              else
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
