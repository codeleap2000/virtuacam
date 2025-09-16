// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';
import 'device_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DeviceService _deviceService = DeviceService();

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  bool get isAuthenticated => _auth.currentUser != null;

  Future<UserCredential> signInWithEmail(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (userCredential.user != null) {
        await _deviceService.trackDeviceInFirebase(userCredential.user!.uid);
        await _updateLastLogin(userCredential.user!.uid);
        await _resetDailyUsageIfNeeded(userCredential.user!.uid);
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('An unexpected error occurred during sign in');
    }
  }

  Future<UserCredential> createUserWithEmail(
    String email,
    String password,
  ) async {
    try {
      final hasTrialBeenUsed = await _deviceService.hasTrialBeenUsed();
      if (hasTrialBeenUsed) {
        throw Exception(
          'Trial has already been used on this device. Contact us on WhatsApp for a new account.',
        );
      }

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (userCredential.user != null) {
        await _createUserDocument(userCredential.user!);
        await _deviceService.trackDeviceInFirebase(userCredential.user!.uid);
        await userCredential.user!.sendEmailVerification();
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Failed to sign out');
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Failed to send password reset email');
    }
  }

  Future<void> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      } else {
        throw Exception('No user found or email already verified');
      }
    } catch (e) {
      throw Exception('Failed to send verification email');
    }
  }

  Future<void> reloadUser() async {
    try {
      await _auth.currentUser?.reload();
    } catch (e) {
      throw Exception('Failed to reload user data');
    }
  }

  Future<void> updatePassword(
    String currentPassword,
    String newPassword,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user found');

      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Failed to update password');
    }
  }

  Future<void> updateEmail(String newEmail, String password) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user found');

      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );

      await user.reauthenticateWithCredential(credential);
      await user.verifyBeforeUpdateEmail(newEmail.trim());

      await _firestore
          .collection(AppConstants.firebaseUsersCollection)
          .doc(user.uid)
          .update({
            'email': newEmail.trim(),
            'email_verified': false,
            'updated_at': Timestamp.now(),
          });
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Failed to update email');
    }
  }

  Future<void> deleteAccount(String password) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user found');

      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );

      await user.reauthenticateWithCredential(credential);

      await _firestore
          .collection(AppConstants.firebaseUsersCollection)
          .doc(user.uid)
          .delete();

      await user.delete();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Failed to delete account');
    }
  }

  Future<void> _createUserDocument(User user) async {
    try {
      final deviceInfo = await _deviceService.getDeviceInfo();
      final userDoc = _firestore
          .collection(AppConstants.firebaseUsersCollection)
          .doc(user.uid);

      await userDoc.set({
        'email': user.email,
        'plan_type': AppConstants.trialPlan,
        'plan_status': 'active',
        'daily_uses_remaining': AppConstants.trialUsageLimit,
        'daily_limit': AppConstants.trialUsageLimit,
        'plan_expiry': null,
        'last_reset_date': Timestamp.now(),
        'created_at': Timestamp.now(),
        'updated_at': Timestamp.now(),
        'last_login': Timestamp.now(),
        'device_ids': [deviceInfo?['device_id']],
        'app_version': AppConstants.appVersion,
        'email_verified': user.emailVerified,
        'total_usage_count': 0,
        'subscription_start_date': null,
        'subscription_end_date': null,
        'payment_method': null,
        'billing_cycle': null,
        'auto_renew': false,
        'trial_used': false,
        'account_status': 'active',
        'device_fingerprint': deviceInfo?['fingerprint'],
        'platform': deviceInfo?['platform'],
        'platform_version': deviceInfo?['platform_version'],
      });
    } catch (e) {
      throw Exception('Failed to create user profile');
    }
  }

  Future<void> _updateLastLogin(String userId) async {
    try {
      await _firestore
          .collection(AppConstants.firebaseUsersCollection)
          .doc(userId)
          .update({
            'last_login': Timestamp.now(),
            'updated_at': Timestamp.now(),
          });
    } catch (e) {
      print('Failed to update last login: $e');
    }
  }

  Future<void> _resetDailyUsageIfNeeded(String userId) async {
    try {
      final userDoc = await _firestore
          .collection(AppConstants.firebaseUsersCollection)
          .doc(userId)
          .get();

      if (!userDoc.exists) return;

      final userData = userDoc.data()!;
      final lastResetDate = userData['last_reset_date'] as Timestamp?;
      final planType = userData['plan_type'] as String? ?? 'trial';
      final now = DateTime.now();

      if (lastResetDate == null) return;

      final lastReset = lastResetDate.toDate();
      final daysSinceReset = now.difference(lastReset).inDays;

      if (daysSinceReset >= 1) {
        final dailyLimit = _getPlanUsageLimit(planType);

        await _firestore
            .collection(AppConstants.firebaseUsersCollection)
            .doc(userId)
            .update({
              'daily_uses_remaining': dailyLimit,
              'last_reset_date': Timestamp.now(),
              'updated_at': Timestamp.now(),
            });
      }
    } catch (e) {
      print('Failed to reset daily usage: $e');
    }
  }

  Future<Map<String, dynamic>?> getUserData() async {
    try {
      final user = currentUser;
      if (user == null) return null;

      final doc = await _firestore
          .collection(AppConstants.firebaseUsersCollection)
          .doc(user.uid)
          .get();

      if (!doc.exists) {
        await _createUserDocument(user);
        return await getUserData();
      }

      return doc.data();
    } catch (e) {
      throw Exception('Failed to load user data');
    }
  }

  Future<void> updateUserPlan(String planType, int dailyLimit) async {
    try {
      if (!_isValidPlan(planType)) {
        throw Exception('Invalid plan type');
      }

      final user = currentUser;
      if (user == null) throw Exception('No user found');

      final subscriptionStartDate = Timestamp.now();
      final subscriptionEndDate = Timestamp.fromDate(
        DateTime.now().add(const Duration(days: 30)),
      );

      await _firestore
          .collection(AppConstants.firebaseUsersCollection)
          .doc(user.uid)
          .update({
            'plan_type': planType,
            'daily_limit': dailyLimit,
            'daily_uses_remaining': dailyLimit,
            'plan_status': 'active',
            'subscription_start_date': subscriptionStartDate,
            'subscription_end_date': subscriptionEndDate,
            'last_reset_date': Timestamp.now(),
            'updated_at': Timestamp.now(),
            'auto_renew': true,
            'billing_cycle': 'monthly',
          });
    } catch (e) {
      throw Exception('Failed to update user plan');
    }
  }

  Future<bool> decrementDailyUsage() async {
    try {
      final user = currentUser;
      if (user == null) return false;

      final userData = await getUserData();
      final planType = userData?['plan_type'] ?? 'trial';

      // Admin accounts don't decrement usage
      if (planType == AppConstants.adminPlan) return true;

      final canUse = await canUseService();
      if (!canUse) return false;

      final userRef = _firestore
          .collection(AppConstants.firebaseUsersCollection)
          .doc(user.uid);

      final success = await _firestore.runTransaction((transaction) async {
        final userDoc = await transaction.get(userRef);

        if (!userDoc.exists) return false;

        final userData = userDoc.data()!;
        final usesRemaining = userData['daily_uses_remaining'] as int? ?? 0;
        final totalUsage = userData['total_usage_count'] as int? ?? 0;

        if (usesRemaining <= 0) return false;

        transaction.update(userRef, {
          'daily_uses_remaining': usesRemaining - 1,
          'total_usage_count': totalUsage + 1,
          'updated_at': Timestamp.now(),
        });

        return true;
      });

      if (success) {
        if (planType == AppConstants.trialPlan) {
          await _deviceService.markTrialAsUsed();
        }

        await _logUsage(user.uid, planType);
      }

      return success;
    } catch (e) {
      throw Exception('Failed to update usage count');
    }
  }

  Future<void> _logUsage(String userId, String planType) async {
    try {
      final deviceInfo = await _deviceService.getDeviceInfo();

      await _firestore
          .collection(AppConstants.firebaseUsageLogsCollection)
          .add({
            'user_id': userId,
            'device_id': deviceInfo?['device_id'],
            'timestamp': Timestamp.now(),
            'action': 'stream_started',
            'plan_type': planType,
            'app_version': AppConstants.appVersion,
            'platform': deviceInfo?['platform'],
            'duration': 0,
          });
    } catch (e) {
      print('Failed to log usage: $e');
    }
  }

  Future<bool> canUseService() async {
    try {
      final userData = await getUserData();
      if (userData == null) return false;

      final planType = userData['plan_type'] as String? ?? 'trial';
      final planStatus = userData['plan_status'] as String? ?? 'expired';
      final usesRemaining = userData['daily_uses_remaining'] as int? ?? 0;

      // Admin unlimited access
      if (planType == AppConstants.adminPlan) return true;

      // Check plan is active
      if (planStatus != 'active') return false;

      // Check usage limits for all plans
      if (usesRemaining <= 0) return false;

      // Trial device verification
      if (planType == AppConstants.trialPlan) {
        return await _deviceService.canUseTrial();
      }

      // All other plans (basic/pro/business/enterprise) allowed if active and has remaining uses
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> isTrialAvailable() async {
    try {
      return await _deviceService.canUseTrial();
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> getDeviceInfo() async {
    try {
      return await _deviceService.getDeviceInfo();
    } catch (e) {
      return null;
    }
  }

  bool _isValidPlan(String planType) {
    return [
      AppConstants.trialPlan,
      AppConstants.basicPlan,
      AppConstants.proPlan,
      AppConstants.businessPlan,
      AppConstants.enterprisePlan,
      AppConstants.adminPlan,
    ].contains(planType);
  }

  int _getPlanUsageLimit(String planType) {
    switch (planType) {
      case AppConstants.trialPlan:
        return AppConstants.trialUsageLimit;
      case AppConstants.basicPlan:
        return AppConstants.basicUsageLimit;
      case AppConstants.proPlan:
        return AppConstants.proUsageLimit;
      case AppConstants.businessPlan:
        return AppConstants.businessUsageLimit;
      case AppConstants.enterprisePlan:
        return AppConstants.enterpriseUsageLimit;
      case AppConstants.adminPlan:
        return -1; // Unlimited
      default:
        return 0;
    }
  }

  Exception _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return Exception('No VirtuCam account found with this email address');
      case 'wrong-password':
        return Exception('Incorrect password for your VirtuCam account');
      case 'invalid-email':
        return Exception('Invalid email address');
      case 'user-disabled':
        return Exception('This VirtuCam account has been disabled');
      case 'too-many-requests':
        return Exception('Too many failed attempts. Please try again later');
      case 'email-already-in-use':
        return Exception('A VirtuCam account with this email already exists');
      case 'weak-password':
        return Exception('Password is too weak');
      case 'requires-recent-login':
        return Exception('Please sign in again to continue');
      case 'invalid-credential':
        return Exception('Invalid credentials provided');
      case 'network-request-failed':
        return Exception('Network error. Please check your connection');
      default:
        return Exception(e.message ?? 'VirtuCam authentication failed');
    }
  }
}
