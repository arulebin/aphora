import 'package:aphora/main.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SessionSelectionPage extends StatefulWidget {
  final double preAssessmentScore;

  const SessionSelectionPage({
    super.key,
    required this.preAssessmentScore,
  });

  @override
  State<SessionSelectionPage> createState() => _SessionSelectionPageState();
}

class _SessionSelectionPageState extends State<SessionSelectionPage> {
  late String _recommendedLevel;
  late String _recommendedCategory;

  @override
  void initState() {
    super.initState();
    _determineRecommendedLevel();
  }

  void _determineRecommendedLevel() {
    if (widget.preAssessmentScore < 10) {
      _recommendedLevel = 'Beginner';
      _recommendedCategory = 'letters';
    } else if (widget.preAssessmentScore >= 10 && widget.preAssessmentScore < 20) {
      _recommendedLevel = 'Intermediate';
      _recommendedCategory = 'words';
    } else {
      _recommendedLevel = 'Advanced';
      _recommendedCategory = 'sentences';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Your Session'),
        backgroundColor: DuoColors.green,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              DuoColors.green.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Score Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: DuoColors.green,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: DuoColors.green.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Pre-Assessment Score',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${widget.preAssessmentScore.toStringAsFixed(1)}/30',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Your Level: $_recommendedLevel',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Recommendation Text
                Text(
                  'Recommended Session',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: DuoColors.greenDark,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  _getRecommendationText(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[700],
                      ),
                ),
                const SizedBox(height: 24),

                // Session Options
                Text(
                  'Choose Your Session',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: DuoColors.greenDark,
                      ),
                ),
                const SizedBox(height: 16),

                // Letters Card
                _buildSessionCard(
                  context,
                  title: 'Letters',
                  description: 'Learn and practice Tamil letters',
                  difficulty: 'Beginner',
                  icon: Icons.abc,
                  color: const Color(0xFF6C63FF),
                  isRecommended: _recommendedCategory == 'letters',
                  onTap: () {
                    context.push('/letters-session', extra: {
                      'preAssessmentScore': widget.preAssessmentScore,
                    });
                  },
                ),
                const SizedBox(height: 12),

                // Words Card
                _buildSessionCard(
                  context,
                  title: 'Words',
                  description: 'Learn and practice Tamil words',
                  difficulty: 'Intermediate',
                  icon: Icons.article,
                  color: const Color(0xFFFF6B6B),
                  isRecommended: _recommendedCategory == 'words',
                  onTap: () {
                    context.push('/words-session', extra: {
                      'preAssessmentScore': widget.preAssessmentScore,
                    });
                  },
                ),
                const SizedBox(height: 12),

                // Sentences Card
                _buildSessionCard(
                  context,
                  title: 'Sentences',
                  description: 'Learn and practice Tamil sentences',
                  difficulty: 'Advanced',
                  icon: Icons.notes,
                  color: const Color(0xFF4ECDC4),
                  isRecommended: _recommendedCategory == 'sentences',
                  onTap: () {
                    context.push('/sentences-session', extra: {
                      'preAssessmentScore': widget.preAssessmentScore,
                    });
                  },
                ),
                const SizedBox(height: 32),

                // Go Home Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      context.go('/home');
                    },
                    child: const Text(
                      'Go to Home',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSessionCard(
    BuildContext context, {
    required String title,
    required String description,
    required String difficulty,
    required IconData icon,
    required Color color,
    required bool isRecommended,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: isRecommended
            ? Border.all(
                color: DuoColors.green,
                width: 3,
              )
            : Border.all(
                color: Colors.grey[200]!,
                width: 1,
              ),
        boxShadow: [
          if (isRecommended)
            BoxShadow(
              color: DuoColors.green.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          else
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                          ),
                          if (isRecommended) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: DuoColors.green,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'RECOMMENDED',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        difficulty,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: color,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey[400],
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getRecommendationText() {
    switch (_recommendedCategory) {
      case 'letters':
        return 'Based on your score, we recommend starting with Letters. This will help you build a strong foundation in recognizing and pronouncing Tamil letters clearly.';
      case 'words':
        return 'Based on your score, we recommend progressing to Words. You\'re ready to combine letters into meaningful words and expand your vocabulary.';
      case 'sentences':
        return 'Based on your score, you\'re ready for Sentences! Practice constructing and understanding complete Tamil sentences.';
      default:
        return '';
    }
  }
}
