import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/responsive_layout.dart';
import '../../core/utils/thai_date_format.dart';
import '../../domain/models/attendance_models.dart';
import '../../domain/models/attendance_status.dart';
import '../../shared/widgets/school_brand_mark.dart';
import '../../shared/widgets/state_views.dart';
import '../../state/app_controller.dart';

/// Parent Dashboard Overview — Personal Daily Check-in & School-Week Timeline.
class ParentOverviewTab extends StatelessWidget {
  const ParentOverviewTab({
    super.key,
    required this.onOpenFullHistory,
    required this.onOpenNotifications,
  });

  final VoidCallback onOpenFullHistory;
  final VoidCallback onOpenNotifications;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final record = controller.parentRecord;
    final session = controller.parentSession;
    final unread = controller.unreadNotificationCount;
    final latestNotification = controller.parentNotifications.isNotEmpty
        ? controller.parentNotifications.first
        : null;
    final inset = ResponsiveContent.horizontalInset(context);

    return Scaffold(
      body: Column(
        children: <Widget>[
          _StudentIdentityTopBar(
            inset: inset,
            studentName: record?.fullName ?? session?.studentName ?? 'นักเรียน',
            subtitle: record != null
                ? 'ม.${record.classroom.grade} • ${record.classroom.roomLabel} • รหัส ${ThaiFormat.maskStudentId(record.studentId)}'
                : session != null
                ? 'ม.${session.classroom.grade} • ${session.classroom.roomLabel} • รหัส ${ThaiFormat.maskStudentId(session.studentId)}'
                : 'โรงเรียนขุนยวมวิทยา',
            unreadCount: unread,
            onOpenNotifications: onOpenNotifications,
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.brandPrimary,
              onRefresh: controller.loadParentData,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(
                  top: AppSpacing.space4,
                  bottom: AppSpacing.space6,
                ),
                children: <Widget>[
                  ResponsiveContent(
                    padding: EdgeInsets.zero,
                    child: controller.isParentLoading && record == null
                        ? const LoadingSkeletonList(itemCount: 4)
                        : controller.parentError != null && record == null
                        ? ErrorStateView(
                            message: controller.parentError!,
                            onRetry: controller.loadParentData,
                          )
                        : record == null
                        ? const EmptyStateView(title: 'ยังไม่มีข้อมูลนักเรียน')
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              final isWideDesktop = constraints.maxWidth >= 820;
                              final todayBlock = _TodayCheckInSurface(
                                entry: record.todayEntry,
                              );
                              final weekBlock = _WeeklyTimelineSection(
                                record: record,
                                todayDate: controller.todayDate,
                                onOpenFullHistory: onOpenFullHistory,
                              );
                              final noticeBlock = latestNotification != null
                                  ? _LatestNoticeRow(
                                      notification: latestNotification,
                                      unreadCount: unread,
                                      onTap: onOpenNotifications,
                                    )
                                  : null;

                              if (isWideDesktop) {
                                return Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: inset,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Expanded(
                                        flex: 5,
                                        child: Column(
                                          children: <Widget>[
                                            todayBlock,
                                            if (noticeBlock !=
                                                null) ...<Widget>[
                                              const SizedBox(
                                                height: AppSpacing.space4,
                                              ),
                                              noticeBlock,
                                            ],
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.space5),
                                      Expanded(flex: 7, child: weekBlock),
                                    ],
                                  ),
                                );
                              }

                              return Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: inset,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    todayBlock,
                                    const SizedBox(height: AppSpacing.space4),
                                    weekBlock,
                                    if (noticeBlock != null) ...<Widget>[
                                      const SizedBox(height: AppSpacing.space4),
                                      noticeBlock,
                                    ],
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentIdentityTopBar extends StatelessWidget {
  const _StudentIdentityTopBar({
    required this.inset,
    required this.studentName,
    required this.subtitle,
    required this.unreadCount,
    required this.onOpenNotifications,
  });

  final double inset;
  final String studentName;
  final String subtitle;
  final int unreadCount;
  final VoidCallback onOpenNotifications;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
        ),
        child: SafeArea(
          bottom: false,
          child: ResponsiveContent(
            padding: EdgeInsets.fromLTRB(
              inset,
              AppSpacing.space3,
              AppSpacing.space2,
              AppSpacing.space3,
            ),
            child: Row(
              children: <Widget>[
                const SchoolLogoMark(size: 32),
                const SizedBox(width: AppSpacing.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        studentName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.sectionTitle.copyWith(
                          fontSize: 19,
                        ),
                      ),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.microLabel.copyWith(
                          color: AppColors.brandPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'การแจ้งเตือน',
                  onPressed: onOpenNotifications,
                  icon: Badge.count(
                    count: unreadCount,
                    isLabelVisible: unreadCount > 0,
                    backgroundColor: AppColors.brandPrimary,
                    child: const Icon(Icons.notifications_outlined),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TodayCheckInSurface extends StatelessWidget {
  const _TodayCheckInSurface({required this.entry});

  final DailyAttendanceEntry entry;

  @override
  Widget build(BuildContext context) {
    final String statusHeadline = switch (entry.status) {
      AttendanceStatus.present => 'มาเรียน • ตรงเวลา',
      AttendanceStatus.late => 'มาสาย',
      AttendanceStatus.absent => 'ขาดเรียนวันนี้',
      AttendanceStatus.leave => 'บันทึกการลาแล้ว',
      AttendanceStatus.pending => 'รอการสแกนเข้าเรียน',
      AttendanceStatus.unknown => 'อยู่ระหว่างตรวจสอบข้อมูล',
    };

    final String arrivalDisplay = switch (entry.status) {
      AttendanceStatus.present || AttendanceStatus.late =>
        entry.firstScanAt != null ? ThaiFormat.time24(entry.firstScanAt!) : '—',
      AttendanceStatus.pending => 'รอสแกน',
      AttendanceStatus.leave => 'วันลา',
      AttendanceStatus.absent => 'ไม่พบสแกน',
      AttendanceStatus.unknown => 'รอซิงก์',
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: entry.status.backgroundColor.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(AppRadius.panel),
        border: Border.all(
          color: entry.status.foregroundColor.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'วันนี้ • ${ThaiFormat.fullDate(entry.date)}',
            style: AppTypography.microLabel.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.space3,
            runSpacing: AppSpacing.space1,
            children: <Widget>[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    entry.status.icon,
                    size: 20,
                    color: entry.status.foregroundColor,
                  ),
                  const SizedBox(width: AppSpacing.space2),
                  Flexible(
                    child: Text(
                      statusHeadline,
                      style: AppTypography.sectionTitle.copyWith(
                        color: entry.status.foregroundColor,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                arrivalDisplay,
                style: AppTypography.pageTitle.copyWith(
                  fontSize: entry.firstScanAt != null ? 28 : 20,
                  color: AppColors.textPrimary,
                  fontFeatures: const <FontFeature>[
                    FontFeature.tabularFigures(),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space2),
          Text(
            entry.status.detailDescription,
            style: AppTypography.supporting.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyTimelineSection extends StatelessWidget {
  const _WeeklyTimelineSection({
    required this.record,
    required this.todayDate,
    required this.onOpenFullHistory,
  });

  final StudentAttendanceRecord record;
  final DateTime todayDate;
  final VoidCallback onOpenFullHistory;

  DailyAttendanceEntry? _entryForDay(DateTime date) {
    if (record.todayEntry.date.year == date.year &&
        record.todayEntry.date.month == date.month &&
        record.todayEntry.date.day == date.day) {
      return record.todayEntry;
    }
    for (final e in record.history) {
      if (e.date.year == date.year &&
          e.date.month == date.month &&
          e.date.day == date.day) {
        return e;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final summary = record.weeklySummary;
    final monday = todayDate.subtract(Duration(days: todayDate.weekday - 1));
    const dayNames = <String>['จ.', 'อ.', 'พ.', 'พฤ.', 'ศ.'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.panel),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpacing.space2,
              children: <Widget>[
                Text('ปฏิทินสัปดาห์นี้', style: AppTypography.sectionTitle),
                Text(summary.weekLabel, style: AppTypography.microLabel),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.space3),

          // 5-day compact Mon-Fri school timeline
          Row(
            children: <Widget>[
              for (var d = 0; d < 5; d++) ...<Widget>[
                Expanded(
                  child: _DayTimelineCell(
                    dayName: dayNames[d],
                    date: monday.add(Duration(days: d)),
                    isToday:
                        monday.add(Duration(days: d)).year == todayDate.year &&
                        monday.add(Duration(days: d)).month ==
                            todayDate.month &&
                        monday.add(Duration(days: d)).day == todayDate.day,
                    entry: _entryForDay(monday.add(Duration(days: d))),
                  ),
                ),
                if (d < 4) const SizedBox(width: 6),
              ],
            ],
          ),

          const SizedBox(height: AppSpacing.space3),
          const Divider(),
          const SizedBox(height: AppSpacing.space3),

          // Compact inline Absence, Leave, and Late summary + link to History tab
          SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpacing.space2,
              runSpacing: AppSpacing.space1,
              children: <Widget>[
                Wrap(
                  spacing: AppSpacing.space2,
                  runSpacing: 4,
                  children: <Widget>[
                    _InlineWeekMetric(
                      label: 'มาสาย',
                      count: summary.lateCount,
                      color: AttendanceStatus.late.foregroundColor,
                    ),
                    _InlineWeekMetric(
                      label: 'ขาด',
                      count: summary.absentCount,
                      color: AttendanceStatus.absent.foregroundColor,
                    ),
                    _InlineWeekMetric(
                      label: 'ลา',
                      count: summary.leaveCount,
                      color: AttendanceStatus.leave.foregroundColor,
                    ),
                  ],
                ),
                TextButton(
                  onPressed: onOpenFullHistory,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    minimumSize: const Size(0, 36),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('ประวัติทั้งหมด →'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DayTimelineCell extends StatelessWidget {
  const _DayTimelineCell({
    required this.dayName,
    required this.date,
    required this.isToday,
    required this.entry,
  });

  final String dayName;
  final DateTime date;
  final bool isToday;
  final DailyAttendanceEntry? entry;

  @override
  Widget build(BuildContext context) {
    final status = entry?.status;
    final scanTime = entry?.firstScanAt;

    final String detailText;
    if (scanTime != null) {
      final d = ThaiFormat.toBangkok(scanTime);
      detailText =
          '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    } else if (status != null) {
      detailText = switch (status) {
        AttendanceStatus.pending => 'รอ',
        AttendanceStatus.absent => 'ขาด',
        AttendanceStatus.leave => 'ลา',
        AttendanceStatus.unknown => 'ซิงก์',
        _ => status.label,
      };
    } else {
      detailText = '—';
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: isToday
            ? AppColors.brandPrimarySoft.withValues(alpha: 0.6)
            : AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.control),
        border: Border.all(
          color: isToday ? AppColors.brandPrimary : AppColors.borderSubtle,
          width: isToday ? 1.2 : 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '$dayName ${date.day}',
              style: AppTypography.microLabel.copyWith(
                color: isToday
                    ? AppColors.brandPrimary
                    : AppColors.textSecondary,
                fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: status != null
                  ? status.backgroundColor
                  : AppColors.surfaceSubtle,
              shape: BoxShape.circle,
            ),
            child: Icon(
              status != null ? status.icon : Icons.remove,
              size: 14,
              color: status != null
                  ? status.foregroundColor
                  : AppColors.textDisabled,
            ),
          ),
          const SizedBox(height: 5),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              detailText,
              style: AppTypography.microLabel.copyWith(
                fontSize: 10.5,
                color: status != null
                    ? AppColors.textPrimary
                    : AppColors.textDisabled,
                fontWeight: scanTime != null
                    ? FontWeight.w600
                    : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineWeekMetric extends StatelessWidget {
  const _InlineWeekMetric({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          '$label $count',
          style: AppTypography.supporting.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _LatestNoticeRow extends StatelessWidget {
  const _LatestNoticeRow({
    required this.notification,
    required this.unreadCount,
    required this.onTap,
  });

  final ParentNotificationItem notification;
  final int unreadCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.panel),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.panel),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space4,
            vertical: AppSpacing.space3,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.panel),
            border: Border.all(
              color: unreadCount > 0
                  ? AppColors.brandPrimary.withValues(alpha: 0.35)
                  : AppColors.borderSubtle,
            ),
          ),
          child: Row(
            children: <Widget>[
              Icon(
                unreadCount > 0
                    ? Icons.notifications_active_outlined
                    : Icons.notifications_outlined,
                size: 18,
                color: unreadCount > 0
                    ? AppColors.brandPrimary
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      notification.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyStrong.copyWith(fontSize: 13.5),
                    ),
                    Text(
                      '${ThaiFormat.shortDate(notification.targetDate)} • เปลี่ยนเป็น "${notification.newStatus.label}"',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.microLabel,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.space2),
              if (unreadCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.brandPrimarySoft,
                    borderRadius: BorderRadius.circular(AppRadius.badge),
                  ),
                  child: Text(
                    '$unreadCount ใหม่',
                    style: AppTypography.microLabel.copyWith(
                      color: AppColors.brandPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right,
                size: 18,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
