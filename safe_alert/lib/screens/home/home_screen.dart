import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:safe_alert/providers/app_providers.dart';
import 'package:safe_alert/theme/app_theme.dart';
import 'package:safe_alert/widgets/status_badge.dart';
import 'package:safe_alert/screens/confirmation/confirmation_screen.dart';
import 'package:safe_alert/services/shake_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  String _selectedEmergencyType = 'general';

  // Voice recording
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  String? _audioPath;
  int _recordingSeconds = 0;
  Timer? _recordingTimer;

  // Background shake service status
  bool _shakeServiceRunning = false;

  // SOS hold-to-activate
  bool _isHolding = false;
  double _holdProgress = 0.0;
  Timer? _holdTimer;
  static const int _holdDurationMs = 1000;
  static const int _holdTickMs = 20;

  // Emergency type definitions — 4 large tiles
  static const List<Map<String, dynamic>> _emergencyTiles = [
    {
      'type': 'fire',
      'icon': Icons.local_fire_department,
      'label': 'Fire',
      'color': Color(0xFFE74C3C),
      'gradient': [Color(0xFFE74C3C), Color(0xFFFF6B35)],
    },
    {
      'type': 'robbery',
      'icon': Icons.gpp_bad,
      'label': 'Robbery',
      'color': Color(0xFF3498DB),
      'gradient': [Color(0xFF2980B9), Color(0xFF3498DB)],
    },
    {
      'type': 'medical',
      'icon': Icons.medical_services,
      'label': 'Medical',
      'color': Color(0xFF2ECC71),
      'gradient': [Color(0xFF27AE60), Color(0xFF2ECC71)],
    },
    {
      'type': 'unsafe',
      'icon': Icons.visibility,
      'label': 'Unsafe',
      'color': Color(0xFFF1C40F),
      'gradient': [Color(0xFFF39C12), Color(0xFFF1C40F)],
    },
  ];

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
    _recordingTimer?.cancel();
    _holdTimer?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }

  Color get _sosColor {
    final match = _emergencyTiles.where((t) => t['type'] == _selectedEmergencyType);
    if (match.isNotEmpty) return match.first['color'] as Color;
    return AppTheme.accentRed;
  }

  void _startHold() {
    setState(() {
      _isHolding = true;
      _holdProgress = 0.0;
    });
    _holdTimer = Timer.periodic(Duration(milliseconds: _holdTickMs), (timer) {
      setState(() {
        _holdProgress += _holdTickMs / _holdDurationMs;
      });
      if (_holdProgress >= 1.0) {
        _holdTimer?.cancel();
        _holdProgress = 1.0;
        _onSOSActivated();
      }
    });
  }

  void _cancelHold() {
    _holdTimer?.cancel();
    setState(() {
      _isHolding = false;
      _holdProgress = 0.0;
    });
  }

  void _onSOSActivated() {
    setState(() {
      _isHolding = false;
      _holdProgress = 0.0;
    });

    // Send SOS with selected emergency type, include audio path if recorded
    final typeLabel = _selectedEmergencyType != 'general'
        ? _selectedEmergencyType.toUpperCase()
        : 'SOS';
    ref.read(sosProvider.notifier).sendSOS(
      '[$typeLabel] Emergency alert triggered!',
      emergencyType: _selectedEmergencyType,
      audioFilePath: _audioPath,
    );

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ConfirmationScreen()),
      );
    }
  }

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
      final path =
          '${dir.path}/sos_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
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
        if (_recordingSeconds >= 20) _toggleRecording();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final sosState = ref.watch(sosProvider);
    final locationAsync = ref.watch(currentLocationProvider);
    final isSafe =
        sosState.status == SOSStatus.idle || sosState.status == SOSStatus.cancelled;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top bar: status + location + shake indicator
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  StatusBadge(isSafe: isSafe),
                  const Spacer(),
                  // Shake protection indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _shakeServiceRunning
                          ? AppTheme.safeGreen.withOpacity(0.15)
                          : AppTheme.cardDark,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _shakeServiceRunning
                            ? AppTheme.safeGreen.withOpacity(0.5)
                            : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.vibration,
                          color: _shakeServiceRunning
                              ? AppTheme.safeGreen
                              : AppTheme.textSecondary,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _shakeServiceRunning ? 'Protected' : 'Off',
                          style: TextStyle(
                            color: _shakeServiceRunning
                                ? AppTheme.safeGreen
                                : AppTheme.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // GPS location
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: locationAsync.when(
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
            ),

            const SizedBox(height: 12),

            // Emergency grid + SOS button (takes remaining space)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Stack(
                  children: [
                    // 4 large emergency tiles in a 2×2 grid
                    Column(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              _buildEmergencyTile(_emergencyTiles[0]), // Fire
                              const SizedBox(width: 12),
                              _buildEmergencyTile(_emergencyTiles[1]), // Robbery
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: Row(
                            children: [
                              _buildEmergencyTile(_emergencyTiles[2]), // Medical
                              const SizedBox(width: 12),
                              _buildEmergencyTile(_emergencyTiles[3]), // Unsafe
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Centered SOS button overlaying the grid
                    Center(
                      child: _buildSOSButton(),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Voice recording bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GestureDetector(
                onTap: _toggleRecording,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: _isRecording
                        ? Colors.red.withOpacity(0.15)
                        : AppTheme.cardDark,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _isRecording
                          ? Colors.red
                          : AppTheme.textSecondary.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isRecording ? Icons.stop_circle : Icons.mic,
                        color: _isRecording ? Colors.red : AppTheme.textSecondary,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isRecording
                            ? 'Recording ${_recordingSeconds}s / 20s  ●'
                            : (_audioPath != null
                                ? '✓ Voice recorded – tap to re-record'
                                : '🎤 Tap to record voice message'),
                        style: TextStyle(
                          color: _isRecording ? Colors.red : AppTheme.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyTile(Map<String, dynamic> tile) {
    final type = tile['type'] as String;
    final icon = tile['icon'] as IconData;
    final label = tile['label'] as String;
    final color = tile['color'] as Color;
    final gradientColors = tile['gradient'] as List<Color>;
    final isSelected = _selectedEmergencyType == type;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedEmergencyType =
                _selectedEmergencyType == type ? 'general' : type;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradientColors
                        .map((c) => c.withOpacity(0.35))
                        .toList(),
                  )
                : null,
            color: isSelected ? null : AppTheme.cardDark.withOpacity(0.7),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? color : Colors.white.withOpacity(0.06),
              width: isSelected ? 2.5 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 16,
                      spreadRadius: 1,
                    )
                  ]
                : [],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 40),
              const SizedBox(height: 10),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
              if (isSelected)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'SELECTED',
                    style: TextStyle(
                      color: color.withOpacity(0.8),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSOSButton() {
    final color = _sosColor;
    final size = 160.0;

    return GestureDetector(
      onLongPressStart: (_) => _startHold(),
      onLongPressEnd: (_) => _cancelHold(),
      onLongPressCancel: _cancelHold,
      child: SizedBox(
        width: size + 16,
        height: size + 16,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Circular progress ring (hold indicator)
            if (_isHolding)
              SizedBox(
                width: size + 14,
                height: size + 14,
                child: CircularProgressIndicator(
                  value: _holdProgress,
                  strokeWidth: 6,
                  backgroundColor: Colors.white.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),

            // Outer glow
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(_isHolding ? 0.7 : 0.4),
                    blurRadius: _isHolding ? 45 : 30,
                    spreadRadius: _isHolding ? 10 : 4,
                  ),
                ],
              ),
            ),

            // Main button
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: _isHolding ? size - 6 : size,
              height: _isHolding ? size - 6 : size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [color, color.withOpacity(0.7)],
                ),
                border: Border.all(color: Colors.white.withOpacity(0.3), width: 3),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: Colors.white, size: 42),
                  const SizedBox(height: 4),
                  const Text(
                    'SOS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4,
                    ),
                  ),
                  Text(
                    _isHolding ? 'HOLD...' : 'HOLD 1s',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ],
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
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(color: color, fontSize: 12)),
      ],
    );
  }
}
