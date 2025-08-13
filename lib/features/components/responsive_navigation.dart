import 'package:flutter/material.dart';
import 'package:enable_web/core/responsive_utils.dart';

class ResponsiveNavigation extends StatelessWidget {
  final List<NavigationItem> items;
  final int currentIndex;
  final Function(int) onItemSelected;
  final Widget? leading;
  final Widget? title;

  const ResponsiveNavigation({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onItemSelected,
    this.leading,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveWidget(
      mobile: _buildBottomNavigation(context),
      tablet: _buildDrawer(context),
      desktop: _buildSideNavigation(context),
    );
  }

  Widget _buildBottomNavigation(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onItemSelected,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Theme.of(context).primaryColor,
      unselectedItemColor: Colors.grey,
      items: items.map((item) => BottomNavigationBarItem(
        icon: Icon(item.icon),
        label: item.label,
      )).toList(),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (leading != null) leading!,
                if (title != null) title!,
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return ListTile(
                  leading: Icon(
                    item.icon,
                    color: currentIndex == index 
                        ? Theme.of(context).primaryColor 
                        : null,
                  ),
                  title: Text(
                    item.label,
                    style: TextStyle(
                      color: currentIndex == index 
                          ? Theme.of(context).primaryColor 
                          : null,
                      fontWeight: currentIndex == index 
                          ? FontWeight.bold 
                          : FontWeight.normal,
                    ),
                  ),
                  selected: currentIndex == index,
                  onTap: () => onItemSelected(index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSideNavigation(BuildContext context) {
    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          right: BorderSide(
            color: Colors.grey.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (leading != null) leading!,
                if (title != null) 
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: title!,
                  ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return ListTile(
                  leading: Icon(
                    item.icon,
                    color: currentIndex == index 
                        ? Theme.of(context).primaryColor 
                        : null,
                  ),
                  title: Text(
                    item.label,
                    style: TextStyle(
                      color: currentIndex == index 
                          ? Theme.of(context).primaryColor 
                          : null,
                      fontWeight: currentIndex == index 
                          ? FontWeight.bold 
                          : FontWeight.normal,
                    ),
                  ),
                  selected: currentIndex == index,
                  onTap: () => onItemSelected(index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class NavigationItem {
  final IconData icon;
  final String label;
  final String route;

  const NavigationItem({
    required this.icon,
    required this.label,
    required this.route,
  });
}

// Responsive app bar
class ResponsiveAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final Color? backgroundColor;
  final double? elevation;

  const ResponsiveAppBar({
    super.key,
    this.title,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.backgroundColor,
    this.elevation,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: title,
      actions: actions,
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      backgroundColor: backgroundColor,
      elevation: elevation,
      centerTitle: ResponsiveUtils.isMobile(context),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
} 