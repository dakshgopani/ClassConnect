import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Centralized responsive layout helper for ClassConnect.
/// Provides consistent breakpoints for Web and Desktop environments.
class ResponsiveBreakpoints {
  /// Desktop breakpoint: On Web, activates at width >= 800 (including laptops & split windows).
  /// On native desktop apps, activates at width >= 1024.
  static bool isDesktop(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return kIsWeb ? width >= 800 : width >= 1024;
  }

  /// Tablet breakpoint (between 600 and desktop threshold).
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final desktopThreshold = kIsWeb ? 800 : 1024;
    return width >= 600 && width < desktopThreshold;
  }

  /// Mobile breakpoint (width < 600).
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 600;
  }

  /// Helper to get current screen width.
  static double width(BuildContext context) => MediaQuery.of(context).size.width;

  /// Helper to get current screen height.
  static double height(BuildContext context) => MediaQuery.of(context).size.height;
}
