import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../services/document_service.dart';
import '../services/model_service.dart';
import '../theme/app_theme.dart';
import '../widgets/model_loader_widget.dart';
import 'study_material_view.dart';

class DocumentUploadView extends StatelessWidget {
  const DocumentUploadView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: AppBar(
        title: const Text('Study Materials'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Consumer2<DocumentService, ModelService>(
        builder: (context, docService, modelService, child) {
          if (!modelService.isLLMLoaded) {
            return ModelLoaderWidget(
              title: 'LLM Model Required',
              subtitle: 'Download the AI model to study your materials',
              icon: Icons.menu_book_rounded,
              accentColor: AppColors.accentCyan,
              isDownloading: modelService.isLLMDownloading,
              isLoading: modelService.isLLMLoading,
              progress: modelService.llmDownloadProgress,
              onLoad: () => modelService.downloadAndLoadLLM(),
            );
          }

          return Column(
            children: [
              if (docService.isProcessing) _buildProcessingBanner(context, docService),
              Expanded(
                child: docService.documents.isEmpty
                    ? _buildEmptyState(context, docService)
                    : _buildDocumentList(context, docService),
              ),
              _buildUploadButton(context, docService),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProcessingBanner(BuildContext context, DocumentService docService) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.accentCyan.withOpacity(0.15),
            AppColors.surfaceCard,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accentCyan.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              color: AppColors.accentCyan,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            docService.processingStatus,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.accentCyan,
                ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildEmptyState(BuildContext context, DocumentService docService) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppColors.accentCyan.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.picture_as_pdf_rounded,
                size: 56,
                color: AppColors.accentCyan,
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.05, 1.05),
                  duration: 2000.ms,
                ),
            const SizedBox(height: 28),
            Text(
              'Upload Study Material',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            Text(
              'Upload a PDF and ThinkMate will help you\nlearn from it with quizzes, explanations,\nand voice conversations.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _buildFeatureRow(context, Icons.quiz_rounded, 'Generate quizzes from your material'),
            const SizedBox(height: 12),
            _buildFeatureRow(context, Icons.lightbulb_rounded, 'Get AI explanations of concepts'),
            const SizedBox(height: 12),
            _buildFeatureRow(context, Icons.mic_rounded, 'Voice conversations about topics'),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 600.ms);
  }

  Widget _buildFeatureRow(BuildContext context, IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: AppColors.accentCyan, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentList(BuildContext context, DocumentService docService) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: docService.documents.length,
      itemBuilder: (context, index) {
        final doc = docService.documents[index];
        return Dismissible(
          key: Key(doc.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.delete_rounded, color: AppColors.error),
          ),
          onDismissed: (_) => docService.deleteDocument(doc.id),
          child: _buildDocumentCard(context, doc, docService),
        ).animate().fadeIn(delay: (index * 80).ms).slideX(begin: 0.05);
      },
    );
  }

  Widget _buildDocumentCard(
      BuildContext context, DocumentData doc, DocumentService docService) {
    final dateStr =
        '${doc.uploadDate.day}/${doc.uploadDate.month}/${doc.uploadDate.year}';
    return GestureDetector(
      onTap: () {
        docService.setActiveDocument(doc);
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                StudyMaterialView(document: doc),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.textMuted.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accentCyan.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.picture_as_pdf_rounded,
                color: AppColors.accentCyan,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doc.title,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${doc.pageCount} pages • ${doc.chunks.length} chunks • ${doc.totalWords} words',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Uploaded $dateStr',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadButton(BuildContext context, DocumentService docService) {
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
          onTap: docService.isProcessing
              ? null
              : () async {
                  final doc = await docService.pickAndProcessPdf();
                  if (doc != null && context.mounted) {
                    Navigator.of(context).push(
                      PageRouteBuilder(
                        pageBuilder:
                            (context, animation, secondaryAnimation) =>
                                StudyMaterialView(document: doc),
                        transitionsBuilder:
                            (context, animation, secondaryAnimation, child) {
                          return FadeTransition(
                              opacity: animation, child: child);
                        },
                        transitionDuration: const Duration(milliseconds: 300),
                      ),
                    );
                  }
                },
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              gradient: docService.isProcessing
                  ? null
                  : const LinearGradient(
                      colors: [AppColors.accentCyan, Color(0xFF0EA5E9)],
                    ),
              color: docService.isProcessing ? AppColors.surfaceElevated : null,
              borderRadius: BorderRadius.circular(30),
              boxShadow: docService.isProcessing
                  ? null
                  : [
                      BoxShadow(
                        color: AppColors.accentCyan.withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
            ),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.upload_file_rounded,
                    color: docService.isProcessing
                        ? AppColors.textMuted
                        : Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Upload PDF',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: docService.isProcessing
                              ? AppColors.textMuted
                              : Colors.white,
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
