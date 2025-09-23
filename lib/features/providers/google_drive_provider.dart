import 'package:dartz/dartz.dart';
import 'package:enable_web/features/entities/google_drive.dart';
import 'package:flutter/foundation.dart';
import 'package:enable_web/features/controllers/google_drive_controller.dart';
import 'package:enable_web/core/failure.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async'; // Added for Timer
import 'dart:html' as html; // Added for web platform

class GoogleDriveProvider extends ChangeNotifier {
  final GoogleDriveController _googleDriveController = GoogleDriveController();
  
  bool _isLoading = false;
  bool _isConnected = false;
  List<GoogleDriveFile> _files = [];
  String? _error;
  DateTime? _lastSync;
  String? _nextPageToken;
  bool _hasMoreFiles = false;
  
  // Connection monitoring
  Timer? _connectionMonitorTimer;
  bool _isMonitoringConnection = false;
  DateTime? _lastConnectionCheck;
  String? _connectionStatusMessage;
  bool _hasConnectionIssues = false;
  bool _tokenExpired = false;
  int _consecutiveFailures = 0;

  // Getters
  bool get isLoading => _isLoading;
  bool get isConnected => _isConnected;
  List<GoogleDriveFile> get files => _files;
  String? get error => _error;
  DateTime? get lastSync => _lastSync;
  bool get hasMoreFiles => _hasMoreFiles;
  
  // Connection monitoring getters
  bool get isMonitoringConnection => _isMonitoringConnection;
  DateTime? get lastConnectionCheck => _lastConnectionCheck;
  String? get connectionStatusMessage => _connectionStatusMessage;
  bool get hasConnectionIssues => _hasConnectionIssues;
  bool get tokenExpired => _tokenExpired;
  int get consecutiveFailures => _consecutiveFailures;

  GoogleDriveProvider() {
    _initializeGoogleDrive();
  }

  Future<void> _initializeGoogleDrive() async {
    await checkConnectionStatus();
    // Start monitoring connection status
    startConnectionMonitoring();
  }

