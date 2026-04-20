import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../services/model_service.dart';
import '../theme/app_theme.dart';
import 'home_view.dart';

class ModelSetupView extends StatefulWidget {
  const ModelSetupView({super.key});

  @override
  State<ModelSetupView> createState() => _ModelSetupViewState();
}

class _ModelSetupViewState extends State<ModelSetupView> {
  bool _isDownloading = false;
  bool _allDone = false;
  String _errorMessage = '';

  Future<void> _startDownload(ModelService modelService) async {
    setState(() {
      _isDownloading = true;
      _errorMessage = '';
    });

    try {
      // Start all downloads concurrently
      await modelService.downloadAndLoadAllModels();

      if (mounted) {
        // Verify all were downloaded successfully
        final allDownloaded = await modelService.areAllModelsDownloaded();
        if (allDownloaded) {
          setState(() {
            _allDone = true;
            _isDownloading = false;
          });
        } else {
          setState(() {
            _isDownloading = false;
            _errorMessage = 'Some models failed to download completely.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _errorMessage = 'Error downloading models: $e';
        });
      }
    }
  }

  void _continueToApp() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const HomeView(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      body: SafeArea(
        child: Consumer<ModelService>(
          builder: (context, modelService, child) {
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.accentCyan, AppColors.accentViolet],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accentViolet.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.model_training_rounded,
                        size: 48,
                        color: Colors.white,
                      ),
                    ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
                    const SizedBox(height: 32),
                    Text(
                      'Setup AI Models',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1),
                    const SizedBox(height: 12),
                    Text(
                      'ThinkMate runs entirely on-device to protect your privacy and work offline. We need to download three AI models to get started (~1.5 GB total).',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                    ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.1),
                    const SizedBox(height: 32),
                    
                    // Progress list
                    _buildModelProgressRow(
                      context,
                      title: 'Language Model (LLM)',
                      subtitle: 'Powers concepts & quizzes',
                      icon: Icons.memory_rounded,
                      color: AppColors.accentCyan,
                      isDownloading: modelService.isLLMDownloading,
                      isLoading: modelService.isLLMLoading,
                      progress: modelService.llmDownloadProgress,
                      isDone: modelService.isLLMLoaded || _allDone,
                    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
                    const SizedBox(height: 16),
                    _buildModelProgressRow(
                      context,
                      title: 'Speech to Text (STT)',
                      subtitle: 'Understands your voice',
                      icon: Icons.mic_rounded,
                      color: AppColors.accentPink,
                      isDownloading: modelService.isSTTDownloading,
                      isLoading: modelService.isSTTLoading,
                      progress: modelService.sttDownloadProgress,
                      isDone: modelService.isSTTLoaded || _allDone,
                    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1),
                    const SizedBox(height: 16),
                    _buildModelProgressRow(
                      context,
                      title: 'Text to Speech (TTS)',
                      subtitle: 'Talks back to you',
                      icon: Icons.volume_up_rounded,
                      color: AppColors.accentViolet,
                      isDownloading: modelService.isTTSDownloading,
                      isLoading: modelService.isTTSLoading,
                      progress: modelService.ttsDownloadProgress,
                      isDone: modelService.isTTSLoaded || _allDone,
                    ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1),
                    const SizedBox(height: 32),

                    if (_errorMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Text(
                          _errorMessage,
                          style: const TextStyle(color: AppColors.error),
                        ),
                      ),

                    // Bottom Action Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isDownloading
                            ? null
                            : (_allDone ? _continueToApp : () => _startDownload(modelService)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _allDone ? AppColors.accentGreen : AppColors.accentCyan,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          elevation: _isDownloading ? 0 : 8,
                          shadowColor: (_allDone ? AppColors.accentGreen : AppColors.accentCyan)
                              .withOpacity(0.4),
                        ),
                        child: _isDownloading
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Flexible(
                                    child: Text(
                                      'Downloading... Please wait',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              )
                            : Text(
                                _allDone ? 'Continue to App' : 'Download Models',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.2),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildModelProgressRow(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isDownloading,
    required bool isLoading,
    required double progress,
    required bool isDone,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDone ? AppColors.accentGreen.withOpacity(0.3) : color.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDone ? AppColors.accentGreen.withOpacity(0.1) : color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isDone ? Icons.check_circle_rounded : icon,
              color: isDone ? AppColors.accentGreen : color,
              size: 24,
            ),
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
                      ),
                ),
                const SizedBox(height: 4),
                if (isDownloading) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: color.withOpacity(0.1),
                      color: color,
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(progress * 100).toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: color,
                        ),
                  ),
                ] else if (isLoading) ...[
                  const LinearProgressIndicator(minHeight: 2),
                  const SizedBox(height: 4),
                  Text('Loading into memory...', style: Theme.of(context).textTheme.bodySmall),
                ] else ...[
                  Text(
                    isDone ? 'Ready' : subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDone ? AppColors.accentGreen : AppColors.textMuted,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
