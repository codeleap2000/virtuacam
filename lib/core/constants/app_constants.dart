// lib/core/constants/app_constants.dart
import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'VirtuCam';
  static const String appVersion = '1.0.0';
  static const String whatsappLink =
      'https://wa.me/923024981975?text=Hi%2C%20I%20need%20a%20VirtuCam%20account';
  static const String adminPlan = 'admin';
  static const int adminUsageLimit = -1;
  static const primaryColor = Colors.blue;
  static const errorColor = Colors.red;
  static const successColor = Colors.green;
  static const backgroundColor = Color(0xFFF5F5F5);
  static const cardColor = Colors.white;
  static const textColor = Color(0xFF2C3E50);
  static const subtitleColor = Color(0xFF7F8C8D);

  static const titleTextStyle = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: primaryColor,
  );

  static const subtitleTextStyle = TextStyle(fontSize: 16, color: Colors.grey);

  static const double defaultPadding = 16.0;
  static const double largePadding = 32.0;
  static const double smallPadding = 8.0;
  static const double extraLargePadding = 48.0;

  static const double defaultBorderRadius = 8.0;
  static const double largeBorderRadius = 16.0;
  static const double smallBorderRadius = 4.0;

  static const String trialPlan = 'trial';
  static const String basicPlan = 'basic';
  static const String proPlan = 'pro';
  static const String businessPlan = 'business';
  static const String enterprisePlan = 'enterprise';

  static const double basicPrice = 29.99;
  static const double proPrice = 59.99;
  static const double businessPrice = 99.99;
  static const double enterprisePrice = 199.99;

  static const int trialUsageLimit = 1;
  static const int basicUsageLimit = 2;
  static const int proUsageLimit = 8;
  static const int businessUsageLimit = 15;
  static const int enterpriseUsageLimit = 25;

  static const Duration sessionTimeout = Duration(hours: 24);
  static const Duration cacheTimeout = Duration(hours: 1);
  static const Duration networkTimeout = Duration(seconds: 30);

  static const String supportEmail = 'support@virtuacam.com';
  static const String privacyPolicyUrl = 'https://virtuacam.com/privacy';
  static const String termsOfServiceUrl = 'https://virtuacam.com/terms';

  static const List<String> supportedVideoFormats = [
    'mp4',
    'avi',
    'mov',
    'mkv',
    'wmv',
    'flv',
    'webm',
  ];

  static const List<String> supportedImageFormats = [
    'jpg',
    'jpeg',
    'png',
    'gif',
    'bmp',
    'webp',
  ];

  static const List<String> supportedDocumentFormats = [
    'pdf',
    'doc',
    'docx',
    'txt',
  ];

  static const Map<String, String> qualitySettings = {
    '480p': '854x480',
    '720p': '1280x720',
    '1080p': '1920x1080',
    '4K': '3840x2160',
  };

  static const List<int> frameRateOptions = [15, 30, 60];

  static const String defaultQuality = '1080p';
  static const int defaultFrameRate = 30;
  static const bool defaultAudioEnabled = false;

  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(seconds: 2);

  static const String firebaseUsersCollection = 'virtuacam_users';
  static const String firebaseDeviceTrackingCollection =
      'virtuacam_device_tracking';
  static const String firebaseUsageLogsCollection = 'virtuacam_usage_logs';
  static const String firebaseSessionsCollection = 'virtuacam_sessions';

  static const String deviceIdKey = 'virtuacam_device_id';
  static const String userPreferencesKey = 'virtuacam_preferences';
  static const String cacheKey = 'virtuacam_cache';

  static const String logLevelDebug = 'DEBUG';
  static const String logLevelInfo = 'INFO';
  static const String logLevelWarning = 'WARNING';
  static const String logLevelError = 'ERROR';

  static const Map<String, Color> planColors = {
    trialPlan: Colors.grey,
    basicPlan: Colors.blue,
    proPlan: Colors.purple,
    businessPlan: Colors.orange,
    enterprisePlan: Colors.green,
  };

  static const Map<String, String> errorMessages = {
    'network_error':
        'Network connection failed. Please check your internet connection.',
    'auth_error': 'Authentication failed. Please check your credentials.',
    'permission_denied': 'Permission denied. Please contact support.',
    'quota_exceeded': 'Daily usage limit exceeded. Please upgrade your plan.',
    'device_limit_reached': 'Maximum device limit reached for your plan.',
    'trial_already_used': 'Trial has already been used on this device.',
    'invalid_qr_code': 'Invalid QR code. Please try again.',
    'connection_timeout': 'Connection timeout. Please try again.',
    'unsupported_format': 'File format not supported.',
    'file_too_large': 'File size too large. Maximum size is 100MB.',
  };

  static const Map<String, String> successMessages = {
    'login_success': 'Successfully signed in to VirtuCam!',
    'logout_success': 'Successfully signed out.',
    'stream_started': 'VirtuCam streaming started successfully!',
    'stream_stopped': 'VirtuCam streaming stopped.',
    'device_connected': 'Mobile device connected to VirtuCam.',
    'file_selected': 'Media file selected successfully.',
    'settings_saved': 'Settings saved successfully.',
    'password_reset_sent': 'Password reset email sent.',
  };

  static const String defaultStreamingIP = '192.168.1.100';
  static const int defaultStreamingPort = 8080;
  static const String defaultProtocol = 'WebRTC';

  static const Duration qrCodeRefreshInterval = Duration(minutes: 5);
  static const Duration heartbeatInterval = Duration(seconds: 10);
  static const Duration connectionTimeout = Duration(seconds: 30);

  static String getPlanDisplayName(String planType) {
    switch (planType) {
      case trialPlan:
        return 'VirtuCam Trial';
      case basicPlan:
        return 'VirtuCam Basic';
      case proPlan:
        return 'VirtuCam Pro';
      case businessPlan:
        return 'VirtuCam Business';
      case enterprisePlan:
        return 'VirtuCam Enterprise';
      default:
        return 'VirtuCam Plan';
    }
  }

  static int getPlanUsageLimit(String planType) {
    switch (planType) {
      case trialPlan:
        return trialUsageLimit;
      case basicPlan:
        return basicUsageLimit;
      case proPlan:
        return proUsageLimit;
      case businessPlan:
        return businessUsageLimit;
      case enterprisePlan:
        return enterpriseUsageLimit;
      default:
        return 0;
    }
  }

  static double getPlanPrice(String planType) {
    switch (planType) {
      case basicPlan:
        return basicPrice;
      case proPlan:
        return proPrice;
      case businessPlan:
        return businessPrice;
      case enterprisePlan:
        return enterprisePrice;
      default:
        return 0.0;
    }
  }

  static Color getPlanColor(String planType) {
    return planColors[planType] ?? Colors.grey;
  }
}
