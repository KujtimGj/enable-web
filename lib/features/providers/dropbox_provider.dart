import 'package:enable_web/features/entities/dropbox.dart';
import 'package:flutter/foundation.dart';
import 'package:enable_web/features/controllers/dropbox_controller.dart';
import 'package:enable_web/core/failure.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';

class DropboxProvider extends ChangeNotifier {
  final DropboxController _dropboxController = DropboxController();

  bool _isLoading = false;
  bool _isConnected = false;
  List<DropboxFile> _files = [];
  String? _error;
  DateTime? _lastSync;

  // Getters
  bool get isLoading => _isLoading;
  bool get isConnected => _isConnected;
  List<DropboxFile> get files => _files;
  String? get error => _error;
  DateTime? get lastSync => _lastSync;

  DropboxProvider() {
    _initializeDropbox();
  }

  Future<void> _initializeDropbox() async {
    await checkConnectionStatus();
  }

  /// Check Dropbox connection status
  Future<void> checkConnectionStatus() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final result = await _dropboxController.getDropboxStatus();
    result.fold(
      (failure) {
        setState(() {
          _isConnected = false;
          _error = _getFailureMessage(failure);
          _isLoading = false;
        });
      },
      (status) {
        setState(() {
          _isConnected = status.isConnected;
          _lastSync = status.lastSync;
          _isLoading = false;
        });
        if (_isConnected) {
          loadFiles();
        }
      },
    );
  }

  /// Connect to Dropbox
  Future<void> connectDropbox() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final authUrlResult = await _dropboxController.getDropboxAuthUrl();
      authUrlResult.fold(
        (failure) {
          setState(() {
            _error = 'Failed to get Dropbox auth URL: \\${failure.toString()}';
            _isLoading = false;
          });
        },
        (authUrl) async {
          final uri = Uri.parse(authUrl);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
            setState(() {
              _error = 'Dropbox authentication opened in browser. Please complete the authentication.';
              _isLoading = false;
            });
            // Optionally poll for connection status
          } else {
            setState(() {
              _error = 'Could not open Dropbox authentication URL. Please try again.';
              _isLoading = false;
            });
          }
        },
      );
    } catch (e) {
      setState(() {
        _error = 'Failed to initiate Dropbox connection: $e';
        _isLoading = false;
      });
    }
  }

  /// Associate Dropbox tokens with authenticated user
  Future<void> associateDropboxTokens(String tokenId) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final result = await _dropboxController.associateDropboxTokens(tokenId);

      result.fold(
        (failure) {
          setState(() {
            _error = _getFailureMessage(failure);
            _isLoading = false;
          });
          throw Exception(_getFailureMessage(failure));
        },
        (isConnected) {
          setState(() {
            _isConnected = isConnected;
            _isLoading = false; 
          });
          if (isConnected) {
            loadFiles();
          }
        },
      );
    } catch (e) {
      setState(() {
        _error = 'Failed to associate Dropbox tokens: $e';
        _isLoading = false;
      });
      rethrow;
    }
  }

  /// Load Dropbox files
  Future<void> loadFiles() async {
    if (!_isConnected) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final result = await _dropboxController.getDropboxFiles();
    result.fold(
      (failure) {
        setState(() {
          _error = _getFailureMessage(failure);
          _isLoading = false;
        });
      },
      (files) {
        setState(() {
          _files = files;
          _lastSync = DateTime.now();
          _isLoading = false;
        });
      },
    );
  }

  /// Disconnect Dropbox (reset state for now)
  Future<void> disconnectDropbox() async {
    setState(() {
      _isConnected = false;
      _files = [];
      _lastSync = null;
      _error = null;
      _isLoading = false;
    });
    // TODO: Implement backend disconnect if needed
  }

  void setState(VoidCallback fn) {
    fn();
    notifyListeners();
  }

  String _getFailureMessage(Failure failure) {
    if (failure is ServerFailure) {
      return failure.message ?? 'Server error occurred';
    } else {
      return 'An unexpected error occurred.';
    }
  }
} 