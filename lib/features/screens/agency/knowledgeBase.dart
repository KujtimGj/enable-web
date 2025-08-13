import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:enable_web/features/components/responsive_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/responsive_utils.dart';
import '../../providers/userProvider.dart';
import '../../providers/agencyProvider.dart';

class Knowledgebase extends StatefulWidget {
  const Knowledgebase({super.key});

  @override
  State<Knowledgebase> createState() => _KnowledgebaseState();
}

class _KnowledgebaseState extends State<Knowledgebase> {
  void showAccountOverlay(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.user;

    OverlayState overlayState = Overlay.of(context);
    OverlayEntry? overlayEntry;

    overlayEntry = OverlayEntry(
      builder:
          (context) => Positioned(
            bottom: 10,
            left: 10,
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 240,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          Icons.circle_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                        title: Text(
                          'Theme',
                          style: TextStyle(color: Colors.white),
                        ),
                        onTap: () {
                          overlayEntry?.remove();
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          Icons.swap_horiz,
                          color: Colors.white,
                          size: 20,
                        ),
                        title: Text(
                          'Settings',
                          style: TextStyle(color: Colors.white),
                        ),
                        onTap: () {
                          overlayEntry?.remove();
                        },
                      ),
                    ),
                    Divider(),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          height: 30,
                          width: 30,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xff574435),
                          ),
                          child: Center(
                            child: Text(
                              user?.name.isNotEmpty == true
                                  ? user!.name[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                              user?.name ?? 'User',
                              style: TextStyle(color: Colors.white),
                            ),
                            Text(
                              user?.email ?? 'user@example.com',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          context.go("/account");
                          overlayEntry?.remove();
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          Icons.logout,
                          color: Colors.white,
                          size: 20,
                        ),
                        title: Text(
                          'Logout',
                          style: TextStyle(color: Colors.white),
                        ),
                        onTap: () async {
                          final userProvider = Provider.of<UserProvider>(
                            context,
                            listen: false,
                          );
                          await userProvider.logout();
                          overlayEntry?.remove();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );

    overlayState.insert(overlayEntry);
  }

  String? id;
  getId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      id = prefs.getString('_id');
    });
  }

  final List<String> items = ['All', 'Users', 'Products'];

  String? selectedValue;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Enable',
          style: TextStyle(
            fontSize: ResponsiveUtils.responsiveFontSize(
              context,
              mobile: 20,
              tablet: 24,
              desktop: 26,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ResponsiveContainer(
        child: Consumer2<UserProvider, AgencyProvider>(
          builder: (context, userProvider, agencyProvider, child) {
            // Fetch document counts when widget is built
            WidgetsBinding.instance.addPostFrameCallback((_) {

              if (userProvider.isAuthenticated && userProvider.user != null) {
                final user = userProvider.user;
                if (user?.agencyId != null && user!.agencyId.isNotEmpty) {
                  try {
                    agencyProvider.fetchAllData(user.agencyId);
                  } catch (e) {
                    print('[KnowledgeBase] Error calling fetchAllData: $e');
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('You need to be associated with an agency to access knowledge base features.'),
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
              } else {
                print('[KnowledgeBase] User not authenticated or user is null');
              }
            });

            return Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Consumer<UserProvider>(
                  builder: (context, authProvider, child) {
                    final user = userProvider.user;
        
                    return Align(
                      alignment: Alignment.bottomCenter,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          GestureDetector(
                            onTap: () {
                              context.go('/vics');
                            },
                            child: SvgPicture.asset(
                              'assets/icons/vics.svg',
                            ),
                          ),
                          SizedBox(height: 10),
                          SvgPicture.asset('assets/icons/diamond.svg'),
                          SizedBox(height: 10),
                          GestureDetector(
                            onTap: () {
                              context.go("/knowledgebase");
                            },
                            child: SvgPicture.asset('assets/icons/Icon.svg',colorFilter: ColorFilter.mode(Colors.white, BlendMode.srcIn),),
                          ),
                          SizedBox(height: 10),
                          GestureDetector(
                            onTap: () {
                              showAccountOverlay(context);
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: CircleAvatar(
                                maxRadius: 14,
                                minRadius: 14,
                                backgroundColor: Color(0xff574131),
                                child: Text(
                                  user?.name.isNotEmpty == true
                                      ? user!.name[0].toUpperCase()
                                      : 'U',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                SizedBox(width: 25),
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      // Show warning if user doesn't have agency access
                      if (userProvider.user?.agencyId == null || userProvider.user!.agencyId.isEmpty)
                        Container(
                          width: double.infinity,
                          margin: EdgeInsets.only(bottom: 20),
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            border: Border.all(color: Colors.orange.withOpacity(0.3)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.orange,
                                size: 20,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'You need to be associated with an agency to access knowledge base features. Please contact your administrator.',
                                  style: TextStyle(
                                    color: Colors.orange[700],
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: 6, // Add itemCount to prevent infinite building
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 20,
                          crossAxisSpacing: 20,
                          childAspectRatio: 1.7,
                        ),
                    itemBuilder: (context, index) {
                      List<String> items=[
                        'Products',
                        'DMC',
                        'External Products',
                        'VIC',
                        'Service Providers',
                        'My folders'
                      ];
                      
                      // Get counts from agency provider
                      final counts = agencyProvider.documentCounts;
                      final isLoading = agencyProvider.isLoadingCounts;
                      
                      String getCountText(int index) {
                        // Check if user has agencyId
                        final user = userProvider.user;
                        if (user?.agencyId == null || user!.agencyId.isEmpty) {
                          return 'No agency access';
                        }
                        
                        if (isLoading) return 'Loading...';
                        
                        // Check if we have valid counts
                        if (counts.isEmpty || agencyProvider.errorMessage != null) {
                          return '0 records available';
                        }
                        
                        switch (index) {
                          case 0: // Products
                            return '${counts['productCount'] ?? 0} records available';
                          case 1: // DMC
                            return '${counts['dmcCount'] ?? 0} records available';
                          case 2: // External Products
                            return '${counts['externalProductCount'] ?? 0} records available';
                          case 3: // VIC
                            return '${counts['experienceCount'] ?? 0} records available';
                          case 4: // Service Providers
                            return '${counts['serviceProviderCount'] ?? 0} records available';
                          case 5: // My folders
                            return '0 folders';
                          default:
                            return '0 records available';
                        }
                      }
                      
                      return MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () {
                            // Check if user has agencyId
                            final user = userProvider.user;
                            if (user?.agencyId == null || user!.agencyId.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('You need to be associated with an agency to access this feature.'),
                                  duration: Duration(seconds: 3),
                                ),
                              );
                              return;
                            }
                            
                            // Navigate to appropriate screen based on index
                            switch (index) {
                              case 0: // Products
                                context.go('/products');
                                break;
                              case 1: // DMC
                                context.go('/dmcs');
                                break;
                              case 2: // External Products
                                context.go('/external-products');
                                break;
                              case 3: // VIC
                                context.go('/experiences');
                                break;
                              case 4: // Service Providers
                                context.go('/service-providers');
                                break;
                              case 5: // My folders
                                // For now, just show a snackbar
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('My folders feature coming soon!'),
                                  ),
                                );
                                break;
                            }
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                width: 1, 
                                color: userProvider.user?.agencyId == null || userProvider.user!.agencyId.isEmpty 
                                  ? Colors.grey[600]! 
                                  : Colors.grey[300]!
                              ),
                              color: userProvider.user?.agencyId == null || userProvider.user!.agencyId.isEmpty 
                                ? Colors.grey[800]!.withOpacity(0.3)
                                : Colors.transparent,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  index<5?Icons.data_object_outlined:Icons.folder_copy_outlined,
                                  color: userProvider.user?.agencyId == null || userProvider.user!.agencyId.isEmpty 
                                    ? Colors.grey[600]!
                                    : Colors.white,
                                  size: 30
                                ),
                                SizedBox(height: 20),
                                Text(
                                  items[index].toString(),
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: userProvider.user?.agencyId == null || userProvider.user!.agencyId.isEmpty 
                                      ? Colors.grey[600]!
                                      : Colors.white,
                                  ),
                                ),
                                Text(
                                  getCountText(index),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w300,
                                    color: userProvider.user?.agencyId == null || userProvider.user!.agencyId.isEmpty 
                                      ? Colors.grey[500]!
                                      : Colors.white,
                                  ),
                                ),
                                if (agencyProvider.errorMessage != null && index < 5)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Icon(
                                      Icons.error_outline,
                                      color: Colors.orange,
                                      size: 16,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  
}
