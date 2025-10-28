import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/svg.dart';

import '../../../core/responsive_utils.dart';
import '../../../core/dimensions.dart';
import '../../components/responsive_scaffold.dart';
import '../../components/widgets.dart';
import '../../providers/vicProvider.dart';
import '../../providers/agencyProvider.dart';
import '../../providers/userProvider.dart';
import '../../providers/bookmark_provider.dart';
import '../../entities/vicModel.dart';

class VICs extends StatefulWidget {
  const VICs({super.key});

  @override
  State<VICs> createState() => _VICsState();
}

class _VICsState extends State<VICs> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  String? _getAgencyId(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final agencyProvider = Provider.of<AgencyProvider>(context, listen: false);
    
    // Try to get agency ID from user first (if user is logged in)
    if (userProvider.user?.agencyId != null && userProvider.user!.agencyId.isNotEmpty) {
      return userProvider.user!.agencyId;
    }
    // Fallback to agency provider
    else if (agencyProvider.agency?.id != null) {
      return agencyProvider.agency!.id;
    }
    
    return null;
  }

  @override
  void initState() {
    super.initState();
    // Fetch VICs when the page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vicProvider = Provider.of<VICProvider>(context, listen: false);
      
      final agencyId = _getAgencyId(context);
      
      
      if (agencyId != null) {
        vicProvider.fetchVICsByAgencyId(agencyId);
      } else {
        print('VICs Screen: No agency ID available from either user or agency');
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    
    if (query.trim().isEmpty) {
      // Clear search immediately
      final vicProvider = Provider.of<VICProvider>(context, listen: false);
      vicProvider.clearSearch();
      return;
    }

    // Perform local search immediately for partial matches
    final vicProvider = Provider.of<VICProvider>(context, listen: false);
    vicProvider.performLocalSearch(query);

    // Set up debounced server search
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      final agencyId = _getAgencyId(context);
      if (agencyId != null) {
        vicProvider.searchVICs(query, agencyId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      appBar: AppBar(
        toolbarHeight: 60,
        automaticallyImplyLeading: false,
        leading: GestureDetector(
          onTap: () => context.go('/home'),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
             SvgPicture.asset("assets/icons/home.svg")
            ],
          ),
        ),
        centerTitle: true,
        title: _customVICSearchForm(context),
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
                  Consumer<VICProvider>(
                    builder: (context, vicProvider, child) {
                      if (vicProvider.isLoading) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('Loading VICs...'),
                            ],
                          ),
                        );
                      }

                      if (vicProvider.errorMessage != null) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline, size: 64, color: Colors.red),
                              SizedBox(height: 16),
                              Text(
                                'Error: ${vicProvider.errorMessage}',
                                style: TextStyle(color: Colors.red),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () {
                                  final vicProvider = Provider.of<VICProvider>(context, listen: false);
                                  final agencyId = _getAgencyId(context);
                                  if (agencyId != null) {
                                    vicProvider.fetchVICsByAgencyId(agencyId);
                                  }
                                },
                                child: Text('Retry'),
                              ),
                            ],
                          ),
                        );
                      }

                      final vics = vicProvider.filteredVICs;
                      if(vics.isNotEmpty){
                        return Container(
                          padding: EdgeInsets.all(20),
                          child: RefreshIndicator(
                            onRefresh: () async {
                              final vicProvider = Provider.of<VICProvider>(context, listen: false);
                              final agencyId = _getAgencyId(context);
                              if (agencyId != null) {
                                await vicProvider.fetchVICsByAgencyId(agencyId);
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
                                childAspectRatio: 3.64,
                                mainAxisSpacing: 40,
                                crossAxisSpacing: 40,
                              ),
                              itemCount: vics.length,
                              itemBuilder: (BuildContext context, int index) {
                                final vic = vics[index];
                                return _buildVICCard(vic, index);
                              },
                            ),
                          ),
                        );
                      }
                      if (vics.isEmpty) {
                        final isSearching = vicProvider.searchQuery.isNotEmpty;
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isSearching ? Icons.search_off : Icons.person_outline, 
                                size: 64, 
                                color: Colors.grey
                              ),
                              SizedBox(height: 16),
                              Text( 
                                isSearching ? 'No VICs found' : 'No VICs found',
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
                                  : 'No VICs found for this agency',
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
                                    vicProvider.clearSearch();
                                  },
                                  child: Text('Clear Search'),
                                ),
                              ],
                            ],
                          ),
                        );
                      }


                      return RefreshIndicator(
                        onRefresh: () async {
                          final vicProvider = Provider.of<VICProvider>(context, listen: false);
                          final agencyId = _getAgencyId(context);
                          if (agencyId != null) {
                            await vicProvider.fetchVICsByAgencyId(agencyId);
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
                             childAspectRatio: 3.64,
                            mainAxisSpacing: 20,
                            crossAxisSpacing: 20,
                          ),
                          itemCount: vics.length,
                          itemBuilder: (BuildContext context, int index) {
                            final vic = vics[index];
                            return _buildVICCard(vic, index);
                          },
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

  Widget _customVICSearchForm(BuildContext context) {
    return ResponsiveContainer(
      maxWidth: getWidth(context) * 0.3,
      child: TextFormField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Search VICs...',
          suffixIcon: Consumer<VICProvider>(
            builder: (context, vicProvider, child) {
              if (vicProvider.isSearching) {
                return SizedBox(
                  width: 10,
                  height: 10,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[600]!),
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

  Widget _buildVICCard(VICModel vic, int index) {
    return _HoverableVICCard(
      onTap: () {
        _showVICDetails(context, vic);
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
        ),
            child: Padding(
            padding: EdgeInsets.all(6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        vic.fullName ?? 'VIC ${index + 1}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: 5),
                    _buildCardBookmarkButton(vic),
                  ],
                ),
                if (vic.nationality != null) ...[
                  SizedBox(height: 2),
                  Text(
                    vic.nationality!,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
                if (vic.email != null) ...[
                  SizedBox(height: 2),
                  Text(
                    vic.email!,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (vic.summary != null && vic.summary!.isNotEmpty) ...[
                  SizedBox(height: 2),
                  Text(
                    vic.summary!,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ] else ...[
                  SizedBox(height: 2),
                  Text(
                    'No description available',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
      ),
    );
  }

  void _showVICDetails(BuildContext context, VICModel vic) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(vic.fullName ?? 'VIC Details'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (vic.email != null) ...[
                  Text('Email: ${vic.email}'),
                  SizedBox(height: 8),
                ],
                if (vic.phone != null) ...[
                  Text('Phone: ${vic.phone}'),
                  SizedBox(height: 8),
                ],
                if (vic.nationality != null) ...[
                  Text('Nationality: ${vic.nationality}'),
                  SizedBox(height: 8),
                ],
                if (vic.summary != null && vic.summary!.isNotEmpty) ...[
                  Text('Summary: ${vic.summary}'),
                  SizedBox(height: 8),
                ],
                if (vic.preferences != null && vic.preferences!.isNotEmpty) ...[
                  Text('Preferences: ${vic.preferences}'),
                  SizedBox(height: 8),
                ],
                if (vic.createdAt != null) ...[
                  Text('Created: ${_formatDate(vic.createdAt!)}'),
                  SizedBox(height: 8),
                ],
              ],
            ), 
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildCardBookmarkButton(VICModel vic) {
    final vicId = vic.id?.toString();
    
    if (vicId == null) {
      return SizedBox.shrink();
    }

    return Consumer<BookmarkProvider>(
      builder: (context, bookmarkProvider, child) {
        final isBookmarked = bookmarkProvider.isItemBookmarked('vic', vicId);
           
        return _BookmarkButton(
          isBookmarked: isBookmarked,
          onTap: () {
            bookmarkProvider.toggleBookmark(
              itemType: 'vic',
              itemId: vicId,
            );
          },
        );
      },
    );
  }
}

class _HoverableVICCard extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;

  const _HoverableVICCard({
    required this.onTap,
    required this.child,
  });

  @override
  State<_HoverableVICCard> createState() => _HoverableVICCardState();
}

class _HoverableVICCardState extends State<_HoverableVICCard> {
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
