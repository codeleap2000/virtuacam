// lib/presentation/screens/desktop/screen_capture_screen.dart
import 'package:flutter/material.dart';
import 'dart:io';
import '../../../services/auth_service.dart';
import '../../../core/constants/app_constants.dart';

class VirtuCamScreenCaptureScreen extends StatefulWidget {
  const VirtuCamScreenCaptureScreen({super.key});

  @override
  State<VirtuCamScreenCaptureScreen> createState() =>
      _VirtuCamScreenCaptureScreenState();
}

class _VirtuCamScreenCaptureScreenState
    extends State<VirtuCamScreenCaptureScreen>
    with TickerProviderStateMixin {
  final _authService = AuthService();

  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

  bool _isStreaming = false;
  String _selectedResolution = AppConstants.defaultQuality;
  int _selectedFrameRate = AppConstants.defaultFrameRate;
  bool _audioEnabled = AppConstants.defaultAudioEnabled;
  String _captureMode = 'fullscreen';
  int _selectedMonitor = 0;
  List<Map<String, dynamic>> _availableMonitors = [];

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _loadAvailableMonitors();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _loadAvailableMonitors() {
    // Mock monitor data - replace with actual monitor detection
    _availableMonitors = [
      {
        'id': 0,
        'name': 'Primary Monitor',
        'width': 1920,
        'height': 1080,
        'isPrimary': true,
      },
      {
        'id': 1,
        'name': 'Secondary Monitor',
        'width': 1440,
        'height': 900,
        'isPrimary': false,
      },
    ];

    // TODO: Implement actual monitor detection
    // if (Platform.isMacOS) {
    //   _availableMonitors = await MacOSScreenCapture.getAvailableDisplays();
    // } else if (Platform.isWindows) {
    //   _availableMonitors = await WindowsScreenCapture.getAvailableDisplays();
    // }
  }

  Future<void> _startStreaming() async {
    try {
      final canUse = await _authService.canUseService();
      if (!canUse) {
        _showError('Usage limit reached. Please upgrade your plan.');
        return;
      }

      setState(() {
        _isStreaming = true;
      });

      _pulseController.repeat(reverse: true);
      _showSuccess('VirtuCam screen capture started successfully!');

      // TODO: Implement actual screen capture streaming
      // if (Platform.isMacOS) {
      //   await MacOSScreenCapture.startCapture(
      //     monitor: _selectedMonitor,
      //     resolution: _selectedResolution,
      //     frameRate: _selectedFrameRate,
      //     audioEnabled: _audioEnabled,
      //     captureMode: _captureMode,
      //   );
      // } else if (Platform.isWindows) {
      //   await WindowsScreenCapture.startCapture(
      //     monitor: _selectedMonitor,
      //     resolution: _selectedResolution,
      //     frameRate: _selectedFrameRate,
      //     audioEnabled: _audioEnabled,
      //     captureMode: _captureMode,
      //   );
      // }
    } catch (e) {
      setState(() {
        _isStreaming = false;
      });
      _showError('Failed to start screen capture: $e');
    }
  }

  Future<void> _stopStreaming() async {
    try {
      setState(() {
        _isStreaming = false;
      });

      _pulseController.stop();
      _showSuccess('VirtuCam screen capture stopped');

      // TODO: Implement actual screen capture stop
      // if (Platform.isMacOS) {
      //   await MacOSScreenCapture.stopCapture();
      // } else if (Platform.isWindows) {
      //   await WindowsScreenCapture.stopCapture();
      // }
    } catch (e) {
      _showError('Failed to stop screen capture: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red[600]),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green[600]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('VirtuCam Screen Capture'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _isStreaming ? _stopStreaming : null,
            icon: const Icon(Icons.stop),
            tooltip: 'Stop Streaming',
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPreviewSection(isSmallScreen),
              const SizedBox(height: 24),
              _buildCaptureSettings(isSmallScreen),
              const SizedBox(height: 24),
              _buildQualitySettings(isSmallScreen),
              const SizedBox(height: 24),
              _buildControlSection(isSmallScreen),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewSection(bool isSmallScreen) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
            child: Row(
              children: [
                Icon(Icons.preview, color: Colors.blue[600]),
                const SizedBox(width: 8),
                Text(
                  'Live Preview',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 16 : 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
                const Spacer(),
                if (_isStreaming)
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red[600],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'LIVE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
          Container(
            margin: EdgeInsets.all(isSmallScreen ? 16 : 20),
            height: isSmallScreen ? 200 : 300,
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!, width: 2),
            ),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isStreaming ? Icons.videocam : Icons.videocam_off,
                        size: 48,
                        color: _isStreaming
                            ? Colors.green[400]
                            : Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _isStreaming
                            ? 'Streaming Active'
                            : 'Preview will appear here',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: isSmallScreen ? 14 : 16,
                        ),
                      ),
                      if (!_isStreaming) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Start streaming to see live preview',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: isSmallScreen ? 12 : 14,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (_isStreaming)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$_selectedResolution @ ${_selectedFrameRate}fps',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaptureSettings(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.desktop_windows, color: Colors.green[600]),
              const SizedBox(width: 8),
              Text(
                'Capture Settings',
                style: TextStyle(
                  fontSize: isSmallScreen ? 16 : 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildSettingRow(
            'Monitor Selection',
            DropdownButton<int>(
              value: _selectedMonitor,
              items: _availableMonitors.map((monitor) {
                return DropdownMenuItem<int>(
                  value: monitor['id'],
                  child: Text(
                    '${monitor['name']} (${monitor['width']}x${monitor['height']})',
                    style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
                  ),
                );
              }).toList(),
              onChanged: _isStreaming
                  ? null
                  : (value) {
                      setState(() => _selectedMonitor = value!);
                    },
              underline: Container(),
            ),
            isSmallScreen,
          ),

          const SizedBox(height: 16),

          _buildSettingRow(
            'Capture Mode',
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'fullscreen', label: Text('Full Screen')),
                ButtonSegment(value: 'window', label: Text('Active Window')),
                ButtonSegment(value: 'region', label: Text('Custom Region')),
              ],
              selected: {_captureMode},
              onSelectionChanged: _isStreaming
                  ? null
                  : (values) {
                      setState(() => _captureMode = values.first);
                    },
            ),
            isSmallScreen,
          ),
        ],
      ),
    );
  }

  Widget _buildQualitySettings(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.high_quality, color: Colors.purple[600]),
              const SizedBox(width: 8),
              Text(
                'Quality Settings',
                style: TextStyle(
                  fontSize: isSmallScreen ? 16 : 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildSettingRow(
            'Resolution',
            DropdownButton<String>(
              value: _selectedResolution,
              items: AppConstants.qualitySettings.keys.map((quality) {
                return DropdownMenuItem<String>(
                  value: quality,
                  child: Text(
                    '$quality (${AppConstants.qualitySettings[quality]})',
                    style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
                  ),
                );
              }).toList(),
              onChanged: _isStreaming
                  ? null
                  : (value) {
                      setState(() => _selectedResolution = value!);
                    },
              underline: Container(),
            ),
            isSmallScreen,
          ),

          const SizedBox(height: 16),

          _buildSettingRow(
            'Frame Rate',
            DropdownButton<int>(
              value: _selectedFrameRate,
              items: AppConstants.frameRateOptions.map((fps) {
                return DropdownMenuItem<int>(
                  value: fps,
                  child: Text(
                    '$fps FPS',
                    style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
                  ),
                );
              }).toList(),
              onChanged: _isStreaming
                  ? null
                  : (value) {
                      setState(() => _selectedFrameRate = value!);
                    },
              underline: Container(),
            ),
            isSmallScreen,
          ),

          const SizedBox(height: 16),

          SwitchListTile(
            title: Text(
              'Audio Streaming',
              style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
            ),
            subtitle: const Text('Include system audio in stream'),
            value: _audioEnabled,
            onChanged: _isStreaming
                ? null
                : (value) {
                    setState(() => _audioEnabled = value);
                  },
            activeColor: Colors.purple[600],
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildControlSection(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.control_camera, color: Colors.orange[600]),
              const SizedBox(width: 8),
              Text(
                'Stream Control',
                style: TextStyle(
                  fontSize: isSmallScreen ? 16 : 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isStreaming ? _stopStreaming : _startStreaming,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isStreaming
                    ? Colors.red[600]
                    : Colors.green[600],
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  vertical: isSmallScreen ? 16 : 18,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: Icon(
                _isStreaming ? Icons.stop : Icons.play_arrow,
                size: isSmallScreen ? 20 : 24,
              ),
              label: Text(
                _isStreaming
                    ? 'Stop VirtuCam Streaming'
                    : 'Start VirtuCam Streaming',
                style: TextStyle(
                  fontSize: isSmallScreen ? 16 : 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          if (_isStreaming) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.green[600], size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'VirtuCam is streaming to connected mobile devices. Open your phone\'s camera app and use VirtuCam as camera source.',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 12 : 14,
                        color: Colors.green[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSettingRow(String title, Widget control, bool isSmallScreen) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: isSmallScreen ? 14 : 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        control,
      ],
    );
  }
}
