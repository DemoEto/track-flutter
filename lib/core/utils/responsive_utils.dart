// Responsive design utilities
import 'package:flutter/material.dart';

class ResponsiveUtils {
  // Breakpoints for responsive design
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;

  // Get screen type based on width
  static ScreenType getScreenType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width < mobileBreakpoint) {
      return ScreenType.mobile;
    } else if (width < tabletBreakpoint) {
      return ScreenType.tablet;
    } else {
      return ScreenType.desktop;
    }
  }

  // Get appropriate padding based on screen size
  static EdgeInsets getResponsivePadding(BuildContext context) {
    final screenType = getScreenType(context);

    switch (screenType) {
      case ScreenType.mobile:
        return const EdgeInsets.all(16.0);
      case ScreenType.tablet:
        return const EdgeInsets.all(24.0);
      case ScreenType.desktop:
        return const EdgeInsets.all(32.0);
    }
  }

  // Get appropriate card spacing based on screen size
  static double getCardSpacing(BuildContext context) {
    final screenType = getScreenType(context);

    switch (screenType) {
      case ScreenType.mobile:
        return 8.0;
      case ScreenType.tablet:
        return 12.0;
      case ScreenType.desktop:
        return 16.0;
    }
  }

  // Get appropriate font size based on screen size
  static double getResponsiveFontSize(BuildContext context, {double baseSize = 16.0}) {
    final screenType = getScreenType(context);

    switch (screenType) {
      case ScreenType.mobile:
        return baseSize;
      case ScreenType.tablet:
        return baseSize * 1.1;
      case ScreenType.desktop:
        return baseSize * 1.2;
    }
  }

  // Get responsive container width
  static double getResponsiveContainerWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    // Limit container width on larger screens
    if (width > 800) {
      return 800;
    }
    return width * 0.9; // Use 90% of screen width
  }

  // Check if screen is landscape
  static bool isLandscape(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    return orientation == Orientation.landscape;
  }

  // Get responsive grid count for lists
  static int getResponsiveGridCount(BuildContext context) {
    final screenType = getScreenType(context);

    switch (screenType) {
      case ScreenType.mobile:
        return 1;
      case ScreenType.tablet:
        return 2;
      case ScreenType.desktop:
        return 3;
    }
  }
}

enum ScreenType { mobile, tablet, desktop }

// Responsive widget builder
class ResponsiveWidget extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveWidget({Key? key, required this.mobile, this.tablet, this.desktop}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenType = ResponsiveUtils.getScreenType(context);

    switch (screenType) {
      case ScreenType.mobile:
        return mobile;
      case ScreenType.tablet:
        return tablet ?? mobile;
      case ScreenType.desktop:
        return desktop ?? tablet ?? mobile;
    }
  }
}

// Responsive padding widget
class ResponsivePadding extends StatelessWidget {
  final Widget child;

  const ResponsivePadding({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(padding: ResponsiveUtils.getResponsivePadding(context), child: child);
  }
}

// Responsive grid view
class ResponsiveGridView extends StatelessWidget {
  final List<Widget> children;
  final double childAspectRatio;

  const ResponsiveGridView({Key? key, required this.children, this.childAspectRatio = 1.0}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = ResponsiveUtils.getResponsiveGridCount(context);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: ResponsiveUtils.getCardSpacing(context),
        mainAxisSpacing: ResponsiveUtils.getCardSpacing(context),
        childAspectRatio: childAspectRatio,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );
  }
}
