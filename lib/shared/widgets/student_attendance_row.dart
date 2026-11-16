import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/responsive_layout.dart';
import '../../core/utils/thai_date_format.dart';
import '../../domain/models/attendance_models.dart';
import '../../domain/models/attendance_status.dart';
import 'status_chip.dart';

/// Responsive student row:
/// - Desktop/tablet (>= 640 dp): aligned Swiss table row
/// - Android mobile (< 640 dp): dedicated compact 2-line editorial row
class StudentAttendanceRow extends StatelessWidget {
  const StudentAttendanceRow({
    super.key,
    required this.record,
    required this.entry,
    required this.onTap,
    this.sequenceNumber,
    this.showStudentId = true,
  });

  final StudentAttendanceRecord record;
  final DailyAttendanceEntry entry;
  final VoidCallback onTap;
  final int? sequenceNumber;
  final bool showStudentId;

  @override
  Widget build(BuildContext context) {
    final inset = ResponsiveContent.horizontalInset(context);
    final seqLabel = sequenceNumber?.toString().padLeft(2, '0');
    final isDesktop = MediaQuery.sizeOf(context).width >= 640;

    final String desktopTime = switch (entry.status) {
      AttendanceStatus.present || AttendanceStatus.late =>
        entry.firstScanAt != null ? ThaiFormat.time24(entry.firstScanAt!) : '—',
      AttendanceStatus.pending => 'รอสแกน',
      AttendanceStatus.absent => '—',
      AttendanceStatus.leave => 'ลา',
      AttendanceStatus.unknown => 'รอซิงก์',
    };

    final String mobileDetail = switch (entry.status) {
      AttendanceStatus.present || AttendanceStatus.late =>
        entry.firstScanAt != null
            ? 'สแกน ${ThaiFormat.time24(entry.firstScanAt!)}'
            : 'บันทึกแล้ว',
      AttendanceStatus.pending => 'ยังไม่พบการสแกน',
      AttendanceStatus.absent => 'ไม่พบการสแกน',
      AttendanceStatus.leave => 'มีบันทึกการลา',
      AttendanceStatus.unknown => 'รอข้อมูลซิงก์',
    };

    return InkWell(
      onTap: onTap,
      hoverColor: AppColors.surfaceSubtle.withValues(alpha: 0.7),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: AppSpacing.minTouchTarget + 10,
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: inset,
            vertical: isDesktop ? 10 : 12,
          ),
          child: isDesktop
              ? _DesktopTableRow(
                  seqLabel: seqLabel,
                  record: record,
                  entry: entry,
                  showStudentId: showStudentId,
                  timeLabel: desktopTime,
                )
              : _MobileCompactRow(
                  seqLabel: seqLabel,
                  record: record,
                  entry: entry,
                  showStudentId: showStudentId,
                  detailText: mobileDetail,
                ),
        ),
      ),
    );
  }
}

class _DesktopTableRow extends StatelessWidget {
  const _DesktopTableRow({
    required this.seqLabel,
    required this.record,
    required this.entry,
    required this.showStudentId,
    required this.timeLabel,
  });

  final String? seqLabel;
  final StudentAttendanceRecord record;
  final DailyAttendanceEntry entry;
  final bool showStudentId;
  final String timeLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        if (seqLabel != null) ...<Widget>[
          SizedBox(
            width: 28,
            child: Text(
              seqLabel!,
              style: AppTypography.microLabel.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.space2),
        ],
        Expanded(child: Text(record.fullName, style: AppTypography.bodyStrong)),
        if (showStudentId) ...<Widget>[
          const SizedBox(width: AppSpacing.space3),
          SizedBox(
            width: 84,
            child: Text(
              ThaiFormat.maskStudentId(record.studentId),
              style: AppTypography.supporting,
            ),
          ),
        ],
        const SizedBox(width: AppSpacing.space3),
        SizedBox(
          width: 72,
          child: Text(
            timeLabel,
            textAlign: TextAlign.right,
            style: AppTypography.supporting.copyWith(
              color: entry.firstScanAt != null
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
              fontWeight: entry.firstScanAt != null
                  ? FontWeight.w500
                  : FontWeight.w400,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.space4),
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 112),
          child: Align(
            alignment: Alignment.centerRight,
            child: AttendanceStatusChip(status: entry.status, compact: true),
          ),
        ),
        const SizedBox(width: AppSpacing.space2),
        const Icon(
          Icons.chevron_right,
          size: 18,
          color: AppColors.textDisabled,
        ),
      ],
    );
  }
}

class _MobileCompactRow extends StatelessWidget {
  const _MobileCompactRow({
    required this.seqLabel,
    required this.record,
    required this.entry,
    required this.showStudentId,
    required this.detailText,
  });

  final String? seqLabel;
  final StudentAttendanceRecord record;
  final DailyAttendanceEntry entry;
  final bool showStudentId;
  final String detailText;

  @override
  Widget build(BuildContext context) {
    final idMeta = <String>[
      if (seqLabel != null) 'ที่ $seqLabel',
      if (showStudentId) 'รหัส ${ThaiFormat.maskStudentId(record.studentId)}',
    ].join(' • ');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: Text(
                      record.fullName,
                      style: AppTypography.bodyStrong,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space2),
                  AttendanceStatusChip(status: entry.status, compact: true),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: <Widget>[
                  if (idMeta.isNotEmpty)
                    Expanded(
                      child: Text(
                        idMeta,
                        style: AppTypography.microLabel,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  Text(
                    detailText,
                    style: AppTypography.microLabel.copyWith(
                      color: entry.firstScanAt != null
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontWeight: entry.firstScanAt != null
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.space1),
        const Icon(
          Icons.chevron_right,
          size: 18,
          color: AppColors.textDisabled,
        ),
      ],
    );
  }
}
