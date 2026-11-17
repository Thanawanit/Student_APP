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
import '../shared/student_detail_screen.dart';

/// Screen A — Apple Wallet-inspired Obsidian Pass + Swiss Weekly & 3-Record History Preview.
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
    final isExpanded = MediaQuery.sizeOf(context).width >= 840;

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
          padding: EdgeInsets.fromLTRB(
            inset,
            AppSpacing.space4,
            inset,
            AppSpacing.space6,
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
                  : isExpanded
                  ? _ExpandedParentOverview(
                      record: record,
                      todayDate: controller.todayDate,
                      latestNotification: latestNotification,
                      unreadCount: unread,
                      onOpenFullHistory: onOpenFullHistory,
                      onOpenNotifications: onOpenNotifications,
                    )
                  : _CompactParentOverview(
                      record: record,
                      todayDate: controller.todayDate,
                      latestNotification: latestNotification,
                      unreadCount: unread,
                      onOpenFullHistory: onOpenFullHistory,
                      onOpenNotifications: onOpenNotifications,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpandedParentOverview extends StatelessWidget {
  const _ExpandedParentOverview({
    required this.record,
    required this.todayDate,
    required this.latestNotification,
    required this.unreadCount,
    required this.onOpenFullHistory,
    required this.onOpenNotifications,
  });

  final StudentAttendanceRecord record;
  final DateTime todayDate;
  final ParentNotificationItem? latestNotification;
  final int unreadCount;
  final VoidCallback onOpenFullHistory;
  final VoidCallback onOpenNotifications;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _ObsidianStudentPass(record: record, isWide: true),
        const SizedBox(height: AppSpacing.space5),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              flex: 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _WeeklySummaryBlock(record: record, todayDate: todayDate),
                  if (latestNotification != null) ...<Widget>[
                    const SizedBox(height: AppSpacing.space4),
                    _NotificationPreviewPanel(
                      notification: latestNotification!,
                      unreadCount: unreadCount,
                      onTap: onOpenNotifications,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.space5),
            Expanded(
              flex: 6,
              child: _HistoryPreviewBlock(
                record: record,
                onOpenFullHistory: onOpenFullHistory,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CompactParentOverview extends StatelessWidget {
  const _CompactParentOverview({
    required this.record,
    required this.todayDate,
    required this.latestNotification,
    required this.unreadCount,
    required this.onOpenFullHistory,
    required this.onOpenNotifications,
  });

  final StudentAttendanceRecord record;
  final DateTime todayDate;
  final ParentNotificationItem? latestNotification;
  final int unreadCount;
  final VoidCallback onOpenFullHistory;
  final VoidCallback onOpenNotifications;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // 01 & 02. Student Identity + Today's Attendance Pass
        _ObsidianStudentPass(record: record, isWide: false),
        const SizedBox(height: AppSpacing.space4),

        // 03. Weekly Summary
        _WeeklySummaryBlock(record: record, todayDate: todayDate),
        if (latestNotification != null) ...<Widget>[
          const SizedBox(height: AppSpacing.space4),
          // 04. Latest Notification
          _NotificationPreviewPanel(
            notification: latestNotification!,
            unreadCount: unreadCount,
            onTap: onOpenNotifications,
          ),
        ],
        const SizedBox(height: AppSpacing.space5),

        // 05. Attendance History Preview (strictly 3 latest records)
        _HistoryPreviewBlock(
          record: record,
          onOpenFullHistory: onOpenFullHistory,
        ),
      ],
    );
  }
}

class _ObsidianStudentPass extends StatelessWidget {
  const _ObsidianStudentPass({required this.record, required this.isWide});

  final StudentAttendanceRecord record;
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    final entry = record.todayEntry;
    final String headline = switch (entry.status) {
      AttendanceStatus.present => 'ถึงโรงเรียนแล้ว (ตรงเวลา)',
      AttendanceStatus.late => 'ถึงโรงเรียนแล้ว (มาสาย)',
      AttendanceStatus.absent => 'ไม่พบการเข้าเรียนวันนี้',
      AttendanceStatus.leave => 'บันทึกการลาเรียบร้อยแล้ว',
      AttendanceStatus.pending => 'ยังไม่พบการสแกน • รอยืนยัน',
      AttendanceStatus.unknown => 'อยู่ระหว่างตรวจสอบข้อมูล',
    };

    final identityWidget = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          '${record.classroom.hierarchyLabel} • รหัส ${ThaiFormat.maskStudentId(record.studentId)}',
          style: AppTypography.supporting.copyWith(
            color: AppColors.inkTextMuted,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          record.fullName,
          style: AppTypography.pageTitle.copyWith(color: AppColors.inkText),
        ),
      ],
    );

    final statusWidget = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'สถานะวันนี้ • ${ThaiFormat.fullDate(entry.date)}',
          style: AppTypography.microLabel.copyWith(
            color: AppColors.inkTextMuted,
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
                  color: AppColors.inkText,
                  fontFeatures: const <FontFeature>[
                    FontFeature.tabularFigures(),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.space2),
        Text(
          headline,
          style: AppTypography.bodyStrong.copyWith(color: AppColors.inkText),
        ),
        Text(
          entry.status.detailDescription,
          style: AppTypography.supporting.copyWith(
            color: AppColors.inkTextMuted,
          ),
        ),
      ],
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.space5),
      decoration: BoxDecoration(
        color: AppColors.inkSurface,
        borderRadius: BorderRadius.circular(AppRadius.panel),
      ),
      child: isWide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Expanded(flex: 5, child: identityWidget),
                const SizedBox(width: AppSpacing.space5),
                Container(
                  width: 1,
                  height: 76,
                  color: AppColors.inkSurfaceDivider,
                ),
                const SizedBox(width: AppSpacing.space5),
                Expanded(flex: 7, child: statusWidget),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                identityWidget,
                const SizedBox(height: AppSpacing.space4),
                Container(height: 1, color: AppColors.inkSurfaceDivider),
                const SizedBox(height: AppSpacing.space4),
                statusWidget,
              ],
            ),
    );
  }
}

