import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/responsive_layout.dart';
import '../../core/utils/thai_date_format.dart';
import '../../domain/models/attendance_models.dart';
import '../../domain/models/attendance_status.dart';
import '../../shared/widgets/dashboard_gradient_header.dart';
import '../../shared/widgets/school_brand_mark.dart';
import '../../shared/widgets/state_views.dart';
import '../../shared/widgets/status_chip.dart';
import '../../state/app_controller.dart';
import '../shared/student_detail_screen.dart';
import 'parent_history_section.dart';
import 'parent_notifications_screen.dart';

/// Dashboard-First Parent Overview (Level 1 Today -> Level 2 Weekly & Updates -> Level 3 History).
class ParentOverviewTab extends StatelessWidget {
  const ParentOverviewTab({super.key, this.onOpenFullHistory});

  final VoidCallback? onOpenFullHistory;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final record = controller.parentRecord;
    final unread = controller.unreadNotificationCount;
    final latestNotification = controller.parentNotifications.isNotEmpty
        ? controller.parentNotifications.first
        : null;
    final inset = ResponsiveContent.horizontalInset(context);
    final isWideDesktop = MediaQuery.sizeOf(context).width >= 760;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.gradientGreenTop,
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
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ParentNotificationsScreen(),
                ),
              );
            },
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
                  : isWideDesktop
                  ? _DesktopParentLayout(
                      inset: inset,
                      record: record,
                      todayDate: controller.todayDate,
                      latestNotification: latestNotification,
                      unreadCount: unread,
                    )
                  : _MobileParentLayout(
                      inset: inset,
                      record: record,
                      todayDate: controller.todayDate,
                      latestNotification: latestNotification,
                      unreadCount: unread,
                      onOpenFullHistory: onOpenFullHistory,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DesktopParentLayout extends StatelessWidget {
  const _DesktopParentLayout({
    required this.inset,
    required this.record,
    required this.todayDate,
    required this.latestNotification,
    required this.unreadCount,
  });

  final double inset;
  final StudentAttendanceRecord record;
  final DateTime todayDate;
  final ParentNotificationItem? latestNotification;
  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // LEVEL 1: Full-width Green-to-White Gradient Hero (Identity + Today's Attendance)
        DashboardGradientBand(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              inset,
              AppSpacing.space3,
              inset,
              AppSpacing.space5,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Expanded(flex: 6, child: _StudentIdentityBlock(record: record)),
                const SizedBox(width: AppSpacing.space5),
                Container(width: 1, height: 68, color: AppColors.borderSubtle),
                const SizedBox(width: AppSpacing.space5),
                Expanded(
                  flex: 6,
                  child: _TodayStatusContent(entry: record.todayEntry),
                ),
              ],
            ),
          ),
        ),

        // LEVEL 2 & LEVEL 3 side-by-side
        Padding(
          padding: EdgeInsets.fromLTRB(inset, AppSpacing.space5, inset, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _WeeklySummaryBlock(
                      record: record,
                      todayDate: todayDate,
                      horizontalPadding: 0,
                      borderedPanel: true,
                    ),
                    if (latestNotification != null) ...<Widget>[
                      const SizedBox(height: AppSpacing.space4),
                      _NotificationPreviewStrip(
                        notification: latestNotification!,
                        unreadCount: unreadCount,
                        horizontalPadding: AppSpacing.space4,
                        bordered: true,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.space6),
              Expanded(
                flex: 7,
                child: ParentHistorySection(
                  record: record,
                  todayDate: todayDate,
                  useContainerInset: false,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MobileParentLayout extends StatelessWidget {
  const _MobileParentLayout({
    required this.inset,
    required this.record,
    required this.todayDate,
    required this.latestNotification,
    required this.unreadCount,
    this.onOpenFullHistory,
  });

  final double inset;
  final StudentAttendanceRecord record;
  final DateTime todayDate;
  final ParentNotificationItem? latestNotification;
  final int unreadCount;
  final VoidCallback? onOpenFullHistory;

  @override
  Widget build(BuildContext context) {
    final recentItems = record.history.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // LEVEL 1: Identity + Today's Attendance on top-to-bottom green-to-white gradient
        DashboardGradientBand(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              inset,
              AppSpacing.space2,
              inset,
              AppSpacing.space4,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _StudentIdentityBlock(record: record),
                const SizedBox(height: AppSpacing.space3),
                const Divider(),
                const SizedBox(height: AppSpacing.space3),
                _TodayStatusContent(entry: record.todayEntry),
              ],
            ),
          ),
        ),

        // LEVEL 2: Weekly summary + 5-day trend + Important notification
        const SizedBox(height: AppSpacing.space4),
        _WeeklySummaryBlock(
          record: record,
          todayDate: todayDate,
          horizontalPadding: inset,
          borderedPanel: false,
        ),
        if (latestNotification != null) ...<Widget>[
          const SizedBox(height: AppSpacing.space3),
          _NotificationPreviewStrip(
            notification: latestNotification!,
            unreadCount: unreadCount,
            horizontalPadding: inset,
            bordered: false,
          ),
        ],

        // LEVEL 3: Concise recent attendance history (does not dominate initial screen)
        Padding(
          padding: EdgeInsets.fromLTRB(
            inset,
            AppSpacing.space5,
            inset,
            AppSpacing.space2,
          ),
          child: SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpacing.space2,
              children: <Widget>[
                Text(
                  'ประวัติการเข้าเรียนล่าสุด',
                  style: AppTypography.sectionTitle,
                ),
                if (onOpenFullHistory != null)
                  TextButton(
                    onPressed: onOpenFullHistory,
                    child: const Text('ดูทั้งหมด / กรองรายเดือน'),
                  ),
              ],
            ),
          ),
        ),
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(
              top: BorderSide(color: AppColors.borderSubtle),
              bottom: BorderSide(color: AppColors.borderSubtle),
            ),
          ),
          child: Column(
            children: <Widget>[
              for (var i = 0; i < recentItems.length; i++) ...<Widget>[
                InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => StudentDetailScreen(
                          studentId: record.studentId,
                          initialDate: recentItems[i].date,
                          isReadOnly: true,
                        ),
                      ),
                    );
                  },
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: AppSpacing.minTouchTarget + 8,
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: inset,
                        vertical: 10,
                      ),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  ThaiFormat.fullDate(recentItems[i].date),
                                  style: AppTypography.bodyStrong,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  recentItems[i].firstScanAt != null
                                      ? 'สแกนเข้า ${ThaiFormat.time24(recentItems[i].firstScanAt!)}'
                                      : recentItems[i].status ==
                                            AttendanceStatus.pending
                                      ? 'ยังไม่พบการสแกน • รอยืนยัน'
                                      : 'ไม่มีบันทึกเวลาสแกน',
                                  style: AppTypography.microLabel,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.space2),
                          AttendanceStatusChip(
                            status: recentItems[i].status,
                            compact: true,
                          ),
                          const SizedBox(width: AppSpacing.space1),
                          const Icon(
                            Icons.chevron_right,
                            size: 18,
                            color: AppColors.textDisabled,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (i < recentItems.length - 1)
                  Divider(indent: inset, endIndent: inset),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _StudentIdentityBlock extends StatelessWidget {
  const _StudentIdentityBlock({required this.record});

  final StudentAttendanceRecord record;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          record.classroom.hierarchyLabel,
          style: AppTypography.supporting.copyWith(
            color: AppColors.brandPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(record.fullName, style: AppTypography.pageTitle),
        const SizedBox(height: 2),
        Text(
          'รหัสนักเรียน ${ThaiFormat.maskStudentId(record.studentId)}',
          style: AppTypography.supporting,
        ),
      ],
    );
  }
}

