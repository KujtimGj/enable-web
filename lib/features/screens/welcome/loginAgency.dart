import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/responsive_utils.dart';
import '../../../router.dart';
import '../../components/responsive_scaffold.dart';
import '../../providers/agencyProvider.dart';

class LoginAgency extends StatefulWidget {
  const LoginAgency({super.key});

  @override
  State<LoginAgency> createState() => _LoginAgencyState();
}

class _LoginAgencyState extends State<LoginAgency> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  void login(AgencyProvider agencyProvider) async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (!_formKey.currentState!.validate()) return;

    await agencyProvider.loginAgency(email, password);

    if (agencyProvider.errorMessage == null && agencyProvider.agency != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login successful')),
        );
        context.go('/agencyroute');
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(agencyProvider.errorMessage ?? 'Login failed')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ResponsiveScaffold(
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
                    Text(
                      'Enable Agency',
                      style: TextStyle(
                        fontSize: ResponsiveUtils.responsiveFontSize(context, mobile: 28, tablet: 32, desktop: 36),
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: ResponsiveUtils.responsiveSpacing(context, mobile: 8, tablet: 12, desktop: 16)),
                    Text(
                      'Sign in to your account',
                      style: TextStyle(
                        fontSize: ResponsiveUtils.responsiveFontSize(context, mobile: 14, tablet: 16, desktop: 18),
                        color: const Color(0xFF999999),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: ResponsiveUtils.responsiveSpacing(context, mobile: 32, tablet: 40, desktop: 48)),

                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Please enter your email';
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) return 'Please enter a valid email';
                        return null;
                      },
                    ),
                    SizedBox(height: ResponsiveUtils.responsiveSpacing(context, mobile: 12, tablet: 16, desktop: 20)),

                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outlined),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Please enter your password';
                        if (value.length < 6) return 'Password must be at least 6 characters';
                        return null;
                      },
                    ),
                    SizedBox(height: ResponsiveUtils.responsiveSpacing(context, mobile: 20, tablet: 24, desktop: 32)),

                    Consumer<AgencyProvider>(
                      builder: (context, agencyProvider, child) {
                        return ElevatedButton(
                          onPressed: agencyProvider.isLoading
                              ? null
                              : () {
                            login(agencyProvider);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: agencyProvider.isLoading
                              ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                            ),
                          )
                              : const Text(
                            'Sign In',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: ResponsiveUtils.responsiveSpacing(context, mobile: 12, tablet: 16, desktop: 20)),

                    Consumer<AgencyProvider>(
                      builder: (context, agencyProvider, child) {
                        if (agencyProvider.errorMessage != null) {
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.withOpacity(0.3)),
                            ),
                            child: Text(
                              agencyProvider.errorMessage!,
                              style: const TextStyle(color: Colors.red, fontSize: 14),
                              textAlign: TextAlign.center,
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Text("Don't have an account? "),
                        GestureDetector(
                          onTap: () {
                            context.goNamed(routeRegister.name);
                          },
                          child: const Text("Sign up", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    SizedBox(height: ResponsiveUtils.responsiveSpacing(context, mobile: 12, tablet: 16, desktop: 20)),

                    TextButton(
                      onPressed: () async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.remove('agency');
                        await prefs.remove('token');
                        if (mounted) context.go('/agencyroute');
                      },
                      child: const Text('Clear Stored Auth (Testing)', style: TextStyle(color: Colors.grey)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
