import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../services/progress_service.dart';
import '../theme/app_theme.dart';
import '../widgets/stat_card.dart';

class ProgressView extends StatelessWidget {
  const ProgressView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: AppBar(
        title: const Text('My Progress'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Consumer<ProgressService>(
        builder: (context, progress, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOverviewCard(context, progress),
                const SizedBox(height: 24),
                _buildStatsGrid(context, progress),
                const SizedBox(height: 28),
                _buildAchievements(context, progress),
                const SizedBox(height: 28),
                _buildSubjectBreakdown(context, progress),
                const SizedBox(height: 28),
                _buildRecentHistory(context, progress),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOverviewCard(BuildContext context, ProgressService progress) {
    final level = _getLevel(progress.totalQuizzes);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.accentCyan.withOpacity(0.15),
            AppColors.accentViolet.withOpacity(0.1),
            AppColors.surfaceCard,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.accentCyan.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.accentCyan, AppColors.accentViolet],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentCyan.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: Text(
                level['emoji'] as String,
                style: const TextStyle(fontSize: 36),
              ),
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                begin: const Offset(1, 1),
                end: const Offset(1.05, 1.05),
                duration: 2000.ms,
              ),
          const SizedBox(height: 16),
          Text(
            level['title'] as String,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.accentCyan,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            level['description'] as String,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms);
  }

  Map<String, String> _getLevel(int totalQuizzes) {
    if (totalQuizzes >= 50) {
      return {'emoji': '🏆', 'title': 'Master Scholar', 'description': 'Incredible dedication! You are a true expert.'};
    } else if (totalQuizzes >= 25) {
      return {'emoji': '⭐', 'title': 'Star Learner', 'description': 'Amazing progress! Keep pushing forward.'};
    } else if (totalQuizzes >= 10) {
      return {'emoji': '🚀', 'title': 'Rising Star', 'description': 'Great momentum! You are growing fast.'};
    } else if (totalQuizzes >= 5) {
      return {'emoji': '📖', 'title': 'Active Learner', 'description': 'Nice! You are building great habits.'};
    } else if (totalQuizzes >= 1) {
      return {'emoji': '🌱', 'title': 'Beginner', 'description': 'Welcome! Your learning journey begins.'};
    }
    return {'emoji': '✨', 'title': 'New Explorer', 'description': 'Take your first quiz to start tracking progress!'};
  }

  Widget _buildStatsGrid(BuildContext context, ProgressService progress) {
    return Row(
      children: [
        Expanded(
          child: StatCard(
            icon: Icons.local_fire_department_rounded,
            value: '${progress.currentStreak}',
            label: 'Day Streak',
            accentColor: AppColors.accentOrange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatCard(
            icon: Icons.check_circle_rounded,
            value: '${progress.totalQuizzes}',
            label: 'Quizzes',
            accentColor: AppColors.accentCyan,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatCard(
            icon: Icons.trending_up_rounded,
            value: '${progress.accuracy.toStringAsFixed(0)}%',
            label: 'Accuracy',
            accentColor: AppColors.accentGreen,
          ),
        ),
      ],
    ).animate().fadeIn(delay: 200.ms, duration: 600.ms);
  }

  Widget _buildAchievements(BuildContext context, ProgressService progress) {
    final achievements = <Map<String, dynamic>>[];

    if (progress.totalQuizzes >= 1) {
      achievements.add({'icon': Icons.star_rounded, 'title': 'First Quiz', 'color': AppColors.accentCyan});
    }
    if (progress.totalQuizzes >= 5) {
      achievements.add({'icon': Icons.auto_awesome_rounded, 'title': '5 Quizzes', 'color': AppColors.accentViolet});
    }
    if (progress.totalQuizzes >= 10) {
      achievements.add({'icon': Icons.emoji_events_rounded, 'title': '10 Quizzes', 'color': AppColors.accentOrange});
    }
    if (progress.currentStreak >= 3) {
      achievements.add({'icon': Icons.local_fire_department_rounded, 'title': '3-Day Streak', 'color': AppColors.error});
    }
    if (progress.currentStreak >= 7) {
      achievements.add({'icon': Icons.whatshot_rounded, 'title': 'Week Streak', 'color': AppColors.accentPink});
    }
    if (progress.accuracy >= 80 && progress.totalQuizzes >= 3) {
      achievements.add({'icon': Icons.workspace_premium_rounded, 'title': '80%+ Accuracy', 'color': AppColors.accentGreen});
    }
    if (progress.conversationCount >= 5) {
      achievements.add({'icon': Icons.chat_rounded, 'title': 'Conversationalist', 'color': AppColors.accentPink});
    }

    if (achievements.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Achievements',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textMuted,
              ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: achievements.map((a) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: (a['color'] as Color).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (a['color'] as Color).withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(a['icon'] as IconData, color: a['color'] as Color, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    a['title'] as String,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: a['color'] as Color,
                        ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildSubjectBreakdown(BuildContext context, ProgressService progress) {
    final stats = progress.subjectStats;
    if (stats.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Subjects',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textMuted,
              ),
        ),
        const SizedBox(height: 14),
        ...stats.entries.map((entry) {
          final data = entry.value as Map<String, dynamic>;
          final correct = data['correct'] as int? ?? 0;
          final total = data['total'] as int? ?? 1;
          final quizzes = data['quizzes'] as int? ?? 0;
          final accuracy = total > 0 ? correct / total : 0.0;

          return Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.textMuted.withOpacity(0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      entry.key,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      '$quizzes quizzes',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: accuracy,
                    backgroundColor: AppColors.surfaceElevated,
                    color: _getAccuracyColor(accuracy * 100),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${(accuracy * 100).toStringAsFixed(0)}% accuracy • $correct/$total correct',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _getAccuracyColor(accuracy * 100),
                      ),
                ),
              ],
            ),
          );
        }),
      ],
    ).animate().fadeIn(delay: 400.ms);
  }

  Color _getAccuracyColor(double accuracy) {
    if (accuracy >= 80) return AppColors.accentGreen;
    if (accuracy >= 60) return AppColors.accentCyan;
    if (accuracy >= 40) return AppColors.accentOrange;
    return AppColors.error;
  }

  Widget _buildRecentHistory(BuildContext context, ProgressService progress) {
    final history = progress.quizHistory;
    if (history.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.textMuted.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Icon(Icons.history_rounded, size: 40, color: AppColors.textMuted.withOpacity(0.5)),
            const SizedBox(height: 12),
            Text(
              'No quiz history yet',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 4),
            Text(
              'Complete a quiz to see your progress here',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ).animate().fadeIn(delay: 500.ms);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Quizzes',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textMuted,
              ),
        ),
        const SizedBox(height: 14),
        ...history.take(10).map((entry) {
          final correct = entry['correct'] as int? ?? 0;
          final total = entry['total'] as int? ?? 0;
          final subject = entry['subject'] as String? ?? 'Unknown';
          final difficulty = entry['difficulty'] as String? ?? '';
          final date = entry['date'] as String? ?? '';
          final accuracy = total > 0 ? (correct / total * 100) : 0;

          String formattedDate = '';
          try {
            final dt = DateTime.parse(date);
            formattedDate = '${dt.day}/${dt.month}/${dt.year}';
          } catch (_) {}

          return Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _getAccuracyColor(accuracy.toDouble()).withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getAccuracyColor(accuracy.toDouble()).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      '${accuracy.toStringAsFixed(0)}%',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: _getAccuracyColor(accuracy.toDouble()),
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(subject, style: Theme.of(context).textTheme.labelLarge),
                      Text(
                        '$correct/$total correct • ${difficulty}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (formattedDate.isNotEmpty)
                  Text(
                    formattedDate,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                  ),
              ],
            ),
          );
        }),
      ],
    ).animate().fadeIn(delay: 500.ms);
  }
}
