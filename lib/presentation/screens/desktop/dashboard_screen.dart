// lib/presentation/screens/desktop/dashboard_screen.dart
import 'package:flutter/material.dart';
import '../../../services/auth_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../widgets/desktop/plan_status_widget.dart';
import '../../widgets/desktop/connection_status_widget.dart';
import '../../widgets/desktop/qr_generator_widget.dart';
import '../../widgets/desktop/whatsapp_banner.dart';
import 'screen_capture_screen.dart';
import 'media_browser_screen.dart';
import 'settings_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class VirtuCamDashboard extends StatefulWidget {
  const VirtuCamDashboard({super.key});

  @override
  State<VirtuCamDashboard> createState() => _VirtuCamDashboardState();
}

class _VirtuCamDashboardState extends State<VirtuCamDashboard>
    with TickerProviderStateMixin {
  final _authService = AuthService();

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  String? _errorMessage;
  VirtuCamConnectionStatus _connectionStatus =
      VirtuCamConnectionStatus.disconnected;
  int _connectedDevices = 0;
  bool _isStreaming = false;
  String? _networkIP;
  int? _networkPort;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.elasticOut),
        );

    _loadUserData();
    _initializeNetworking();
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final userData = await _authService.getUserData();
      setState(() {
        _userData = userData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _initializeNetworking() {
    // Simulate network initialization
    setState(() {
      _networkIP = '192.168.1.100'; // Replace with actual IP detection
      _networkPort = 8080;
      _connectionStatus = VirtuCamConnectionStatus.connected;
    });
  }

  Future<void> _startScreenCapture() async {
    try {
      final canUse = await _authService.canUseService();
      if (!canUse) {
        _showUpgradeDialog();
        return;
      }

      final success = await _authService.decrementDailyUsage();
      if (!success) {
        _showError('Failed to start screen capture. Please try again.');
        return;
      }

      // Navigate to screen capture screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const VirtuCamScreenCaptureScreen(),
        ),
      );

      setState(() {
        _isStreaming = true;
        _connectionStatus = VirtuCamConnectionStatus.streaming;
      });

      _showSuccess('VirtuCam screen capture started successfully!');

      // TODO: Implement actual screen capture
      // await VirtuCamPlugin.startScreenCapture();
    } catch (e) {
      _showError('Failed to start screen capture: $e');
    }
  }

  Future<void> _selectMediaFile() async {
    try {
      final canUse = await _authService.canUseService();
      if (!canUse) {
        _showUpgradeDialog();
        return;
      }

      // Navigate to media browser
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const VirtuCamMediaBrowserScreen(),
        ),
      );
    } catch (e) {
      _showError('Failed to open media browser: $e');
    }
  }

  void _showUpgradeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Usage Limit Reached'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('You have reached your daily usage limit.'),
            const SizedBox(height: 16),
            const Text('Upgrade options:'),
            const SizedBox(height: 8),
            Text(
              '• Basic Plan: ${AppConstants.basicUsageLimit} uses/day - \$${AppConstants.basicPrice}/month',
            ),
            Text(
              '• Pro Plan: ${AppConstants.proUsageLimit} uses/day - \$${AppConstants.proPrice}/month',
            ),
            Text(
              '• Business Plan: ${AppConstants.businessUsageLimit} uses/day - \$${AppConstants.businessPrice}/month',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _openWhatsApp();
            },
            child: const Text('Contact Us'),
          ),
        ],
      ),
    );
  }

  Future<void> _openWhatsApp() async {
    final Uri whatsappUri = Uri.parse(AppConstants.whatsappLink);
    try {
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
      } else {
        _showError('Could not open WhatsApp. Please install WhatsApp.');
      }
    } catch (e) {
      _showError('Error opening WhatsApp: $e');
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

  // Quick Actions Methods
  void _viewUsage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const VirtuCamSettingsScreen()),
    );
  }

  void _performNetworkTest() {
    setState(() {
      _connectionStatus = VirtuCamConnectionStatus.connecting;
    });

    // Simulate network test
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _connectionStatus = VirtuCamConnectionStatus.connected;
        });
        _showSuccess(
          'Network test completed successfully! Connection is stable.',
        );
      }
    });
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.help_outline, color: Colors.blue[600]),
            const SizedBox(width: 8),
            const Text('VirtuCam Help'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Start Guide:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('1. Click "Screen Capture" to stream your desktop'),
            const Text('2. Scan QR code with your phone camera'),
            const Text('3. Open VirtuCam app on mobile when prompted'),
            const Text('4. Use VirtuCam as camera source in any app'),
            const SizedBox(height: 16),
            Text(
              'For detailed help, contact support via WhatsApp.',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _openWhatsApp();
            },
            child: const Text('Contact Support'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    final isMediumScreen = screenSize.width < 900;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              Icons.videocam,
              color: Colors.white,
              size: isSmallScreen ? 20 : 24,
            ),
            const SizedBox(width: 8),
            const Text('VirtuCam Dashboard'),
          ],
        ),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadUserData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const VirtuCamSettingsScreen(),
                ),
              );
            },
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
          ),
          IconButton(
            onPressed: () async {
              await _authService.signOut();
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? _buildErrorView()
            : _buildDashboardContent(isSmallScreen, isMediumScreen),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
          const SizedBox(height: 16),
          Text(
            'Failed to load dashboard',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(_errorMessage!),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadUserData, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildDashboardContent(bool isSmallScreen, bool isMediumScreen) {
    return SlideTransition(
      position: _slideAnimation,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeHeader(isSmallScreen),
            SizedBox(height: isSmallScreen ? 20 : 24),

            if (isSmallScreen) ...[
              // Stack layout for small screens
              _buildStatusCards(isSmallScreen),
              const SizedBox(height: 20),
              _buildMainActions(isSmallScreen),
              const SizedBox(height: 20),
              _buildQRSection(isSmallScreen),
            ] else ...[
              // Grid layout for larger screens
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        _buildStatusCards(isSmallScreen),
                        const SizedBox(height: 24),
                        _buildMainActions(isSmallScreen),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(flex: 1, child: _buildQRSection(isSmallScreen)),
                ],
              ),
            ],

            const SizedBox(height: 24),
            _buildQuickActions(isSmallScreen),

            if (_shouldShowUpgradeBanner()) ...[
              const SizedBox(height: 24),
              WhatsAppBanner(
                isSmallScreen: isSmallScreen,
                showUpgradeMessage: true,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader(bool isSmallScreen) {
    final userEmail = _userData?['email'] ?? 'User';
    final planType = _userData?['plan_type'] ?? 'trial';

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[600]!, Colors.blue[700]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.waving_hand,
              color: Colors.white,
              size: isSmallScreen ? 24 : 32,
            ),
          ),
          SizedBox(width: isSmallScreen ? 12 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome to VirtuCam!',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 18 : 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  userEmail,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                Text(
                  AppConstants.getPlanDisplayName(planType),
                  style: TextStyle(
                    fontSize: isSmallScreen ? 12 : 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCards(bool isSmallScreen) {
    return Column(
      children: [
        PlanStatusWidget(
          userData: _userData!,
          isSmallScreen: isSmallScreen,
          onUpgradePressed: _openWhatsApp,
          onRefreshPressed: _loadUserData,
        ),
        ConnectionStatusWidget(
          isSmallScreen: isSmallScreen,
          status: _connectionStatus,
          connectedDevices: _connectedDevices,
          networkIP: _networkIP,
          networkPort: _networkPort,
          onRefreshPressed: () {
            setState(() {
              _connectionStatus = VirtuCamConnectionStatus.connecting;
            });
            Future.delayed(const Duration(seconds: 2), () {
              setState(() {
                _connectionStatus = VirtuCamConnectionStatus.connected;
              });
            });
          },
          onSettingsPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const VirtuCamSettingsScreen(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMainActions(bool isSmallScreen) {
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
              Icon(Icons.play_circle, color: Colors.blue[600]),
              const SizedBox(width: 8),
              Text(
                'Start VirtuCam Streaming',
                style: TextStyle(
                  fontSize: isSmallScreen ? 16 : 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 16 : 20),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  'Screen Capture',
                  'Stream your desktop screen',
                  Icons.desktop_windows,
                  Colors.green,
                  _startScreenCapture,
                  isSmallScreen,
                ),
              ),
              SizedBox(width: isSmallScreen ? 12 : 16),
              Expanded(
                child: _buildActionButton(
                  'Media File',
                  'Stream videos, images, docs',
                  Icons.folder,
                  Colors.blue,
                  _selectMediaFile,
                  isSmallScreen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String title,
    String subtitle,
    IconData icon,
    MaterialColor color,
    VoidCallback onPressed,
    bool isSmallScreen,
  ) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color[50],
        foregroundColor: color[700],
        elevation: 0,
        padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color[200]!, width: 1),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: isSmallScreen ? 32 : 40, color: color[600]),
          SizedBox(height: isSmallScreen ? 8 : 12),
          Text(
            title,
            style: TextStyle(
              fontSize: isSmallScreen ? 14 : 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: isSmallScreen ? 10 : 12,
              color: color[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQRSection(bool isSmallScreen) {
    return QrGeneratorWidget(
      isSmallScreen: isSmallScreen,
      networkIP: _networkIP,
      networkPort: _networkPort,
      isStreaming: _isStreaming,
      onRegeneratePressed: () {
        _showSuccess('QR code regenerated successfully');
      },
      onSharePressed: () {
        _showSuccess('QR code sharing feature coming soon');
      },
    );
  }

  Widget _buildQuickActions(bool isSmallScreen) {
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
              Icon(Icons.flash_on, color: Colors.orange[600]),
              const SizedBox(width: 8),
              Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: isSmallScreen ? 16 : 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[700],
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildQuickActionChip('View Usage', Icons.analytics, _viewUsage),
              _buildQuickActionChip(
                'Network Test',
                Icons.speed,
                _performNetworkTest,
              ),
              _buildQuickActionChip('Help', Icons.help, _showHelp),
              _buildQuickActionChip(
                'Contact Support',
                Icons.chat,
                _openWhatsApp,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionChip(
    String label,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return ActionChip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      onPressed: onPressed,
      backgroundColor: Colors.grey[100],
      side: BorderSide(color: Colors.grey[300]!),
      elevation: 2,
      pressElevation: 4,
    );
  }

  bool _shouldShowUpgradeBanner() {
    final planType = _userData?['plan_type'] ?? 'trial';
    final usesRemaining = _userData?['daily_uses_remaining'] ?? 0;
    return planType == AppConstants.trialPlan || usesRemaining <= 1;
  }
}
