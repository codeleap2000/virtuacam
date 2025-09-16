// lib/presentation/screens/desktop/login_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/auth_service.dart';
import '../../../core/utils/validators.dart';
import '../../widgets/desktop/custom_text_field.dart';
import '../../widgets/desktop/whatsapp_banner.dart';

class VirtuCamLoginScreen extends StatefulWidget {
  const VirtuCamLoginScreen({super.key});

  @override
  State<VirtuCamLoginScreen> createState() => _VirtuCamLoginScreenState();
}

class _VirtuCamLoginScreenState extends State<VirtuCamLoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isLoading = false;
  bool _passwordVisible = false;
  String? _errorMessage;
  bool _rememberMe = false;

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
        Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.elasticOut),
        );

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      await _authService.signInWithEmail(email, password);

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    } on Exception catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your email address first';
      });
      return;
    }

    try {
      await _authService.sendPasswordResetEmail(email);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset email sent! Check your inbox.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } on Exception catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _clearError() {
    if (_errorMessage != null) {
      setState(() {
        _errorMessage = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    final isMediumScreen = screenSize.width < 900;

    final horizontalPadding = isSmallScreen
        ? 16.0
        : isMediumScreen
        ? 32.0
        : 64.0;
    final maxWidth = isSmallScreen
        ? screenSize.width - 32
        : isMediumScreen
        ? 450.0
        : 500.0;
    final cardPadding = isSmallScreen ? 24.0 : 32.0;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: isSmallScreen ? 16.0 : 32.0,
                  ),
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: maxWidth,
                        minHeight:
                            constraints.maxHeight - (isSmallScreen ? 32 : 64),
                      ),
                      child: Card(
                        elevation: isSmallScreen ? 6 : 12,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            isSmallScreen ? 16 : 20,
                          ),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              isSmallScreen ? 16 : 20,
                            ),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white,
                                Colors.blue[50]!.withOpacity(0.3),
                              ],
                            ),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(cardPadding),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.blue[600],
                                      borderRadius: BorderRadius.circular(50),
                                    ),
                                    child: Icon(
                                      Icons.videocam,
                                      size: isSmallScreen ? 40 : 48,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: isSmallScreen ? 16 : 20),
                                  Text(
                                    'VirtuCam',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 28 : 36,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue[700],
                                      letterSpacing: 1.2,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(height: isSmallScreen ? 6 : 8),
                                  Text(
                                    'Desktop Virtual Camera Solution',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 14 : 16,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(height: isSmallScreen ? 32 : 40),

                                  CustomTextField(
                                    controller: _emailController,
                                    label: 'Email Address',
                                    hintText: 'Enter your email',
                                    keyboardType: TextInputType.emailAddress,
                                    prefixIcon: Icons.email_outlined,
                                    validator: Validators.validateEmail,
                                    enabled: !_isLoading,
                                    isSmallScreen: isSmallScreen,
                                    onChanged: (_) => _clearError(),
                                    textCapitalization: TextCapitalization.none,
                                  ),
                                  SizedBox(height: isSmallScreen ? 16 : 20),

                                  CustomTextField(
                                    controller: _passwordController,
                                    label: 'Password',
                                    hintText: 'Enter your password',
                                    obscureText: !_passwordVisible,
                                    prefixIcon: Icons.lock_outline,
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _passwordVisible
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        color: Colors.grey[600],
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _passwordVisible = !_passwordVisible;
                                        });
                                      },
                                    ),
                                    validator: Validators.validatePassword,
                                    enabled: !_isLoading,
                                    isSmallScreen: isSmallScreen,
                                    onChanged: (_) => _clearError(),
                                    onFieldSubmitted: (_) => _handleLogin(),
                                  ),

                                  SizedBox(height: isSmallScreen ? 12 : 16),

                                  Row(
                                    children: [
                                      Checkbox(
                                        value: _rememberMe,
                                        onChanged: _isLoading
                                            ? null
                                            : (value) {
                                                setState(() {
                                                  _rememberMe = value ?? false;
                                                });
                                              },
                                        activeColor: Colors.blue[600],
                                      ),
                                      Text(
                                        'Remember me',
                                        style: TextStyle(
                                          fontSize: isSmallScreen ? 12 : 14,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                      const Spacer(),
                                      TextButton(
                                        onPressed: _isLoading
                                            ? null
                                            : _handleForgotPassword,
                                        child: Text(
                                          'Forgot Password?',
                                          style: TextStyle(
                                            fontSize: isSmallScreen ? 12 : 14,
                                            color: Colors.blue[600],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  SizedBox(height: isSmallScreen ? 20 : 24),

                                  if (_errorMessage != null)
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      margin: EdgeInsets.only(
                                        bottom: isSmallScreen ? 16 : 20,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.red[50],
                                        border: Border.all(
                                          color: Colors.red[200]!,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.error_outline,
                                            color: Colors.red[700],
                                            size: isSmallScreen ? 18 : 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              _errorMessage!,
                                              style: TextStyle(
                                                color: Colors.red[700],
                                                fontSize: isSmallScreen
                                                    ? 12
                                                    : 14,
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            icon: Icon(
                                              Icons.close,
                                              color: Colors.red[700],
                                              size: 18,
                                            ),
                                            onPressed: _clearError,
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                          ),
                                        ],
                                      ),
                                    ),

                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.blue[600]!,
                                          Colors.blue[700]!,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.blue.withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton(
                                      onPressed: _isLoading
                                          ? null
                                          : _handleLogin,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        foregroundColor: Colors.white,
                                        shadowColor: Colors.transparent,
                                        padding: EdgeInsets.symmetric(
                                          vertical: isSmallScreen ? 16 : 18,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      child: _isLoading
                                          ? SizedBox(
                                              height: isSmallScreen ? 20 : 22,
                                              width: isSmallScreen ? 20 : 22,
                                              child:
                                                  const CircularProgressIndicator(
                                                    strokeWidth: 2.5,
                                                    valueColor:
                                                        AlwaysStoppedAnimation<
                                                          Color
                                                        >(Colors.white),
                                                  ),
                                            )
                                          : Text(
                                              'Sign In to VirtuCam',
                                              style: TextStyle(
                                                fontSize: isSmallScreen
                                                    ? 16
                                                    : 18,
                                                fontWeight: FontWeight.w600,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                    ),
                                  ),
                                  SizedBox(height: isSmallScreen ? 24 : 32),

                                  WhatsAppBanner(isSmallScreen: isSmallScreen),

                                  SizedBox(height: isSmallScreen ? 16 : 20),

                                  Center(
                                    child: Text(
                                      'VirtuCam Desktop v1.0.0',
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 10 : 12,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
