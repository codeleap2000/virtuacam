// lib/services/device_service.dart
import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../core/constants/app_constants.dart';

class DeviceService {
  static const String _deviceIdKey = 'virtuacam_device_id';
  static const String _deviceFingerprintKey = 'virtuacam_device_fingerprint';
  static const String _trialUsedKey = 'virtuacam_trial_used';
  static const String _firstLaunchKey = 'virtuacam_first_launch';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static String? _cachedDeviceId;
  static String? _cachedFingerprint;

  Future<String> getDeviceId() async {
    if (_cachedDeviceId != null) return _cachedDeviceId!;

    try {
      final prefs = await SharedPreferences.getInstance();
      String? deviceId = prefs.getString(_deviceIdKey);

      if (deviceId == null) {
        deviceId = await _generateDeviceFingerprint();
        await prefs.setString(_deviceIdKey, deviceId);
        await _markFirstLaunch();
      }

      _cachedDeviceId = deviceId;
      return deviceId;
    } catch (e) {
      throw Exception('Failed to get device ID: $e');
    }
  }

  Future<String> getDeviceFingerprint() async {
    if (_cachedFingerprint != null) return _cachedFingerprint!;

    try {
      final prefs = await SharedPreferences.getInstance();
      String? fingerprint = prefs.getString(_deviceFingerprintKey);

      if (fingerprint == null) {
        fingerprint = await _generateHardwareFingerprint();
        await prefs.setString(_deviceFingerprintKey, fingerprint);
      }

      _cachedFingerprint = fingerprint;
      return fingerprint;
    } catch (e) {
      throw Exception('Failed to get device fingerprint: $e');
    }
  }

  Future<String> _generateDeviceFingerprint() async {
    try {
      final hardwareInfo = await _getHardwareInfo();
      final platformInfo = _getPlatformInfo();
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();

      final combinedInfo = '$hardwareInfo$platformInfo$timestamp';
      final bytes = utf8.encode(combinedInfo);
      final digest = sha256.convert(bytes);

      return digest.toString();
    } catch (e) {
      return _generateFallbackId();
    }
  }

  Future<String> _generateHardwareFingerprint() async {
    try {
      final hardwareInfo = await _getHardwareInfo();
      final bytes = utf8.encode(hardwareInfo);
      final digest = sha256.convert(bytes);

      return digest.toString();
    } catch (e) {
      return _generateFallbackId();
    }
  }

  Future<String> _getHardwareInfo() async {
    if (Platform.isMacOS) {
      return await _getMacOSHardwareInfo();
    } else if (Platform.isWindows) {
      return await _getWindowsHardwareInfo();
    } else {
      return _generateFallbackId();
    }
  }

  Future<String> _getMacOSHardwareInfo() async {
    try {
      final results = <String>[];

      final systemProfilerResult = await Process.run('system_profiler', [
        'SPHardwareDataType',
      ]);

      if (systemProfilerResult.exitCode == 0) {
        final output = systemProfilerResult.stdout.toString();

        final uuidMatch = RegExp(r'Hardware UUID:\s*(.+)').firstMatch(output);
        if (uuidMatch != null) {
          results.add('UUID:${uuidMatch.group(1)?.trim()}');
        }

        final serialMatch = RegExp(
          r'Serial Number \(system\):\s*(.+)',
        ).firstMatch(output);
        if (serialMatch != null) {
          results.add('SERIAL:${serialMatch.group(1)?.trim()}');
        }

        final modelMatch = RegExp(
          r'Model Identifier:\s*(.+)',
        ).firstMatch(output);
        if (modelMatch != null) {
          results.add('MODEL:${modelMatch.group(1)?.trim()}');
        }
      }

      final ioreg = await Process.run('ioreg', ['-l']);
      if (ioreg.exitCode == 0) {
        final output = ioreg.stdout.toString();
        final cpuMatch = RegExp(
          r'"IOPlatformSerialNumber"\s*=\s*"([^"]+)"',
        ).firstMatch(output);
        if (cpuMatch != null) {
          results.add('PLATFORM:${cpuMatch.group(1)}');
        }
      }

      return results.isNotEmpty ? results.join('|') : _generateFallbackId();
    } catch (e) {
      return _generateFallbackId();
    }
  }

