import 'package:flutter/material.dart';

/// Color tokens aligned with ATTENDANCE_APP_DESIGN_SYSTEM.md (Section 3.1).
abstract final class AppColors {
  static const Color background = Color(0xFFF7F7F4);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSubtle = Color(0xFFF0F1EE);

  static const Color textPrimary = Color(0xFF202624);
  static const Color textSecondary = Color(0xFF69716D);
  static const Color textDisabled = Color(0xFF9AA19D);

  static const Color borderSubtle = Color(0xFFE3E7E2);

  static const Color brandPrimary = Color(0xFF31566D);
  static const Color brandPrimaryPressed = Color(0xFF254456);
  static const Color brandPrimarySoft = Color(0xFFEAF0F4);
  static const Color focusRing = Color(0xFF5B83A0);

  // Subtle top-to-bottom botanical green-to-white gradient tokens for dashboard headers.
  static const Color gradientGreenTop = Color(0xFFD9EDE1);
  static const Color gradientGreenMid = Color(0xFFEDF6F0);

  static const LinearGradient topGreenToWhiteGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[gradientGreenTop, gradientGreenMid, background],
    stops: <double>[0.0, 0.55, 1.0],
  );

  // Attendance semantic colors (always paired with Thai text & icon).
  static const Color presentForeground = Color(0xFF287451);
  static const Color presentBackground = Color(0xFFEAF4EE);

  static const Color lateForeground = Color(0xFF98621F);
  static const Color lateBackground = Color(0xFFFFF3E2);

  static const Color absentForeground = Color(0xFFA94444);
  static const Color absentBackground = Color(0xFFFBECEC);

  static const Color leaveForeground = Color(0xFF59659A);
  static const Color leaveBackground = Color(0xFFEEF0FA);

  static const Color pendingForeground = Color(0xFF68716F);
  static const Color pendingBackground = Color(0xFFF0F2F1);

  static const Color unknownForeground = Color(0xFF606A78);
  static const Color unknownBackground = Color(0xFFEEF1F5);
}
