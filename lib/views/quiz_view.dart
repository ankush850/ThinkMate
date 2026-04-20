import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../services/model_service.dart';
import '../theme/app_theme.dart';
import '../widgets/model_loader_widget.dart';
import '../widgets/subject_chip.dart';
import 'quiz_session_view.dart';

class QuizView extends StatefulWidget {
  const QuizView({super.key});

  @override
  State<QuizView> createState() => _QuizViewState();
}

class _QuizViewState extends State<QuizView> {
  String? _selectedSubject;
  final TextEditingController _customTopicController = TextEditingController();

  static const List<Map<String, dynamic>> _subjects = [
    {'label': 'Mathematics', 'icon': Icons.calculate_rounded, 'color': AppColors.accentCyan},
    {'label': 'Science', 'icon': Icons.science_rounded, 'color': AppColors.accentViolet},
    {'label': 'History', 'icon': Icons.history_edu_rounded, 'color': AppColors.accentOrange},
    {'label': 'Geography', 'icon': Icons.public_rounded, 'color': AppColors.accentGreen},
    {'label': 'English', 'icon': Icons.menu_book_rounded, 'color': AppColors.accentPink},
    {'label': 'Computer Science', 'icon': Icons.computer_rounded, 'color': AppColors.accentCyan},
    {'label': 'Physics', 'icon': Icons.bolt_rounded, 'color': AppColors.accentOrange},
    {'label': 'Biology', 'icon': Icons.biotech_rounded, 'color': AppColors.accentGreen},
  ];

  @override
  void dispose() {
    _customTopicController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: AppBar(
        title: const Text('AI Quiz'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Consumer<ModelService>(
        builder: (context, modelService, child) {
          if (!modelService.isLLMLoaded) {
            return ModelLoaderWidget(
              title: 'LLM Model Required',
              subtitle: 'Download the AI model to generate personalized quizzes',
              icon: Icons.quiz_rounded,
              accentColor: AppColors.accentCyan,
              isDownloading: modelService.isLLMDownloading,
              isLoading: modelService.isLLMLoading,
              progress: modelService.llmDownloadProgress,
              onLoad: () => modelService.downloadAndLoadLLM(),
            );
          }

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeaderCard(context),
                      const SizedBox(height: 28),
                      Text(
                        'Choose a Subject',
                        style: Theme.of(context).textTheme.titleMedium,
                      ).animate().fadeIn(delay: 100.ms),
                      const SizedBox(height: 14),
                      _buildSubjectGrid(context),
                      const SizedBox(height: 24),
                      Text(
                        'Or enter a custom topic',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppColors.textMuted,
                            ),
                      ).animate().fadeIn(delay: 300.ms),
                      const SizedBox(height: 12),
                      _buildCustomTopicInput(context),
                    ],
                  ),
                ),
              ),
              _buildStartButton(context),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.accentCyan.withOpacity(0.1),
            AppColors.surfaceCard,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.accentCyan.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.accentCyan.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.quiz_rounded, size: 36, color: AppColors.accentCyan),
          ),
          const SizedBox(height: 16),
          Text(
            'Adaptive AI Quiz',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'The AI adjusts difficulty based on your performance.\n10 questions per quiz.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms);
  }

  Widget _buildSubjectGrid(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _subjects.map((s) {
        return SubjectChip(
          label: s['label'] as String,
          icon: s['icon'] as IconData,
          color: s['color'] as Color,
          isSelected: _selectedSubject == s['label'],
          onTap: () {
            setState(() {
              _selectedSubject = s['label'] as String;
              _customTopicController.clear();
            });
          },
        );
      }).toList(),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildCustomTopicInput(BuildContext context) {
    return TextField(
      controller: _customTopicController,
      decoration: InputDecoration(
        hintText: 'e.g., "World War II", "Algebra", "Photosynthesis"',
        prefixIcon: const Icon(Icons.edit_rounded, color: AppColors.textMuted),
        filled: true,
        fillColor: AppColors.surfaceCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.textMuted.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.accentCyan, width: 2),
        ),
      ),
      onChanged: (value) {
        if (value.isNotEmpty) {
          setState(() => _selectedSubject = null);
        }
      },
    ).animate().fadeIn(delay: 350.ms);
  }

  Widget _buildStartButton(BuildContext context) {
    final topic = _customTopicController.text.trim().isNotEmpty
        ? _customTopicController.text.trim()
        : _selectedSubject;
    final isEnabled = topic != null && topic.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard.withOpacity(0.8),
        border: Border(
          top: BorderSide(color: AppColors.textMuted.withOpacity(0.1)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: GestureDetector(
          onTap: isEnabled
              ? () {
                  Navigator.of(context).push(
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          QuizSessionView(subject: topic),
                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                      transitionDuration: const Duration(milliseconds: 300),
                    ),
                  );
                }
              : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 60,
            decoration: BoxDecoration(
              gradient: isEnabled
                  ? const LinearGradient(
                      colors: [AppColors.accentCyan, Color(0xFF0EA5E9)],
                    )
                  : null,
              color: isEnabled ? null : AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(30),
              boxShadow: isEnabled
                  ? [
                      BoxShadow(
                        color: AppColors.accentCyan.withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.play_arrow_rounded,
                    color: isEnabled ? Colors.white : AppColors.textMuted,
                    size: 28,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Start Quiz',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: isEnabled ? Colors.white : AppColors.textMuted,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
