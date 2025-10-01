import 'package:flutter/material.dart';
import 'package:enable_web/features/components/bookmark_components.dart';

class ServiceProviderDetailModal extends StatelessWidget {
  final dynamic serviceProvider;

  const ServiceProviderDetailModal({
    Key? key,
    required this.serviceProvider,
  }) : super(key: key);

  String _getServiceProviderCompanyName() {
    try {
      return serviceProvider['companyName']?.toString() ?? 'Unknown Company';
    } catch (e) {
      return 'Unknown Company';
    }
  }

  String _getServiceProviderCountry() {
    try {
      return serviceProvider['countryOfOperation']?.toString() ?? 'Unknown Country';
    } catch (e) {
      return 'Unknown Country';
    }
  }

  String _getServiceProviderAddress() {
    try {
      return serviceProvider['address']?.toString() ?? '';
    } catch (e) {
      return '';
    }
  }

  String _getServiceProviderExpertise() {
    try {
      final expertise = serviceProvider['productExpertise'];
      if (expertise is List) {
        return expertise.join(', ');
      }
      return expertise?.toString() ?? '';
    } catch (e) {
      return '';
    }
  }

  List<dynamic> _getServiceProviderContacts() {
    try {
      return List<dynamic>.from(serviceProvider['pointsOfContact'] ?? []);
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
                            Icons.support_agent,
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
                                _getServiceProviderCompanyName(),
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                _getServiceProviderCountry(),
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
                    if (_getServiceProviderAddress().isNotEmpty)
                      _buildDetailRow(Icons.location_on, 'Address', _getServiceProviderAddress()),
                    if (_getServiceProviderExpertise().isNotEmpty)
                      _buildDetailRow(Icons.star, 'Expertise', _getServiceProviderExpertise()),
                    SizedBox(height: 20),
                    if (_getServiceProviderContacts().isNotEmpty) ...[
                      Text(
                        'Contact Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 10),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _getServiceProviderContacts().length,
                          itemBuilder: (context, index) {
                            final contact = _getServiceProviderContacts()[index];
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
                                    '${contact['name'] ?? ''} ${contact['surname'] ?? ''}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  if (contact['emailAddress'] != null)
                                    Text(
                                      contact['emailAddress'],
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[400],
                                      ),
                                    ),
                                  if (contact['phoneNumber'] != null)
                                    Text(
                                      contact['phoneNumber'],
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

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[400], size: 20),
          SizedBox(width: 12),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[300],
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookmarkButton() {
    final serviceProviderId = serviceProvider['_id']?.toString() ?? serviceProvider['id']?.toString() ?? '';

    return BookmarkButton(
      itemType: 'serviceProvider',
      itemId: serviceProviderId,
      color: Colors.white,
      activeColor: Colors.amber,
      size: 24,
    );
  }
}

