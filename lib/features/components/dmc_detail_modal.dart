import 'package:flutter/material.dart';
import 'package:enable_web/features/components/bookmark_components.dart';

class DMCDetailModal extends StatelessWidget {
  final dynamic dmc;

  const DMCDetailModal({
    Key? key,
    required this.dmc,
  }) : super(key: key);

  String _getDMCBusinessName() {
    try {
      return dmc['businessName']?.toString() ?? 'Unknown Business';
    } catch (e) {
      return 'Unknown Business';
    }
  }

  String _getDMCLocation() {
    try {
      return dmc['location']?.toString() ?? 'Unknown Location';
    } catch (e) {
      return 'Unknown Location';
    }
  }

  String _getDMCDescription() {
    try {
      return dmc['description']?.toString() ?? '';
    } catch (e) {
      return '';
    }
  }

  List<dynamic> _getDMCServiceProviders() {
    try {
      return List<dynamic>.from(dmc['serviceProviders'] ?? []);
    } catch (e) {
      return [];
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
                            color: Color(0xff574435),
                            borderRadius: BorderRadius.circular(40),
                          ),
                          child: Icon(
                            Icons.business,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                        SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getDMCBusinessName(),
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                _getDMCLocation(),
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[300],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 30),
                    if (_getDMCDescription().isNotEmpty) ...[
                      Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getDMCDescription(),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[300],
                            height: 1.5,
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                    ],
                    if (_getDMCServiceProviders().isNotEmpty) ...[
                      Text(
                        'Service Providers',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 10),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _getDMCServiceProviders().length,
                          itemBuilder: (context, index) {
                            final provider = _getDMCServiceProviders()[index];
                            return Container(
                              margin: EdgeInsets.only(bottom: 8),
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Color(0xFF1E1E1E),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    provider['companyName']?.toString() ?? 'Unknown Company',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  if (provider['countryOfOperation'] != null)
                                    Text(
                                      provider['countryOfOperation'],
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[400],
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
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

  Widget _buildBookmarkButton() {
    final dmcId = dmc['_id']?.toString() ?? dmc['id']?.toString() ?? '';

    return BookmarkButton(
      itemType: 'dmc',
      itemId: dmcId,
      color: Colors.white,
      activeColor: Colors.amber,
      size: 24,
    );
  }
}

