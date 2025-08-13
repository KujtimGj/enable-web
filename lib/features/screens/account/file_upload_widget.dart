import 'package:flutter/material.dart';
import 'package:enable_web/features/controllers/file_upload_service.dart';
import 'package:enable_web/features/entities/agency.dart';

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
    setState(() {
      _isLoadingFiles = true;
      _errorMessage = null;
    });

    final result = await _fileUploadService.getAgencyFiles(widget.agencyId);

    result.fold(
      (failure) {
        setState(() {
          _errorMessage = _fileUploadService.getFailureMessage(failure);
          _isLoadingFiles = false;
        });
      },
      (files) {
        setState(() {
          _files = files;
          _isLoadingFiles = false;
        });
      },
    );
  }

  Future<void> _uploadFile() async {
    setState(() {
      _isUploading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    final result = await _fileUploadService.uploadFileToAgency(widget.agencyId);

    result.fold(
      (failure) {
        setState(() {
          _errorMessage = _fileUploadService.getFailureMessage(failure);
          _isUploading = false;
        });
      },
      (uploadData) {
        setState(() {
          _successMessage = 'File uploaded successfully!';
          _isUploading = false;
        });
        
        // Reload the files list
        _loadFiles();
      },
    );
  }

  Future<void> _deleteFile(String fileId) async {
    final result = await _fileUploadService.deleteAgencyFile(
      widget.agencyId,
      fileId,
    );

    result.fold(
      (failure) {
        setState(() {
          _errorMessage = _fileUploadService.getFailureMessage(failure);
        });
      },
      (message) {
        setState(() {
          _successMessage = message;
        });
        
        // Reload the files list
        _loadFiles();
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
            child: Text(
              _errorMessage!,
              style: TextStyle(color: Colors.red.shade800),
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
          'Agency Files',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        
        const SizedBox(height: 8),
        
        if (_isLoadingFiles)
          const Center(child: CircularProgressIndicator())
        else if (_files.isEmpty)
          const Text('No files uploaded yet.')
        else
          ListView.builder(
            shrinkWrap: true,
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
      ],
    );
  }
} 