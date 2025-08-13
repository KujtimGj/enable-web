import 'package:enable_web/features/entities/user.dart';
import 'package:enable_web/features/providers/userProvider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:enable_web/core/responsive_utils.dart';
import 'package:enable_web/features/components/responsive_scaffold.dart';

import '../../../router.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _emailController.text = '';
    _passwordController.text = '';
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  login(UserProvider userProvider) async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    UserModel? user = await userProvider.login(email, password);
    if (user != null) {
      context.go('/account');
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login failed please try again')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    return ResponsiveScaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: ResponsiveUtils.responsivePadding(context),
          child: ResponsiveContainer(
            maxWidth: ResponsiveUtils.isMobile(context) ? double.infinity : 500,
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo/Title
                  Text(
                    'Enable',
                    style: TextStyle(
                      fontSize: ResponsiveUtils.responsiveFontSize(
                        context,
                        mobile: 28,
                        tablet: 32,
                        desktop: 36,
                      ),
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(
                    height: ResponsiveUtils.responsiveSpacing(
                      context,
                      mobile: 8,
                      tablet: 12,
                      desktop: 16,
                    ),
                  ),
                  Text(
                    'Sign in to your account',
                    style: TextStyle(
                      fontSize: ResponsiveUtils.responsiveFontSize(
                        context,
                        mobile: 14,
                        tablet: 16,
                        desktop: 18,
                      ),
                      color: const Color(0xFF999999),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(
                    height: ResponsiveUtils.responsiveSpacing(
                      context,
                      mobile: 32,
                      tablet: 40,
                      desktop: 48,
                    ),
                  ),

                  // Email Field
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!RegExp(
                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                      ).hasMatch(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  SizedBox(
                    height: ResponsiveUtils.responsiveSpacing(
                      context,
                      mobile: 12,
                      tablet: 16,
                      desktop: 20,
                    ),
                  ),

                  // Password Field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  SizedBox(
                    height: ResponsiveUtils.responsiveSpacing(
                      context,
                      mobile: 20,
                      tablet: 24,
                      desktop: 32,
                    ),
                  ),

                  // Login Button
                  Consumer<UserProvider>(
                    builder: (context, userProvider, child) {
                      return ElevatedButton(
                        onPressed:
                            userProvider.isLoading
                                ? null
                                : () {
                                  login(userProvider);
                                },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child:
                            userProvider.isLoading
                                ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.black,
                                    ),
                                  ),
                                )
                                : const Text(
                                  'Sign In',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                      );
                    },
                  ),
                  SizedBox(
                    height: ResponsiveUtils.responsiveSpacing(
                      context,
                      mobile: 12,
                      tablet: 16,
                      desktop: 20,
                    ),
                  ),

                  // Error Message
                  Consumer<UserProvider>(
                    builder: (context, userProvider, child) {
                      if (userProvider.error != null) {
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.red.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            userProvider.error!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  // SizedBox(height: ResponsiveUtils.responsiveSpacing(context, mobile: 8, tablet: 12, desktop: 15)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text("Don't have an account? "),
                      GestureDetector(
                        onTap: () {
                          context.goNamed(routeRegister.name);
                          },
                        child: Text(
                          "Sign up",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: ResponsiveUtils.responsiveSpacing(
                      context,
                      mobile: 12,
                      tablet: 16,
                      desktop: 20,
                    ),
                  ),
                  // Clear Auth Button (for testing)
                  TextButton(
                    onPressed: () async {
                      final userProvider = Provider.of<UserProvider>(
                        context,
                        listen: false,
                      );
                      await userProvider.logout();
                      if (mounted) {
                        context.go('/signin');
                      }
                    },
                    child: const Text(
                      'Clear Stored Auth (Testing)',
                      style: TextStyle(color: Colors.grey),
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
}
