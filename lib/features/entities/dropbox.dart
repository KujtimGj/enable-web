class DropboxFile {
  final String id;
  final String name;
  final String pathLower;
  final String pathDisplay;
  final String tag;
  final int size;
  final DateTime serverModified;
  final DateTime clientModified;
  final String rev;
  final bool isDownloadable;
  final String? webViewLink;

  DropboxFile({
    required this.id,
    required this.name,
    required this.pathLower,
    required this.pathDisplay,
    required this.tag,
    required this.size,
    required this.serverModified,
    required this.clientModified,
    required this.rev,
    required this.isDownloadable,
    this.webViewLink,
  });

  factory DropboxFile.fromJson(Map<String, dynamic> json) {
    return DropboxFile(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      pathLower: json['path_lower'] ?? '',
      pathDisplay: json['path_display'] ?? '',
      tag: json['.tag'] ?? '',
      size: json['size'] ?? 0,
      serverModified: DateTime.parse(json['server_modified'] ?? DateTime.now().toIso8601String()),
      clientModified: DateTime.parse(json['client_modified'] ?? DateTime.now().toIso8601String()),
      rev: json['rev'] ?? '',
      isDownloadable: json['is_downloadable'] ?? false,
      webViewLink: json['web_view_link'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'path_lower': pathLower,
      'path_display': pathDisplay,
      '.tag': tag,
      'size': size,
      'server_modified': serverModified.toIso8601String(),
      'client_modified': clientModified.toIso8601String(),
      'rev': rev,
      'is_downloadable': isDownloadable,
      'web_view_link': webViewLink,
    };
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

  Map<String, dynamic> toJson() {
    return {
      'isConnected': isConnected,
      'lastSync': lastSync?.toIso8601String(),
    };
  }
} 