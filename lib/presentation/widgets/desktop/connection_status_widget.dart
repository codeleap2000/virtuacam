// lib/presentation/widgets/desktop/connection_status_widget.dart
import 'package:flutter/material.dart';
import 'dart:async';

enum VirtuCamConnectionStatus {
  disconnected,
  connecting,
  connected,
  streaming,
  error,
}

class ConnectionStatusWidget extends StatefulWidget {
  final bool isSmallScreen;
  final VirtuCamConnectionStatus status;
  final int connectedDevices;
  final String? networkIP;
  final int? networkPort;
  final VoidCallback? onRefreshPressed;
  final VoidCallback? onSettingsPressed;

  const ConnectionStatusWidget({
    super.key,
    this.isSmallScreen = false,
    this.status = VirtuCamConnectionStatus.disconnected,
    this.connectedDevices = 0,
    this.networkIP,
    this.networkPort,
    this.onRefreshPressed,
    this.onSettingsPressed,
  });

  @override
  State<ConnectionStatusWidget> createState() => _ConnectionStatusWidgetState();
}

class _ConnectionStatusWidgetState extends State<ConnectionStatusWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rippleController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rippleAnimation;

  Timer? _statusTimer;
  late DateTime _lastStatusUpdate;

  @override
  void initState() {
    super.initState();
    _lastStatusUpdate = DateTime.now();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _rippleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rippleController, curve: Curves.easeOut),
    );

    _startAnimations();
    _startStatusTimer();
  }

  @override
  void didUpdateWidget(ConnectionStatusWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.status != widget.status) {
      _lastStatusUpdate = DateTime.now();
      _startAnimations();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rippleController.dispose();
    _statusTimer?.cancel();
    super.dispose();
  }

  void _startAnimations() {
    switch (widget.status) {
      case VirtuCamConnectionStatus.connecting:
        _pulseController.repeat(reverse: true);
        _rippleController.repeat();
        break;
      case VirtuCamConnectionStatus.streaming:
        _pulseController.repeat(reverse: true);
        _rippleController.stop();
        break;
      case VirtuCamConnectionStatus.connected:
        _pulseController.stop();
        _rippleController.stop();
        break;
      case VirtuCamConnectionStatus.disconnected:
      case VirtuCamConnectionStatus.error:
        _pulseController.stop();
        _rippleController.stop();
        break;
    }
  }

  void _startStatusTimer() {
    _statusTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          // Update UI every second for real-time feel
        });
      }
    });
  }

  Color get statusColor {
    switch (widget.status) {
      case VirtuCamConnectionStatus.connected:
        return Colors.green[600]!;
      case VirtuCamConnectionStatus.streaming:
        return Colors.blue[600]!;
      case VirtuCamConnectionStatus.connecting:
        return Colors.orange[600]!;
      case VirtuCamConnectionStatus.error:
        return Colors.red[600]!;
      case VirtuCamConnectionStatus.disconnected:
      default:
        return Colors.grey[600]!;
    }
  }

  IconData get statusIcon {
    switch (widget.status) {
      case VirtuCamConnectionStatus.connected:
        return Icons.wifi;
      case VirtuCamConnectionStatus.streaming:
        return Icons.videocam;
      case VirtuCamConnectionStatus.connecting:
        return Icons.wifi_find;
      case VirtuCamConnectionStatus.error:
        return Icons.wifi_off;
      case VirtuCamConnectionStatus.disconnected:
      default:
        return Icons.wifi_off_outlined;
    }
  }

  String get statusText {
    switch (widget.status) {
      case VirtuCamConnectionStatus.connected:
        return 'Connected';
      case VirtuCamConnectionStatus.streaming:
        return 'Streaming Active';
      case VirtuCamConnectionStatus.connecting:
        return 'Connecting...';
      case VirtuCamConnectionStatus.error:
        return 'Connection Error';
      case VirtuCamConnectionStatus.disconnected:
      default:
        return 'Disconnected';
    }
  }

  String get deviceCountText {
    if (widget.connectedDevices == 0) {
      return 'No devices connected';
    } else if (widget.connectedDevices == 1) {
      return '1 device connected';
    } else {
      return '${widget.connectedDevices} devices connected';
    }
  }

  String get timeSinceUpdate {
    final now = DateTime.now();
    final difference = now.difference(_lastStatusUpdate);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else {
      return '${difference.inHours}h ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: widget.isSmallScreen ? 8 : 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [statusColor.withOpacity(0.1), statusColor.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: statusColor.withOpacity(0.3), width: 1.5),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(widget.isSmallScreen ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            SizedBox(height: widget.isSmallScreen ? 12 : 16),
            _buildConnectionInfo(),
            if (widget.networkIP != null) ...[
              SizedBox(height: widget.isSmallScreen ? 12 : 16),
              _buildNetworkInfo(),
            ],
            SizedBox(height: widget.isSmallScreen ? 12 : 16),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            if (widget.status == VirtuCamConnectionStatus.connecting ||
                widget.status == VirtuCamConnectionStatus.streaming)
              AnimatedBuilder(
                animation: _rippleAnimation,
                builder: (context, child) {
                  return Container(
                    width:
                        (widget.isSmallScreen ? 40 : 48) *
                        (1 + _rippleAnimation.value * 0.5),
                    height:
                        (widget.isSmallScreen ? 40 : 48) *
                        (1 + _rippleAnimation.value * 0.5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: statusColor.withOpacity(
                          0.3 * (1 - _rippleAnimation.value),
                        ),
                        width: 2,
                      ),
                    ),
                  );
                },
              ),
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale:
                      (widget.status == VirtuCamConnectionStatus.connecting ||
                          widget.status == VirtuCamConnectionStatus.streaming)
                      ? _pulseAnimation.value
                      : 1.0,
                  child: Container(
                    padding: EdgeInsets.all(widget.isSmallScreen ? 8 : 10),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      statusIcon,
                      color: Colors.white,
                      size: widget.isSmallScreen ? 20 : 24,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        SizedBox(width: widget.isSmallScreen ? 12 : 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'VirtuCam Connection',
                style: TextStyle(
                  fontSize: widget.isSmallScreen ? 16 : 18,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
              SizedBox(height: 2),
              Text(
                statusText,
                style: TextStyle(
                  fontSize: widget.isSmallScreen ? 12 : 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: widget.isSmallScreen ? 8 : 10,
            vertical: widget.isSmallScreen ? 4 : 6,
          ),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: statusColor.withOpacity(0.3), width: 1),
          ),
          child: Text(
            timeSinceUpdate,
            style: TextStyle(
              fontSize: widget.isSmallScreen ? 10 : 12,
              fontWeight: FontWeight.w600,
              color: statusColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConnectionInfo() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Devices',
                style: TextStyle(
                  fontSize: widget.isSmallScreen ? 12 : 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.devices,
                    size: widget.isSmallScreen ? 16 : 18,
                    color: statusColor,
                  ),
                  SizedBox(width: 6),
                  Text(
                    deviceCountText,
                    style: TextStyle(
                      fontSize: widget.isSmallScreen ? 14 : 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (widget.status == VirtuCamConnectionStatus.streaming)
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: widget.isSmallScreen ? 8 : 12,
              vertical: widget.isSmallScreen ? 6 : 8,
            ),
            decoration: BoxDecoration(
              color: Colors.green[100],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.green[300]!, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.green[600],
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 6),
                Text(
                  'LIVE',
                  style: TextStyle(
                    fontSize: widget.isSmallScreen ? 10 : 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildNetworkInfo() {
    return Container(
      padding: EdgeInsets.all(widget.isSmallScreen ? 12 : 14),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Row(
        children: [
          Icon(
            Icons.router,
            size: widget.isSmallScreen ? 16 : 18,
            color: Colors.grey[600],
          ),
          SizedBox(width: 8),
          Text(
            'Network: ${widget.networkIP}:${widget.networkPort}',
            style: TextStyle(
              fontSize: widget.isSmallScreen ? 12 : 14,
              fontFamily: 'monospace',
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        if (widget.onRefreshPressed != null)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: widget.onRefreshPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: statusColor,
                side: BorderSide(color: statusColor),
                padding: EdgeInsets.symmetric(
                  vertical: widget.isSmallScreen ? 8 : 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: Icon(Icons.refresh, size: widget.isSmallScreen ? 16 : 18),
              label: Text(
                'Refresh',
                style: TextStyle(
                  fontSize: widget.isSmallScreen ? 12 : 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        if (widget.onRefreshPressed != null && widget.onSettingsPressed != null)
          SizedBox(width: 12),
        if (widget.onSettingsPressed != null)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: widget.onSettingsPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: statusColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  vertical: widget.isSmallScreen ? 8 : 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: Icon(Icons.settings, size: widget.isSmallScreen ? 16 : 18),
              label: Text(
                'Settings',
                style: TextStyle(
                  fontSize: widget.isSmallScreen ? 12 : 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
