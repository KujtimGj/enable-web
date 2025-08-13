
class GoogleDriveFile {
  final String id;
  final String name;
  final String mimeType;
  final int? size;
  final String? modifiedTime;
  final String? webViewLink;

  GoogleDriveFile({
    required this.id,
    required this.name,
    required this.mimeType,
    this.size,
    this.modifiedTime,
    this.webViewLink,
  });

  factory GoogleDriveFile.fromJson(Map<String, dynamic> json) {
    int? parseSize(dynamic sizeValue) {
      if (sizeValue == null) return null;
      if (sizeValue is int) return sizeValue;
      if (sizeValue is String) {
        try {
          final parsed = int.parse(sizeValue);
          return parsed;
        } catch (e) {
          return null;
        }
      }
      return null;
    }

    final size = parseSize(json['size']);

    return GoogleDriveFile(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      mimeType: json['mimeType'] ?? '',
      size: size,
      modifiedTime: json['modifiedTime'] ?? '',
      webViewLink: json['webViewLink'] ?? '',
    );
  }
}

class GoogleDriveStatus {
  final bool isConnected;
  final DateTime? lastSync;

  GoogleDriveStatus({
    required this.isConnected,
    this.lastSync,
  });

  factory GoogleDriveStatus.fromJson(Map<String, dynamic> json) {
    return GoogleDriveStatus(
      isConnected: json['isConnected'] ?? false,
      lastSync: json['lastSync'] != null 
          ? DateTime.parse(json['lastSync']) 
          : null,
    );
  }
}

class DropboxFile {
  final String id;
  final String name;
  final String? pathDisplay;
  final int? size;
  final String? clientModified;
  final String? serverModified;
  final String? mimeType;

  DropboxFile({
    required this.id,
    required this.name,
    this.pathDisplay,
    this.size,
    this.clientModified,
    this.serverModified,
    this.mimeType,
  });

  factory DropboxFile.fromJson(Map<String, dynamic> json) {
    return DropboxFile(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      pathDisplay: json['path_display'],
      size: json['size'],
      clientModified: json['client_modified'],
      serverModified: json['server_modified'],
      mimeType: json['.tag'],
    );
  }
}

class DropboxStatus {
  final bool isConnected;
  final DateTime? lastSync;

  DropboxStatus({
    required this.isConnected,
    this.lastSync,
  });

  factory DropboxStatus.fromJson(Map<String, dynamic> json) {
    return DropboxStatus(
      isConnected: json['isConnected'] ?? false,
      lastSync: json['lastSync'] != null 
          ? DateTime.parse(json['lastSync']) 
          : null,
    );
  }
}
