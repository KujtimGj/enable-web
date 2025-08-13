import 'package:dartz/dartz.dart';
import 'package:enable_web/features/entities/google_drive.dart';
import 'package:flutter/foundation.dart';
import 'package:enable_web/features/controllers/google_drive_controller.dart';
import 'package:enable_web/core/failure.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async'; // Added for Timer
import 'package:dartz/dartz.dart';

class GoogleDriveProvider extends ChangeNotifier {
  final GoogleDriveController _googleDriveController = GoogleDriveController();
  
  bool _isLoading = false;
  bool _isConnected = false;
  List<GoogleDriveFile> _files = [];
  String? _error;
  DateTime? _lastSync;
  String? _nextPageToken;
  bool _hasMoreFiles = false;

  // Getters
  bool get isLoading => _isLoading;
  bool get isConnected => _isConnected;
  List<GoogleDriveFile> get files => _files;
  String? get error => _error;
  DateTime? get lastSync => _lastSync;
  bool get hasMoreFiles => _hasMoreFiles;

  GoogleDriveProvider() {
    _initializeGoogleDrive();
  }

  Future<void> _initializeGoogleDrive() async {
    await checkConnectionStatus();
  }

  /// Check Google Drive connection status
  Future<void> checkConnectionStatus() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await _googleDriveController.getGoogleDriveStatus();
    
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
      },
    );
  }

  /// Connect to Google Drive
  Future<void> connectGoogleDrive() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authUrlResult = await _googleDriveController.getGoogleAuthUrl();
      
      authUrlResult.fold(
        (failure) {
          setState(() {
            _error = 'Failed to get Google auth URL: ${failure.toString()}';
            _isLoading = false;
          });
        },
        (authUrl) async {
          // Open the auth URL in the browser
          final uri = Uri.parse(authUrl);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
            
            // Show success message with instructions
            setState(() {
              _error = 'Google authentication opened in browser. Please complete the authentication in the browser window. You will be redirected back to the app automatically.';
              _isLoading = false;
            });
            
            // Poll for connection status after a delay
            _pollForConnectionStatus();
          } else {
            setState(() {
              _error = 'Could not open Google authentication URL. Please try again.';
              _isLoading = false;
            });
          }
        },
      );
    } catch (e) {
      setState(() {
        _error = 'Failed to initiate Google Drive connection: $e';
        _isLoading = false;
      });
    }
  }

  void _pollForConnectionStatus() {
    int attempts = 0;
    const maxAttempts = 30; // Reduced from 60 to 30 seconds
    const pollInterval = Duration(seconds: 2); // Increased from 1 to 2 seconds
    
    Timer.periodic(pollInterval, (timer) async {
      attempts++;
      
      if (attempts >= maxAttempts) {
        timer.cancel();
        setState(() {
          _error = 'Authentication timeout. Please try connecting again or check if you completed the authentication in your browser.';
        });
        return;
      }
      
      // Update the message to show progress
      if (attempts % 5 == 0) { // Update message every 10 seconds (5 * 2 seconds)
        setState(() {
          _error = 'Waiting for authentication completion... (${attempts * 2}s)';
        });
      }
      
      await checkConnectionStatus();
      
      if (_isConnected) {
        timer.cancel();
        setState(() {
          _error = null;
        });
        // Load files after successful connection
        loadFiles();
      }
    });
  }


  // Future<void> handleGoogleCallback(String code) async {
  //   setState(() {
  //     _isLoading = true;
  //     _error = null;
  //   });

  //   final result = await _googleDriveController.handleGoogleCallback(code);
    
  //   result.fold(
  //     (failure) {
  //       setState(() {
  //         _error = _getFailureMessage(failure);
  //         _isLoading = false;
  //       });
  //     },
  //     (response) {
  //       setState(() {
  //         _isConnected = response['isConnected'] ?? false;
  //         _isLoading = false;
  //       });
        
  //       if (_isConnected) {
  //         loadFiles();
  //       }
  //     },
  //   );
  // }




  Future<void> associateGoogleDriveTokens(String accessToken, String refreshToken, String? expiryDate) async {
    print('[associateGoogleDriveTokens] Called with tokens');

    final result = await _googleDriveController.associateGoogleDriveTokens(accessToken, refreshToken, expiryDate);

    result.fold(
      (failure) {
        print('[associateGoogleDriveTokens] Failed to associate tokens: ${_getFailureMessage(failure)}');
        setState(() {
          _error = _getFailureMessage(failure);
          _isConnected = false;
        });
      },
      (connected) {
        print('[associateGoogleDriveTokens] Token association success: isConnected = $connected');
        setState(() {
          _isConnected = connected;
          _error = null;
          if (connected) {
            _lastSync = DateTime.now();
            print('[associateGoogleDriveTokens] Last sync set to $_lastSync');
          } else {
            print('[associateGoogleDriveTokens] Unexpected: connected=false despite success response');
          }
        });
      },
    );
  }

  /// Load Google Drive files
  Future<void> loadFiles() async {
    if (!_isConnected) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await _googleDriveController.getGoogleDriveFiles();
    
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

  /// Load more files (pagination)
  Future<void> loadMoreFiles() async {
    if (!_hasMoreFiles || _isLoading || _nextPageToken == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await _googleDriveController.getMoreGoogleDriveFiles(_nextPageToken!);
    
    result.fold(
      (failure) {
        setState(() {
          _error = _getFailureMessage(failure);
          _isLoading = false;
        });
      },
      (files) {
        setState(() {
          _files.addAll(files);
          _lastSync = DateTime.now();
          _isLoading = false;
        });
      },
    );
  }

  /// Read Google Drive file content
  Future<Either<Failure, List<Map<String, dynamic>>>> readFileContent(String fileId) async {
    return await _googleDriveController.readGoogleDriveFile(fileId);
  }


  /// Get Google Drive file preview
  Future<Either<Failure, Map<String, dynamic>>> getFilePreview(String fileId) async {
    try {
      final result = await _googleDriveController.getGoogleDriveFilePreview(fileId);
      return result;
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to get file preview: $e'));
    }
  }

  /// Disconnect Google Drive
  Future<void> disconnectGoogleDrive() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await _googleDriveController.disconnectGoogleDrive();
    
    result.fold(
      (failure) {
        setState(() {
          _error = _getFailureMessage(failure);
          _isLoading = false;
        });
      },
      (message) {
        setState(() {
          _isConnected = false;
          _files = [];
          _lastSync = null;
          _error = null;
          _isLoading = false;
        });
      },
    );
  }

  /// Clear error state
  void clearError() {
    setState(() {
      _error = null;
    });
  }

  /// Set loading state
  void setState(VoidCallback fn) {
    fn();
    notifyListeners();
  }

  /// Get failure message
  String _getFailureMessage(Failure failure) {
    if (failure is ServerFailure) {
      return failure.message ?? 'Server error occurred';
    } else {
      return 'An unexpected error occurred.';
    }
  }
} 