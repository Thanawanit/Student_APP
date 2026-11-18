import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/models/attendance_status.dart';

/// Horizontal scrollable status filter chips.
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
    final chips = <(AttendanceStatus?, String, int?)>[
      (null, 'ทั้งหมด', totalCount),
      for (final s in availableStatuses) (s, s.label, countsByStatus?[s]),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: <Widget>[
          for (var i = 0; i < chips.length; i++) ...<Widget>[
            _StatusFilterChip(
              label: chips[i].$3 != null
                  ? '${chips[i].$2} ${chips[i].$3}'
                  : chips[i].$2,
              isSelected: selectedStatus == chips[i].$1,
              onTap: () {
                final target = chips[i].$1;
                if (target == null) {
                  onChanged(null);
                } else {
                  onChanged(selectedStatus == target ? null : target);
                }
              },
            ),
            if (i < chips.length - 1) const SizedBox(width: AppSpacing.space2),
          ],
        ],
      ),
    );
  }
}

class _StatusFilterChip extends StatelessWidget {
  const _StatusFilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(99),
        child: AnimatedContainer(
          duration: AppMotion.resolve(context, AppMotion.fast),
          curve: AppMotion.gentleCurve,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF14532D)
                : const Color(0xFFFFFFFF),
            borderRadius: BorderRadius.circular(99),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF14532D)
                  : const Color(0xFFE2E8E4),
            ),
          ),
          child: Text(
            label,
            style: AppTypography.microLabel.copyWith(
              fontSize: 12.5,
              color: isSelected ? Colors.white : const Color(0xFF475569),
              fontWeight: FontWeight.w600,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
        ),
      ),
    );
  }
}
