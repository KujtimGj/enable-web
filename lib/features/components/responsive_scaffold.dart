import 'package:enable_web/core/dimensions.dart';
import 'package:flutter/material.dart';
import 'package:enable_web/core/responsive_utils.dart';

class ResponsiveScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget? drawer;
  final Widget? endDrawer;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final Widget body;
  final Color? backgroundColor;
  final bool? resizeToAvoidBottomInset;

  const ResponsiveScaffold({
    super.key,
    this.appBar,
    this.drawer,
    this.endDrawer,
    this.floatingActionButton,
    this.bottomNavigationBar,
    required this.body,
    this.backgroundColor,
    this.resizeToAvoidBottomInset,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveWidget(
      mobile: _buildMobileScaffold(context),
      tablet: _buildTabletScaffold(context),
      desktop: _buildDesktopScaffold(context),
    );
  }

  Widget _buildMobileScaffold(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      drawer: drawer,
      endDrawer: endDrawer,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      body: body,
    );
  }

  Widget _buildTabletScaffold(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      drawer: drawer,
      endDrawer: endDrawer,
      floatingActionButton: floatingActionButton,
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      body: Row(
        children: [
          if (drawer != null) 
            SizedBox(
              width: 280,
              child: drawer!,
            ),
          Expanded(child: body),
        ],
      ),
    );
  }

  Widget _buildDesktopScaffold(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      drawer: drawer,
      endDrawer: endDrawer,
      floatingActionButton: floatingActionButton,
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      body: Row(
        children: [
          if (drawer != null) 
            SizedBox(
              width: 320,
              child: drawer!,
            ),
          Expanded(child: body),
        ],
      ),
    );
  }
}

// Responsive container with max width
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final EdgeInsets? padding;
  final Alignment? alignment;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
    this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? _getMaxWidth(context),
        ),
        child: Container(
          padding: padding ?? ResponsiveUtils.responsivePadding(context),
          alignment: alignment,
          child: child,
        ),
      ),
    );
  }

  double _getMaxWidth(BuildContext context) {
    if (ResponsiveUtils.isMobile(context)) {
      return double.infinity;
    } else if (ResponsiveUtils.isTablet(context)) {
      return 800;
    } else {
      return getWidth(context);
    }
  }
} 