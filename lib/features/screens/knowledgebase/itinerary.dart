import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/svg.dart';

import '../../../core/dimensions.dart';
import '../../../core/responsive_utils.dart';
import '../../components/responsive_scaffold.dart';
import '../../components/widgets.dart';
import '../../providers/agencyProvider.dart';
import '../../providers/userProvider.dart';
import '../../providers/bookmark_provider.dart';
import '../../entities/experienceModel.dart';
class Itinerary extends StatefulWidget {
  const Itinerary({super.key});

  @override
  State<Itinerary> createState() => _ItineraryState();
}

class _ItineraryState extends State<Itinerary> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    print('Itinerary screen initState called');
    
    // Setup scroll listener for infinite scroll
    _scrollController.addListener(_onScroll);
    
    // Fetch experiences when the page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('Itinerary screen post frame callback executing');
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final agencyProvider = Provider.of<AgencyProvider>(context, listen: false);
      
      print('Itinerary screen - UserProvider state: isAuthenticated: ${userProvider.isAuthenticated}, user: ${userProvider.user?.email}');
      print('Itinerary screen - AgencyProvider state: isAuthenticated: ${agencyProvider.isAuthenticated}');
      
      if (userProvider.user?.agencyId != null) {
        print('Fetching experiences for agency: ${userProvider.user!.agencyId}');
        agencyProvider.fetchExperiences(userProvider.user!.agencyId, refresh: true);
      } else {
        print('No agency ID found in user provider');
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      // Load more when user is 200 pixels from the bottom
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final agencyProvider = Provider.of<AgencyProvider>(context, listen: false);
      
      if (userProvider.user?.agencyId != null && 
          agencyProvider.hasMore && 
          !agencyProvider.isLoadingMore &&
          agencyProvider.searchQuery.isEmpty) {
        agencyProvider.loadMoreExperiences(userProvider.user!.agencyId);
      }
    }
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    
    if (query.trim().isEmpty) {
      // Clear search immediately
      final agencyProvider = Provider.of<AgencyProvider>(context, listen: false);
      agencyProvider.clearSearch();
      return;
    }

    // Perform local search immediately for partial matches
    final agencyProvider = Provider.of<AgencyProvider>(context, listen: false);
    agencyProvider.performLocalSearch(query);

    // Set up debounced server search
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (userProvider.user?.agencyId != null) {
        // Use server search which already queries itinerary-aware endpoint
        agencyProvider.searchExperiences(query, userProvider.user!.agencyId);
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
              Text("Experiences", style: TextStyle(fontSize: 14)),
            ],
          ),
        ),
        centerTitle: true,
        title: customExperienceForm(context),
        actions: [customButton((){context.go("/home");})],
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
                                agencyProvider.fetchExperiences(userProvider.user!.agencyId);
                              }
                            },
                            child: Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  final visible = agencyProvider.visibleExperiences;
                  
                  if (agencyProvider.experiences.isEmpty) {
                    final isSearching = agencyProvider.searchQuery.isNotEmpty;
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isSearching ? Icons.search_off : Icons.flight_takeoff,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            isSearching ? 'No experiences found' : 'No itineraries found',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            isSearching
                                ? 'Try searching with different keywords'
                                : 'Create your first experience to see itineraries here',
                            style: TextStyle(
                              color: Colors.grey[500],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (isSearching) ...[
                            SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                _searchController.clear();
                                agencyProvider.clearSearch();
                              },
                              child: Text('Clear Search'),
                            ),
                          ],
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
                          await agencyProvider.fetchExperiences(userProvider.user!.agencyId, refresh: true);
                        }
                      },
                      child: Column(
                        children: [
                          _ItineraryFilterBar(),
                          SizedBox(height: 10),
                          // Pagination info bar
                          if (agencyProvider.totalCount > 0) ...[
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Showing ${visible.length} of ${agencyProvider.totalCount} itineraries',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        'Page ${agencyProvider.currentPage} of ${agencyProvider.totalPages}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      // Previous page button
                                      IconButton(
                                        icon: Icon(Icons.arrow_back_ios, size: 16),
                                        onPressed: agencyProvider.currentPage > 1
                                            ? () {
                                                final userProvider = Provider.of<UserProvider>(context, listen: false);
                                                if (userProvider.user?.agencyId != null) {
                                                  agencyProvider.goToPreviousPage(userProvider.user!.agencyId);
                                                }
                                              }
                                            : null,
                                        tooltip: 'Previous page',
                                        padding: EdgeInsets.all(4),
                                        constraints: BoxConstraints(),
                                      ),
                                      SizedBox(width: 4),
                                      // Next page button
                                      IconButton(
                                        icon: Icon(Icons.arrow_forward_ios, size: 16),
                                        onPressed: agencyProvider.currentPage < agencyProvider.totalPages
                                            ? () {
                                                final userProvider = Provider.of<UserProvider>(context, listen: false);
                                                if (userProvider.user?.agencyId != null) {
                                                  agencyProvider.goToNextPage(userProvider.user!.agencyId);
                                                }
                                              }
                                            : null,
                                        tooltip: 'Next page',
                                        padding: EdgeInsets.all(4),
                                        constraints: BoxConstraints(),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 10),
                          ],
                          
                          // Grid view
                          Expanded(
                            child: visible.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.search_off,
                                          size: 64,
                                          color: Colors.grey,
                                        ),
                                        SizedBox(height: 16),
                                        Text(
                                          'No experiences found',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          'Try adjusting your filters',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(color: Colors.grey[600]),
                                        ),
                                      ],
                                    ),
                                  )
                                : GridView.builder(
                              controller: _scrollController,
                              shrinkWrap: false,
                              physics: AlwaysScrollableScrollPhysics(),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount:
                                ResponsiveUtils.isMobile(context)
                                    ? 1
                                    : ResponsiveUtils.isTablet(context)
                                    ? 2
                                    : 3,
                                childAspectRatio: 1.9,
                                mainAxisSpacing: 30,
                                crossAxisSpacing: 30,
                              ),
                              itemCount: visible.length + ((agencyProvider.hasMore && !agencyProvider.hasActiveExperienceFilters) ? 1 : 0),
                              itemBuilder: (BuildContext context, int index) {
                                // Show loading indicator at the end
                                if (index == visible.length && agencyProvider.hasMore && !agencyProvider.hasActiveExperienceFilters) {
                                  return Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          if (agencyProvider.isLoadingMore)
                                            CircularProgressIndicator()
                                          else
                                            ElevatedButton.icon(
                                              onPressed: () {
                                                final userProvider = Provider.of<UserProvider>(context, listen: false);
                                                if (userProvider.user?.agencyId != null) {
                                                  agencyProvider.loadMoreExperiences(userProvider.user!.agencyId);
                                                }
                                              },
                                              icon: Icon(Icons.refresh),
                                              label: Text('Load More'),
                                              style: ElevatedButton.styleFrom(
                                                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                }
                                
                                final experience = visible[index];
                                return _buildItineraryCard(experience, index);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget customExperienceForm(BuildContext context) {
    return ResponsiveContainer(
      maxWidth: getWidth(context) * 0.3,
      child: TextFormField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Search experiences...',
          suffixIcon: Consumer<AgencyProvider>(
            builder: (context, agencyProvider, child) {
              if (agencyProvider.isSearching) {
                return SizedBox(
                  width: 10,
                  height: 10,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[600]!),
                    ),
                  ),
                );
              }
              return Icon(Icons.search);
            },
          ),
          border: OutlineInputBorder(
            borderSide: BorderSide(width: 0.5, color: Colors.grey[500]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(width: 0.5, color: Colors.grey[500]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(width: 0.5, color: Colors.grey[500]!),
          ),
        ),
      ),
    );
  }
  Widget _buildItineraryCard(ExperienceModel experience, int index) {
    final hasItinerary = experience.itinerary != null && experience.itinerary!.isNotEmpty;
    final itineraryCount = hasItinerary ? experience.itinerary!.length : 0;
    
    return _HoverableItineraryCard(
      onTap: () {
        _showItineraryDetails(context, experience);
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
        ),
        child: Padding(
            padding: EdgeInsets.all(8),
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
                                  borderRadius: BorderRadius.only(topLeft: Radius.circular(4)),
                                  color: _getStatusColor(experience.status),
                                  image: (experience.images != null && 
                                          experience.images!.isNotEmpty && 
                                          experience.images![0].signedUrl != null)
                                      ? DecorationImage(
                                          image: NetworkImage(experience.images![0].signedUrl!),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: (experience.images == null || 
                                        experience.images!.isEmpty || 
                                        experience.images![0].signedUrl == null)
                                    ? Icon(Icons.image_outlined, color: Colors.grey[600], size: 24)
                                    : null,
                              ),
                            ),
                            Expanded(
                              child: Container(
                                margin: EdgeInsets.only(left: 2.5, bottom: 2.5),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.only(topRight: Radius.circular(4)),
                                  color: _getStatusColor(experience.status),
                                  image: (experience.images != null && 
                                          experience.images!.length > 1 && 
                                          experience.images![1].signedUrl != null)
                                      ? DecorationImage(
                                          image: NetworkImage(experience.images![1].signedUrl!),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: (experience.images == null || 
                                        experience.images!.length <= 1 || 
                                        experience.images![1].signedUrl == null)
                                    ? Icon(Icons.image_outlined, color: Colors.grey[600], size: 24)
                                    : null,
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
                                  borderRadius: BorderRadius.only(bottomLeft: Radius.circular(4)),
                                  color: _getStatusColor(experience.status),
                                  image: (experience.images != null && 
                                          experience.images!.length > 2 && 
                                          experience.images![2].signedUrl != null)
                                      ? DecorationImage(
                                          image: NetworkImage(experience.images![2].signedUrl!),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: (experience.images == null || 
                                        experience.images!.length <= 2 || 
                                        experience.images![2].signedUrl == null)
                                    ? Icon(Icons.image_outlined, color: Colors.grey[600], size: 24)
                                    : null,
                              ),
                            ),
                            Expanded(
                              child: Container(
                                margin: EdgeInsets.only(left: 2.5, top: 2.5),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.only(bottomRight: Radius.circular(4)),
                                  color: _getStatusColor(experience.status),
                                  image: (experience.images != null && 
                                          experience.images!.length > 3 && 
                                          experience.images![3].signedUrl != null)
                                      ? DecorationImage(
                                          image: NetworkImage(experience.images![3].signedUrl!),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: (experience.images == null || 
                                        experience.images!.length <= 3 || 
                                        experience.images![3].signedUrl == null)
                                    ? Icon(Icons.image_outlined, color: Colors.grey[600], size: 24)
                                    : null,
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
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                          SizedBox(width: 8),
                          _buildCardBookmarkButton(experience),
                        ],
                      ),
                      SizedBox(height: 4),
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
                      SizedBox(height: 4),
                      if (experience.country != null) ...[
                        Text(
                          experience.country!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 8),
                      ],
                      if (experience.startDate != null && experience.endDate != null) ...[
                        Text(
                          '${_formatDate(experience.startDate!)} - ${_formatDate(experience.endDate!)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 8),
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
                        SizedBox(height: 8),
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
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'confirmed':
        return Color(0xff1e1e1e);
      case 'proposed':
        return Color(0xff1e1e1e);
      case 'cancelled':
        return Color(0xff1e1e1e);
      case 'draft':
      default:
        return Color(0xff1e1e1e);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildCardBookmarkButton(ExperienceModel experience) {
    final experienceId = experience.id?.toString();
    
    if (experienceId == null) {
      return SizedBox.shrink();
    }

    return Consumer<BookmarkProvider>(
      builder: (context, bookmarkProvider, child) {
        final isBookmarked = bookmarkProvider.isItemBookmarked('experience', experienceId);
        
        return _BookmarkButton(
          isBookmarked: isBookmarked,
          onTap: () {
            bookmarkProvider.toggleBookmark(
              itemType: 'experience',
              itemId: experienceId,
            );
          },
        );
      },
    );
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
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.dashboard, size: 20),
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
                Icon(Icons.tag, size: 18, ),
                SizedBox(width: 8),
                Text(
                  'Tags:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
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
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey[400]!),
                        ),
                        child: Text(
                          entry.value.toString(),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white,
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
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16,),
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
                  child: Icon(Icons.calendar_today, size: 16, ),
                ),
                SizedBox(width: 12),
                Text(
                  'Day $day',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Spacer(),
                Text(
                  '${dayItems.length} activities',
                  style: TextStyle(
                    fontSize: 12,
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

class _HoverableItineraryCard extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;

  const _HoverableItineraryCard({
    required this.onTap,
    required this.child,
  });

  @override
  State<_HoverableItineraryCard> createState() => _HoverableItineraryCardState();
}

class _HoverableItineraryCardState extends State<_HoverableItineraryCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: Duration(milliseconds: 150),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: _isHovered ? Color(0xFF211E1E) : Color(0xFF181616),
            border: Border.all(color: _isHovered ? Color(0xFF665B5B) : Color(0xff292525)),
            boxShadow: [], // Explicitly no box shadow
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

class _ItineraryFilterBar extends StatefulWidget {
  @override
  State<_ItineraryFilterBar> createState() => _ItineraryFilterBarState();
}

class _ItineraryFilterBarState extends State<_ItineraryFilterBar> {
  String _tagQuery = '';

  @override
  Widget build(BuildContext context) {
    return Consumer<AgencyProvider>(
      builder: (context, provider, _) {
        final statuses = provider.experienceStatuses;
        final countries = provider.experienceCountries;
        final destinations = provider.experienceDestinations;
        final tags = provider.experienceTagKeys;

        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[700]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: _DropdownFilter<String>(
                    label: 'Status',
                    value: provider.selectedStatus,
                    items: statuses,
                    onChanged: provider.setExperienceStatus,
                  ),
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: _DropdownFilter<String>(
                    label: 'Country',
                    value: provider.selectedCountryFilter,
                    items: countries,
                    onChanged: provider.setExperienceCountry,
                  ),
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: _DropdownFilter<String>(
                    label: 'Destination',
                    value: provider.selectedDestination,
                    items: destinations,
                    onChanged: provider.setExperienceDestination,
                  ),
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: (tags.isNotEmpty)
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 36,
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: TextField(
                              onChanged: (v) {
                                setState(() => _tagQuery = v);
                                provider.setExperienceTagQuery(v);
                              },
                              style: TextStyle(fontSize: 12),
                              decoration: InputDecoration(
                                isDense: true,
                                hintText: 'Search tags',
                                hintStyle: TextStyle(fontSize: 12),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(vertical: 12),
                                suffixIcon: _tagQuery.isEmpty
                                    ? null
                                    : IconButton(
                                        onPressed: () => setState(() => _tagQuery = ''),
                                        icon: Icon(Icons.close, size: 16, color: Colors.grey[400]),
                                      ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : SizedBox.shrink(),
              ),

              if (provider.hasActiveExperienceFilters) ...[
                SizedBox(width: 10),
                SizedBox(
                  height: 36,
                  child: TextButton(
                    onPressed: provider.clearExperienceFilters,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[300],
                      padding: EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: Text('Clear'),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _DropdownFilter<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<T> items;
  final ValueChanged<T?> onChanged;

  const _DropdownFilter({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Theme(
        data: Theme.of(context).copyWith(
          canvasColor: Colors.black,
          hoverColor: Colors.grey[800],
          focusColor: Colors.grey[800],
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            isDense: true,
            isExpanded: true,
            value: value,
            hint: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[400])),
            items: [
              DropdownMenuItem<T>(
                value: null,
                child: Text('All $label', style: TextStyle(fontSize: 12, color: Colors.white)),
              ),
              ...items.map((e) => DropdownMenuItem<T>(
                value: e,
                child: Text(e.toString(), style: TextStyle(fontSize: 12, color: Colors.white)),
              )),
            ],
            onChanged: onChanged,
            dropdownColor: Colors.black,
            style: TextStyle(color: Colors.white, fontSize: 12),
            iconSize: 18,
          ),
        ),
      ),
    );
  }
}

class _BookmarkButton extends StatefulWidget {
  final bool isBookmarked;
  final VoidCallback onTap;

  const _BookmarkButton({
    required this.isBookmarked,
    required this.onTap,
  });

  @override
  State<_BookmarkButton> createState() => _BookmarkButtonState();
}

class _BookmarkButtonState extends State<_BookmarkButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 40,
          height: 40,
          child: SvgPicture.asset(
            widget.isBookmarked
                ? 'assets/icons/bookmark-selected.svg'
                : _isHovered
                    ? 'assets/icons/bookmark-hover.svg'
                    : 'assets/icons/bookmark-default.svg',
            width: 40,
            height: 40,
          ),
        ),
      ),
    );
  }
}
