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

/// Parent Dashboard Overview — Light Editorial × Swiss Data Design.
/// Replaces nested Bento cards and separate day boxes with:
/// 1) Compact student header
/// 2) Clean highlighted today's attendance section
/// 3) Single connected Monday–Friday weekly timeline + inline summary row
/// 4) Compact Activity Feed notification row
/// 5) Simple editorial navigation row to Attendance History
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
      backgroundColor: AppColors.background,
      body: Column(
        children: <Widget>[
          _StudentHeader(
            inset: inset,
            studentName: record?.fullName ?? session?.studentName ?? 'นักเรียน',
            subtitle: record != null
                ? 'ม.${record.classroom.grade} · ${record.classroom.roomLabel} · รหัส ${ThaiFormat.maskStudentId(record.studentId)}'
                : session != null
                ? 'ม.${session.classroom.grade} · ${session.classroom.roomLabel} · รหัส ${ThaiFormat.maskStudentId(session.studentId)}'
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
                              final isWideDesktop = constraints.maxWidth >= 840;

                              final todaySection = _TodayHighlightedSection(
                                entry: record.todayEntry,
                              );

                              final weeklySection = _WeeklyConnectedTimeline(
                                record: record,
                                todayDate: controller.todayDate,
                              );

                              final feedAndHistorySection = Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  const Divider(),
                                  if (latestNotification != null) ...<Widget>[
                                    _NotificationActivityRow(
                                      notification: latestNotification,
                                      unreadCount: unread,
                                      onTap: onOpenNotifications,
                                    ),
                                    const Divider(),
                                  ],
                                  _HistoryEditorialRow(
                                    onTap: onOpenFullHistory,
                                  ),
                                  const Divider(),
                                ],
                              );

                              if (isWideDesktop) {
                                return Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: inset,
                                  ),
                                  child: IntrinsicHeight(
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Expanded(
                                          flex: 5,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: <Widget>[
                                              todaySection,
                                              const SizedBox(
                                                height: AppSpacing.space6,
                                              ),
                                              feedAndHistorySection,
                                            ],
                                          ),
                                        ),
                                        const VerticalDivider(
                                          width: AppSpacing.space8,
                                          thickness: 1,
                                          color: AppColors.borderSubtle,
                                        ),
                                        Expanded(flex: 7, child: weeklySection),
                                      ],
                                    ),
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
                                    todaySection,
                                    const SizedBox(height: AppSpacing.space6),
                                    weeklySection,
                                    const SizedBox(height: AppSpacing.space5),
                                    feedAndHistorySection,
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

