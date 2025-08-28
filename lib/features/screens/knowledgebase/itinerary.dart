import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/responsive_utils.dart';
import '../../components/responsive_scaffold.dart';
import '../../components/widgets.dart';
import '../../providers/experienceProvider.dart';
import '../../providers/agencyProvider.dart';
import '../../providers/userProvider.dart';
import '../../entities/experienceModel.dart';

class Itinerary extends StatefulWidget {
  const Itinerary({super.key});

  @override
  State<Itinerary> createState() => _ItineraryState();
}

class _ItineraryState extends State<Itinerary> {
  @override
  void initState() {
    super.initState();
    print('Itinerary screen initState called');
    // Fetch experiences when the page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('Itinerary screen post frame callback executing');
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final agencyProvider = Provider.of<AgencyProvider>(context, listen: false);
      
      print('Itinerary screen - UserProvider state: isAuthenticated: ${userProvider.isAuthenticated}, user: ${userProvider.user?.email}');
      print('Itinerary screen - AgencyProvider state: isAuthenticated: ${agencyProvider.isAuthenticated}');
      
      if (userProvider.user?.agencyId != null) {
        print('Fetching experiences for agency: ${userProvider.user!.agencyId}');
        agencyProvider.fetchExperiences(userProvider.user!.agencyId);
      } else {
        print('No agency ID found in user provider');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      appBar: AppBar(
        toolbarHeight: 65,
        automaticallyImplyLeading: false,
        leadingWidth: 120,
        leading: GestureDetector(
          onTap: () => context.go('/home'),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.arrow_back, size: 20),
              SizedBox(width: 4),
              Text("Itinerary", style: TextStyle(fontSize: 14)),
            ],
          ),
        ),
        centerTitle: true,
        title: customForm(context),
        actions: [customButton((){context.go("/");})],
      ),
      body: ResponsiveContainer(
        child: Row(
          children: [
            bottomLeftBar(),
            Expanded(
              flex: 1,
              child: Stack(
                children: [
                  Consumer<AgencyProvider>(
                builder: (context, agencyProvider, child) {
                  if (agencyProvider.isLoadingData) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Loading itineraries...'),
                        ],
                      ),
                    );
                  }

                  if (agencyProvider.errorMessage != null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 64, color: Colors.red),
                          SizedBox(height: 16),
                          Text(
                            'Error: ${agencyProvider.errorMessage}',
                            style: TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              final userProvider = Provider.of<UserProvider>(context, listen: false);
                              if (userProvider.user?.agencyId != null) {
                                agencyProvider.fetchExperiences(userProvider.user!.agencyId!);
                              }
                            },
                            child: Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  final experiences = agencyProvider.experiences;
                  
                  if (experiences.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.flight_takeoff, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No itineraries found',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Create your first experience to see itineraries here',
                            style: TextStyle(
                              color: Colors.grey[500],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  return Container(
                    padding: EdgeInsets.all(10),
                    child: RefreshIndicator(
                      onRefresh: () async {
                        final userProvider = Provider.of<UserProvider>(context, listen: false);
                        if (userProvider.user?.agencyId != null) {
                          await agencyProvider.fetchExperiences(userProvider.user!.agencyId!);
                        }
                      },
                      child: GridView.builder(
                        shrinkWrap: false,
                        physics: AlwaysScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount:
                          ResponsiveUtils.isMobile(context)
                              ? 1
                              : ResponsiveUtils.isTablet(context)
                              ? 2
                              : 3,
                          childAspectRatio: 1.7,
                          mainAxisSpacing: 20,
                          crossAxisSpacing: 20,
                        ),
                        itemCount: experiences.length,
                        itemBuilder: (BuildContext context, int index) {
                          final experience = experiences[index];
                          return _buildItineraryCard(experience, index);
                        },
                      ),
                    ),
                  );
                },
              ),
                  // Floating Action Button for creating new experiences
                  Positioned(
                    bottom: 20,
                    right: 20,
                    child: FloatingActionButton.extended(
                      onPressed: () {
                        // TODO: Navigate to create experience page
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Create new experience functionality coming soon!'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: Icon(Icons.add),
                      label: Text('New Experience'),
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItineraryCard(ExperienceModel experience, int index) {
    final hasItinerary = experience.itinerary != null && experience.itinerary!.isNotEmpty;
    final itineraryCount = hasItinerary ? experience.itinerary!.length : 0;
    
    return GestureDetector(
      onTap: () {
        _showItineraryDetails(context, experience);
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          decoration: BoxDecoration(
            border: Border.all(width: 1, color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(10),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 3,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                margin: EdgeInsets.only(right: 2.5, bottom: 2.5),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(5),
                                  color: _getStatusColor(experience.status),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                margin: EdgeInsets.only(left: 2.5, bottom: 2.5),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(5),
                                  color: _getStatusColor(experience.status),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                margin: EdgeInsets.only(right: 2.5, top: 2.5),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(5),
                                  color: _getStatusColor(experience.status),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                margin: EdgeInsets.only(left: 2.5, top: 2.5),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(5),
                                  color: _getStatusColor(experience.status),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              experience.destination ?? 'Unknown Destination',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusColor(experience.status),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              experience.status?.toUpperCase() ?? 'DRAFT',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      if (experience.country != null) ...[
                        Text(
                          experience.country!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 4),
                      ],
                      if (experience.startDate != null && experience.endDate != null) ...[
                        Text(
                          '${_formatDate(experience.startDate!)} - ${_formatDate(experience.endDate!)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 4),
                      ],
                      if (hasItinerary) ...[
                        Text(
                          '$itineraryCount itinerary items',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ] else ...[
                        Text(
                          'No itinerary items',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                      if (experience.party != null) ...[
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.people, size: 14, color: Colors.grey[600]),
                            SizedBox(width: 4),
                            Text(
                              '${experience.party!['adults'] ?? 0} adults, ${experience.party!['children'] ?? 0} children',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'proposed':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      case 'draft':
      default:
        return Color(0xff1e1e1e);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showItineraryDetails(BuildContext context, ExperienceModel experience) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: ResponsiveUtils.isMobile(context) ? double.infinity : 900,
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
            child: Column(
              children: [
                // Header
                Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).primaryColor,
                        Theme.of(context).primaryColor.withOpacity(0.8),
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
                          color: Colors.white.withOpacity(0.2),
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
                              experience.destination ?? 'Itinerary Details',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (experience.country != null) ...[
                              SizedBox(height: 6),
                              Text(
                                experience.country!,
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
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withOpacity(0.3)),
                            ),
                            child: Text(
                              experience.status?.toUpperCase() ?? 'DRAFT',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(height: 8),
                          if (experience.itinerary != null && experience.itinerary!.isNotEmpty)
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                '${experience.itinerary!.length} itinerary items',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Experience Overview
                        _buildOverviewSection(experience),
                        SizedBox(height: 32),
                        
                        // Itinerary Timeline
                        if (experience.itinerary != null && experience.itinerary!.isNotEmpty) ...[
                          _buildItineraryTimeline(experience.itinerary!),
                        ] else ...[
                          _buildEmptyItinerary(),
                        ],
                      ],
                    ),
                  ),
                ),
                
                // Actions
                Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
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
                            'Experience ID: ${experience.id?.substring(0, 8) ?? 'N/A'}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text('Close'),
                          ),
                          SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: () {
                              // TODO: Navigate to edit experience page
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Edit experience functionality coming soon!')),
                              );
                            },
                            icon: Icon(Icons.edit),
                            label: Text('Edit Experience'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOverviewSection(ExperienceModel experience) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue[50]!, Colors.indigo[50]!],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.dashboard, size: 20, color: Colors.blue[700]),
              SizedBox(width: 8),
              Text(
                'Experience Overview',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
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
                  experience.startDate != null && experience.endDate != null
                      ? '${_formatDate(experience.startDate!)} - ${_formatDate(experience.endDate!)}'
                      : 'Not specified',
                ),
              ),
              Expanded(
                child: _buildOverviewItem(
                  Icons.people,
                  'Party',
                  experience.party != null
                      ? '${experience.party!['adults'] ?? 0} adults, ${experience.party!['children'] ?? 0} children'
                      : 'Not specified',
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          if (experience.notes != null && experience.notes!.isNotEmpty) ...[
            _buildOverviewItem(
              Icons.note,
              'Notes',
              experience.notes!,
            ),
            SizedBox(height: 16),
          ],
          if (experience.tags != null && experience.tags!.isNotEmpty) ...[
            Row(
              children: [
                Icon(Icons.tag, size: 18, color: Colors.blue[600]),
                SizedBox(width: 8),
                Text(
                  'Tags:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.blue[800],
                    fontSize: 14,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: experience.tags!.entries.map((entry) {
                      return Container(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.blue[300]!),
                        ),
                        child: Text(
                          entry.value.toString(),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[800],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
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
            color: Colors.blue[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: Colors.blue[700]),
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
                  color: Colors.blue[700],
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.blue[900],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildItineraryTimeline(List<ItineraryItemModel> itinerary) {
    // Group itinerary items by day
    Map<int, List<ItineraryItemModel>> groupedByDay = {};
    for (var item in itinerary) {
      if (item.day != null) {
        groupedByDay.putIfAbsent(item.day!, () => []).add(item);
      }
    }
    
    // Sort days and items within each day
    var sortedDays = groupedByDay.keys.toList()..sort();
    for (var day in sortedDays) {
      groupedByDay[day]!.sort((a, b) => (a.order ?? 0).compareTo(b.order ?? 0));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.timeline, size: 24, color: Colors.orange[700]),
            SizedBox(width: 12),
            Text(
              'Itinerary Timeline',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            Spacer(),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orange[300]!),
              ),
              child: Text(
                '${sortedDays.length} days',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[800],
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

  Widget _buildDaySection(int day, List<ItineraryItemModel> dayItems) {
    return Container(
      margin: EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day Header
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Colors.orange[100]!, Colors.amber[100]!],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.orange[300]!),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.calendar_today, size: 16, color: Colors.orange[800]),
                ),
                SizedBox(width: 12),
                Text(
                  'Day $day',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[800],
                  ),
                ),
                Spacer(),
                Text(
                  '${dayItems.length} activities',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          
          // Timeline items
          ...dayItems.asMap().entries.map((entry) {
            int index = entry.key;
            ItineraryItemModel item = entry.value;
            return _buildTimelineItem(item, index, dayItems.length);
          }),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(ItineraryItemModel item, int index, int totalItems) {
    bool isLast = index == totalItems - 1;
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline line and dot
        Column(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: _getItineraryItemColor(item.type),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: _getItineraryItemColor(item.type).withOpacity(0.3),
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
                      _getItineraryItemColor(item.type).withOpacity(0.3),
                      _getItineraryItemColor(item.type).withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
          ],
        ),
        SizedBox(width: 20),
        
        // Item content
        Expanded(
          child: Container(
            margin: EdgeInsets.only(bottom: 20),
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _getItineraryItemColor(item.type).withOpacity(0.2)),
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
                // Header row
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getItineraryItemColor(item.type).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _getItineraryItemColor(item.type).withOpacity(0.2)),
                      ),
                      child: Text(
                        item.type?.toUpperCase() ?? 'UNKNOWN',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _getItineraryItemColor(item.type),
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusColor(item.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _getStatusColor(item.status).withOpacity(0.2)),
                      ),
                      child: Text(
                        item.status?.toUpperCase() ?? 'SUGGESTED',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _getStatusColor(item.status),
                        ),
                      ),
                    ),
                    Spacer(),
                    if (item.order != null)
                      Container(
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '#${item.order}',
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
                
                // Description
                Text(
                  item.details?['description'] ?? 'No description available',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 16),
                
                // Additional details in a grid layout
                Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  children: [
                    if (item.supplier != null && item.supplier!['name'] != null)
                      _buildDetailChip(Icons.business, 'Supplier', item.supplier!['name']!),
                    if (item.startAt != null)
                      _buildDetailChip(Icons.access_time, 'Start', _formatDateTime(item.startAt!)),
                    if (item.endAt != null)
                      _buildDetailChip(Icons.access_time, 'End', _formatDateTime(item.endAt!)),
                    if (item.location != null && item.location!['address'] != null)
                      _buildDetailChip(Icons.location_on, 'Location', item.location!['address']!),
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
        color: Colors.grey[50],
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
          SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              // TODO: Navigate to add itinerary item page
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Add itinerary item functionality coming soon!')),
              );
            },
            icon: Icon(Icons.add),
            label: Text('Add Itinerary Item'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
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

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
