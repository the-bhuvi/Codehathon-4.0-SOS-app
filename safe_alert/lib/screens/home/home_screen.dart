import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:safe_alert/providers/app_providers.dart';
import 'package:safe_alert/theme/app_theme.dart';
import 'package:safe_alert/widgets/sos_button.dart';
import 'package:safe_alert/widgets/status_badge.dart';
import 'package:safe_alert/screens/confirmation/confirmation_screen.dart';
import 'package:safe_alert/services/shake_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _messageController = TextEditingController();
  String _selectedEmergencyType = 'general';

  // Voice recording
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  String? _audioPath;
  int _recordingSeconds = 0;
  Timer? _recordingTimer;

  // Background shake service status
  bool _shakeServiceRunning = false;

  @override
  void initState() {
    super.initState();
    _checkShakeServiceStatus();
  }

  Future<void> _checkShakeServiceStatus() async {
    final running = await ShakeBackgroundService.isRunning();
    if (mounted) setState(() => _shakeServiceRunning = running);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _recordingTimer?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }

  // Emergency type definitions
  static const List<Map<String, dynamic>> _emergencyTypes = [
    {'type': 'fire', 'icon': Icons.local_fire_department, 'label': 'Fire', 'color': Colors.deepOrange},
    {'type': 'accident', 'icon': Icons.car_crash, 'label': 'Accident', 'color': Colors.orange},
    {'type': 'robbery', 'icon': Icons.warning_amber, 'label': 'Robbery', 'color': Colors.red},
    {'type': 'medical', 'icon': Icons.medical_services, 'label': 'Medical', 'color': Colors.blue},
    {'type': 'following', 'icon': Icons.visibility, 'label': 'Following', 'color': Colors.purple},
    {'type': 'unsafe', 'icon': Icons.shield, 'label': 'Unsafe', 'color': Colors.amber},
  ];

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      final path = await _audioRecorder.stop();
      _recordingTimer?.cancel();
      setState(() {
        _isRecording = false;
        _audioPath = path;
        _recordingSeconds = 0;
      });
    } else {
      final hasPermission = await _audioRecorder.hasPermission();
      if (!hasPermission) return;

      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/sos_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _audioRecorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000),
        path: path,
      );
      setState(() {
        _isRecording = true;
        _recordingSeconds = 0;
      });
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() => _recordingSeconds++);
        if (_recordingSeconds >= 20) {
          _toggleRecording(); // Auto-stop at 20s
        }
      });
    }
  }

  void _showSOSBottomSheet() {
    _selectedEmergencyType = 'general';
    _audioPath = null;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '🚨 Emergency Alert',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Select type & describe your emergency',
                style: TextStyle(color: AppTheme.textSecondary.withOpacity(0.7), fontSize: 13),
              ),
              const SizedBox(height: 16),

              // Emergency type quick buttons
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _emergencyTypes.map((type) {
                  final isSelected = _selectedEmergencyType == type['type'];
                  return GestureDetector(
                    onTap: () => setSheetState(() => _selectedEmergencyType = type['type'] as String),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (type['color'] as Color).withOpacity(0.25)
                            : AppTheme.cardDark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? type['color'] as Color : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(type['icon'] as IconData, color: type['color'] as Color, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            type['label'] as String,
                            style: TextStyle(
                              color: isSelected ? Colors.white : AppTheme.textSecondary,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Message input
              TextField(
                controller: _messageController,
                maxLines: 3,
                autofocus: true,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Describe your emergency (any language)...',
                  hintStyle: TextStyle(color: AppTheme.textSecondary.withOpacity(0.5)),
                  filled: true,
                  fillColor: AppTheme.cardDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.accentRed, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Voice recording button
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      _toggleRecording();
                      setSheetState(() {});
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: _isRecording ? Colors.red.withOpacity(0.2) : AppTheme.cardDark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _isRecording ? Colors.red : AppTheme.textSecondary.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isRecording ? Icons.stop : Icons.mic,
                            color: _isRecording ? Colors.red : AppTheme.textSecondary,
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _isRecording
                                ? 'Recording ${_recordingSeconds}s / 20s'
                                : (_audioPath != null ? '✓ Voice recorded' : 'Record voice'),
                            style: TextStyle(
                              color: _isRecording ? Colors.red : AppTheme.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_audioPath != null && !_isRecording) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        _audioPath = null;
                        setSheetState(() {});
                      },
                      child: const Icon(Icons.close, color: AppTheme.textSecondary, size: 18),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),

              // Action buttons
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
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
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentRed,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _triggerSOS() async {
    final message = _messageController.text.trim();
    _messageController.clear();

    // Prepend emergency type to message if selected
    final effectiveMessage = _selectedEmergencyType != 'general'
        ? '[${_selectedEmergencyType.toUpperCase()}] $message'
        : message;

    ref.read(sosProvider.notifier).sendSOS(
      effectiveMessage,
      emergencyType: _selectedEmergencyType,
    );

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
              const SizedBox(height: 16),

              // Quick emergency type chips
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  alignment: WrapAlignment.center,
                  children: _emergencyTypes.map((type) {
                    return ActionChip(
                      avatar: Icon(type['icon'] as IconData, color: type['color'] as Color, size: 16),
                      label: Text(type['label'] as String, style: const TextStyle(fontSize: 11)),
                      backgroundColor: AppTheme.cardDark,
                      side: BorderSide.none,
                      onPressed: () {
                        _selectedEmergencyType = type['type'] as String;
                        _showSOSBottomSheet();
                      },
                    );
                  }).toList(),
                ),
              ),

              const Spacer(),
              SOSButton(
                onPressed: _showSOSBottomSheet,
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

              // Background shake service indicator
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(
                          Icons.vibration,
                          color: _shakeServiceRunning ? AppTheme.safeGreen : AppTheme.textSecondary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _shakeServiceRunning
                                    ? 'Background Protection Active'
                                    : 'Background Protection Off',
                                style: TextStyle(
                                  color: _shakeServiceRunning ? AppTheme.safeGreen : AppTheme.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                _shakeServiceRunning
                                    ? 'Shake phone to trigger SOS even when app is closed'
                                    : 'Enable in Settings → Panic Mode',
                                style: TextStyle(
                                  color: AppTheme.textSecondary.withOpacity(0.7),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          _shakeServiceRunning ? Icons.check_circle : Icons.cancel_outlined,
                          color: _shakeServiceRunning ? AppTheme.safeGreen : AppTheme.textSecondary,
                          size: 18,
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
