import 'package:flutter/material.dart';
import 'package:enable_web/features/components/bookmark_components.dart';

class ExperienceDetailModal extends StatelessWidget {
  final dynamic experience;

  const ExperienceDetailModal({
    Key? key,
    required this.experience,
  }) : super(key: key);

  String _getExperienceDestination() {
    try {
      return experience['destination']?.toString() ?? 'Unknown Destination';
    } catch (e) {
      return 'Unknown Destination';
    }
  }

  String _getExperienceCountry() {
    try {
      return experience['country']?.toString() ?? 'Unknown Country';
    } catch (e) {
      return 'Unknown Country';
    }
  }

  String _getExperienceDates() {
    try {
      final startDate = experience['startDate'];
      final endDate = experience['endDate'];

      if (startDate != null && endDate != null) {
        DateTime? start, end;

        if (startDate is Map && startDate['\$date'] != null) {
          start = DateTime.tryParse(startDate['\$date'].toString());
        } else if (startDate is String) {
          start = DateTime.tryParse(startDate);
        }

        if (endDate is Map && endDate['\$date'] != null) {
          end = DateTime.tryParse(endDate['\$date'].toString());
        } else if (endDate is String) {
          end = DateTime.tryParse(endDate);
        }

        if (start != null && end != null) {
          return '${start.day}/${start.month}/${start.year} - ${end.day}/${end.month}/${end.year}';
        }
      }

      return 'Dates not available';
    } catch (e) {
      return 'Dates not available';
    }
  }

  String _getExperienceStatus() {
    try {
      return experience['status']?.toString() ?? 'Unknown Status';
    } catch (e) {
      return 'Unknown Status';
    }
  }

  String _getExperienceNotes() {
    try {
      return experience['notes']?.toString() ?? '';
    } catch (e) {
      return '';
    }
  }

  String _getExperienceParty() {
    try {
      final party = experience['party'];
      if (party != null) {
        final adults = party['adults'] ?? 0;
        final children = party['children'] ?? 0;
        if (children > 0) {
          return '$adults adults, $children children';
        } else {
          return '$adults adults';
        }
      }
      return 'Party size not available';
    } catch (e) {
      return 'Party size not available';
    }
  }

