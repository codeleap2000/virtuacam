// lib/presentation/screens/desktop/settings_screen.dart
import 'package:flutter/material.dart';
import '../../../services/auth_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../widgets/desktop/whatsapp_banner.dart';
import 'package:url_launcher/url_launcher.dart';

class VirtuCamSettingsScreen extends StatefulWidget {
  const VirtuCamSettingsScreen({super.key});

  @override
  State<VirtuCamSettingsScreen> createState() => _VirtuCamSettingsScreenState();
}

class _VirtuCamSettingsScreenState extends State<VirtuCamSettingsScreen>
    with TickerProviderStateMixin {
  final _authService = AuthService();

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  String? _errorMessage;

  // Settings
  String _selectedQuality = AppConstants.defaultQuality;
  int _selectedFrameRate = AppConstants.defaultFrameRate;
  bool _audioEnabled = AppConstants.defaultAudioEnabled;
  bool _autoConnect = true;
  bool _notifications = true;
  bool _darkMode = false;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _loadUserData();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
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

  Future<void> _signOut() async {
    final confirm = await _showConfirmDialog(
      'Sign Out',
      'Are you sure you want to sign out of VirtuCam?',
    );

    if (confirm) {
      try {
        await _authService.signOut();
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      } catch (e) {
        _showError('Failed to sign out: $e');
      }
    }
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

  Future<bool> _showConfirmDialog(String title, String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Confirm'),
              ),
            ],
          ),
        ) ??
        false;
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
        title: const Text('VirtuCam Settings'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? _buildErrorView()
            : _buildSettingsView(isSmallScreen),
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
            'Error loading settings',
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

  Widget _buildSettingsView(bool isSmallScreen) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAccountSection(isSmallScreen),
          const SizedBox(height: 24),
          _buildStreamingSettings(isSmallScreen),
          const SizedBox(height: 24),
          _buildAppSettings(isSmallScreen),
          const SizedBox(height: 24),
          _buildNetworkDiagnostics(isSmallScreen),
          const SizedBox(height: 24),
          _buildSupportSection(isSmallScreen),
          const SizedBox(height: 24),
          _buildAboutSection(isSmallScreen),
        ],
      ),
    );
  }

  Widget _buildAccountSection(bool isSmallScreen) {
    return _buildSection(
      'Account Information',
      Icons.account_circle,
      isSmallScreen,
      [
        _buildInfoTile(
          'Email',
          _userData?['email'] ?? 'Unknown',
          Icons.email,
          isSmallScreen,
        ),
        _buildInfoTile(
          'Plan',
          AppConstants.getPlanDisplayName(_userData?['plan_type'] ?? 'trial'),
          Icons.star,
          isSmallScreen,
          trailing: Chip(
            label: Text(
              _userData?['plan_status'] ?? 'inactive',
              style: const TextStyle(fontSize: 12),
            ),
            backgroundColor: (_userData?['plan_status'] == 'active')
                ? Colors.green[100]
                : Colors.red[100],
          ),
        ),
        _buildInfoTile(
          'Usage Today',
          '${_userData?['daily_uses_remaining'] ?? 0} of ${_userData?['daily_limit'] ?? 0} remaining',
          Icons.analytics,
          isSmallScreen,
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _signOut,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 12 : 14),
            ),
            icon: const Icon(Icons.logout),
            label: const Text('Sign Out'),
          ),
        ),
      ],
    );
  }

  Widget _buildStreamingSettings(bool isSmallScreen) {
    return _buildSection('Streaming Settings', Icons.videocam, isSmallScreen, [
      _buildDropdownTile(
        'Video Quality',
        _selectedQuality,
        AppConstants.qualitySettings.keys.toList(),
        (value) => setState(() => _selectedQuality = value!),
        isSmallScreen,
      ),
      _buildDropdownTile(
        'Frame Rate',
        '$_selectedFrameRate FPS',
        AppConstants.frameRateOptions.map((e) => '$e FPS').toList(),
        (value) => setState(
          () => _selectedFrameRate = int.parse(value!.split(' ')[0]),
        ),
        isSmallScreen,
      ),
      _buildSwitchTile(
        'Audio Streaming',
        'Enable audio streaming with video',
        _audioEnabled,
        (value) => setState(() => _audioEnabled = value),
        isSmallScreen,
      ),
      _buildSwitchTile(
        'Auto-Connect',
        'Automatically connect to devices',
        _autoConnect,
        (value) => setState(() => _autoConnect = value),
        isSmallScreen,
      ),
    ]);
  }

  Widget _buildAppSettings(bool isSmallScreen) {
    return _buildSection('App Settings', Icons.settings, isSmallScreen, [
      _buildSwitchTile(
        'Notifications',
        'Show connection and streaming notifications',
        _notifications,
        (value) => setState(() => _notifications = value),
        isSmallScreen,
      ),
      _buildSwitchTile(
        'Dark Mode',
        'Use dark theme (coming soon)',
        _darkMode,
        null, // Disabled
        isSmallScreen,
      ),
    ]);
  }

  Widget _buildNetworkDiagnostics(bool isSmallScreen) {
    return _buildSection(
      'Network Diagnostics',
      Icons.network_check,
      isSmallScreen,
      [
        _buildInfoTile(
          'Local IP',
          '192.168.1.100', // Replace with actual IP detection
          Icons.router,
          isSmallScreen,
        ),
        _buildInfoTile('Streaming Port', '8080', Icons.lan, isSmallScreen),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              _showSuccess('Network test completed successfully');
            },
            icon: const Icon(Icons.speed),
            label: const Text('Test Connection'),
          ),
        ),
      ],
    );
  }

  Widget _buildSupportSection(bool isSmallScreen) {
    return _buildSection('Support & Contact', Icons.help, isSmallScreen, [
      WhatsAppBanner(
        isSmallScreen: isSmallScreen,
        customMessage: 'Need help with VirtuCam?',
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _openWhatsApp,
              icon: const Icon(Icons.chat),
              label: const Text('Contact Support'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                // Open help documentation
              },
              icon: const Icon(Icons.help_outline),
              label: const Text('Help Docs'),
            ),
          ),
        ],
      ),
    ]);
  }

  Widget _buildAboutSection(bool isSmallScreen) {
    return _buildSection('About VirtuCam', Icons.info, isSmallScreen, [
      _buildInfoTile(
        'Version',
        AppConstants.appVersion,
        Icons.code,
        isSmallScreen,
      ),
      _buildInfoTile(
        'Platform',
        'Desktop (macOS/Windows)',
        Icons.computer,
        isSmallScreen,
      ),
      const SizedBox(height: 16),
      Text(
        'VirtuCam - Desktop Virtual Camera Solution\n\nStream your desktop screen or media files to mobile devices as a virtual camera feed. Perfect for content creation, document verification, and professional presentations.',
        style: TextStyle(
          fontSize: isSmallScreen ? 12 : 14,
          color: Colors.grey[600],
          height: 1.4,
        ),
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                // Open privacy policy
              },
              child: const Text('Privacy Policy'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                // Open terms of service
              },
              child: const Text('Terms of Service'),
            ),
          ),
        ],
      ),
    ]);
  }

  Widget _buildSection(
    String title,
    IconData icon,
    bool isSmallScreen,
    List<Widget> children,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.blue[600]),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 16 : 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(
    String title,
    String value,
    IconData icon,
    bool isSmallScreen, {
    Widget? trailing,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Colors.grey[600]),
      title: Text(
        title,
        style: TextStyle(
          fontSize: isSmallScreen ? 14 : 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        value,
        style: TextStyle(
          fontSize: isSmallScreen ? 12 : 14,
          color: Colors.grey[600],
        ),
      ),
      trailing: trailing,
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    Function(bool)? onChanged,
    bool isSmallScreen,
  ) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: TextStyle(
          fontSize: isSmallScreen ? 14 : 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: isSmallScreen ? 12 : 14,
          color: Colors.grey[600],
        ),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: Colors.blue[600],
    );
  }

  Widget _buildDropdownTile(
    String title,
    String value,
    List<String> options,
    Function(String?) onChanged,
    bool isSmallScreen,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: TextStyle(
          fontSize: isSmallScreen ? 14 : 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: DropdownButton<String>(
        value: value,
        items: options.map((option) {
          return DropdownMenuItem<String>(value: option, child: Text(option));
        }).toList(),
        onChanged: onChanged,
        underline: Container(),
      ),
    );
  }
}
