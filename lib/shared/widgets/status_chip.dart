import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/models/attendance_status.dart';

/// Compact semantic status chip pairing icon, color, and Thai text (Section 7.3).
class AttendanceStatusChip extends StatelessWidget {
  const AttendanceStatusChip({
    super.key,
    required this.status,
    this.compact = false,
  });

  final AttendanceStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = compact ? AppSpacing.space2 : AppSpacing.space3;
    final verticalPadding = compact ? 4.0 : 6.0;

    return Semantics(
      label: 'สถานะ ${status.label}',
      child: AnimatedContainer(
        duration: AppMotion.resolve(context, AppMotion.fast),
        curve: AppMotion.gentleCurve,
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        decoration: BoxDecoration(
          color: status.backgroundColor,
          borderRadius: BorderRadius.circular(AppRadius.control),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              status.icon,
              size: compact ? 14 : 16,
              color: status.foregroundColor,
            ),
            const SizedBox(width: AppSpacing.space1),
            Text(
              status.label,
              style:
                  (compact
                          ? AppTypography.microLabel
                          : AppTypography.supporting)
                      .copyWith(
                        color: status.foregroundColor,
                        fontWeight: FontWeight.w600,
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
