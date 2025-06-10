import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum StatusType { success, warning, error, info }

class StatusCard extends StatelessWidget {
  final String title;
  final String message;
  final StatusType type;
  final IconData? icon;
  final VoidCallback? onTap;

  const StatusCard({
    super.key,
    required this.title,
    required this.message,
    required this.type,
    this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _getColors();
    final defaultIcon = _getDefaultIcon();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors['border']!, width: 1),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors['background'],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon ?? defaultIcon,
                  color: colors['icon'],
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
                        fontWeight: FontWeight.w600,
                        color: colors['text'],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors['text']?.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.chevron_right,
                  color: colors['icon'],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, Color> _getColors() {
    switch (type) {
      case StatusType.success:
        return {
          'background': AppTheme.successGreen.withOpacity(0.1),
          'border': AppTheme.successGreen.withOpacity(0.3),
          'icon': AppTheme.successGreen,
          'text': AppTheme.textDark,
        };
      case StatusType.warning:
        return {
          'background': AppTheme.accentGold.withOpacity(0.1),
          'border': AppTheme.accentGold.withOpacity(0.3),
          'icon': AppTheme.accentGold,
          'text': AppTheme.textDark,
        };
      case StatusType.error:
        return {
          'background': AppTheme.errorRed.withOpacity(0.1),
          'border': AppTheme.errorRed.withOpacity(0.3),
          'icon': AppTheme.errorRed,
          'text': AppTheme.textDark,
        };
      case StatusType.info:
        return {
          'background': AppTheme.primaryGreen.withOpacity(0.1),
          'border': AppTheme.primaryGreen.withOpacity(0.3),
          'icon': AppTheme.primaryGreen,
          'text': AppTheme.textDark,
        };
    }
  }

  IconData _getDefaultIcon() {
    switch (type) {
      case StatusType.success:
        return Icons.check_circle;
      case StatusType.warning:
        return Icons.warning;
      case StatusType.error:
        return Icons.error;
      case StatusType.info:
        return Icons.info;
    }
  }
}