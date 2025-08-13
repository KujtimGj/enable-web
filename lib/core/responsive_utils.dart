import 'package:flutter/material.dart';

class ResponsiveUtils {
  // Breakpoints for different screen sizes
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;
  static const double largeDesktopBreakpoint = 1600;

  // Screen size detection
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileBreakpoint;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= mobileBreakpoint &&
      MediaQuery.of(context).size.width < tabletBreakpoint;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= tabletBreakpoint &&
      MediaQuery.of(context).size.width < desktopBreakpoint;

  static bool isLargeDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= desktopBreakpoint;

  // Responsive padding
  static EdgeInsets responsivePadding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.all(16.0);
    } else if (isTablet(context)) {
      return const EdgeInsets.all(24.0);
    } else {
      return const EdgeInsets.all(5);
    }
  }

  // Responsive font sizes
  static double responsiveFontSize(BuildContext context, {
    double mobile = 14.0,
    double tablet = 16.0,
    double desktop = 18.0,
  }) {
    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet;
    return desktop;
  }

  // Responsive spacing
  static double responsiveSpacing(BuildContext context, {
    double mobile = 8.0,
    double tablet = 16.0,
    double desktop = 24.0,
  }) {
    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet;
    return desktop;
  }

  // Get screen width
  static double screenWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;

  // Get screen height
  static double screenHeight(BuildContext context) =>
      MediaQuery.of(context).size.height;

  // Check if device has mouse (desktop) - simplified for web
  static bool hasMouse(BuildContext context) =>
      !ResponsiveUtils.isMobile(context);
}

// Responsive widget wrapper
class ResponsiveWidget extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;
  final Widget? largeDesktop;

  const ResponsiveWidget({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
    this.largeDesktop,
  });

  @override
  Widget build(BuildContext context) {
    if (ResponsiveUtils.isLargeDesktop(context) && largeDesktop != null) {
      return largeDesktop!;
    } else if (ResponsiveUtils.isDesktop(context) && desktop != null) {
      return desktop!;
    } else if (ResponsiveUtils.isTablet(context) && tablet != null) {
      return tablet!;
    } else {
      return mobile;
    }
  }
}

// Responsive layout builder
class ResponsiveLayoutBuilder extends StatelessWidget {
  final Widget Function(BuildContext, BoxConstraints) builder;

  const ResponsiveLayoutBuilder({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => builder(context, constraints),
    );
  }
} 