class _TodayStatusContent extends StatelessWidget {
  const _TodayStatusContent({required this.entry});

  final DailyAttendanceEntry entry;

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
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: entry.status.foregroundColor, width: 3),
        ),
      ),
      padding: const EdgeInsets.only(left: AppSpacing.space3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'สถานะวันนี้ • ${ThaiFormat.fullDate(entry.date)}',
            style: AppTypography.microLabel.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
          Wrap(
            spacing: AppSpacing.space3,
            runSpacing: AppSpacing.space2,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              AttendanceStatusChip(status: entry.status),
              if (entry.firstScanAt != null)
                Text(
                  ThaiFormat.time24(entry.firstScanAt!),
                  style: AppTypography.pageTitle.copyWith(
                    fontFeatures: const <FontFeature>[
                      FontFeature.tabularFigures(),
                    ],
                  ),
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

class _WeeklySummaryBlock extends StatelessWidget {
  const _WeeklySummaryBlock({
    required this.record,
    required this.todayDate,
    required this.horizontalPadding,
    required this.borderedPanel,
  });

  final StudentAttendanceRecord record;
  final DateTime todayDate;
  final double horizontalPadding;
  final bool borderedPanel;

  @override
  Widget build(BuildContext context) {
    final summary = record.weeklySummary;
    final monday = todayDate.subtract(Duration(days: todayDate.weekday - 1));
    const dayLabels = <String>['จ.', 'อ.', 'พ.', 'พฤ.', 'ศ.'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
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
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: borderedPanel
                ? Border.all(color: AppColors.borderSubtle)
                : const Border(
                    top: BorderSide(color: AppColors.borderSubtle),
                    bottom: BorderSide(color: AppColors.borderSubtle),
                  ),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: borderedPanel ? AppSpacing.space3 : horizontalPadding,
            vertical: AppSpacing.space3,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                  for (var d = 0; d < 5; d++) ...<Widget>[
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
            borderRadius: BorderRadius.circular(6),
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

class _NotificationPreviewStrip extends StatelessWidget {
  const _NotificationPreviewStrip({
    required this.notification,
    required this.unreadCount,
    required this.horizontalPadding,
    required this.bordered,
  });

  final ParentNotificationItem notification;
  final int unreadCount;
  final double horizontalPadding;
  final bool bordered;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const ParentNotificationsScreen(),
            ),
          );
        },
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            border: bordered
                ? Border.all(color: AppColors.borderSubtle)
                : const Border(
                    top: BorderSide(color: AppColors.borderSubtle),
                    bottom: BorderSide(color: AppColors.borderSubtle),
                  ),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      notification.title,
                      style: AppTypography.supporting.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${ThaiFormat.shortDate(notification.targetDate)} • ${notification.newStatus.label}',
                      style: AppTypography.microLabel,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.space2),
              Text(
                unreadCount > 0 ? 'ดูแจ้งเตือน ($unreadCount)' : 'ทั้งหมด',
                style: AppTypography.microLabel.copyWith(
                  color: AppColors.brandPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: 18,
                color: AppColors.brandPrimary,
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
