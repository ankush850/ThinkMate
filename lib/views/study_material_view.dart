import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../services/document_service.dart';
import '../theme/app_theme.dart';
import 'quiz_session_view.dart';
import 'concept_simplifier_view.dart';
import 'voice_study_view.dart';

class StudyMaterialView extends StatelessWidget {
  final DocumentData document;

  const StudyMaterialView({super.key, required this.document});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: AppBar(
        title: Text(
          document.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDocumentHeader(context),
            const SizedBox(height: 28),
            Text(
              'Study with AI',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textMuted,
                  ),
            ).animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 16),
            _buildActionCard(
              context,
              icon: Icons.quiz_rounded,
              title: 'Quiz Me',
              subtitle: 'Test your knowledge with AI-generated questions from this material',
              gradientColors: [AppColors.accentCyan, const Color(0xFF0EA5E9)],
              onTap: () => _openQuiz(context),
            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
            const SizedBox(height: 14),
            _buildActionCard(
              context,
              icon: Icons.lightbulb_rounded,
              title: 'Explain Concepts',
              subtitle: 'Ask AI to simplify and explain topics from your study material',
              gradientColors: [AppColors.accentViolet, const Color(0xFF7C3AED)],
              onTap: () => _openSimplifier(context),
            ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1),
            const SizedBox(height: 14),
            _buildActionCard(
              context,
              icon: Icons.mic_rounded,
              title: 'Talk About It',
              subtitle: 'Have a voice conversation with AI about your study material',
              gradientColors: [AppColors.accentPink, const Color(0xFFDB2777)],
              onTap: () => _openVoiceStudy(context),
            ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1),
            const SizedBox(height: 28),
            _buildContentPreview(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.accentCyan.withOpacity(0.12),
            AppColors.surfaceCard,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accentCyan.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.accentCyan.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.picture_as_pdf_rounded,
              size: 40,
              color: AppColors.accentCyan,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            document.title,
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 8,
            children: [
              _buildMetaBadge(context, Icons.description_rounded, '${document.pageCount} pages'),
              _buildMetaBadge(context, Icons.text_snippet_rounded, '${document.chunks.length} chunks'),
              _buildMetaBadge(context, Icons.text_fields_rounded, '${document.totalWords} words'),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms);
  }

  Widget _buildMetaBadge(BuildContext context, IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textMuted),
          const SizedBox(width: 4),
          Text(text, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: gradientColors[0].withOpacity(0.2),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradientColors),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: gradientColors[0].withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColors.textMuted,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContentPreview(BuildContext context) {
    final preview = document.chunks.isNotEmpty
        ? document.chunks.first.substring(
            0,
            document.chunks.first.length > 300
                ? 300
                : document.chunks.first.length,
          )
        : 'No content extracted.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Content Preview',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textMuted,
              ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard.withOpacity(0.5),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.textMuted.withOpacity(0.1)),
          ),
          child: Text(
            '$preview...',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
            maxLines: 8,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ).animate().fadeIn(delay: 700.ms);
  }

  void _openQuiz(BuildContext context) {
    final docService = context.read<DocumentService>();
    docService.setActiveDocument(document);
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            QuizSessionView(
          subject: document.title,
          documentContext: document,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  void _openSimplifier(BuildContext context) {
    final docService = context.read<DocumentService>();
    docService.setActiveDocument(document);
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            ConceptSimplifierView(document: document),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  void _openVoiceStudy(BuildContext context) {
    final docService = context.read<DocumentService>();
    docService.setActiveDocument(document);
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            VoiceStudyView(document: document),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }
}