  Future<String> _getWindowsHardwareInfo() async {
    try {
      final results = <String>[];

      final motherboardResult = await Process.run('wmic', [
        'baseboard',
        'get',
        'serialnumber',
        '/value',
      ]);

      if (motherboardResult.exitCode == 0) {
        final output = motherboardResult.stdout.toString();
        final serialMatch = RegExp(r'SerialNumber=(.+)').firstMatch(output);
        if (serialMatch != null &&
            serialMatch.group(1)?.trim().isNotEmpty == true) {
          results.add('MB:${serialMatch.group(1)?.trim()}');
        }
      }

      final cpuResult = await Process.run('wmic', [
        'cpu',
        'get',
        'processorid',
        '/value',
      ]);

      if (cpuResult.exitCode == 0) {
        final output = cpuResult.stdout.toString();
        final cpuMatch = RegExp(r'ProcessorId=(.+)').firstMatch(output);
        if (cpuMatch != null && cpuMatch.group(1)?.trim().isNotEmpty == true) {
          results.add('CPU:${cpuMatch.group(1)?.trim()}');
        }
      }

      final biosResult = await Process.run('wmic', [
        'bios',
        'get',
        'serialnumber',
        '/value',
      ]);

      if (biosResult.exitCode == 0) {
        final output = biosResult.stdout.toString();
        final biosMatch = RegExp(r'SerialNumber=(.+)').firstMatch(output);
        if (biosMatch != null &&
            biosMatch.group(1)?.trim().isNotEmpty == true) {
          results.add('BIOS:${biosMatch.group(1)?.trim()}');
        }
      }

      final systemResult = await Process.run('wmic', [
        'csproduct',
        'get',
        'uuid',
        '/value',
      ]);

      if (systemResult.exitCode == 0) {
        final output = systemResult.stdout.toString();
        final uuidMatch = RegExp(r'UUID=(.+)').firstMatch(output);
        if (uuidMatch != null &&
            uuidMatch.group(1)?.trim().isNotEmpty == true) {
          results.add('UUID:${uuidMatch.group(1)?.trim()}');
        }
      }

      return results.isNotEmpty ? results.join('|') : _generateFallbackId();
    } catch (e) {
      return _generateFallbackId();
    }
  }

  String _getPlatformInfo() {
    return '${Platform.operatingSystem}|${Platform.operatingSystemVersion}';
  }

  String _generateFallbackId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 1000000).toString();
    final platform = Platform.operatingSystem;
    return 'FALLBACK_${platform}_$random';
  }

  Future<void> _markFirstLaunch() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_firstLaunchKey, true);
    } catch (e) {
      debugPrint('Failed to mark first launch: $e');
    }
  }

  Future<bool> isFirstLaunch() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return !prefs.containsKey(_firstLaunchKey);
    } catch (e) {
      return true;
    }
  }

  Future<void> trackDeviceInFirebase(String userId) async {
    try {
      final deviceId = await getDeviceId();
      final fingerprint = await getDeviceFingerprint();
      final timestamp = Timestamp.now();

      final deviceDoc = _firestore
          .collection(AppConstants.firebaseDeviceTrackingCollection)
          .doc(deviceId);

      final existingDoc = await deviceDoc.get();

      if (existingDoc.exists) {
        await deviceDoc.update({
          'user_id': userId,
          'last_seen': timestamp,
          'updated_at': timestamp,
        });
      } else {
        await deviceDoc.set({
          'device_id': deviceId,
          'hardware_fingerprint': fingerprint,
          'user_id': userId,
          'first_seen': timestamp,
          'last_seen': timestamp,
          'created_at': timestamp,
          'updated_at': timestamp,
          'trial_used': false,
          'app_version': AppConstants.appVersion,
          'platform': Platform.operatingSystem,
          'platform_version': Platform.operatingSystemVersion,
        });
      }
    } catch (e) {
      throw Exception('Failed to track device: $e');
    }
  }

  Future<bool> hasTrialBeenUsed() async {
    try {
      final deviceId = await getDeviceId();

      final deviceDoc = await _firestore
          .collection(AppConstants.firebaseDeviceTrackingCollection)
          .doc(deviceId)
          .get();

      if (deviceDoc.exists) {
        final data = deviceDoc.data()!;
        return data['trial_used'] as bool? ?? false;
      }

      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_trialUsedKey) ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<void> markTrialAsUsed() async {
    try {
      final deviceId = await getDeviceId();

      await _firestore
          .collection(AppConstants.firebaseDeviceTrackingCollection)
          .doc(deviceId)
          .update({
            'trial_used': true,
            'trial_used_at': Timestamp.now(),
            'updated_at': Timestamp.now(),
          });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_trialUsedKey, true);
    } catch (e) {
      throw Exception('Failed to mark trial as used: $e');
    }
  }

  Future<bool> canUseTrial() async {
    try {
      return !(await hasTrialBeenUsed());
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> getDeviceInfo() async {
    try {
      final deviceId = await getDeviceId();
      final fingerprint = await getDeviceFingerprint();
      final trialUsed = await hasTrialBeenUsed();
      final firstLaunch = await isFirstLaunch();

      return {
        'device_id': deviceId,
        'fingerprint': fingerprint,
        'trial_used': trialUsed,
        'first_launch': firstLaunch,
        'platform': Platform.operatingSystem,
        'platform_version': Platform.operatingSystemVersion,
      };
    } catch (e) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getUserDevices(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(AppConstants.firebaseDeviceTrackingCollection)
          .where('user_id', isEqualTo: userId)
          .orderBy('last_seen', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Failed to get user devices: $e');
    }
  }

  Future<void> clearDeviceData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_deviceIdKey);
      await prefs.remove(_deviceFingerprintKey);
      await prefs.remove(_trialUsedKey);
      await prefs.remove(_firstLaunchKey);

      _cachedDeviceId = null;
      _cachedFingerprint = null;
    } catch (e) {
      throw Exception('Failed to clear device data: $e');
    }
  }

  Future<bool> validateDeviceIntegrity() async {
    try {
      final currentFingerprint = await _generateHardwareFingerprint();
      final storedFingerprint = await getDeviceFingerprint();

      return currentFingerprint == storedFingerprint;
    } catch (e) {
      return false;
    }
  }
}
