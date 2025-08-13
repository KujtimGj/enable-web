import 'package:flutter/material.dart';
import 'package:enable_web/core/responsive_utils.dart';

class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final int? mobileColumns;
  final int? tabletColumns;
  final int? desktopColumns;
  final double? spacing;
  final double? runSpacing;
  final EdgeInsets? padding;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.mobileColumns,
    this.tabletColumns,
    this.desktopColumns,
    this.spacing,
    this.runSpacing,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? ResponsiveUtils.responsivePadding(context),
      child: GridView.count(
        crossAxisCount: _getColumnCount(context),
        crossAxisSpacing: spacing ?? ResponsiveUtils.responsiveSpacing(context, mobile: 8, tablet: 16, desktop: 24),
        mainAxisSpacing: runSpacing ?? ResponsiveUtils.responsiveSpacing(context, mobile: 8, tablet: 16, desktop: 24),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: children,
      ),
    );
  }

  int _getColumnCount(BuildContext context) {
    if (ResponsiveUtils.isMobile(context)) {
      return mobileColumns ?? 1;
    } else if (ResponsiveUtils.isTablet(context)) {
      return tabletColumns ?? 2;
    } else {
      return desktopColumns ?? 3;
    }
  }
}

// Responsive list view with different layouts
class ResponsiveListView extends StatelessWidget {
  final List<Widget> children;
  final bool? shrinkWrap;
  final ScrollPhysics? physics;
  final EdgeInsets? padding;
  final double? spacing;

  const ResponsiveListView({
    super.key,
    required this.children,
    this.shrinkWrap,
    this.physics,
    this.padding,
    this.spacing,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: shrinkWrap ?? true,
      physics: physics ?? const NeverScrollableScrollPhysics(),
      padding: padding ?? ResponsiveUtils.responsivePadding(context),
      itemCount: children.length,
      separatorBuilder: (context, index) => SizedBox(
        height: spacing ?? ResponsiveUtils.responsiveSpacing(context, mobile: 8, tablet: 12, desktop: 16),
      ),
      itemBuilder: (context, index) => children[index],
    );
  }
}

// Responsive card with adaptive sizing
class ResponsiveCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? margin;
  final EdgeInsets? padding;
  final Color? color;
  final double? elevation;
  final ShapeBorder? shape;

  const ResponsiveCard({
    super.key,
    required this.child,
    this.margin,
    this.padding,
    this.color,
    this.elevation,
    this.shape,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? EdgeInsets.all(ResponsiveUtils.responsiveSpacing(context, mobile: 4, tablet: 8, desktop: 12)),
      padding: padding ?? EdgeInsets.all(ResponsiveUtils.responsiveSpacing(context, mobile: 12, tablet: 16, desktop: 20)),
      decoration: BoxDecoration(
        color: color ?? Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(ResponsiveUtils.responsiveSpacing(context, mobile: 8, tablet: 12, desktop: 16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: elevation ?? (ResponsiveUtils.hasMouse(context) ? 4 : 2),
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
} 