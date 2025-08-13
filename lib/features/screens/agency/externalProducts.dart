import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/responsive_utils.dart';
import '../../providers/userProvider.dart';

class Externalproducts extends StatefulWidget {
  const Externalproducts({super.key});

  @override
  State<Externalproducts> createState() => _ExternalproductsState();
}

class _ExternalproductsState extends State<Externalproducts> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
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
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
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
                child: GridView.builder(
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
                    return MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(width: 1, color: Colors.grey[300]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(index<5?Icons.data_object_outlined:Icons.folder_copy_outlined,color: Colors.white,size: 30),
                            SizedBox(height: 20),
                            Text(items[index].toString(),style: TextStyle(fontSize: 20),),
                            index<5?Text('40 records available',style: TextStyle(fontSize: 16,fontWeight: FontWeight.w300),):Text('5 folders',style: TextStyle(fontSize: 16,fontWeight: FontWeight.w300))
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),

    );
  }
}
