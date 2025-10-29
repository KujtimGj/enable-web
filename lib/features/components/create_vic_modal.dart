import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/vicProvider.dart';
import '../providers/userProvider.dart';
import '../providers/agencyProvider.dart';

class CreateVICModal extends StatefulWidget {
  const CreateVICModal({super.key});

  @override
  State<CreateVICModal> createState() => _CreateVICModalState();
}

class _CreateVICModalState extends State<CreateVICModal> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _nationalityController = TextEditingController();
  final _summaryController = TextEditingController();
  bool _isSubmitting = false;

  String? _getAgencyId(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final agencyProvider = Provider.of<AgencyProvider>(context, listen: false);
    
    if (userProvider.user?.agencyId != null && userProvider.user!.agencyId.isNotEmpty) {
      return userProvider.user!.agencyId;
    } else if (agencyProvider.agency?.id != null) {
      return agencyProvider.agency!.id;
    }
    
    return null;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _nationalityController.dispose();
    _summaryController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final agencyId = _getAgencyId(context);
    if (agencyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: No agency ID available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final vicProvider = Provider.of<VICProvider>(context, listen: false);

    final vicData = {
      'fullName': _fullNameController.text.trim(),
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
      'nationality': _nationalityController.text.trim().isNotEmpty ? _nationalityController.text.trim() : null,
      'summary': _summaryController.text.trim().isNotEmpty ? _summaryController.text.trim() : null,
      'preferences': {},
      'agencyId': agencyId,
    };

    final success = await vicProvider.createVIC(vicData);

    setState(() {
      _isSubmitting = false;
    });

    if (success) {
      // Refresh the VICs list
      await vicProvider.fetchVICsByAgencyId(agencyId);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('VIC created successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(vicProvider.errorMessage ?? 'Failed to create VIC'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.5,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
        decoration: BoxDecoration(
          color: Color(0xff292525),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Create New VIC',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: Colors.white, size: 24),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Full Name
                      TextFormField(
                        controller: _fullNameController,
                        decoration: InputDecoration(
                          labelText: 'Full Name *',
                          labelStyle: TextStyle(color: Colors.grey[400]),
                          filled: true,
                          fillColor: Color(0xff3A3A3A),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[600]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[600]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.white),
                          ),
                        ),
                        style: TextStyle(color: Colors.white),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Full name is required';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),

                      // Email
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email *',
                          labelStyle: TextStyle(color: Colors.grey[400]),
                          filled: true,
                          fillColor: Color(0xff3A3A3A),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[600]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[600]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.white),
                          ),
                        ),
                        style: TextStyle(color: Colors.white),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Email is required';
                          }
                          if (!value.contains('@')) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),

                      // Phone
                      TextFormField(
                        controller: _phoneController,
                        decoration: InputDecoration(
                          labelText: 'Phone',
                          labelStyle: TextStyle(color: Colors.grey[400]),
                          filled: true,
                          fillColor: Color(0xff3A3A3A),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[600]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[600]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.white),
                          ),
                        ),
                        style: TextStyle(color: Colors.white),
                        keyboardType: TextInputType.phone,
                      ),
                      SizedBox(height: 16),

                      // Nationality
                      TextFormField(
                        controller: _nationalityController,
                        decoration: InputDecoration(
                          labelText: 'Nationality',
                          labelStyle: TextStyle(color: Colors.grey[400]),
                          filled: true,
                          fillColor: Color(0xff3A3A3A),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[600]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[600]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.white),
                          ),
                        ),
                        style: TextStyle(color: Colors.white),
                      ),
                      SizedBox(height: 16),

                      // Summary
                      TextFormField(
                        controller: _summaryController,
                        decoration: InputDecoration(
                          labelText: 'Summary',
                          labelStyle: TextStyle(color: Colors.grey[400]),
                          filled: true,
                          fillColor: Color(0xff3A3A3A),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[600]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[600]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.white),
                          ),
                        ),
                        style: TextStyle(color: Colors.white),
                        maxLines: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                  ),
                  SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xff574435),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: _isSubmitting
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text('Create'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

