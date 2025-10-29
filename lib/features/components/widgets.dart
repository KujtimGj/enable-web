import 'package:enable_web/core/dimensions.dart';
import 'package:enable_web/features/components/responsive_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/userProvider.dart';

Widget customForm(BuildContext context) {
  return ResponsiveContainer(
    maxWidth: getWidth(context) * 0.3,
    child: TextFormField(
      decoration: InputDecoration(
        hintText: 'Search items',
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
        margin: EdgeInsets.all(8),
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
        (context) => Stack(
          children: [
            // Full-screen transparent barrier
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  overlayEntry?.remove();
                },
                child: Container(
                  color: Colors.transparent,
                ),
              ),
            ),
            // Account overlay content
            Positioned(
              bottom: 10,
              left: 10,
              child: GestureDetector(
                onTap: () {
                  // Prevent tap from propagating to barrier
                },
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
                              context.go("/signin");
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
  );

  overlayState.insert(overlayEntry);
}

class _HoverableIcon extends StatefulWidget {
  final String defaultIcon;
  final String hoverIcon;
  final String tooltipMessage;
  final VoidCallback onTap;
  final double height;
  final double width;

  const _HoverableIcon({
    required this.defaultIcon,
    required this.hoverIcon,
    required this.tooltipMessage,
    required this.onTap,
    required this.height,
    required this.width,
  });

  @override
  State<_HoverableIcon> createState() => _HoverableIconState();
}

class _HoverableIconState extends State<_HoverableIcon> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Tooltip(
          message: widget.tooltipMessage,
          child: SvgPicture.asset(
            _isHovered ? widget.hoverIcon : widget.defaultIcon,
            height: widget.height,
            width: widget.width,
          ),
        ),
      ),
    );
  }
}

class _HoverableAccountIcon extends StatefulWidget {
  final dynamic user;

  const _HoverableAccountIcon({required this.user});

  @override
  State<_HoverableAccountIcon> createState() => _HoverableAccountIconState();
}

class _HoverableAccountIconState extends State<_HoverableAccountIcon> {
  bool _isHovered = false; 

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () {
          showAccountOverlay(context);
        },
        child: Tooltip(
          message: 'Account',
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: CircleAvatar(
              maxRadius: 14,
              minRadius: 14,
              backgroundColor: _isHovered 
                  ? Color(0xff6a5139) 
                  : Color(0xff574131),
              child: Text(
                widget.user?.name.isNotEmpty == true
                    ? widget.user!.name[0].toUpperCase()
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
      ),
    );
  }
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
            _HoverableIcon(
              defaultIcon: 'assets/icons/navicons/chat-default.svg',
              hoverIcon: 'assets/icons/navicons/chat-hover.svg',
              tooltipMessage: 'Chats',
              onTap: () => context.go("/chats"),
              height: 20,
              width: 20,
            ),
            SizedBox(height: 12),
            _HoverableIcon(
              defaultIcon: 'assets/icons/navicons/product-default.svg',
              hoverIcon: 'assets/icons/navicons/product-hovered.svg',
              tooltipMessage: 'Products',
              onTap: () => context.go('/products'),
              height: 20,
              width: 20,
            ),
            SizedBox(height: 12),
            _HoverableIcon(
              defaultIcon: 'assets/icons/navicons/vic-default.svg',
              hoverIcon: 'assets/icons/navicons/vic-hover.svg',
              tooltipMessage: 'VICs',
              onTap: () => context.go("/vics"),
              height: 20,
              width: 20,
            ),
            SizedBox(height: 12),
            _HoverableIcon(
              defaultIcon: 'assets/icons/navicons/itinerary-default.svg',
              hoverIcon: 'assets/icons/navicons/itinerary-hover.svg',
              tooltipMessage: 'Itinerary',
              onTap: () => context.go("/itinerary"),
              height: 20,
              width: 20,
            ),
            SizedBox(height: 12),
            _HoverableIcon(
              defaultIcon: 'assets/icons/navicons/service-providers-default.svg',
              hoverIcon: 'assets/icons/navicons/service-providers-hover.svg',
              tooltipMessage: 'Service Providers',
              onTap: () => context.go("/service-providers"),
              height: 16,
              width: 15,
            ),
            SizedBox(height: 12),
            _HoverableIcon(
              defaultIcon: 'assets/icons/navicons/bookmark-default.svg',
              hoverIcon: 'assets/icons/navicons/bookmark-hover.svg',
              tooltipMessage: 'Bookmarks',
              onTap: () => context.go("/bookmarks"),
              height: 16,
              width: 15,
            ),
            SizedBox(height: 12),
            _HoverableAccountIcon(user: user),
          ],
        ),
      );
    },
  );
}
 