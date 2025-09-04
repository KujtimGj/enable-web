class IngestionProgress {
  final String fileId;
  final String fileName;
  final String status;
  final int? progress;
  final String? message;
  final DateTime? startedAt;
  final DateTime? finishedAt;
  final String? error;

  IngestionProgress({
    required this.fileId,
    required this.fileName,
    required this.status,
    this.progress,
    this.message,
    this.startedAt,
    this.finishedAt,
    this.error,
  });

  factory IngestionProgress.fromJson(Map<String, dynamic> json) {
    return IngestionProgress(
      fileId: json['fileId'] ?? '',
      fileName: json['fileName'] ?? '',
      status: json['status'] ?? 'unknown',
      progress: json['progress'],
      message: json['message'],
      startedAt: json['startedAt'] != null ? DateTime.parse(json['startedAt']) : null,
      finishedAt: json['finishedAt'] != null ? DateTime.parse(json['finishedAt']) : null,
      error: json['error'],
    );
  }

  IngestionProgress copyWith({
    String? fileId,
    String? fileName,
    String? status,
    int? progress,
    String? message,
    DateTime? startedAt,
    DateTime? finishedAt,
    String? error,
  }) {
    return IngestionProgress(
      fileId: fileId ?? this.fileId,
      fileName: fileName ?? this.fileName,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      message: message ?? this.message,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      error: error ?? this.error,
    );
  }
}
