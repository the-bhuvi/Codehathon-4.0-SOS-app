import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safe_alert/providers/app_providers.dart';
import 'package:safe_alert/theme/app_theme.dart';
import 'package:safe_alert/widgets/sos_button.dart';
import 'package:safe_alert/widgets/status_badge.dart';
import 'package:safe_alert/screens/confirmation/confirmation_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _showMessageDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '🚨 Describe Your Emergency',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _messageController,
              maxLines: 3,
              autofocus: true,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'Type your distress message...',
                hintStyle: TextStyle(
                    color: AppTheme.textSecondary.withOpacity(0.5)),
                filled: true,
                fillColor: AppTheme.cardDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppTheme.accentRed, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      _messageController.clear();
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.textSecondary),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Cancel',
                        style: TextStyle(color: AppTheme.textSecondary)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _triggerSOS();
                    },
                    icon: const Icon(Icons.send, color: Colors.white),
                    label: const Text('SEND SOS',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentRed,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _triggerSOS() async {
    final message = _messageController.text.trim();
    _messageController.clear();

    ref.read(sosProvider.notifier).sendSOS(message);

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ConfirmationScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sosState = ref.watch(sosProvider);
    final locationAsync = ref.watch(currentLocationProvider);
    final isSafe = sosState.status == SOSStatus.idle ||
        sosState.status == SOSStatus.cancelled;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shield, color: AppTheme.accentRed, size: 24),
            SizedBox(width: 8),
            Text('SafeAlert'),
          ],
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            children: [
              const SizedBox(height: 24),
              StatusBadge(isSafe: isSafe),
              const Spacer(),
              SOSButton(
                onPressed: _showMessageDialog,
                isActive: !isSafe,
              ),
              const SizedBox(height: 32),
              // Location display
              locationAsync.when(
                data: (position) {
                  if (position == null) {
                    return const _LocationRow(
                      icon: Icons.location_off,
                      text: 'Location unavailable',
                      color: AppTheme.textSecondary,
                    );
                  }
                  return _LocationRow(
                    icon: Icons.location_on,
                    text:
                        '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}',
                    color: AppTheme.safeGreen,
                  );
                },
                loading: () => const _LocationRow(
                  icon: Icons.my_location,
                  text: 'Getting location...',
                  color: AppTheme.warningYellow,
                ),
                error: (_, __) => const _LocationRow(
                  icon: Icons.location_off,
                  text: 'Location error',
                  color: AppTheme.accentRed,
                ),
              ),
              const Spacer(),
              // Emergency contacts quick view
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.contacts,
                                color: AppTheme.accentOrange, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Emergency Contacts',
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap Settings to manage your emergency contacts',
                          style: TextStyle(
                            color: AppTheme.textSecondary.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocationRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _LocationRow({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(color: color, fontSize: 14),
        ),
      ],
    );
  }
}
