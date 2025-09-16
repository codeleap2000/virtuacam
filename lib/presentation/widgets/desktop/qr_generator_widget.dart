// lib/presentation/widgets/desktop/qr_generator_widget.dart
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:convert';
import 'dart:async';

class QrGeneratorWidget extends StatefulWidget {
  final bool isSmallScreen;
  final String? networkIP;
  final int? networkPort;
  final bool isStreaming;
  final VoidCallback? onRegeneratePressed;
  final VoidCallback? onSharePressed;

  const QrGeneratorWidget({
    super.key,
    this.isSmallScreen = false,
    this.networkIP,
    this.networkPort,
    this.isStreaming = false,
    this.onRegeneratePressed,
    this.onSharePressed,
  });

  @override
  State<QrGeneratorWidget> createState() => _QrGeneratorWidgetState();
}

class _QrGeneratorWidgetState extends State<QrGeneratorWidget>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _rotateController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _rotateAnimation;

  Timer? _refreshTimer;
  String? _currentQrData;
  DateTime? _generatedAt;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _rotateController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _rotateAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rotateController, curve: Curves.elasticOut),
    );

    _generateQrCode();
    _startRefreshTimer();
  }

  @override
  void didUpdateWidget(QrGeneratorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.networkIP != widget.networkIP ||
        oldWidget.networkPort != widget.networkPort ||
        oldWidget.isStreaming != widget.isStreaming) {
      _generateQrCode();
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _rotateController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _generateQrCode() {
    if (widget.networkIP == null || widget.networkPort == null) {
      _currentQrData = null;
      return;
    }

    final qrData = {
      'app': 'VirtuCam',
      'version': '1.0.0',
      'ip': widget.networkIP,
      'port': widget.networkPort,
      'token': _generateSecureToken(),
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'streaming': widget.isStreaming,
    };

    setState(() {
      _currentQrData = jsonEncode(qrData);
      _generatedAt = DateTime.now();
    });

    _fadeController.forward();
  }

  String _generateSecureToken() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().microsecond;
    return 'vc_${timestamp}_$random';
  }

  void _startRefreshTimer() {
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (mounted) {
        _regenerateQrCode();
      }
    });
  }

  void _regenerateQrCode() {
    _rotateController.forward().then((_) {
      _generateQrCode();
      _rotateController.reset();
      widget.onRegeneratePressed?.call();
    });
  }

  String get timeRemaining {
    if (_generatedAt == null) return '0:00';

    final now = DateTime.now();
    final elapsed = now.difference(_generatedAt!);
    final remaining = const Duration(minutes: 5) - elapsed;

    if (remaining.isNegative) return '0:00';

    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: widget.isSmallScreen ? 8 : 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[50]!, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.blue[200]!, width: 1.5),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(widget.isSmallScreen ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildHeader(),
            SizedBox(height: widget.isSmallScreen ? 16 : 20),
            _buildQrCodeSection(),
            SizedBox(height: widget.isSmallScreen ? 12 : 16),
            _buildInstructions(),
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
        Container(
          padding: EdgeInsets.all(widget.isSmallScreen ? 8 : 10),
          decoration: BoxDecoration(
            color: Colors.blue[600],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.qr_code,
            color: Colors.white,
            size: widget.isSmallScreen ? 20 : 24,
          ),
        ),
        SizedBox(width: widget.isSmallScreen ? 12 : 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'VirtuCam QR Code',
                style: TextStyle(
                  fontSize: widget.isSmallScreen ? 16 : 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Scan with phone camera to connect',
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
            color: Colors.orange[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange[300]!, width: 1),
          ),
          child: Text(
            timeRemaining,
            style: TextStyle(
              fontSize: widget.isSmallScreen ? 10 : 12,
              fontWeight: FontWeight.bold,
              color: Colors.orange[700],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQrCodeSection() {
    if (_currentQrData == null) {
      return _buildPlaceholder();
    }

    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: AnimatedBuilder(
            animation: _rotateAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotateAnimation.value * 0.1,
                child: Container(
                  padding: EdgeInsets.all(widget.isSmallScreen ? 12 : 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: QrImageView(
                    data: _currentQrData!,
                    version: QrVersions.auto,
                    size: widget.isSmallScreen ? 160 : 200,
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    errorStateBuilder: (context, error) {
                      return Container(
                        width: widget.isSmallScreen ? 160 : 200,
                        height: widget.isSmallScreen ? 160 : 200,
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.red[600],
                              size: widget.isSmallScreen ? 32 : 40,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'QR Code Error',
                              style: TextStyle(
                                color: Colors.red[700],
                                fontSize: widget.isSmallScreen ? 12 : 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: widget.isSmallScreen ? 160 : 200,
      height: widget.isSmallScreen ? 160 : 200,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!, width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.qr_code_scanner,
            color: Colors.grey[400],
            size: widget.isSmallScreen ? 32 : 40,
          ),
          SizedBox(height: 8),
          Text(
            'No Network\nConnection',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: widget.isSmallScreen ? 12 : 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructions() {
    return Container(
      padding: EdgeInsets.all(widget.isSmallScreen ? 12 : 14),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.blue[600],
                size: widget.isSmallScreen ? 16 : 18,
              ),
              SizedBox(width: 8),
              Text(
                'How to Connect:',
                style: TextStyle(
                  fontSize: widget.isSmallScreen ? 12 : 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          _buildInstructionStep('1', 'Open camera app on your phone'),
          _buildInstructionStep('2', 'Point camera at QR code above'),
          _buildInstructionStep('3', 'Tap the notification to open VirtuCam'),
          _buildInstructionStep(
            '4',
            'VirtuCam will auto-connect and start streaming',
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionStep(String number, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.blue[600],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: widget.isSmallScreen ? 8 : 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: widget.isSmallScreen ? 11 : 13,
                color: Colors.blue[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _currentQrData != null ? _regenerateQrCode : null,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.blue[600],
              side: BorderSide(color: Colors.blue[600]!),
              padding: EdgeInsets.symmetric(
                vertical: widget.isSmallScreen ? 8 : 10,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: Icon(Icons.refresh, size: widget.isSmallScreen ? 16 : 18),
            label: Text(
              'Regenerate',
              style: TextStyle(
                fontSize: widget.isSmallScreen ? 12 : 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _currentQrData != null ? widget.onSharePressed : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                vertical: widget.isSmallScreen ? 8 : 10,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: Icon(Icons.share, size: widget.isSmallScreen ? 16 : 18),
            label: Text(
              'Share',
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
