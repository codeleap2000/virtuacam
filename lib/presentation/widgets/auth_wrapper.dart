import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/desktop/login_screen.dart';
import '../screens/desktop/dashboard_screen.dart';
import '../../services/device_service.dart';

class VirtuCamAuthWrapper extends StatelessWidget {
  const VirtuCamAuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const VirtuCamSplashScreen();
        }

        if (snapshot.hasData && snapshot.data != null) {
          return const VirtuCamDashboard();
        }

        return const VirtuCamLoginScreen();
      },
    );
  }
}

class VirtuCamSplashScreen extends StatefulWidget {
  const VirtuCamSplashScreen({super.key});

  @override
  State<VirtuCamSplashScreen> createState() => _VirtuCamSplashScreenState();
}

class _VirtuCamSplashScreenState extends State<VirtuCamSplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late Animation<double> _logoAnimation;
  late Animation<double> _textAnimation;

  bool _showDeviceInfo = false;
  String _deviceStatus = 'Initializing VirtuCam...';

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _textController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _logoAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    _textAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeInOut),
    );

    _initializeApp();
  }

  Future<void> _initializeApp() async {
    if (!mounted) return;
    _logoController.forward();

    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    _textController.forward();

    if (mounted) {
      setState(() {
        _deviceStatus = 'Configuring device fingerprint...';
        _showDeviceInfo = true;
      });
    }

    try {
      final deviceService = DeviceService();
      await deviceService.getDeviceInfo();

      if (mounted) {
        setState(() {
          _deviceStatus = 'Device configured successfully';
        });
      }

      await Future.delayed(const Duration(milliseconds: 800));

      if (mounted) {
        setState(() {
          _deviceStatus = 'Loading VirtuCam...';
        });
      }

      await Future.delayed(const Duration(milliseconds: 500));
    } catch (e) {
      if (mounted) {
        setState(() {
          _deviceStatus = 'Device configuration warning';
        });
      }
      await Future.delayed(const Duration(milliseconds: 1000));
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _logoAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _logoAnimation.value,
                  child: Container(
                    padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
                    decoration: BoxDecoration(
                      color: Colors.blue[600],
                      borderRadius: BorderRadius.circular(50),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.videocam,
                      size: isSmallScreen ? 48 : 64,
                      color: Colors.white,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 32),

            AnimatedBuilder(
              animation: _textAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _textAnimation.value,
                  child: Column(
                    children: [
                      Text(
                        'VirtuCam',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 32 : 42,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Desktop Virtual Camera Solution',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 14 : 16,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 48),

            if (_showDeviceInfo) ...[
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
                ),
              ),

              const SizedBox(height: 16),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  _deviceStatus,
                  key: ValueKey(_deviceStatus),
                  style: TextStyle(
                    fontSize: isSmallScreen ? 12 : 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],

            const SizedBox(height: 32),

            Text(
              'v1.0.0',
              style: TextStyle(fontSize: 10, color: Colors.grey[400]),
            ),
          ],
        ),
      ),
    );
  }
}
