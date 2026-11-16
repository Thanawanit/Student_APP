import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/models/attendance_status.dart';

/// Cohesive segmented status filter control (Section 7.5).
class StatusFilterBar extends StatelessWidget {
  const StatusFilterBar({
    super.key,
    required this.selectedStatus,
    required this.onChanged,
    this.availableStatuses = const <AttendanceStatus>[
      AttendanceStatus.present,
      AttendanceStatus.late,
      AttendanceStatus.absent,
      AttendanceStatus.leave,
      AttendanceStatus.pending,
    ],
    this.countsByStatus,
    this.totalCount,
  });

  final AttendanceStatus? selectedStatus;
  final ValueChanged<AttendanceStatus?> onChanged;
  final List<AttendanceStatus> availableStatuses;
  final Map<AttendanceStatus, int>? countsByStatus;
  final int? totalCount;

  @override
  Widget build(BuildContext context) {
    final segments = <(AttendanceStatus?, String, int?)>[
      (null, 'ทั้งหมด', totalCount),
      for (final s in availableStatuses) (s, s.label, countsByStatus?[s]),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceSubtle,
          borderRadius: BorderRadius.circular(AppRadius.control),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        padding: const EdgeInsets.all(3),
        child: IntrinsicHeight(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              for (var i = 0; i < segments.length; i++) ...<Widget>[
                _SegmentItem(
                  label: segments[i].$2,
                  count: segments[i].$3,
                  isSelected: selectedStatus == segments[i].$1,
                  onTap: () {
                    final target = segments[i].$1;
                    if (target == null) {
                      onChanged(null);
                    } else {
                      onChanged(selectedStatus == target ? null : target);
                    }
                  },
                ),
                if (i < segments.length - 1 &&
                    selectedStatus != segments[i].$1 &&
                    selectedStatus != segments[i + 1].$1)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: VerticalDivider(
                      width: 1,
                      thickness: 1,
                      color: AppColors.borderSubtle,
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SegmentItem extends StatelessWidget {
  const _SegmentItem({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final int? count;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.control - 2),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppSpacing.minTouchTarget - 6,
            minWidth: AppSpacing.minTouchTarget,
          ),
          child: AnimatedContainer(
            duration: AppMotion.resolve(context, AppMotion.fast),
            curve: AppMotion.gentleCurve,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space3,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.surface : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.control - 2),
              border: isSelected
                  ? Border.all(color: AppColors.borderSubtle)
                  : null,
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    label,
                    style: AppTypography.supporting.copyWith(
                      fontSize: 12.5,
                      color: isSelected
                          ? AppColors.brandPrimary
                          : AppColors.textSecondary,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                  ),
                  if (count != null) ...<Widget>[
                    const SizedBox(width: 4),
                    Text(
                      '$count',
                      style: AppTypography.microLabel.copyWith(
                        color: isSelected
                            ? AppColors.brandPrimary
                            : AppColors.textDisabled,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
