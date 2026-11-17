import 'package:flutter/material.dart';

/// Spacing, sharp architectural radii, border, and motion tokens.
abstract final class AppSpacing {
  static const double space1 = 4;
  static const double space2 = 8;
  static const double space3 = 12;
  static const double space4 = 16;
  static const double space5 = 20;
  static const double space6 = 24;
  static const double space8 = 32;

  static const double minTouchTarget = 48;
  static const double maxContentWidth = 960;
}

abstract final class AppRadius {
  static const double badge = 6;
  static const double control = 8;
  static const double panel = 12;
  static const double sheet = 16;
}

abstract final class AppBorders {
  static const double width = 1;
}

abstract final class AppMotion {
  static const Duration fast = Duration(milliseconds: 140);
  static const Duration standard = Duration(milliseconds: 200);
  static const Curve gentleCurve = Curves.easeOutCubic;

  static Duration resolve(BuildContext context, Duration duration) {
    return MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration;
  }
}
