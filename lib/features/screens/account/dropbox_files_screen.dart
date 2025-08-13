import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:enable_web/features/providers/dropbox_provider.dart';
import 'package:enable_web/features/entities/dropbox.dart';

class DropboxFilesScreen extends StatelessWidget {
  const DropboxFilesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DropboxProvider>(
      builder: (context, dropboxProvider, child) {
        if (dropboxProvider.isLoading) {
          return Scaffold(
            appBar: AppBar(title: Text('Dropbox Files')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (dropboxProvider.error != null) {
          return Scaffold(
            appBar: AppBar(title: Text('Dropbox Files')),
            body: Center(child: Text('Error: ${dropboxProvider.error}')),
          );
        }
        if (!dropboxProvider.isConnected) {
          return Scaffold(
            appBar: AppBar(title: Text('Dropbox Files')),
            body: const Center(child: Text('Dropbox is not connected.')),
          );
        }
        final files = dropboxProvider.files;
        return Scaffold(
          appBar: AppBar(title: Text('Dropbox Files')),
          body: files.isEmpty
              ? const Center(child: Text('No files found.'))
              : ListView.builder(
                  itemCount: files.length,
                  itemBuilder: (context, index) {
                    final DropboxFile file = files[index];
                    return ListTile(
                      leading: const Icon(Icons.insert_drive_file),
                      title: Text(file.name),
                      subtitle: Text(file.pathDisplay),
                      trailing: SelectableText('${file.id}==${(file.size / 1024).toStringAsFixed(1)} KB'),
                      onTap: () {
                        // Optionally: open file in Dropbox web
                        if (file.webViewLink != null) {
                          // You can use url_launcher to open the link
                        }
                      },
                    );
                  },
                ),
        );
      },
    );
  }
} 