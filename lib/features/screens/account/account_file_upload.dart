import 'package:flutter/material.dart';
import 'package:enable_web/features/controllers/file_upload_service.dart';
import 'package:enable_web/features/entities/agency.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:enable_web/core/dio_api.dart';

class AccountFileUpload extends StatefulWidget {
  const AccountFileUpload({super.key});

  @override
  State<AccountFileUpload> createState() => _AccountFileUploadState();
}

class _AccountFileUploadState extends State<AccountFileUpload> {
  final FileUploadService _fileUploadService = FileUploadService();
  final ApiClient _apiClient = ApiClient();
  String? _agencyId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAgencyId();
  }

  Future<void> _loadAgencyId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('user');
      
      if (userJson != null) {
        final userMap = jsonDecode(userJson);
        // Assuming the user has an agencyId field
        setState(() {
          _agencyId = userMap['agencyId'] ?? userMap['agency']?['_id'];
          _isLoading = false;
        });
        
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testApiConnection() async {
    try {
      final response = await _apiClient.get('/auth/login');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('API connection test: ${response.statusCode}'),
            backgroundColor: response.statusCode == 200 ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('API connection failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_agencyId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('File Upload'),
        ),
        body: const Center(
          child: Text('No agency ID found. Please contact support.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('File Upload'),
        actions: [
          IconButton(
            icon: const Icon(Icons.wifi_find),
            onPressed: _testApiConnection,
            tooltip: 'Test API Connection',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Upload Files to Your Agency',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Text('Agency ID: $_agencyId'),
            const SizedBox(height: 16),
            Expanded(
              child: FileUploadWidget(agencyId: _agencyId!),
            ),
          ],
        ),
      ),
    );
  }
}

// Simple widget that can be used anywhere
class FileUploadWidget extends StatefulWidget {
  final String agencyId;

  const FileUploadWidget({
    super.key,
    required this.agencyId,
  });

  @override
  State<FileUploadWidget> createState() => _FileUploadWidgetState();
}

class _FileUploadWidgetState extends State<FileUploadWidget> {
  final FileUploadService _fileUploadService = FileUploadService();
  bool _isUploading = false;
  bool _isLoadingFiles = false;
  List<AgencyFile> _files = [];
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    if (!mounted) return;
    
    setState(() {
      _isLoadingFiles = true;
      _errorMessage = null;
    });

    final result = await _fileUploadService.getAgencyFiles(widget.agencyId);

    if (!mounted) return;
    
    result.fold(
      (failure) {
        if (mounted) {
          setState(() {
            _errorMessage = _fileUploadService.getFailureMessage(failure);
            _isLoadingFiles = false;
          });
        }
      },
      (files) {
        if (mounted) {
          setState(() {
            _files = files;
            _isLoadingFiles = false;
          });
        }
      },
    );
  }

  Future<void> _uploadFile() async {
    if (!mounted) return;
    
    setState(() {
      _isUploading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    final result = await _fileUploadService.uploadFileToAgency(widget.agencyId);

    if (!mounted) return;
    
    result.fold(
      (failure) {
        if (mounted) {
          setState(() {
            _errorMessage = _fileUploadService.getFailureMessage(failure);
            _isUploading = false;
          });
        }
      },
      (uploadData) {
        if (mounted) {
          setState(() {
            _successMessage = 'File uploaded successfully!';
            _isUploading = false;
          });
          
          // Reload the files list
          _loadFiles();
        }
      },
    );
  }

  Future<void> _deleteFile(String fileId) async {
    final result = await _fileUploadService.deleteAgencyFile(
      widget.agencyId,
      fileId,
    );

    if (!mounted) return;
    
    result.fold(
      (failure) {
        if (mounted) {
          setState(() {
            _errorMessage = _fileUploadService.getFailureMessage(failure);
          });
        }
      },
      (message) {
        if (mounted) {
          setState(() {
            _successMessage = message;
          });
          
          // Reload the files list
          _loadFiles();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Upload button
        ElevatedButton.icon(
          onPressed: _isUploading ? null : _uploadFile,
          icon: _isUploading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.upload),
          label: Text(_isUploading ? 'Uploading...' : 'Upload File'),
        ),
        
        const SizedBox(height: 16),
        
        // Messages
        if (_errorMessage != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Error:',
                  style: TextStyle(
                    color: Colors.red.shade800,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red.shade800),
                ),
              ],
            ),
          ),
        
        if (_successMessage != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _successMessage!,
              style: TextStyle(color: Colors.green.shade800),
            ),
          ),
        
        const SizedBox(height: 16),
        
        // Files list
        Text(
          'Your Files',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        
        const SizedBox(height: 8),
        
        if (_isLoadingFiles)
          const Center(child: CircularProgressIndicator())
        else if (_files.isEmpty)
          const Text('No files uploaded yet.')
        else
          Expanded(
            child: ListView.builder(
              itemCount: _files.length,
              itemBuilder: (context, index) {
                final file = _files[index];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.file_present),
                    title: Text(file.name),
                    subtitle: Text('${(file.size / 1024).toStringAsFixed(1)} KB'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _deleteFile(file.file),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
