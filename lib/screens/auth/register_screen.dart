import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../utils/styles.dart';
import '../../constants/app_constants.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Styles.darkBackground,
              Styles.primaryColor.withOpacity(0.1),
              Styles.darkBackground,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo or Icon
                  Icon(
                    Icons.fitness_center,
                    size: 64,
                    color: Styles.primaryColor,
                  ),
                  const SizedBox(height: AppConstants.defaultPadding),
                  Text(
                    'GymW3dlat',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Styles.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: AppConstants.defaultPadding / 2),
                  Text(
                    'Create your account',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Styles.subtleText,
                        ),
                  ),
                  const SizedBox(height: AppConstants.defaultPadding * 2),
                  Container(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _nameController,
                            decoration: Styles.textFieldDecoration(
                              'Full Name',
                              Icons.person_outline,
                            ),
                            style: const TextStyle(color: Styles.textColor),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppConstants.defaultPadding),
                          TextFormField(
                            controller: _emailController,
                            decoration: Styles.textFieldDecoration(
                              'Email',
                              Icons.email_outlined,
                            ),
                            style: const TextStyle(color: Styles.textColor),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              // Regular expression for email validation
                              final emailRegex = RegExp(
                                r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                              );
                              if (!emailRegex.hasMatch(value)) {
                                return 'Please enter a valid email address';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppConstants.defaultPadding),
                          TextFormField(
                            controller: _passwordController,
                            decoration: Styles.textFieldDecoration(
                              'Password',
                              Icons.lock_outline,
                            ),
                            style: const TextStyle(color: Styles.textColor),
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              if (value.length <
                                  AppConstants.minPasswordLength) {
                                return 'Password must be at least ${AppConstants.minPasswordLength} characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppConstants.defaultPadding),
                          TextFormField(
                            controller: _confirmPasswordController,
                            decoration: Styles.textFieldDecoration(
                              'Confirm Password',
                              Icons.lock_outline,
                            ),
                            style: const TextStyle(color: Styles.textColor),
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please confirm your password';
                              }
                              if (value != _passwordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(
                              height: AppConstants.defaultPadding * 1.5),
                          ElevatedButton(
                            onPressed: _isLoading ? null : _register,
                            style: Styles.primaryButtonStyle(context),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Styles.textColor,
                                      ),
                                    ),
                                  )
                                : const Text(
                                    'START YOUR JOURNEY',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LoginScreen(),
                              ),
                            ),
                            style: Styles.textButtonStyle(),
                            child: const Text('Already have an account? Login'),
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
    );
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final result = await SupabaseService.createUserWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _nameController.text.trim(),
      );

      if (result == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to create account. Please try again.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created successfully! Please log in.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
          ),
        );

        // Registration successful, navigate to login screen after showing success message
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const LoginScreen(),
              ),
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString();
        // Remove the "Exception: " prefix from the error message
        if (errorMessage.startsWith('Exception: ')) {
          errorMessage = errorMessage.substring('Exception: '.length);
        }

        bool shouldNavigateToLogin =
            errorMessage.contains('already registered') ||
                errorMessage.contains('already in use');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            backgroundColor: shouldNavigateToLogin ? Colors.orange : Colors.red,
          ),
        );

        // Navigate to login screen if the email is already registered
        if (shouldNavigateToLogin) {
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const LoginScreen(),
                ),
              );
            }
          });
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
