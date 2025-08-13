import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:enable_web/features/providers/google_drive_provider.dart';

class GoogleOAuthCallbackScreen extends StatefulWidget {
  const GoogleOAuthCallbackScreen({super.key});

  @override
  State<GoogleOAuthCallbackScreen> createState() => _GoogleOAuthCallbackScreenState();
}

class _GoogleOAuthCallbackScreenState extends State<GoogleOAuthCallbackScreen> {
  bool _isProcessing = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _handleCallback();
  }

  Future<void> _handleCallback() async {
    try {
      // Get the authorization code from URL parameters
      final uri = Uri.base;
      final code = uri.queryParameters['code'];
      
      if (code == null) {
        setState(() {
          _error = 'No authorization code received';
          _isProcessing = false;
        });
        return;
      }

      // This screen is no longer needed with the new flow
      // The tokens are handled directly in the account screen
      setState(() {
        _error = 'This callback screen is deprecated. Please use the main account screen.';
        _isProcessing = false;
      });
      
      // Navigate back to account screen after a short delay
      Future.delayed(Duration(seconds: 2), () {
        if (mounted) {
          context.go('/account');
        }
      });
    } catch (e) {
      setState(() {
        _error = 'Error processing authentication: $e';
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Google Drive Authentication'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isProcessing) ...[
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Processing Google Drive authentication...'),
            ] else if (_error != null) ...[
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(
                'Authentication Failed',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/account'),
                child: Text('Back to Account'),
              ),
            ] else ...[
              Icon(Icons.check_circle, size: 64, color: Colors.green),
              SizedBox(height: 16),
              Text(
                'Authentication Successful!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Redirecting to account page...',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ],
        ),
      ),
    );
  }
} 