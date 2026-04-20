import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

class InstructionsView extends StatelessWidget {
  const InstructionsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'How to Use',
          style: TextStyle(
              color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildIntroSection(context)
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: 0.1),
              const SizedBox(height: 32),
              _buildStepCard(
                context: context,
                stepNumber: '1',
                title: 'Download AI Models',
                description:
                    'To work 100% offline, ThinkMate needs to download three specialized AI models (LLM, Voice, and Speech). You only need to do this once during the initial setup.',
                icon: Icons.download_for_offline_rounded,
                color: AppColors.accentViolet,
                delay: 200,
              ),
              _buildStepCard(
                context: context,
                stepNumber: '2',
                title: 'Upload a Study Document',
                description:
                    'Tap the large "Upload Material" button on the Home screen to pick any PDF document from your device. ThinkMate will extract the text and save it for offline access.',
                icon: Icons.upload_file_rounded,
                color: AppColors.accentCyan,
                delay: 400,
              ),
              _buildStepCard(
                context: context,
                stepNumber: '3',
                title: 'Choose a Learning Module',
                description:
                    'Once uploaded, tap on the document in your Recent Materials list. You can then select from interactive modules like Concept Simplifier, Talk About It, or Quiz Mode.',
                icon: Icons.dashboard_customize_rounded,
                color: AppColors.accentViolet,
                delay: 600,
              ),
              _buildStepCard(
                context: context,
                stepNumber: '4',
                title: 'Talk to your AI Tutor',
                description:
                    'Use the "Talk About It" module for a real-time voice conversation. The AI listens to your voice, studies the document, and talks back to you completely offline!',
                icon: Icons.record_voice_over_rounded,
                color: AppColors.accentPink,
                delay: 800,
              ),
              _buildStepCard(
                context: context,
                stepNumber: '5',
                title: 'Test your Knowledge',
                description:
                    'Open the "Quiz Mode" module. The AI will generate custom multiple-choice questions based specifically on the document you uploaded, complete with detailed explanations.',
                icon: Icons.quiz_rounded,
                color: AppColors.accentGreen,
                delay: 1000,
              ),
              const SizedBox(height: 32),
              Center(
                child: Text(
                  'ThinkMate runs 100% offline. No internet required.\nEverything stays on your device.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                ).animate().fadeIn(delay: 1000.ms),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIntroSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accentCyan.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.accentCyan.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.psychology_rounded,
              color: AppColors.accentCyan,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome to ThinkMate!',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your personal, offline AI study companion.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepCard({
    required BuildContext context,
    required String stepNumber,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required int delay,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    stepNumber,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Icon(icon, color: color.withOpacity(0.5), size: 24),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ).animate().fadeIn(delay: delay.ms).slideY(begin: 0.1),
    );
  }
}
