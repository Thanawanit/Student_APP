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
import '../../shared/widgets/status_chip.dart';
import '../../state/app_controller.dart';

/// Screen A — Light Editorial Parent Overview (Apple Health inspired).
/// Prioritizes: 1) Student identity, 2) Today's status & time, 3) Weekly summary,
/// plus a compact notification row. Full history lives on the History tab.
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
    final unread = controller.unreadNotificationCount;
    final latestNotification = controller.parentNotifications.isNotEmpty
        ? controller.parentNotifications.first
        : null;
    final inset = ResponsiveContent.horizontalInset(context);
    final isExpanded = MediaQuery.sizeOf(context).width >= 800;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: inset,
        title: const Row(
          children: <Widget>[
            SchoolLogoMark(size: 26),
            SizedBox(width: AppSpacing.space2),
            Flexible(
              child: Text(
                'โรงเรียนขุนยวมวิทยา',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: <Widget>[
          IconButton(
            tooltip: 'การแจ้งเตือน',
            onPressed: onOpenNotifications,
            icon: Badge.count(
              count: unread,
              isLabelVisible: unread > 0,
              backgroundColor: AppColors.brandPrimary,
              child: const Icon(Icons.notifications_outlined),
            ),
          ),
          const SizedBox(width: AppSpacing.space2),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.brandPrimary,
        onRefresh: controller.loadParentData,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: AppSpacing.space6),
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
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        // 01. Student identity directly on clean light canvas
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            inset,
                            AppSpacing.space4,
                            inset,
                            AppSpacing.space3,
                          ),
                          child: _StudentIdentityHeader(record: record),
                        ),

                        if (isExpanded)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Expanded(
                                flex: 6,
                                child: _TodayStatusBand(
                                  entry: record.todayEntry,
                                  inset: inset,
                                ),
                              ),
                              Container(
                                width: 1,
                                color: AppColors.borderSubtle,
                              ),
                              Expanded(
                                flex: 6,
                                child: Column(
                                  children: <Widget>[
                                    _WeeklySummaryBand(
                                      record: record,
                                      todayDate: controller.todayDate,
                                      inset: inset,
                                    ),
                                    if (latestNotification != null) ...<Widget>[
                                      const SizedBox(height: AppSpacing.space3),
                                      _CompactNotificationRow(
                                        notification: latestNotification,
                                        unreadCount: unread,
                                        inset: inset,
                                        onTap: onOpenNotifications,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          )
                        else ...<Widget>[
                          // 02. Today's attendance status & arrival time
                          _TodayStatusBand(
                            entry: record.todayEntry,
                            inset: inset,
                          ),
                          const SizedBox(height: AppSpacing.space4),

                          // 03. Weekly attendance summary
                          _WeeklySummaryBand(
                            record: record,
                            todayDate: controller.todayDate,
                            inset: inset,
                          ),

                          // 04. Compact notification information row
                          if (latestNotification != null) ...<Widget>[
                            const SizedBox(height: AppSpacing.space4),
                            _CompactNotificationRow(
                              notification: latestNotification,
                              unreadCount: unread,
                              inset: inset,
                              onTap: onOpenNotifications,
                            ),
                          ],
                        ],

                        // Quiet link to dedicated History tab (no history list on initial dashboard)
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            inset,
                            AppSpacing.space4,
                            inset,
                            0,
                          ),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: onOpenFullHistory,
                              icon: const Icon(
                                Icons.history_outlined,
                                size: 18,
                              ),
                              label: const Text(
                                'ดูประวัติการเข้าเรียนย้อนหลัง',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StudentIdentityHeader extends StatelessWidget {
  const _StudentIdentityHeader({required this.record});

  final StudentAttendanceRecord record;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          '${record.classroom.hierarchyLabel} • รหัส ${ThaiFormat.maskStudentId(record.studentId)}',
          style: AppTypography.supporting.copyWith(
            color: AppColors.brandPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(record.fullName, style: AppTypography.pageTitle),
      ],
    );
  }
}

class _TodayStatusBand extends StatelessWidget {
  const _TodayStatusBand({required this.entry, required this.inset});

  final DailyAttendanceEntry entry;
  final double inset;

  @override
  Widget build(BuildContext context) {
    final String headline = switch (entry.status) {
      AttendanceStatus.present => 'ถึงโรงเรียนแล้ว (ตรงเวลา)',
      AttendanceStatus.late => 'ถึงโรงเรียนแล้ว (มาสาย)',
      AttendanceStatus.absent => 'ไม่พบการเข้าเรียนวันนี้',
      AttendanceStatus.leave => 'บันทึกการลาเรียบร้อยแล้ว',
      AttendanceStatus.pending => 'ยังไม่พบการสแกน • รอยืนยัน',
      AttendanceStatus.unknown => 'อยู่ระหว่างตรวจสอบข้อมูล',
    };

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: const BorderSide(color: AppColors.borderSubtle),
          bottom: const BorderSide(color: AppColors.borderSubtle),
          left: BorderSide(color: entry.status.foregroundColor, width: 3),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        inset - 3 < 10 ? 13 : inset - 3,
        AppSpacing.space4,
        inset,
        AppSpacing.space4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'สถานะวันนี้ • ${ThaiFormat.fullDate(entry.date)}',
            style: AppTypography.microLabel,
          ),
          const SizedBox(height: AppSpacing.space3),
          Wrap(
            spacing: AppSpacing.space3,
            runSpacing: AppSpacing.space2,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              AttendanceStatusChip(status: entry.status),
              if (entry.firstScanAt != null)
                Text(
                  ThaiFormat.time24(entry.firstScanAt!),
                  style: AppTypography.display.copyWith(fontSize: 34),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.space2),
          Text(headline, style: AppTypography.bodyStrong),
          Text(entry.status.detailDescription, style: AppTypography.supporting),
        ],
      ),
    );
  }
}

class _WeeklySummaryBand extends StatelessWidget {
  const _WeeklySummaryBand({
    required this.record,
    required this.todayDate,
    required this.inset,
  });

  final StudentAttendanceRecord record;
  final DateTime todayDate;
  final double inset;

  @override
  Widget build(BuildContext context) {
    final summary = record.weeklySummary;
    final monday = todayDate.subtract(Duration(days: todayDate.weekday - 1));
    const dayLabels = <String>['จ.', 'อ.', 'พ.', 'พฤ.', 'ศ.'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.symmetric(horizontal: inset),
          child: SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpacing.space2,
              runSpacing: 2,
              children: <Widget>[
                Text('สรุปสัปดาห์นี้', style: AppTypography.sectionTitle),
                Text(summary.weekLabel, style: AppTypography.microLabel),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.space2),
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(
              top: BorderSide(color: AppColors.borderSubtle),
              bottom: BorderSide(color: AppColors.borderSubtle),
            ),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: inset,
            vertical: AppSpacing.space3,
          ),
          child: Column(
            children: <Widget>[
              IntrinsicHeight(
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: _WeeklyStat(
                        label: 'มาสาย',
                        count: summary.lateCount,
                        color: AttendanceStatus.late.foregroundColor,
                      ),
                    ),
                    const VerticalDivider(
                      width: 1,
                      thickness: 1,
                      color: AppColors.borderSubtle,
                    ),
                    Expanded(
                      child: _WeeklyStat(
                        label: 'ขาดเรียน',
                        count: summary.absentCount,
                        color: AttendanceStatus.absent.foregroundColor,
                      ),
                    ),
                    const VerticalDivider(
                      width: 1,
                      thickness: 1,
                      color: AppColors.borderSubtle,
                    ),
                    Expanded(
                      child: _WeeklyStat(
                        label: 'ลา',
                        count: summary.leaveCount,
                        color: AttendanceStatus.leave.foregroundColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.space3),
              const Divider(),
              const SizedBox(height: AppSpacing.space2),
              Row(
                children: <Widget>[
                  for (var d = 0; d < 5; d++)
                    Expanded(
                      child: _WeekDayIndicator(
                        dayLabel: dayLabels[d],
                        entry: _findDayEntry(
                          record,
                          monday.add(Duration(days: d)),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  DailyAttendanceEntry? _findDayEntry(
    StudentAttendanceRecord record,
    DateTime date,
  ) {
    for (final e in record.history) {
      if (e.date.year == date.year &&
          e.date.month == date.month &&
          e.date.day == date.day) {
        return e;
      }
    }
    return null;
  }
}

class _WeekDayIndicator extends StatelessWidget {
  const _WeekDayIndicator({required this.dayLabel, required this.entry});

  final String dayLabel;
  final DailyAttendanceEntry? entry;

  @override
  Widget build(BuildContext context) {
    final status = entry?.status;
    return Column(
      children: <Widget>[
        Text(dayLabel, style: AppTypography.microLabel),
        const SizedBox(height: 4),
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: status != null
                ? status.backgroundColor
                : AppColors.surfaceSubtle,
            borderRadius: BorderRadius.circular(AppRadius.badge),
          ),
          child: Icon(
            status != null ? status.icon : Icons.remove,
            size: 14,
            color: status != null
                ? status.foregroundColor
                : AppColors.textDisabled,
          ),
        ),
      ],
    );
  }
}

class _CompactNotificationRow extends StatelessWidget {
  const _CompactNotificationRow({
    required this.notification,
    required this.unreadCount,
    required this.inset,
    required this.onTap,
  });

  final ParentNotificationItem notification;
  final int unreadCount;
  final double inset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: AppColors.borderSubtle),
              bottom: BorderSide(color: AppColors.borderSubtle),
            ),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: inset,
            vertical: AppSpacing.space3,
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
                child: Text(
                  '${notification.title} • ${ThaiFormat.shortDate(notification.targetDate)} (${notification.newStatus.label})',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.supporting.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.space2),
              if (unreadCount > 0)
                Text(
                  '$unreadCount ใหม่',
                  style: AppTypography.microLabel.copyWith(
                    color: AppColors.brandPrimary,
                    fontWeight: FontWeight.w600,
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

class _WeeklyStat extends StatelessWidget {
  const _WeeklyStat({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: AppTypography.microLabel),
          const SizedBox(height: 2),
          Text.rich(
            TextSpan(
              children: <InlineSpan>[
                TextSpan(
                  text: '$count',
                  style: AppTypography.pageTitle.copyWith(
                    color: color,
                    fontFeatures: const <FontFeature>[
                      FontFeature.tabularFigures(),
                    ],
                  ),
                ),
                TextSpan(text: ' ครั้ง', style: AppTypography.microLabel),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
