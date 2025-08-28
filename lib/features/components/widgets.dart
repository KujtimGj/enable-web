import 'package:enable_web/core/dimensions.dart';
import 'package:enable_web/features/components/responsive_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/userProvider.dart';
import '../screens/knowledgebase/itinerary.dart';

Widget customForm(BuildContext context) {
  return ResponsiveContainer(
    maxWidth: getWidth(context) * 0.3,
    child: TextFormField(
      decoration: InputDecoration(
        hintText: 'Search products',
        suffixIcon: Icon(Icons.search),
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

Widget customButton(VoidCallback onPressed) {
  return MouseRegion(
    cursor: SystemMouseCursors.click,
    child: GestureDetector(
      onTap: onPressed,
      child: Container(
        margin: EdgeInsets.all(10),
        padding: EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          color: Color(0xff3a3132),
        ),
        child: Center(child: Text("New conversation",style: TextStyle(color: Colors.white),)),
      ),
    ),
  );
}

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

Widget bottomLeftBar() {
  return Consumer<UserProvider>(
    builder: (context, userProvider, child) {
      final user = userProvider.user;

      return Align(
        alignment: Alignment.bottomCenter,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            GestureDetector(
              onTap: () {
                context.go("/chats");
              },
              child: SvgPicture.asset('assets/icons/mssg.svg'),
            ),
            SizedBox(height: 10),
            GestureDetector(
              onTap: () {
                context.go('/products');
              },
              child: SvgPicture.asset('assets/icons/cube-02.svg'),
            ),
            SizedBox(height: 10),
            GestureDetector(
              onTap: () {
                context.go("/vics");
              },
              child: SvgPicture.asset("assets/icons/user-02.svg"),
            ),
            SizedBox(height: 10),
            GestureDetector(
              onTap: () {
                context.go("/itinerary");
              },
              child: SvgPicture.asset('assets/icons/asterisk-01.svg'),
            ),
            SizedBox(height: 10),
            SvgPicture.asset('assets/icons/image-03.svg'),
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
  );
}
