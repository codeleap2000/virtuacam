import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:virtuacam/presentation/widgets/auth_wrapper.dart';
import 'firebase_options.dart';
import 'presentation/screens/desktop/login_screen.dart';
import 'presentation/screens/desktop/dashboard_screen.dart';
import 'services/device_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await _initializeVirtuCamDevice();

  runApp(const VirtuCamApp());
}

Future<void> _initializeVirtuCamDevice() async {
  try {
    final deviceService = DeviceService();
    final deviceId = await deviceService.getDeviceId();
    final fingerprint = await deviceService.getDeviceFingerprint();
    final isFirstLaunch = await deviceService.isFirstLaunch();

    debugPrint('VirtuCam Device ID: ${deviceId.substring(0, 8)}...');
    debugPrint('VirtuCam First Launch: $isFirstLaunch');
    debugPrint('VirtuCam Device initialized successfully');
  } catch (e) {
    debugPrint('VirtuCam device initialization failed: $e');
  }
}

class VirtuCamApp extends StatelessWidget {
  const VirtuCamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VirtuCam',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 3,
            shadowColor: Colors.black26,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 4,
          shadowColor: Colors.black12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      home: const VirtuCamAuthWrapper(),
      routes: {
        '/login': (context) => const VirtuCamLoginScreen(),
        '/dashboard': (context) => const VirtuCamDashboard(),
      },
    );
  }
}
