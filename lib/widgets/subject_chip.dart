import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Subject category chip for quiz topic selection
class SubjectChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const SubjectChip({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.2) : AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? color : AppColors.textMuted.withOpacity(0.15),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: isSelected ? color : AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
