
class GoogleDriveFile {
  final String id;
  final String name;
  final String mimeType;
  final int? size;
  final String? modifiedTime;
  final String? webViewLink;
  final String? iconLink;
  final bool isFolder;
  final String type;
  final List<String>? parents;
  final int? itemCount;
  final bool isShared;
  final String owner;
  final List<dynamic> permissions;

  GoogleDriveFile({
    required this.id,
    required this.name,
    required this.mimeType,
    this.size,
    this.modifiedTime,
    this.webViewLink,
    this.iconLink,
    required this.isFolder,
    required this.type,
    this.parents,
    this.itemCount,
    this.isShared = false,
    this.owner = 'Unknown',
    this.permissions = const [],
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
    final isFolder = json['mimeType'] == 'application/vnd.google-apps.folder' || json['isFolder'] == true;
    final type = isFolder ? 'folder' : 'file';

    return GoogleDriveFile(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      mimeType: json['mimeType'] ?? '',
      size: size,
      modifiedTime: json['modifiedTime'] ?? '',
      webViewLink: json['webViewLink'] ?? '',
      iconLink: json['iconLink'],
      isFolder: isFolder,
      type: type,
      parents: json['parents'] != null ? List<String>.from(json['parents']) : null,
      itemCount: json['itemCount'],
      isShared: json['isShared'] ?? false,
      owner: json['owner'] ?? 'Unknown',
      permissions: json['permissions'] != null ? List<dynamic>.from(json['permissions']) : [],
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

class GoogleDriveFolder {
  final String id;
  final String name;
  final List<String>? parents;
  final String? webViewLink;
  final String? iconLink;

  GoogleDriveFolder({
    required this.id,
    required this.name,
    this.parents,
    this.webViewLink,
    this.iconLink,
  });

  factory GoogleDriveFolder.fromJson(Map<String, dynamic> json) {
    return GoogleDriveFolder(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      parents: json['parents'] != null ? List<String>.from(json['parents']) : null,
      webViewLink: json['webViewLink'],
      iconLink: json['iconLink'],
    );
  }
}

class Breadcrumb {
  final String id;
  final String name;

  Breadcrumb({
    required this.id,
    required this.name,
  });

  factory Breadcrumb.fromJson(Map<String, dynamic> json) {
    return Breadcrumb(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
    );
  }
}

class PaginationInfo {
  final int currentPage;
  final int pageSize;
  final int totalPages;
  final bool hasMore;
  final int totalItems;

  PaginationInfo({
    required this.currentPage,
    required this.pageSize,
    required this.totalPages,
    required this.hasMore,
    required this.totalItems,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      currentPage: json['currentPage'] ?? 1,
      pageSize: json['pageSize'] ?? 50,
      totalPages: json['totalPages'] ?? 1,
      hasMore: json['hasMore'] ?? false,
      totalItems: json['totalItems'] ?? 0,
    );
  }
}

class FolderContents {
  final GoogleDriveFolder folder;
  final List<Breadcrumb> breadcrumbs;
  final List<GoogleDriveFile> contents;
  final int totalItems;
  final int totalFolders;
  final int totalFiles;
  final PaginationInfo? pagination;

  FolderContents({
    required this.folder,
    required this.breadcrumbs,
    required this.contents,
    required this.totalItems,
    required this.totalFolders,
    required this.totalFiles,
    this.pagination,
  });

  factory FolderContents.fromJson(Map<String, dynamic> json) {
    return FolderContents(
      folder: GoogleDriveFolder.fromJson(json['folder'] ?? {}),
      breadcrumbs: (json['breadcrumbs'] as List<dynamic>?)
          ?.map((crumb) => Breadcrumb.fromJson(crumb))
          .toList() ?? [],
      contents: (json['contents'] as List<dynamic>?)
          ?.map((item) => GoogleDriveFile.fromJson(item))
          .toList() ?? [],
      totalItems: json['totalItems'] ?? 0,
      totalFolders: json['totalFolders'] ?? 0,
      totalFiles: json['totalFiles'] ?? 0,
      pagination: json['pagination'] != null 
          ? PaginationInfo.fromJson(json['pagination']) 
          : null,
    );
  }
}

class GoogleDriveStructure {
  final List<GoogleDriveFile> folderStructure;
  final List<GoogleDriveFile> rootItems;
  final List<GoogleDriveFile> files;
  final int totalFiles;
  final int totalFolders;
  final int rootFolders;
  final int rootFiles;

  GoogleDriveStructure({
    required this.folderStructure,
    required this.rootItems,
    required this.files,
    required this.totalFiles,
    required this.totalFolders,
    required this.rootFolders,
    required this.rootFiles,
  });

  factory GoogleDriveStructure.fromJson(Map<String, dynamic> json) {
    return GoogleDriveStructure(
      folderStructure: (json['folderStructure'] as List<dynamic>?)
          ?.map((item) => GoogleDriveFile.fromJson(item))
          .toList() ?? [],
      rootItems: (json['rootItems'] as List<dynamic>?)
          ?.map((item) => GoogleDriveFile.fromJson(item))
          .toList() ?? [],
      files: (json['files'] as List<dynamic>?)
          ?.map((item) => GoogleDriveFile.fromJson(item))
          .toList() ?? [],
      totalFiles: json['totalFiles'] ?? 0,
      totalFolders: json['totalFolders'] ?? 0,
      rootFolders: json['rootFolders'] ?? 0,
      rootFiles: json['rootFiles'] ?? 0,
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
