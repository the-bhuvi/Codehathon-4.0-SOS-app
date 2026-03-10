import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:safe_alert/models/incident.dart';
import 'package:safe_alert/providers/app_providers.dart';
import 'package:safe_alert/theme/app_theme.dart';
import 'package:safe_alert/widgets/severity_chip.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incidentsAsync = ref.watch(incidentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Incident History'),
      ),
      body: incidentsAsync.when(
        data: (incidents) {
          if (incidents.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history,
                      size: 80,
                      color: AppTheme.textSecondary.withOpacity(0.3)),
                  const SizedBox(height: 16),
                  const Text(
                    'No incidents yet',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your SOS history will appear here',
                    style: TextStyle(
                      color: AppTheme.textSecondary.withOpacity(0.6),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: incidents.length,
            itemBuilder: (context, index) =>
                _IncidentCard(incident: incidents[index]),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.accentRed),
        ),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off,
                  size: 60, color: AppTheme.textSecondary),
              const SizedBox(height: 16),
              Text(
                'Failed to load incidents',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => ref.invalidate(incidentsProvider),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentRed),
                child:
                    const Text('Retry', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IncidentCard extends StatelessWidget {
  final Incident incident;

  const _IncidentCard({required this.incident});

  @override
  Widget build(BuildContext context) {
    final isActive = incident.status == 'active';
    final dateFormat = DateFormat('MMM d, yyyy – h:mm a');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isActive
            ? const BorderSide(color: AppTheme.accentRed, width: 1)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isActive ? Icons.warning : Icons.check_circle,
                      color:
                          isActive ? AppTheme.accentRed : AppTheme.safeGreen,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isActive ? 'ACTIVE' : 'RESOLVED',
                      style: TextStyle(
                        color: isActive
                            ? AppTheme.accentRed
                            : AppTheme.safeGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                if (incident.severity != null)
                  SeverityChip(severity: incident.severity!),
              ],
            ),
            const SizedBox(height: 12),
            if (incident.message != null && incident.message!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  incident.message!,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            Row(
              children: [
                const Icon(Icons.access_time,
                    size: 14, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Text(
                  dateFormat.format(incident.createdAt.toLocal()),
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.location_on,
                    size: 14, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Text(
                  '${incident.lat.toStringAsFixed(4)}, ${incident.lng.toStringAsFixed(4)}',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