  /// Check Google Drive connection status
  Future<void> checkConnectionStatus({bool isBackgroundCheck = false}) async {
    if (!isBackgroundCheck) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    final result = await _googleDriveController.getGoogleDriveStatus();
    
    result.fold(
      (failure) {
        final wasConnected = _isConnected;
        _consecutiveFailures++;
        
        // Check if this is a token expiration error
        final failureMessage = _getFailureMessage(failure);
        final isTokenExpired = failureMessage.toLowerCase().contains('token') || 
                              failureMessage.toLowerCase().contains('expired') ||
                              failureMessage.toLowerCase().contains('unauthorized') ||
                              failureMessage.toLowerCase().contains('401');
        
        setState(() {
          _isConnected = false;
          _hasConnectionIssues = true;
          _tokenExpired = isTokenExpired;
          _connectionStatusMessage = isTokenExpired 
              ? 'Google Drive token expired. Please reconnect.'
              : failureMessage;
          _lastConnectionCheck = DateTime.now();
          if (!isBackgroundCheck) {
            _error = failureMessage;
            _isLoading = false;
          }
        });
        
        // Log connection loss
        if (wasConnected && !_isConnected) {
          print('[GoogleDriveProvider] Connection lost: $failureMessage');
          if (isTokenExpired) {
            print('[GoogleDriveProvider] Token expired - user needs to reconnect');
          }
        }
      },
      (status) {
        final wasConnected = _isConnected;
        _consecutiveFailures = 0; // Reset failure count on success
        
        setState(() {
          _isConnected = status.isConnected;
          _lastSync = status.lastSync;
          _lastConnectionCheck = DateTime.now();
          _hasConnectionIssues = false;
          _tokenExpired = false;
          _connectionStatusMessage = status.isConnected 
              ? 'Connected to Google Drive' 
              : 'Not connected to Google Drive';
          if (!isBackgroundCheck) {
            _isLoading = false;
          }
        });
        
        // Log connection status changes
        if (wasConnected != _isConnected) {
          print('[GoogleDriveProvider] Connection status changed: ${_isConnected ? "Connected" : "Disconnected"}');
        }
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
          // For web, we need to open in a popup window for postMessage to work
          if (kIsWeb) {
            try {
              // Open OAuth URL in a popup window
              try {
                html.window.open(
                  authUrl,
                  'google_oauth',
                  'width=500,height=600,scrollbars=yes,resizable=yes'
                );
              } catch (e) {
                setState(() {
                  _error = 'Popup blocked! Please allow popups for this site and try again.';
                  _isLoading = false;
                });
                return;
              }
              
              setState(() {
                _error = 'Google authentication opened in popup. Please complete the authentication.';
                _isLoading = false;
              });
              
              // Poll for connection status after a delay
              _pollForConnectionStatus();
              
            } catch (e) {
              setState(() {
                _error = 'Failed to open OAuth popup: $e';
                _isLoading = false;
              });
            }
          } else {
            // For non-web platforms, use the original approach
            final uri = Uri.parse(authUrl);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
              
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
          }
        },
      );
    } catch (e) {
      setState(() {
        _error = 'Failed to connect to Google Drive: $e';
        print(_error);
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

  /// Read file content
  Future<Either<Failure, dynamic>> readFileContent(String fileId) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _googleDriveController.readGoogleDriveFile(fileId);
      
      setState(() {
        _isLoading = false;
      });
      
      return result;
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Error reading file content: $e';
      });
      return Left(ServerFailure(message: 'Error reading file content: $e'));
    }
  }

  /// Enqueue file for ingestion
  Future<Either<Failure, Map<String, dynamic>>> enqueueFileForIngestion(String fileId) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // For now, we'll use a simple HTTP call to the batch ingestion endpoint
      // This will be implemented properly when we add the full batch ingestion controller
      await _googleDriveController.readGoogleDriveFile(fileId);
      
      setState(() {
        _isLoading = false;
      });
      
      // Return a success response for now
      return Right({'message': 'File enqueued for ingestion', 'fileId': fileId});
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Error enqueuing file for ingestion: $e';
      });
      return Left(ServerFailure(message: 'Error enqueuing file for ingestion: $e'));
    }
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

  /// Start monitoring connection status periodically
  void startConnectionMonitoring({Duration interval = const Duration(seconds: 30)}) {
    if (_isMonitoringConnection) {
      print('[GoogleDriveProvider] Connection monitoring already active');
      return;
    }
    
    print('[GoogleDriveProvider] Starting connection monitoring with ${interval.inSeconds}s interval');
    _isMonitoringConnection = true;
    
    _connectionMonitorTimer = Timer.periodic(interval, (timer) async {
      try {
        await checkConnectionStatus(isBackgroundCheck: true);
      } catch (e) {
        print('[GoogleDriveProvider] Error during background connection check: $e');
      }
    });
  }
  
  /// Stop monitoring connection status
  void stopConnectionMonitoring() {
    if (!_isMonitoringConnection) {
      return;
    }
    
    print('[GoogleDriveProvider] Stopping connection monitoring');
    _connectionMonitorTimer?.cancel();
    _connectionMonitorTimer = null;
    _isMonitoringConnection = false;
  }
  
  /// Force a connection status check
  Future<void> forceConnectionCheck() async {
    print('[GoogleDriveProvider] Force checking connection status');
    await checkConnectionStatus(isBackgroundCheck: false);
  }
  
  /// Get connection status summary
  Map<String, dynamic> getConnectionStatusSummary() {
    return {
      'isConnected': _isConnected,
      'isMonitoring': _isMonitoringConnection,
      'lastCheck': _lastConnectionCheck?.toIso8601String(),
      'hasIssues': _hasConnectionIssues,
      'tokenExpired': _tokenExpired,
      'consecutiveFailures': _consecutiveFailures,
      'statusMessage': _connectionStatusMessage,
      'lastSync': _lastSync?.toIso8601String(),
    };
  }

  @override
  void dispose() {
    stopConnectionMonitoring();
    super.dispose();
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