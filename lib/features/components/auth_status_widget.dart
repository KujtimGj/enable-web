import 'package:flutter/material.dart';
import '../../core/auth_utils.dart';
import '../../features/providers/userProvider.dart';
import '../../features/providers/agencyProvider.dart';
import '../../features/entities/user.dart';
import 'package:provider/provider.dart';

class AuthStatusWidget extends StatefulWidget {
  const AuthStatusWidget({super.key});

  @override
  State<AuthStatusWidget> createState() => _AuthStatusWidgetState();
}

class _AuthStatusWidgetState extends State<AuthStatusWidget> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'user';
  bool _isCreatingUser = false;
  String? _creationMessage;

  final List<String> _roles = ['user', 'admin', 'manager'];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Authentication Status',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            
            // Check if any user is authenticated
            _buildStatusRow(
              context,
              'Any User Authenticated:',
              AuthUtils.isAnyUserAuthenticated(context),
            ),
            
            const SizedBox(height: 8),
            
            // Check specific user types
            _buildStatusRow(
              context,
              'Regular User:',
              AuthUtils.isUserAuthenticated(context),
            ),
            
            _buildStatusRow(
              context,
              'Agency User:',
              AuthUtils.isAgencyAuthenticated(context),
            ),
            
            const SizedBox(height: 16),
            
            // Show current user type
            Text(
              'Current User Type: ${AuthUtils.getCurrentUserType(context) ?? 'None'}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            
            const SizedBox(height: 16),
            
            // User Creation Section (only for agency users)
            if (AuthUtils.isAgencyAuthenticated(context)) ...[
              _buildUserCreationSection(),
              const SizedBox(height: 16),
            ],
            
            // Logout button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => AuthUtils.logoutAll(context),
                child: const Text('Logout All'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCreationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Create New User',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Add a new user to your agency',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 16),
        
        Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an email';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Role',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.work),
                ),
                items: _roles.map((role) {
                  return DropdownMenuItem(
                    value: role,
                    child: Text(role.toUpperCase()),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedRole = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              
              if (_creationMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _creationMessage!.contains('success') 
                        ? Colors.green[100] 
                        : Colors.red[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _creationMessage!,
                    style: TextStyle(
                      color: _creationMessage!.contains('success') 
                          ? Colors.green[800] 
                          : Colors.red[800],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isCreatingUser ? null : _createUser,
                  child: _isCreatingUser 
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 8),
                            Text('Creating...'),
                          ],
                        )
                      : const Text('Create User'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _createUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isCreatingUser = true;
      _creationMessage = null;
    });

    try {
      // Get current agency to get agency ID
      final agencyProvider = Provider.of<AgencyProvider>(context, listen: false);
      if (!agencyProvider.isAuthenticated || agencyProvider.agency == null) {
        setState(() {
          _creationMessage = 'Error: You must be logged in as an agency to create users';
          _isCreatingUser = false;
        });
        return;
      }

      final agencyId = agencyProvider.agency!.id;

      // Create new user model
      final newUser = UserModel(
        id: '', // Will be set by the server
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        agencyId: agencyId, // Use the authenticated agency's ID
        role: _selectedRole,
      );

      // Register the user through the provider
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final result = await userProvider.register(newUser);

      if (result != null) {
        setState(() {
          _creationMessage = 'User created successfully!';
          _isCreatingUser = false;
        });
        
        // Clear form
        _nameController.clear();
        _emailController.clear();
        _passwordController.clear();
        _selectedRole = 'user';
        
        // Clear message after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _creationMessage = null;
            });
          }
        });
      } else {
        setState(() {
          _creationMessage = userProvider.error ?? 'Failed to create user';
          _isCreatingUser = false;
        });
      }
    } catch (e) {
      setState(() {
        _creationMessage = 'Error creating user: $e';
        _isCreatingUser = false;
      });
    }
  }

  Widget _buildStatusRow(BuildContext context, String label, bool isAuthenticated) {
    return Row(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(width: 8),
        Icon(
          isAuthenticated ? Icons.check_circle : Icons.cancel,
          color: isAuthenticated ? Colors.green : Colors.red,
          size: 20,
        ),
      ],
    );
  }
}
