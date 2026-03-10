import 'package:flutter/material.dart';
import 'package:safe_alert/theme/app_theme.dart';

class StatusBadge extends StatelessWidget {
  final bool isSafe;

  const StatusBadge({super.key, required this.isSafe});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: isSafe
            ? AppTheme.safeGreen.withOpacity(0.15)
            : AppTheme.accentRed.withOpacity(0.15),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: isSafe ? AppTheme.safeGreen : AppTheme.accentRed,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSafe ? Icons.check_circle : Icons.error,
            color: isSafe ? AppTheme.safeGreen : AppTheme.accentRed,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            isSafe ? 'Safe' : 'SOS Sent',
            style: TextStyle(
              color: isSafe ? AppTheme.safeGreen : AppTheme.accentRed,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
