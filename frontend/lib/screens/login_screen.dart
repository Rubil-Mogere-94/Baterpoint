import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:page_transition/page_transition.dart';
import 'dart:ui';
import '../providers/auth_provider.dart';
import '../constants/ui_constants.dart';
import 'register_screen.dart';
import '../widgets/modern_button.dart';
import '../widgets/modern_text_field.dart';
import '../widgets/holographic_background.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: AppAnimations.slow,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: const Interval(0.4, 1.0, curve: Curves.easeOut)),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: const Interval(0.4, 1.0, curve: Curves.easeOut)),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter your credentials'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedMD),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await Provider.of<AuthProvider>(context, listen: false).login(
        _usernameController.text.trim(),
        _passwordController.text,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedMD),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return HolographicBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: AppPadding.lg),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // App Logo Minimalist
                        Hero(
                          tag: 'app_logo',
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: colorScheme.primary,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: colorScheme.primary.withOpacity(0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.handshake_rounded,
                                size: 40,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        
                        Text(
                          'Welcome back.',
                          textAlign: TextAlign.center,
                          style: textTheme.headlineLarge?.copyWith(
                            letterSpacing: -1.0,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sign in to your Baterpoint account.',
                          textAlign: TextAlign.center,
                          style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 48),

                        // Glassy Form Card
                        ClipRRect(
                          borderRadius: AppRadius.roundedXXL,
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.75),
                                borderRadius: AppRadius.roundedXXL,
                                border: Border.all(color: Colors.white.withOpacity(0.2)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  ModernTextField(
                                    labelText: 'Username',
                                    hintText: 'Enter your username',
                                    controller: _usernameController,
                                    prefixIcon: Icon(Icons.person_outline_rounded, color: colorScheme.primary),
                                  ),
                                  const SizedBox(height: 20),
                                  ModernTextField(
                                    labelText: 'Password',
                                    hintText: 'Enter your password',
                                    controller: _passwordController,
                                    obscureText: _obscurePassword,
                                    prefixIcon: Icon(Icons.lock_outline_rounded, color: colorScheme.primary),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword 
                                            ? Icons.visibility_off_outlined 
                                            : Icons.visibility_outlined,
                                        color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                                      ),
                                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: () {
                                        Vibrate.feedback(FeedbackType.light);
                                      },
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: Text(
                                        'Forgot Password?',
                                        style: TextStyle(
                                          color: colorScheme.primary,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 32),
                                  ModernButton(
                                    text: 'Sign In',
                                    isLoading: _isLoading,
                                    onPressed: _handleLogin,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "New to Baterpoint? ",
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Vibrate.feedback(FeedbackType.light);
                                Navigator.push(
                                  context,
                                  PageTransition(
                                    type: PageTransitionType.bottomToTop,
                                    child: const RegisterScreen(),
                                  ),
                                );
                              },
                              child: Text(
                                'Create account',
                                style: TextStyle(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
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
    );
  }
}