class _WeeklySummaryBlock extends StatelessWidget {
  const _WeeklySummaryBlock({required this.record, required this.todayDate});

  final StudentAttendanceRecord record;
  final DateTime todayDate;

  @override
  Widget build(BuildContext context) {
    final summary = record.weeklySummary;
    final monday = todayDate.subtract(Duration(days: todayDate.weekday - 1));
    const dayLabels = <String>['จ.', 'อ.', 'พ.', 'พฤ.', 'ศ.'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
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
        const SizedBox(height: AppSpacing.space2),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.panel),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space3,
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

class _HistoryPreviewBlock extends StatelessWidget {
  const _HistoryPreviewBlock({
    required this.record,
    required this.onOpenFullHistory,
  });

  final StudentAttendanceRecord record;
  final VoidCallback onOpenFullHistory;

  @override
  Widget build(BuildContext context) {
    final previewItems = record.history.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
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
              TextButton(
                onPressed: onOpenFullHistory,
                child: const Text('ดูประวัติทั้งหมด'),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.space1),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.panel),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Column(
            children: <Widget>[
              for (var i = 0; i < previewItems.length; i++) ...<Widget>[
                InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => StudentDetailScreen(
                          studentId: record.studentId,
                          initialDate: previewItems[i].date,
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.space4,
                        vertical: 10,
                      ),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  ThaiFormat.fullDate(previewItems[i].date),
                                  style: AppTypography.bodyStrong,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  previewItems[i].firstScanAt != null
                                      ? 'สแกนเข้า ${ThaiFormat.time24(previewItems[i].firstScanAt!)}'
                                      : previewItems[i].status ==
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
                            status: previewItems[i].status,
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
                if (i < previewItems.length - 1) const Divider(),
              ],
            ],
          ),
        ),
      ],
    );
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

class _NotificationPreviewPanel extends StatelessWidget {
  const _NotificationPreviewPanel({
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
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.panel),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space4,
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
