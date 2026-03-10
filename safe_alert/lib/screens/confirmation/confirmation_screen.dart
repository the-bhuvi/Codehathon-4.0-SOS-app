import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:safe_alert/providers/app_providers.dart';
import 'package:safe_alert/theme/app_theme.dart';
import 'package:safe_alert/widgets/severity_chip.dart';

class ConfirmationScreen extends ConsumerStatefulWidget {
  const ConfirmationScreen({super.key});

  @override
  ConsumerState<ConfirmationScreen> createState() => _ConfirmationScreenState();
}

class _ConfirmationScreenState extends ConsumerState<ConfirmationScreen> {
  late Timer _timer;
  int _elapsedSeconds = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _elapsedSeconds++);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String get _formattedTime {
    final minutes = _elapsedSeconds ~/ 60;
    final seconds = _elapsedSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final sosState = ref.watch(sosProvider);
    final locationAsync = ref.watch(currentLocationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SOS Active'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: AppTheme.accentRed.withOpacity(0.3),
      ),
      body: SafeArea(
        child: switch (sosState.status) {
          SOSStatus.sending => const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppTheme.accentRed),
                  SizedBox(height: 24),
                  Text(
                    'Sending SOS...',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Getting your location and contacting help',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
          SOSStatus.failed => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline,
                      color: AppTheme.accentRed, size: 80),
                  const SizedBox(height: 16),
                  const Text(
                    'Failed to Send SOS',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      sosState.errorMessage ?? 'Unknown error',
                      textAlign: TextAlign.center,
                      style:
                          const TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      ref.read(sosProvider.notifier).reset();
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    label: const Text('Try Again',
                        style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentRed,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
          SOSStatus.cancelled => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle,
                      color: AppTheme.safeGreen, size: 80),
                  const SizedBox(height: 16),
                  const Text(
                    'SOS Cancelled',
                    style: TextStyle(
                      color: AppTheme.safeGreen,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Incident marked as resolved',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
          _ => _buildSentContent(sosState, locationAsync),
        },
      ),
    );
  }

  Widget _buildSentContent(SOSState sosState, AsyncValue locationAsync) {
    final severity = sosState.response?.aiSeverity ?? 'PENDING';
    final locationData = locationAsync.valueOrNull;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Help is on the way banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.accentRed.withOpacity(0.3),
                  AppTheme.accentOrange.withOpacity(0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: AppTheme.accentRed.withOpacity(0.5)),
            ),
            child: Column(
              children: [
                const Icon(Icons.emergency_share,
                    color: AppTheme.accentOrange, size: 48),
                const SizedBox(height: 12),
                const Text(
                  'Help is on the way!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your SOS has been received and is being processed',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.8), fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Severity and Timer row
          Row(
            children: [
              Expanded(
                child: _InfoCard(
                  title: 'AI Severity',
                  child: SeverityChip(severity: severity),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InfoCard(
                  title: 'Time Elapsed',
                  child: Text(
                    _formattedTime,
                    style: const TextStyle(
                      color: AppTheme.accentOrange,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Location card with OpenStreetMap
          _InfoCard(
            title: 'Your Location',
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    height: 200,
                    width: double.infinity,
                    child: locationData != null
                        ? FlutterMap(
                            options: MapOptions(
                              initialCenter: LatLng(
                                locationData.latitude,
                                locationData.longitude,
                              ),
                              initialZoom: 15.0,
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.safealert.app',
                              ),
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: LatLng(
                                      locationData.latitude,
                                      locationData.longitude,
                                    ),
                                    width: 60,
                                    height: 60,
                                    child: const Icon(
                                      Icons.location_on,
                                      color: AppTheme.accentRed,
                                      size: 50,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          )
                        : Container(
                            color: AppTheme.primaryDark,
                            child: const Center(
                              child: Text('Location data unavailable',
                                  style: TextStyle(
                                      color: AppTheme.textSecondary)),
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Cancel SOS button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: AppTheme.surfaceDark,
                    title: const Text('Cancel SOS?',
                        style: TextStyle(color: AppTheme.textPrimary)),
                    content: const Text(
                      'This will mark the incident as resolved. Are you sure?',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('No, Keep Active'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.safeGreen),
                        child: const Text('Yes, Cancel SOS',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );
                if (confirm == true && mounted) {
                  await ref.read(sosProvider.notifier).cancelSOS();
                  if (mounted) Navigator.pop(context);
                }
              },
              icon: const Icon(Icons.cancel, color: AppTheme.safeGreen),
              label: const Text(
                'CANCEL SOS - I\'M SAFE',
                style: TextStyle(
                  color: AppTheme.safeGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.safeGreen, width: 2),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _InfoCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}
