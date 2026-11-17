import 'package:flutter/material.dart';

/// Light Editorial × Data Intelligence color system (Apple Health / Linear inspired).
abstract final class AppColors {
  static const Color background = Color(0xFFF9F9F7);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSubtle = Color(0xFFF1F2EF);

  static const Color textPrimary = Color(0xFF161918);
  static const Color textSecondary = Color(0xFF626A66);
  static const Color textDisabled = Color(0xFF9EA5A1);

  static const Color borderSubtle = Color(0xFFE5E7E3);
  static const Color borderStrong = Color(0xFFD0D4CE);

  static const Color brandPrimary = Color(0xFF1B6B4A);
  static const Color brandPrimaryPressed = Color(0xFF134F36);
  static const Color brandPrimarySoft = Color(0xFFE9F4EE);
  static const Color focusRing = Color(0xFF288961);

  // Attendance semantic colors (always paired with Thai text & icon).
  static const Color presentForeground = Color(0xFF1B6B4A);
  static const Color presentBackground = Color(0xFFE9F4EE);

  static const Color lateForeground = Color(0xFFA35B0E);
  static const Color lateBackground = Color(0xFFFEF3E2);

  static const Color absentForeground = Color(0xFFB43434);
  static const Color absentBackground = Color(0xFFFDECEC);

  static const Color leaveForeground = Color(0xFF435399);
  static const Color leaveBackground = Color(0xFFECEFFA);

  static const Color pendingForeground = Color(0xFF5A6360);
  static const Color pendingBackground = Color(0xFFEEEEEC);

  static const Color unknownForeground = Color(0xFF4C596B);
  static const Color unknownBackground = Color(0xFFEBF0F5);
}
