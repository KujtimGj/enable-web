import 'package:enable_web/features/entities/google_drive.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Google Drive Integration Tests', () {
    test('GoogleDriveFile fromJson should parse correctly', () {
      final json = {
        'id': 'test-id',
        'name': 'test-file.pdf',
        'mimeType': 'application/pdf',
        'size': 1024,
        'modifiedTime': '2024-01-01T12:00:00Z',
        'webViewLink': 'https://drive.google.com/file/d/test-id/view',
      };

      final file = GoogleDriveFile.fromJson(json);

      expect(file.id, equals('test-id'));
      expect(file.name, equals('test-file.pdf'));
      expect(file.mimeType, equals('application/pdf'));
      expect(file.size, equals(1024));
      expect(file.modifiedTime, equals('2024-01-01T12:00:00Z'));
      expect(file.webViewLink, equals('https://drive.google.com/file/d/test-id/view'));
    });

    test('GoogleDriveStatus fromJson should parse correctly', () {
      final json = {
        'isConnected': true,
        'lastSync': '2024-01-01T12:00:00Z',
      };

      final status = GoogleDriveStatus.fromJson(json);

      expect(status.isConnected, isTrue);
      expect(status.lastSync, isNotNull);
      expect(status.lastSync!.year, equals(2024));
      expect(status.lastSync!.month, equals(1));
      expect(status.lastSync!.day, equals(1));
    });

    test('GoogleDriveStatus fromJson should handle null lastSync', () {
      final json = {
        'isConnected': false,
        'lastSync': null,
      };

      final status = GoogleDriveStatus.fromJson(json);

      expect(status.isConnected, isFalse);
      expect(status.lastSync, isNull);
    });
  });
} 