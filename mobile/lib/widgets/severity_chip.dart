import 'package:flutter/material.dart';
import 'package:safe_alert/theme/app_theme.dart';

class SeverityChip extends StatelessWidget {
  final String severity;

  const SeverityChip({super.key, required this.severity});

  Color get _color {
    switch (severity.toUpperCase()) {
      case 'HIGH':
        return AppTheme.accentRed;
      case 'MEDIUM':
        return AppTheme.warningYellow;
      case 'LOW':
        return AppTheme.safeGreen;
      default:
        return AppTheme.textSecondary;
    }
  }

  IconData get _icon {
    switch (severity.toUpperCase()) {
      case 'HIGH':
        return Icons.error;
      case 'MEDIUM':
        return Icons.warning;
      case 'LOW':
        return Icons.info;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, color: _color, size: 18),
          const SizedBox(width: 6),
          Text(
            severity.toUpperCase(),
            style: TextStyle(
              color: _color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
