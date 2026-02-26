// frontend/lib/screens/register_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Background decoration
          Positioned(
            top: -50,
            left: -50,
            child: CircleAvatar(
              radius: 120,
              backgroundColor: theme.colorScheme.secondary.withOpacity(0.05),
            ),
          ),
          Positioned(
            bottom: -100,
            right: -100,
            child: CircleAvatar(
              radius: 150,
              backgroundColor: theme.colorScheme.primary.withOpacity(0.05),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.person_add_rounded,
                          size: 48,
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Join Baterpoint',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Start your trading journey today',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Card(
                        elevation: 4,
                        shadowColor: Colors.black.withOpacity(0.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextField(
                                controller: _usernameController,
                                decoration: const InputDecoration(
                                  labelText: 'Username',
                                  prefixIcon: Icon(Icons.person_outline_rounded),
                                ),
                              ),
                              const SizedBox(height: 20),
                              TextField(
                                controller: _emailController,
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                  prefixIcon: Icon(Icons.email_outlined),
                                ),
                                keyboardType: TextInputType.emailAddress,
                              ),
                              const SizedBox(height: 20),
                              TextField(
                                controller: _passwordController,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword 
                                          ? Icons.visibility_off_outlined 
                                          : Icons.visibility_outlined,
                                      size: 20,
                                    ),
                                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                  ),
                                ),
                                obscureText: _obscurePassword,
                              ),
                              const SizedBox(height: 32),
                              if (auth.isLoading)
                                const Center(child: CircularProgressIndicator())
                              else
                                ElevatedButton(
                                  onPressed: () async {
                                    if (_usernameController.text.isEmpty || 
                                        _emailController.text.isEmpty || 
                                        _passwordController.text.isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Please fill in all fields')),
                                      );
                                      return;
                                    }
                                    try {
                                      await auth.signup(
                                        _usernameController.text.trim(),
                                        _emailController.text.trim(),
                                        _passwordController.text,
                                      );
                                      // On success, AuthProvider will set the user and home screen will show MainScreen
                                    } catch (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(e.toString().replaceAll('Exception: ', '')),
                                            backgroundColor: Colors.red.shade400,
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    backgroundColor: theme.colorScheme.primary,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Create Account'),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: RichText(
                          text: TextSpan(
                            text: "Already have an account? ",
                            style: TextStyle(color: Colors.grey.shade600),
                            children: [
                              TextSpan(
                                text: 'Login',
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
