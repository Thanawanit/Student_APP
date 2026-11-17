import 'package:flutter/material.dart';

/// Refined Swiss Editorial × Modern Analytics color system.
abstract final class AppColors {
  static const Color background = Color(0xFFF5F6F4);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSubtle = Color(0xFFECEEEB);

  // Architectural dark-ink surface for hero command/pass sections and primary CTAs.
  static const Color inkSurface = Color(0xFF131B18);
  static const Color inkSurfaceDivider = Color(0xFF283530);
  static const Color inkText = Color(0xFFF7F8F7);
  static const Color inkTextMuted = Color(0xFFA3B2AB);
  static const Color inkEmeraldAccent = Color(0xFF34D399);

  static const Color textPrimary = Color(0xFF141917);
  static const Color textSecondary = Color(0xFF5B6460);
  static const Color textDisabled = Color(0xFF9AA29E);

  static const Color borderSubtle = Color(0xFFE1E4DF);
  static const Color borderStrong = Color(0xFFC9CEC7);

  static const Color brandPrimary = Color(0xFF165E42);
  static const Color brandPrimaryPressed = Color(0xFF0F442F);
  static const Color brandPrimarySoft = Color(0xFFE6F2EC);
  static const Color focusRing = Color(0xFF248A62);

  // Attendance semantic colors (always paired with Thai text & icon).
  static const Color presentForeground = Color(0xFF156D47);
  static const Color presentBackground = Color(0xFFE6F4ED);

  static const Color lateForeground = Color(0xFFA35B0E);
  static const Color lateBackground = Color(0xFFFEF2E0);

  static const Color absentForeground = Color(0xFFB43434);
  static const Color absentBackground = Color(0xFFFDECEC);

  static const Color leaveForeground = Color(0xFF435399);
  static const Color leaveBackground = Color(0xFFECEFFA);

  static const Color pendingForeground = Color(0xFF56605D);
  static const Color pendingBackground = Color(0xFFECEDEC);

  static const Color unknownForeground = Color(0xFF4C596B);
  static const Color unknownBackground = Color(0xFFEBF0F5);
}
