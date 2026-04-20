import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

/// Multiple choice answer card with selection animation
class QuizOptionCard extends StatelessWidget {
  final String label;
  final String text;
  final bool isSelected;
  final bool? isCorrect; // null = not revealed, true/false after answer
  final bool isRevealed;
  final VoidCallback? onTap;

  const QuizOptionCard({
    super.key,
    required this.label,
    required this.text,
    required this.isSelected,
    this.isCorrect,
    this.isRevealed = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color borderColor = AppColors.textMuted.withOpacity(0.2);
    Color bgColor = AppColors.surfaceCard;
    Color labelColor = AppColors.textSecondary;
    Color textColor = AppColors.textPrimary;
    IconData? trailingIcon;

    if (isRevealed) {
      if (isCorrect == true) {
        borderColor = AppColors.success;
        bgColor = AppColors.success.withOpacity(0.1);
        labelColor = AppColors.success;
        trailingIcon = Icons.check_circle_rounded;
      } else if (isSelected && isCorrect == false) {
        borderColor = AppColors.error;
        bgColor = AppColors.error.withOpacity(0.1);
        labelColor = AppColors.error;
        textColor = AppColors.error;
        trailingIcon = Icons.cancel_rounded;
      }
    } else if (isSelected) {
      borderColor = AppColors.accentCyan;
      bgColor = AppColors.accentCyan.withOpacity(0.1);
      labelColor = AppColors.accentCyan;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isRevealed ? null : onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: labelColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: labelColor,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  text,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: textColor,
                      ),
                ),
              ),
              if (trailingIcon != null)
                Icon(trailingIcon, color: labelColor, size: 24)
                    .animate()
                    .scale(begin: const Offset(0, 0), duration: 300.ms, curve: Curves.elasticOut),
            ],
          ),
        ),
      ),
    );
  }
}
