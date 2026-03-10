import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:camera/camera.dart';
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

  // Voice recording
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  String? _audioPath;
  int _recordingSeconds = 0;
  Timer? _recordingTimer;

  // Video recording
  CameraController? _cameraController;
  bool _isVideoRecording = false;
  String? _videoPath;
  int _videoRecordingSeconds = 0;
  Timer? _videoRecordingTimer;
  bool _cameraInitializing = false;

  // Background shake service status
  bool _shakeServiceRunning = false;

  // SOS hold-to-activate (for center SOS button)
  bool _isHolding = false;
  double _holdProgress = 0.0;
  Timer? _holdTimer;
  static const int _holdDurationMs = 1000;
  static const int _holdTickMs = 20;

  // Emergency tile hold-to-activate (for each tile)
  String? _holdingTileType;
  double _tileHoldProgress = 0.0;
  Timer? _tileHoldTimer;

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
    _videoRecordingTimer?.cancel();
    _holdTimer?.cancel();
    _tileHoldTimer?.cancel();
    _audioRecorder.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  Color get _sosColor {
    // Center SOS button is always red (general emergency)
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

  // Emergency tile hold methods
  void _startTileHold(String tileType) {
    setState(() {
      _holdingTileType = tileType;
      _tileHoldProgress = 0.0;
    });
    _tileHoldTimer = Timer.periodic(Duration(milliseconds: _holdTickMs), (timer) {
      setState(() {
        _tileHoldProgress += _holdTickMs / _holdDurationMs;
      });
      if (_tileHoldProgress >= 1.0) {
        _tileHoldTimer?.cancel();
        _tileHoldProgress = 1.0;
        _onTileSOSActivated(tileType);
      }
    });
  }

  void _cancelTileHold() {
    _tileHoldTimer?.cancel();
    setState(() {
      _holdingTileType = null;
      _tileHoldProgress = 0.0;
    });
  }

  void _onTileSOSActivated(String emergencyType) {
    setState(() {
      _holdingTileType = null;
      _tileHoldProgress = 0.0;
    });

    // Send SOS with specific emergency type, include audio and video paths if recorded
    final typeLabel = emergencyType.toUpperCase();
    ref.read(sosProvider.notifier).sendSOS(
      '[$typeLabel] Emergency alert triggered!',
      emergencyType: emergencyType,
      audioFilePath: _audioPath,
      videoFilePath: _videoPath,
    );

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ConfirmationScreen()),
      );
    }
  }

  void _onSOSActivated() {
    setState(() {
      _isHolding = false;
      _holdProgress = 0.0;
    });

    // Send general SOS (center button always sends general alert)
    ref.read(sosProvider.notifier).sendSOS(
      '[SOS] General emergency alert triggered!',
      emergencyType: 'general',
      audioFilePath: _audioPath,
      videoFilePath: _videoPath,
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
      try {
        final path = await _audioRecorder.stop();
        _recordingTimer?.cancel();
        setState(() {
          _isRecording = false;
          _audioPath = path;
          _recordingSeconds = 0;
        });
      } catch (e) {
        _recordingTimer?.cancel();
        setState(() {
          _isRecording = false;
          _recordingSeconds = 0;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to stop recording'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      final hasPermission = await _audioRecorder.hasPermission();
      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Microphone permission required for voice recording'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      try {
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
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to start recording'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _toggleVideoRecording() async {
    if (_isVideoRecording) {
      // Stop recording
      try {
        if (_cameraController != null && _cameraController!.value.isRecordingVideo) {
          final file = await _cameraController!.stopVideoRecording();
          _videoRecordingTimer?.cancel();
          setState(() {
            _isVideoRecording = false;
            _videoPath = file.path;
            _videoRecordingSeconds = 0;
          });
          // Dispose camera to free resources
          await _cameraController?.dispose();
          _cameraController = null;
        }
      } catch (e) {
        _videoRecordingTimer?.cancel();
        setState(() {
          _isVideoRecording = false;
          _videoRecordingSeconds = 0;
        });
        await _cameraController?.dispose();
        _cameraController = null;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to stop video recording'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      // Start recording
      setState(() => _cameraInitializing = true);
      try {
        final cameras = await availableCameras();
        if (cameras.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No camera available'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          setState(() => _cameraInitializing = false);
          return;
        }

        // Prefer back camera
        final camera = cameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.back,
          orElse: () => cameras.first,
        );

        _cameraController = CameraController(
          camera,
          ResolutionPreset.medium,
          enableAudio: true,
        );

        await _cameraController!.initialize();

        final dir = await getTemporaryDirectory();
        final path = '${dir.path}/sos_video_${DateTime.now().millisecondsSinceEpoch}.mp4';

        await _cameraController!.startVideoRecording();

        setState(() {
          _cameraInitializing = false;
          _isVideoRecording = true;
          _videoRecordingSeconds = 0;
          _videoPath = path;
        });

        // Auto-stop after 30 seconds
        _videoRecordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() => _videoRecordingSeconds++);
          if (_videoRecordingSeconds >= 30) _toggleVideoRecording();
        });
      } catch (e) {
        setState(() => _cameraInitializing = false);
        await _cameraController?.dispose();
        _cameraController = null;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to start video: ${e.toString().substring(0, 50)}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
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

            // Media recording buttons (Audio + Video)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // Voice recording button
                  Expanded(
                    child: GestureDetector(
                      onTap: _isVideoRecording ? null : _toggleRecording,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          color: _isRecording
                              ? Colors.red.withOpacity(0.15)
                              : (_isVideoRecording ? AppTheme.cardDark.withOpacity(0.5) : AppTheme.cardDark),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _isRecording
                                ? Colors.red
                                : (_audioPath != null ? AppTheme.safeGreen.withOpacity(0.5) : AppTheme.textSecondary.withOpacity(0.2)),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _isRecording ? Icons.stop_circle : (_audioPath != null ? Icons.check_circle : Icons.mic),
                              color: _isRecording ? Colors.red : (_audioPath != null ? AppTheme.safeGreen : AppTheme.textSecondary),
                              size: 20,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                _isRecording
                                    ? '${_recordingSeconds}s / 20s'
                                    : (_audioPath != null ? 'Audio ✓' : 'Audio'),
                                style: TextStyle(
                                  color: _isRecording ? Colors.red : (_audioPath != null ? AppTheme.safeGreen : AppTheme.textSecondary),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Video recording button
                  Expanded(
                    child: GestureDetector(
                      onTap: (_isRecording || _cameraInitializing) ? null : _toggleVideoRecording,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          color: _isVideoRecording
                              ? Colors.red.withOpacity(0.15)
                              : (_isRecording ? AppTheme.cardDark.withOpacity(0.5) : AppTheme.cardDark),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _isVideoRecording
                                ? Colors.red
                                : (_videoPath != null ? AppTheme.safeGreen.withOpacity(0.5) : AppTheme.textSecondary.withOpacity(0.2)),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_cameraInitializing)
                              const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.textSecondary),
                              )
                            else
                              Icon(
                                _isVideoRecording ? Icons.stop_circle : (_videoPath != null ? Icons.check_circle : Icons.videocam),
                                color: _isVideoRecording ? Colors.red : (_videoPath != null ? AppTheme.safeGreen : AppTheme.textSecondary),
                                size: 20,
                              ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                _cameraInitializing
                                    ? 'Starting...'
                                    : (_isVideoRecording
                                        ? '${_videoRecordingSeconds}s / 30s'
                                        : (_videoPath != null ? 'Video ✓' : 'Video')),
                                style: TextStyle(
                                  color: _isVideoRecording ? Colors.red : (_videoPath != null ? AppTheme.safeGreen : AppTheme.textSecondary),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
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
    final isHolding = _holdingTileType == type;
    final holdProgress = isHolding ? _tileHoldProgress : 0.0;

    return Expanded(
      child: GestureDetector(
        onLongPressStart: (_) => _startTileHold(type),
        onLongPressEnd: (_) => _cancelTileHold(),
        onLongPressCancel: _cancelTileHold,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            gradient: isHolding
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradientColors
                        .map((c) => c.withOpacity(0.5))
                        .toList(),
                  )
                : null,
            color: isHolding ? null : AppTheme.cardDark.withOpacity(0.7),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isHolding ? color : Colors.white.withOpacity(0.06),
              width: isHolding ? 3.0 : 1,
            ),
            boxShadow: isHolding
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 2,
                    )
                  ]
                : [],
          ),
          child: Stack(
            children: [
              // Hold progress indicator (circular around the tile)
              if (isHolding)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: color.withOpacity(0.8),
                        width: 4.0 * holdProgress,
                      ),
                    ),
                  ),
                ),
              // Main content
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: color, size: 40),
                    const SizedBox(height: 10),
                    Text(
                      label,
                      style: TextStyle(
                        color: isHolding ? Colors.white : AppTheme.textSecondary,
                        fontSize: 16,
                        fontWeight: isHolding ? FontWeight.bold : FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isHolding ? 'SENDING...' : 'HOLD 1s',
                      style: TextStyle(
                        color: isHolding
                            ? color.withOpacity(0.9)
                            : AppTheme.textSecondary.withOpacity(0.5),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
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