  List<dynamic> _getExperienceItinerary() {
    try {
      final itinerary = experience['itinerary'] ?? experience['itineraryItems'];
      if (itinerary != null) {
        return List<dynamic>.from(itinerary);
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: Color(0xff292525),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildOverviewSection(),
                    SizedBox(height: 32),
                    if (_getExperienceItinerary().isNotEmpty) ...[
                      _buildItineraryTimeline(),
                    ] else ...[
                      _buildEmptyItinerary(),
                    ],
                  ],
                ),
              ),
            ),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xff574435),
            Color(0xff574435).withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.flight_takeoff, color: Colors.white, size: 28),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getExperienceDestination(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_getExperienceCountry().isNotEmpty) ...[
                  SizedBox(height: 6),
                  Text(
                    _getExperienceCountry(),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 18,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: Text(
                  _getExperienceStatus().toUpperCase(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 8),
              if (_getExperienceItinerary().isNotEmpty)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${_getExperienceItinerary().length} itinerary items',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(width: 16),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.close, color: Colors.white, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xff1e1e1e),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
              SizedBox(width: 8),
              Text(
                'Experience ID: ${experience['_id']?.toString().substring(0, 8) ?? 'N/A'}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          Row(
            children: [
              _buildBookmarkButton(),
              SizedBox(width: 16),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Close'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.dashboard, size: 20, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'Experience Overview',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildOverviewItem(
                  Icons.calendar_today,
                  'Duration',
                  _getExperienceDates(),
                ),
              ),
              Expanded(
                child: _buildOverviewItem(
                  Icons.people,
                  'Party',
                  _getExperienceParty(),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          if (_getExperienceNotes().isNotEmpty) ...[
            _buildOverviewItem(
              Icons.note,
              'Notes',
              _getExperienceNotes(),
            ),
            SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildOverviewItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: Colors.white),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[300],
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildItineraryTimeline() {
    final itinerary = _getExperienceItinerary();

    Map<int, List<dynamic>> groupedByDay = {};
    for (var item in itinerary) {
      if (item['day'] != null) {
        final day = item['day'] as int;
        groupedByDay.putIfAbsent(day, () => []).add(item);
      }
    }

    // Fallback: if no day values present, show all items under Day 1
    if (groupedByDay.isEmpty && itinerary.isNotEmpty) {
      groupedByDay[1] = List<dynamic>.from(itinerary);
    }

    var sortedDays = groupedByDay.keys.toList()..sort();
    for (var day in sortedDays) {
      groupedByDay[day]!.sort((a, b) => (a['order'] ?? 0).compareTo(b['order'] ?? 0));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.timeline, size: 24, color: Colors.white),
            SizedBox(width: 12),
            Text(
              'Itinerary Timeline',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Spacer(),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white),
              ),
              child: Text(
                '${sortedDays.length} days',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 24),
        ...sortedDays.map((day) => _buildDaySection(day, groupedByDay[day]!)),
      ],
    );
  }

  Widget _buildDaySection(int day, List<dynamic> dayItems) {
    return Container(
      margin: EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey[400]!),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.calendar_today, size: 16, color: Colors.white),
                ),
                SizedBox(width: 12),
                Text(
                  'Day $day',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Spacer(),
                Text(
                  '${dayItems.length} activities',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          ...dayItems.asMap().entries.map((entry) {
            int index = entry.key;
            dynamic item = entry.value;
            return _buildTimelineItem(item, index, dayItems.length);
          }),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(dynamic item, int index, int totalItems) {
    bool isLast = index == totalItems - 1;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: _getItineraryItemColor(item['type']),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    spreadRadius: 2,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
            ),
            if (!isLast)
              Container(
                width: 3,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      _getItineraryItemColor(item['type']).withOpacity(0.3),
                      _getItineraryItemColor(item['type']).withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
          ],
        ),
        SizedBox(width: 20),
        Expanded(
          child: Container(
            margin: EdgeInsets.only(bottom: 20),
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _getItineraryItemColor(item['type']).withOpacity(0.2)),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.08),
                  spreadRadius: 1,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getItineraryItemColor(item['type']).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _getItineraryItemColor(item['type']).withOpacity(0.2)),
                      ),
                      child: Text(
                        (item['type'] ?? 'UNKNOWN').toString().toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _getItineraryItemColor(item['type']),
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusColor(item['status']).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white),
                      ),
                      child: Text(
                        (item['status'] ?? 'SUGGESTED').toString().toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Spacer(),
                    if (item['order'] != null)
                      Container(
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '#${item['order']}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 16),
                Text(
                  _getItineraryItemDescription(item),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 16),
                Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  children: [
                    if (item['supplier'] != null && item['supplier']['name'] != null)
                      _buildDetailChip(Icons.business, 'Supplier', item['supplier']['name']),
                    if (item['startAt'] != null)
                      _buildDetailChip(Icons.access_time, 'Start', _formatDateTime(item['startAt'])),
                    if (item['endAt'] != null)
                      _buildDetailChip(Icons.access_time, 'End', _formatDateTime(item['endAt'])),
                    if (item['location'] != null && item['location']['address'] != null)
                      _buildDetailChip(Icons.location_on, 'Location', item['location']['address']),
                    if (item['location'] != null && item['location']['city'] != null)
                      _buildDetailChip(Icons.location_city, 'City', item['location']['city']),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailChip(IconData icon, String label, String value) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[800],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyItinerary() {
    return Container(
      padding: EdgeInsets.all(40),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.timeline,
              size: 64,
              color: Colors.grey[400],
            ),
          ),
          SizedBox(height: 24),
          Text(
            'No Itinerary Items',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 12),
          Text(
            'This experience doesn\'t have any itinerary items yet.\nAdd activities, flights, accommodations, and more to create a complete travel plan.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Color _getItineraryItemColor(String? type) {
    switch (type?.toLowerCase()) {
      case 'flight':
        return Colors.blue;
      case 'stay':
        return Colors.green;
      case 'activity':
        return Colors.orange;
      case 'transfer':
        return Colors.purple;
      case 'reservation':
        return Colors.teal;
      case 'info':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'proposed':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      case 'suggested':
      default:
        return Colors.blue;
    }
  }

  String _formatDateTime(dynamic dateTime) {
    try {
      if (dateTime is Map && dateTime['\$date'] != null) {
        final parsed = DateTime.tryParse(dateTime['\$date'].toString());
        if (parsed != null) {
          return '${parsed.day}/${parsed.month}/${parsed.year} ${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
        }
      } else if (dateTime is String) {
        final parsed = DateTime.tryParse(dateTime);
        if (parsed != null) {
          return '${parsed.day}/${parsed.month}/${parsed.year} ${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
        }
      }
      return dateTime.toString();
    } catch (e) {
      return dateTime.toString();
    }
  }

  // Derive a meaningful itinerary item description
  String _getItineraryItemDescription(dynamic item) {
    try {
      // Prefer explicit fields
      final String? title = item['details']?['title']?.toString();
      final String? description = item['details']?['description']?.toString();
      final String? name = item['details']?['name']?.toString();
      final String? supplier = item['supplier']?['name']?.toString();
      final String? address = item['location']?['address']?.toString();
      final String? city = item['location']?['city']?.toString();

      String base = title?.trim().isNotEmpty == true
          ? title!
          : (description?.trim().isNotEmpty == true
              ? description!
              : (name?.trim().isNotEmpty == true ? name! : ''));

      final List<String> suffix = [];
      if (supplier != null && supplier.trim().isNotEmpty) suffix.add(supplier);
      if (address != null && address.trim().isNotEmpty) suffix.add(address);
      if ((address == null || address.trim().isEmpty) && city != null && city.trim().isNotEmpty) suffix.add(city);

      if (base.isEmpty && suffix.isEmpty) {
        // Construct something from type and status
        final type = (item['type'] ?? 'item').toString();
        final status = (item['status'] ?? '').toString();
        base = status.isNotEmpty ? '${_capitalize(type)} • ${_capitalize(status)}' : _capitalize(type);
      }

      if (suffix.isNotEmpty) {
        return '$base — ${suffix.join(' • ')}';
      }
      return base;
    } catch (_) {
      return 'Itinerary item';
    }
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  Widget _buildBookmarkButton() {
    final experienceId = experience['_id']?.toString() ?? experience['id']?.toString() ?? '';

    return BookmarkButton(
      itemType: 'experience',
      itemId: experienceId,
      color: Colors.white,
      activeColor: Colors.amber,
      size: 24,
    );
  }
}

