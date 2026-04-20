import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_theme.dart';
import 'quiz_session_view.dart';

class QuizResultView extends StatelessWidget {
  final String subject;
  final List<QuizSessionRecord> records;
  final int correct;
  final int total;

  const QuizResultView({
    super.key,
    required this.subject,
    required this.records,
    required this.correct,
    required this.total,
  });

  double get percentage => (correct / total) * 100;

  String get gradeEmoji {
    if (percentage >= 90) return '🏆';
    if (percentage >= 70) return '🌟';
    if (percentage >= 50) return '👍';
    return '📚';
  }

  String get gradeMessage {
    if (percentage >= 90) return 'Outstanding!';
    if (percentage >= 70) return 'Great Work!';
    if (percentage >= 50) return 'Good Effort!';
    return 'Keep Practicing!';
  }

  Color get gradeColor {
    if (percentage >= 90) return AppColors.accentGreen;
    if (percentage >= 70) return AppColors.accentCyan;
    if (percentage >= 50) return AppColors.accentOrange;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: AppBar(
        title: const Text('Quiz Results'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _buildScoreCard(context),
                  const SizedBox(height: 28),
                  _buildStatsRow(context),
                  const SizedBox(height: 28),
                  _buildReviewSection(context),
                ],
              ),
            ),
          ),
          _buildActions(context),
        ],
      ),
    );
  }

  Widget _buildScoreCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            gradeColor.withOpacity(0.15),
            AppColors.surfaceCard,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: gradeColor.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          Text(
            gradeEmoji,
            style: const TextStyle(fontSize: 64),
          ).animate().scale(
                begin: const Offset(0, 0),
                end: const Offset(1, 1),
                duration: 600.ms,
                curve: Curves.elasticOut,
              ),
          const SizedBox(height: 16),
          Text(
            gradeMessage,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: gradeColor,
                ),
          ).animate().fadeIn(delay: 300.ms),
          const SizedBox(height: 8),
          Text(
            '$subject Quiz Complete',
            style: Theme.of(context).textTheme.bodyMedium,
          ).animate().fadeIn(delay: 400.ms),
          const SizedBox(height: 24),
          Text(
            '$correct / $total',
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: gradeColor,
                  fontWeight: FontWeight.bold,
                ),
          ).animate().fadeIn(delay: 500.ms),
          const SizedBox(height: 4),
          Text(
            '${percentage.toStringAsFixed(0)}% Accuracy',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textMuted,
                ),
          ).animate().fadeIn(delay: 600.ms),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms);
  }

  Widget _buildStatsRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            context,
            icon: Icons.check_circle_rounded,
            value: '$correct',
            label: 'Correct',
            color: AppColors.accentGreen,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatItem(
            context,
            icon: Icons.cancel_rounded,
            value: '${total - correct}',
            label: 'Incorrect',
            color: AppColors.error,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatItem(
            context,
            icon: Icons.timer_rounded,
            value: '$total',
            label: 'Questions',
            color: AppColors.accentCyan,
          ),
        ),
      ],
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildStatItem(BuildContext context,
      {required IconData icon, required String value, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: color, fontWeight: FontWeight.bold)),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _buildReviewSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Question Review',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textMuted,
              ),
        ),
        const SizedBox(height: 14),
        ...List.generate(records.length, (index) {
          final record = records[index];
          return Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard.withOpacity(0.5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: record.isCorrect
                    ? AppColors.accentGreen.withOpacity(0.3)
                    : AppColors.error.withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      record.isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                      color: record.isCorrect ? AppColors.accentGreen : AppColors.error,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Q${index + 1}',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: record.isCorrect ? AppColors.accentGreen : AppColors.error,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  record.question.question,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                if (!record.isCorrect) ...[
                  Text(
                    'Your answer: ${record.selectedAnswer}) ${record.question.options[record.selectedAnswer] ?? ""}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.error),
                  ),
                  Text(
                    'Correct: ${record.question.correctAnswer}) ${record.question.options[record.question.correctAnswer] ?? ""}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.accentGreen),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  record.question.explanation,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                        fontStyle: FontStyle.italic,
                      ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: (500 + index * 50).ms);
        }),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard.withOpacity(0.8),
        border: Border(top: BorderSide(color: AppColors.textMuted.withOpacity(0.1))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('New Topic'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppColors.accentCyan),
                  foregroundColor: AppColors.accentCyan,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.home_rounded),
                label: const Text('Home'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: AppColors.accentCyan,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
