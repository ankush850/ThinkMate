import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_theme.dart';

class ModelLoaderWidget extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final bool isDownloading;
  final bool isLoading;
  final double progress;
  final VoidCallback onLoad;

  const ModelLoaderWidget({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.isDownloading,
    required this.isLoading,
    required this.progress,
    required this.onLoad,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: accentColor.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Icon(
                icon,
                size: 64,
                color: accentColor,
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.05, 1.05),
                  duration: 2000.ms,
                ),
            const SizedBox(height: 32),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (isDownloading) ...[
              SizedBox(
                width: 240,
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: AppColors.surfaceCard,
                        color: accentColor,
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Downloading... ${(progress * 100).toStringAsFixed(1)}%',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: accentColor,
                          ),
                    ),
                  ],
                ),
              ),
            ] else if (isLoading) ...[
              CircularProgressIndicator(color: accentColor),
              const SizedBox(height: 16),
              Text(
                'Loading model...',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: accentColor,
                    ),
              ),
            ] else ...[
              ElevatedButton.icon(
                onPressed: onLoad,
                icon: const Icon(Icons.download_rounded),
                label: const Text('Download & Load'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.textMuted.withOpacity(0.1),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.textMuted,
                    size: 18,
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      'Models are downloaded once and stored locally',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 600.ms);
  }
}