class _StudentHeader extends StatelessWidget {
  const _StudentHeader({
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
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: SafeArea(
        bottom: false,
        child: ResponsiveContent(
          padding: EdgeInsets.fromLTRB(
            inset,
            AppSpacing.space2,
            AppSpacing.space2,
            AppSpacing.space2,
          ),
          child: Row(
            children: <Widget>[
              const SchoolLogoMark(size: 28),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      studentName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.sectionTitle.copyWith(fontSize: 18),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.microLabel.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
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
    );
  }
}

class _TodayHighlightedSection extends StatelessWidget {
  const _TodayHighlightedSection({required this.entry});

  final DailyAttendanceEntry entry;

  @override
  Widget build(BuildContext context) {
    final String statusHeadline = switch (entry.status) {
      AttendanceStatus.present => 'มาเรียน · ตรงเวลา',
      AttendanceStatus.late => 'มาสาย',
      AttendanceStatus.absent => 'ขาดเรียนวันนี้',
      AttendanceStatus.leave => 'บันทึกการลาแล้ว',
      AttendanceStatus.pending => 'รอยืนยัน',
      AttendanceStatus.unknown => 'ตรวจสอบข้อมูล',
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
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space4,
        AppSpacing.space3,
        AppSpacing.space4,
        AppSpacing.space3,
      ),
      decoration: BoxDecoration(
        color: entry.status.backgroundColor.withValues(alpha: 0.65),
        border: Border(
          left: BorderSide(color: entry.status.foregroundColor, width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'สถานะวันนี้ · ${ThaiFormat.fullDate(entry.date)}',
            style: AppTypography.microLabel.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.space3,
            runSpacing: 4,
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
                style: AppTypography.display.copyWith(
                  fontSize: entry.firstScanAt != null ? 30 : 20,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
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

class _WeeklyConnectedTimeline extends StatelessWidget {
  const _WeeklyConnectedTimeline({
    required this.record,
    required this.todayDate,
  });

  final StudentAttendanceRecord record;
  final DateTime todayDate;

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Section header
        SizedBox(
          width: double.infinity,
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.space2,
            children: <Widget>[
              Text('การเข้าเรียนสัปดาห์นี้', style: AppTypography.sectionTitle),
              Text(summary.weekLabel, style: AppTypography.microLabel),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.space3),

        // Single connected Monday–Friday timeline (no individual day boxes)
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: AppColors.borderSubtle),
              bottom: BorderSide(color: AppColors.borderSubtle),
            ),
          ),
          child: IntrinsicHeight(
            child: Row(
              children: <Widget>[
                for (var d = 0; d < 5; d++) ...<Widget>[
                  Expanded(
                    child: _ConnectedDayColumn(
                      dayName: dayNames[d],
                      date: monday.add(Duration(days: d)),
                      isToday:
                          monday.add(Duration(days: d)).year ==
                              todayDate.year &&
                          monday.add(Duration(days: d)).month ==
                              todayDate.month &&
                          monday.add(Duration(days: d)).day == todayDate.day,
                      entry: _entryForDay(monday.add(Duration(days: d))),
                    ),
                  ),
                  if (d < 4)
                    const VerticalDivider(
                      width: 1,
                      thickness: 1,
                      color: AppColors.borderSubtle,
                    ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.space3),

        // Compact weekly summary row: มาสาย 0 | ขาด 0 | ลา 0
        IntrinsicHeight(
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.space3,
            runSpacing: 4,
            children: <Widget>[
              _InlineSummaryMetric(
                label: 'มาสาย',
                count: summary.lateCount,
                color: AttendanceStatus.late.foregroundColor,
              ),
              const Text('|', style: TextStyle(color: AppColors.borderStrong)),
              _InlineSummaryMetric(
                label: 'ขาด',
                count: summary.absentCount,
                color: AttendanceStatus.absent.foregroundColor,
              ),
              const Text('|', style: TextStyle(color: AppColors.borderStrong)),
              _InlineSummaryMetric(
                label: 'ลา',
                count: summary.leaveCount,
                color: AttendanceStatus.leave.foregroundColor,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ConnectedDayColumn extends StatelessWidget {
  const _ConnectedDayColumn({
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
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: BoxDecoration(
        color: isToday
            ? AppColors.brandPrimarySoft.withValues(alpha: 0.5)
            : Colors.transparent,
        border: isToday
            ? const Border(
                bottom: BorderSide(color: AppColors.brandPrimary, width: 2),
              )
            : null,
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
          Icon(
            status != null ? status.icon : Icons.remove,
            size: 16,
            color: status != null
                ? status.foregroundColor
                : AppColors.textDisabled,
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              detailText,
              style: AppTypography.microLabel.copyWith(
                fontSize: 11,
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

class _InlineSummaryMetric extends StatelessWidget {
  const _InlineSummaryMetric({
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
            fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _NotificationActivityRow extends StatelessWidget {
  const _NotificationActivityRow({
    required this.notification,
    required this.unreadCount,
    required this.onTap,
  });

  final ParentNotificationItem notification;
  final int unreadCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 52),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyStrong.copyWith(fontSize: 14),
                    ),
                    Text(
                      '${ThaiFormat.shortDate(notification.targetDate)} · เปลี่ยนเป็น "${notification.newStatus.label}"',
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

class _HistoryEditorialRow extends StatelessWidget {
  const _HistoryEditorialRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: <Widget>[
              const Icon(
                Icons.history_outlined,
                size: 18,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: Text(
                  'ดูประวัติการเข้าเรียนย้อนหลัง',
                  style: AppTypography.bodyStrong.copyWith(fontSize: 14),
                ),
              ),
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
