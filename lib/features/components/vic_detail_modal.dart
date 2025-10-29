import 'package:flutter/material.dart';
import 'package:enable_web/features/components/bookmark_components.dart';

class VICDetailModal extends StatelessWidget {
  final dynamic vic;

  const VICDetailModal({
    Key? key,
    required this.vic,
  }) : super(key: key);

  String _getVicName() {
    if (vic == null) return 'Client Detail';
    try {
      return vic['fullName']?.toString() ?? 'Client Detail';
    } catch (e) {
      return 'Client Detail';
    }
  }

  String _getVicEmail() {
    if (vic == null) return '';
    try {
      return vic['email']?.toString() ?? '';
    } catch (e) {
      return '';
    }
  }

  String _getVicPhone() {
    if (vic == null) return '';
    try {
      return vic['phone']?.toString() ?? '';
    } catch (e) {
      return '';
    }
  }

  String _getVicNationality() {
    if (vic == null) return '';
    try {
      return vic['nationality']?.toString() ?? '';
    } catch (e) {
      return '';
    }
  }

  String _getVicSummary() {
    if (vic == null) return '';
    try {
      return vic['summary']?.toString() ?? '';
    } catch (e) {
      return '';
    }
  }

  Map<String, dynamic> _getVicPreferences() {
    if (vic == null) return {};
    try {
      return Map<String, dynamic>.from(vic['preferences'] ?? {});
    } catch (e) {
      return {};
    }
  }

  String _formatPreferenceValue(dynamic value) {
    if (value == null) return '';
    
    // Handle lists/arrays
    if (value is List) {
      if (value.isEmpty) return '';
      return value.map((item) => item.toString()).join(', ');
    }
    
    // Handle maps/objects
    if (value is Map) {
      if (value.isEmpty) return '';
      return value.entries
          .map((entry) => '${entry.key}: ${entry.value}')
          .join(', ');
    }
    
    // Handle simple types
    return value.toString();
  }

  DateTime? _getVicCreatedAt() {
    if (vic == null) return null;
    try {
      final createdAt = vic['createdAt'];
      if (createdAt == null) return null;
      if (createdAt is DateTime) return createdAt;
      if (createdAt is String) return DateTime.parse(createdAt);
      return null;
    } catch (e) {
      return null;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.month}/${date.day}/${date.year}';
  }

  String _getVicInitials() {
    final name = _getVicName();
    if (name.isEmpty) return 'U';

    final nameParts = name.split(' ');
    if (nameParts.length >= 2) {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    } else {
      return name[0].toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.6,
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Color(0xff292525),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: Colors.white, size: 24),
                  ),
                  _buildBookmarkButton(),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xff574435),
                          ),
                          child: Center(
                            child: Text(
                              _getVicInitials(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 28,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getVicName(),
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 8),
                              if (_getVicEmail().isNotEmpty)
                                _buildDetailRow(Icons.email, _getVicEmail()),
                              if (_getVicPhone().isNotEmpty)
                                _buildDetailRow(Icons.phone, _getVicPhone()),
                              if (_getVicNationality().isNotEmpty)
                                _buildDetailRow(Icons.flag, _getVicNationality()),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 30),
                    if (_getVicSummary().isNotEmpty) ...[
                      Text(
                        'Summary',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Color(0xff3A3A3A),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getVicSummary(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                    ],
                    if (_getVicPreferences().isNotEmpty) ...[
                      Text(
                        'Preferences',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12),
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Color(0xff3A3A3A),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                for (String key in _getVicPreferences().keys)
                                  Padding(
                                    padding: EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 120,
                                          child: Text(
                                            key.replaceAll('_', ' ').split(' ').map((word) => word.isEmpty ? word : word[0].toUpperCase() + word.substring(1).toLowerCase()).join(' '),
                                            style: TextStyle(
                                              color: Colors.grey[300],
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            _formatPreferenceValue(_getVicPreferences()[key]),
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                    Spacer(),
                    if (_getVicCreatedAt() != null) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Created: ${_formatDate(_getVicCreatedAt())}',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                          ),
                          SizedBox(width: 20),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[400]),
          SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[300],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookmarkButton() {
    String? vicId;
    try {
      vicId = vic['_id']?.toString() ?? vic['id']?.toString();
    } catch (e) {
      print('Error getting VIC ID: $e');
      return SizedBox.shrink();
    }

    if (vicId == null) {
      return SizedBox.shrink();
    }

    return BookmarkButton(
      itemType: 'vic',
      itemId: vicId,
      color: Colors.white,
      activeColor: Colors.amber,
      size: 24,
    );
  }
}

