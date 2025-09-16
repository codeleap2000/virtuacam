// lib/presentation/widgets/desktop/whatsapp_banner.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_constants.dart';

class WhatsAppBanner extends StatefulWidget {
  final bool isSmallScreen;
  final bool showUpgradeMessage;
  final String? customMessage;
  final VoidCallback? onDismiss;

  const WhatsAppBanner({
    super.key,
    this.isSmallScreen = false,
    this.showUpgradeMessage = false,
    this.customMessage,
    this.onDismiss,
  });

  @override
  State<WhatsAppBanner> createState() => _WhatsAppBannerState();
}

class _WhatsAppBannerState extends State<WhatsAppBanner>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isHovered = false;
  bool _isDismissed = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(-1.0, 0.0), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.elasticOut),
        );

    _slideController.forward();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _openWhatsApp() async {
    final Uri whatsappUri = Uri.parse(AppConstants.whatsappLink);

    try {
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Opening WhatsApp...'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not open WhatsApp. Please install WhatsApp or contact us directly.',
            ),
            duration: Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening WhatsApp: ${e.toString()}'),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.red,
        ),
      );
      debugPrint('Error opening WhatsApp: $e');
    }
  }

  void _dismissBanner() {
    setState(() {
      _isDismissed = true;
    });
    widget.onDismiss?.call();
  }

  String _getMessage() {
    if (widget.customMessage != null) {
      return widget.customMessage!;
    } else if (widget.showUpgradeMessage) {
      return 'Upgrade your VirtuCam plan for unlimited usage!';
    } else {
      return 'Need a VirtuCam account?';
    }
  }

  String _getSubMessage() {
    if (widget.showUpgradeMessage) {
      return 'Contact us to upgrade to Pro, Business, or Enterprise plans';
    } else {
      return 'Contact us on WhatsApp to get instant access to VirtuCam';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isDismissed) {
      return const SizedBox.shrink();
    }

    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: widget.isSmallScreen ? 8 : 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green[50]!, Colors.green[100]!.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: Colors.green[300]!, width: 1.5),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.1),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              Positioned(
                top: -20,
                right: -20,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(widget.isSmallScreen ? 12 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green[600],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.chat_bubble,
                            color: Colors.white,
                            size: widget.isSmallScreen ? 16 : 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _getMessage(),
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Colors.green[800],
                              fontSize: widget.isSmallScreen ? 14 : 16,
                            ),
                          ),
                        ),
                        if (widget.onDismiss != null)
                          IconButton(
                            onPressed: _dismissBanner,
                            icon: Icon(
                              Icons.close,
                              color: Colors.green[600],
                              size: widget.isSmallScreen ? 18 : 20,
                            ),
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(),
                          ),
                      ],
                    ),

                    SizedBox(height: widget.isSmallScreen ? 8 : 12),

                    Text(
                      _getSubMessage(),
                      style: TextStyle(
                        color: Colors.green[700],
                        fontSize: widget.isSmallScreen ? 12 : 14,
                        height: 1.3,
                      ),
                    ),

                    SizedBox(height: widget.isSmallScreen ? 12 : 16),

                    Row(
                      children: [
                        Expanded(
                          child: MouseRegion(
                            onEnter: (_) => setState(() => _isHovered = true),
                            onExit: (_) => setState(() => _isHovered = false),
                            child: AnimatedBuilder(
                              animation: _pulseAnimation,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _isHovered
                                      ? _pulseAnimation.value
                                      : 1.0,
                                  child: ElevatedButton.icon(
                                    onPressed: _openWhatsApp,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green[600],
                                      foregroundColor: Colors.white,
                                      elevation: _isHovered ? 6 : 3,
                                      shadowColor: Colors.green.withOpacity(
                                        0.4,
                                      ),
                                      padding: EdgeInsets.symmetric(
                                        vertical: widget.isSmallScreen
                                            ? 12
                                            : 14,
                                        horizontal: widget.isSmallScreen
                                            ? 16
                                            : 20,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    icon: Icon(
                                      Icons.chat,
                                      size: widget.isSmallScreen ? 16 : 18,
                                    ),
                                    label: Text(
                                      'Contact us on WhatsApp',
                                      style: TextStyle(
                                        fontSize: widget.isSmallScreen
                                            ? 13
                                            : 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: widget.isSmallScreen ? 8 : 12),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green[200]!, width: 1),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            color: Colors.green[600],
                            size: widget.isSmallScreen ? 14 : 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Quick response • Professional support • Instant activation',
                              style: TextStyle(
                                color: Colors.green[700],
                                fontSize: widget.isSmallScreen ? 10 : 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
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
}
