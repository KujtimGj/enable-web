import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/responsive_utils.dart';
import '../../components/responsive_scaffold.dart';
import '../../entities/agency.dart';
import '../../entities/user.dart';
import '../../providers/agencyProvider.dart';
import '../../providers/userProvider.dart';
import 'package:mongo_dart/mongo_dart.dart' as M;

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _obscurePassword = true;


  void registerAgency(AgencyProvider agencyProvider) async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();
    String name = _nameController.text.trim();
    String phone = _phoneController.text.trim();

    AgencyModel agency = AgencyModel(
      id: M.ObjectId().toHexString(),
      name: name,
      email: email,
      password: password,
      phone: phone,
      logoUrl: 'via.png',
    );


    await agencyProvider.createAgency(agency);

    if (agencyProvider.errorMessage == null && agencyProvider.createdAgency != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Agency registered successfully.'))
        );
      }
      context.go('/home');
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(agencyProvider.errorMessage ?? 'Unknown error'))
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  SizedBox(height: ResponsiveUtils.responsiveSpacing(context, mobile: 8, tablet: 12, desktop: 16)),
                  Text(
                    'Create an Enable Account',
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
                  SizedBox(height: ResponsiveUtils.responsiveSpacing(context, mobile: 32, tablet: 40, desktop: 48)),
                  //Name field
                  TextFormField(
                    controller: _nameController,
                    keyboardType: TextInputType.name,
                    decoration: const InputDecoration(
                      labelText: 'Agency name',
                      prefixIcon: Icon(Icons.account_circle),
                    ),
                  ),
                  SizedBox(height: ResponsiveUtils.responsiveSpacing(context, mobile: 12, tablet: 16, desktop: 20)),
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
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: ResponsiveUtils.responsiveSpacing(context, mobile: 12, tablet: 16, desktop: 20)),
                  //Phone
                  TextFormField(
                    controller: _phoneController,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      prefixIcon: const Icon(Icons.phone),
                      ),
                    ),
                  SizedBox(height: ResponsiveUtils.responsiveSpacing(context, mobile: 12, tablet: 16, desktop: 20)),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility : Icons.visibility_off,
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
                  SizedBox(height: ResponsiveUtils.responsiveSpacing(context, mobile: 12, tablet: 16, desktop: 20)),
                  Consumer<AgencyProvider>(
                    builder: (context, agencyProvider, child) {
                      return ElevatedButton(
                        onPressed: agencyProvider.isLoading ? null : () {
                          if (_formKey.currentState!.validate()) {
                            registerAgency(agencyProvider);
                          }
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
                          'Register',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
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

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text("Already have an account? "),
                      GestureDetector(onTap: (){context.go("/agencylogin");},child: Text("Log In",style: TextStyle(fontWeight: FontWeight.bold),))
                    ],
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
