import 'package:enable_web/core/responsive_utils.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../components/widgets.dart';
import '../../components/responsive_scaffold.dart';
import '../../components/service_provider_detail_modal.dart';
import '../../providers/userProvider.dart';
import '../../providers/serviceProviderProvider.dart';
import '../../providers/bookmark_provider.dart';
import '../../entities/serviceProviderModel.dart';
import 'package:flutter_svg/svg.dart';

class ServiceProviders extends StatefulWidget {
  const ServiceProviders({super.key});

  @override
  State<ServiceProviders> createState() => _ServiceProvidersState();
}

class _ServiceProvidersState extends State<ServiceProviders> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final serviceProviderProvider = Provider.of<ServiceProviderProvider>(context, listen: false);
      
      if (userProvider.user?.agencyId != null && serviceProviderProvider.serviceProviders.isEmpty) {
        serviceProviderProvider.fetchServiceProvidersByAgencyId(userProvider.user!.agencyId);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final agencyId = userProvider.user?.agencyId ?? '';

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
        title: Container(
          constraints: BoxConstraints(maxWidth: 500),
          child: TextField(
            controller: _searchController,
            style: TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search service providers...',
              hintStyle: TextStyle(fontSize: 14),
              suffixIcon: Icon(Icons.search, size: 20),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[700]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[700]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.blue[600]!, width: 1.5),
              ),
            ),
            onChanged: (value) {
              final provider = Provider.of<ServiceProviderProvider>(context, listen: false);
              // Local filtering for responsiveness
              provider.localSearch(value);
              setState(() {});
            },
          ),
        ),
        actions: [
          customButton(() {
            context.go("/");
          }),
        ],
      ),
      body: ResponsiveContainer(
        child: Row(
          children: [
            bottomLeftBar(),
            Expanded(
              flex: 1,
              child: Container(
                padding: EdgeInsets.all(10),
                child: Consumer<ServiceProviderProvider>(
                  builder: (context, provider, child) {
                    // Loading state
                    if (provider.isLoading && provider.serviceProviders.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Loading service providers...'),
                          ],
                        ),
                      );
                    }

                    // Error state
                    if (provider.errorMessage != null) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.red,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Error loading service providers',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            SelectableText(
                              provider.errorMessage!,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => provider.refresh(agencyId),
                              child: Text('Retry'),
                            ),
                          ],
                        ),
                      );
                    }

                    // Empty state
                    if (provider.serviceProviders.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.support_agent,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No service providers found',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Service providers will appear here once they are added to your agency.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      );
                    }

                    // Service providers list (after filters)
                    final filteredServiceProviders = provider.visibleServiceProviders;
                    
                    return Column(
                      children: [
                        // Horizontal filter bar
                        _ServiceProvidersFilterBar(),
                        SizedBox(height: 10),

                        // Grid view
                        Expanded(
                          child: filteredServiceProviders.isEmpty
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
                                        'No service providers found',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Try adjusting your search query',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(color: Colors.grey[600]),
                                      ),
                                    ],
                                  ),
                                )
                              : GridView.builder(
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
                                  itemCount: filteredServiceProviders.length,
                                  itemBuilder: (BuildContext context, int index) {
                                    final serviceProvider = filteredServiceProviders[index];
                                    return _buildServiceProviderCard(serviceProvider);
                                  },
                                ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceProviderCard(ServiceProviderModel serviceProvider) {
    return _HoverableServiceProviderCard(
      onTap: () => _showServiceProviderModal(context, serviceProvider),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
        ),
        child: Padding(
          padding: EdgeInsets.all(8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 1, child: _buildServiceProviderIcon(serviceProvider)),
              SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start, 
                  children: [
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            serviceProvider.name ?? 'Unknown',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 8),
                        _buildCardBookmarkButton(serviceProvider),
                      ],
                    ),
                    SizedBox(height: 4),
                    if (serviceProvider.type != null && serviceProvider.type!.isNotEmpty)
                      Text(
                        serviceProvider.type!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    SizedBox(height: 4),
                    if (serviceProvider.email != null && serviceProvider.email!.isNotEmpty)
                      Row(
                        children: [
                          Icon(Icons.email, size: 14, color: Colors.grey[600]),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              serviceProvider.email!,
                              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    SizedBox(height: 4),
                    if (serviceProvider.country != null && serviceProvider.country!.isNotEmpty)
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              serviceProvider.country!,
                              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceProviderIcon(ServiceProviderModel serviceProvider) {
    return Container(
      height: double.infinity,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: Color(0xff1e1e1e),
      ),
      child: Center(
        child: Icon(
          Icons.support_agent,
          color: Colors.grey[600],
          size: 48,
        ),
      ),
    );
  }

  void _showServiceProviderModal(BuildContext context, ServiceProviderModel serviceProvider) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return ServiceProviderDetailModal(
          serviceProvider: serviceProvider.toJson(),
        );
      },
    );
  }

  Widget _buildCardBookmarkButton(ServiceProviderModel serviceProvider) {
    final serviceProviderId = serviceProvider.id ?? '';

    return Consumer<BookmarkProvider>(
      builder: (context, bookmarkProvider, child) {
        final isBookmarked = bookmarkProvider.isItemBookmarked('serviceProvider', serviceProviderId);
        
        return _BookmarkButton(
          isBookmarked: isBookmarked,
          onTap: () {
            bookmarkProvider.toggleBookmark(
              itemType: 'serviceProvider',
              itemId: serviceProviderId,
            );
          },
        );
      },
    );
  }
}

class _HoverableServiceProviderCard extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;

  const _HoverableServiceProviderCard({
    required this.onTap,
    required this.child,
  });

  @override
  State<_HoverableServiceProviderCard> createState() => _HoverableServiceProviderCardState();
}

class _HoverableServiceProviderCardState extends State<_HoverableServiceProviderCard> {
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
            boxShadow: [],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

class _ServiceProvidersFilterBar extends StatefulWidget {
  @override
  State<_ServiceProvidersFilterBar> createState() => _ServiceProvidersFilterBarState();
}

class _ServiceProvidersFilterBarState extends State<_ServiceProvidersFilterBar> {
  @override
  Widget build(BuildContext context) {
    return Consumer<ServiceProviderProvider>(
      builder: (context, provider, _) {
        final countries = provider.countries;

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
                    label: 'Country',
                    value: provider.selectedCountry,
                    items: countries,
                    onChanged: provider.setCountry,
                  ),
                ),
              ),
              if (provider.hasActiveFilters) ...[
                SizedBox(width: 10),
                SizedBox(
                  height: 36,
                  child: TextButton(
                    onPressed: provider.clearFilters,
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
