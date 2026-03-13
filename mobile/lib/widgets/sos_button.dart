import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:safe_alert/theme/app_theme.dart';

class SOSButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isActive;

  const SOSButton({
    super.key,
    required this.onPressed,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: isActive ? null : onPressed,
      child: Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: isActive
                ? [Colors.orange, Colors.deepOrange]
                : [const Color(0xFFFF4444), const Color(0xFFCC0000)],
          ),
          boxShadow: [
            BoxShadow(
              color: (isActive ? Colors.orange : Colors.red).withOpacity(0.5),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: Colors.white, size: 48),
              const SizedBox(height: 8),
              Text(
                isActive ? 'ACTIVE' : 'SOS',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                ),
              ),
              if (!isActive)
                Text(
                  'HOLD TO ACTIVATE',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 2,
                  ),
                ),
            ],
          ),
        ),
      )
          .animate(
            onPlay: (controller) => controller.repeat(reverse: true),
          )
          .scale(
            begin: const Offset(1.0, 1.0),
            end: const Offset(1.05, 1.05),
            duration: 1500.ms,
            curve: Curves.easeInOut,
          ),
    );
  }
}
