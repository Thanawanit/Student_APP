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

/// Student/Parent Overview Screen with soft greenish-gray canvas (#F2F5F3),
/// White Hero Status Card, Weekly Attendance Card with 5 day pills, and
/// separate White Action Cards at the bottom.
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
      backgroundColor: const Color(0xFFF2F5F3),
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

                              final heroStatusCard = _HeroStatusCard(
                                entry: record.todayEntry,
                              );

                              final weeklyCard = _WeeklyAttendanceCard(
                                record: record,
                                todayDate: controller.todayDate,
                              );

                              final bottomActionCards = Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  if (latestNotification != null)
                                    _NotificationActionCard(
                                      notification: latestNotification,
                                      unreadCount: unread,
                                      onTap: onOpenNotifications,
                                    ),
                                  _HistoryActionCard(onTap: onOpenFullHistory),
                                ],
                              );

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
                                            heroStatusCard,
                                            const SizedBox(
                                              height: AppSpacing.space4,
                                            ),
                                            bottomActionCards,
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.space5),
                                      Expanded(flex: 7, child: weeklyCard),
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
                                    heroStatusCard,
                                    const SizedBox(height: AppSpacing.space4),
                                    weeklyCard,
                                    const SizedBox(height: AppSpacing.space4),
                                    bottomActionCards,
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
  });

  final double inset;
  final String studentName;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFFFFFFFF),
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8E4))),
      ),
      child: SafeArea(
        bottom: false,
        child: ResponsiveContent(
          padding: EdgeInsets.fromLTRB(
            inset,
            AppSpacing.space3,
            inset,
            AppSpacing.space3,
          ),
          child: Row(
            children: <Widget>[
              const SchoolLogoMark(size: 30),
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
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroStatusCard extends StatelessWidget {
  const _HeroStatusCard({required this.entry});

  final DailyAttendanceEntry entry;

  @override
  Widget build(BuildContext context) {
    final isPending = entry.status == AttendanceStatus.pending;

    final Color iconCircleBg = isPending
        ? const Color(0xFFF1F5F9)
        : entry.status.backgroundColor;
    final Color iconCircleFg = isPending
        ? const Color(0xFF475569)
        : entry.status.foregroundColor;

    final Color pillBg = isPending
        ? const Color(0xFFF1F5F9)
        : entry.status.backgroundColor;
    final Color pillFg = isPending
        ? const Color(0xFF475569)
        : entry.status.foregroundColor;

    final String titleText = switch (entry.status) {
      AttendanceStatus.pending => 'รอสแกนเข้าเรียน',
      AttendanceStatus.present => 'มาเรียน · ตรงเวลา',
      AttendanceStatus.late => 'มาสาย',
      AttendanceStatus.absent => 'ขาดเรียนวันนี้',
      AttendanceStatus.leave => 'บันทึกการลาแล้ว',
      AttendanceStatus.unknown => 'อยู่ระหว่างตรวจสอบข้อมูล',
    };

    final String subtitleText = switch (entry.status) {
      AttendanceStatus.pending =>
        'ยังไม่พบการสแกน • รอยืนยันสถานะถึง 09:00\u00A0น.',
      AttendanceStatus.present => 'บันทึกการมาเรียนก่อนเวลา 08:00\u00A0น.',
      AttendanceStatus.late =>
        'บันทึกการเข้าเรียนตั้งแต่เวลา 08:00\u00A0น. เป็นต้นไป',
      AttendanceStatus.absent =>
        'ไม่พบการสแกนและไม่มีบันทึกการลาหลังเวลา 09:00\u00A0น.',
      AttendanceStatus.leave => 'มีการบันทึกสถานะลาเรียบร้อยแล้ว',
      AttendanceStatus.unknown =>
        'ข้อมูลยังไม่ล่าสุดหรืออยู่ระหว่างตรวจสอบ กรุณารอการซิงก์',
    };

    final scanTimeText = entry.firstScanAt != null
        ? ThaiFormat.time24Nbsp(entry.firstScanAt!)
        : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8E4), width: 1),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconCircleBg,
              shape: BoxShape.circle,
            ),
            child: Icon(entry.status.icon, size: 22, color: iconCircleFg),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Wrap(
                  spacing: AppSpacing.space2,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: pillBg,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        entry.status.label,
                        style: AppTypography.microLabel.copyWith(
                          fontSize: 12,
                          color: pillFg,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (scanTimeText != null)
                      Text(
                        scanTimeText,
                        style: AppTypography.supporting.copyWith(
                          color: const Color(0xFF111827),
                          fontWeight: FontWeight.w700,
                          fontFeatures: const <FontFeature>[
                            FontFeature.tabularFigures(),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  titleText,
                  style: AppTypography.sectionTitle.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitleText,
                  style: AppTypography.supporting.copyWith(
                    fontSize: 13,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyAttendanceCard extends StatelessWidget {
  const _WeeklyAttendanceCard({required this.record, required this.todayDate});

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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8E4), width: 1),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
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
                Text(
                  'การเข้าเรียนสัปดาห์นี้',
                  style: AppTypography.sectionTitle,
                ),
                Text(summary.weekLabel, style: AppTypography.microLabel),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.space3),

          // 5 separate vertical pill boxes inside a Row with SizedBox(width: 8)
          Row(
            children: <Widget>[
              for (var d = 0; d < 5; d++) ...<Widget>[
                Expanded(
                  child: _DayPillBox(
                    dayName: dayNames[d],
                    date: monday.add(Duration(days: d)),
                    isActive:
                        monday.add(Duration(days: d)).year == todayDate.year &&
                        monday.add(Duration(days: d)).month ==
                            todayDate.month &&
                        monday.add(Duration(days: d)).day == todayDate.day,
                    entry: _entryForDay(monday.add(Duration(days: d))),
                  ),
                ),
                if (d < 4) const SizedBox(width: 8),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.space3),

          // Compact weekly summary row inside the same card
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.space3,
            runSpacing: 4,
            children: <Widget>[
              _InlineSummaryMetric(
                label: 'มาสาย',
                count: summary.lateCount,
                color: AttendanceStatus.late.foregroundColor,
              ),
              const Text('|', style: TextStyle(color: Color(0xFFE2E8E4))),
              _InlineSummaryMetric(
                label: 'ขาด',
                count: summary.absentCount,
                color: AttendanceStatus.absent.foregroundColor,
              ),
              const Text('|', style: TextStyle(color: Color(0xFFE2E8E4))),
              _InlineSummaryMetric(
                label: 'ลา',
                count: summary.leaveCount,
                color: AttendanceStatus.leave.foregroundColor,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DayPillBox extends StatelessWidget {
  const _DayPillBox({
    required this.dayName,
    required this.date,
    required this.isActive,
    required this.entry,
  });

  final String dayName;
  final DateTime date;
  final bool isActive;
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

    final Color fgColor = isActive
        ? const Color(0xFF14532D)
        : const Color(0xFF94A3B8);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFE8F5EE) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? const Color(0xFF16A34A) : const Color(0xFFE2E8F0),
          width: isActive ? 1.5 : 1,
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
                color: fgColor,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Icon(
            status != null ? status.icon : Icons.remove,
            size: 16,
            color: fgColor,
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              detailText,
              style: AppTypography.microLabel.copyWith(
                fontSize: 11,
                color: fgColor,
                fontWeight: isActive || scanTime != null
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

class _NotificationActionCard extends StatelessWidget {
  const _NotificationActionCard({
    required this.notification,
    required this.unreadCount,
    required this.onTap,
  });

  final ParentNotificationItem notification;
  final int unreadCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8E4), width: 1),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: <Widget>[
                Icon(
                  unreadCount > 0
                      ? Icons.notifications_active_outlined
                      : Icons.notifications_outlined,
                  size: 20,
                  color: unreadCount > 0
                      ? const Color(0xFF14532D)
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
                      const SizedBox(height: 2),
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
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCECE2),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      '$unreadCount ใหม่',
                      style: AppTypography.microLabel.copyWith(
                        color: const Color(0xFF14532D),
                        fontWeight: FontWeight.w700,
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
      ),
    );
  }
}

class _HistoryActionCard extends StatelessWidget {
  const _HistoryActionCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8E4), width: 1),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: <Widget>[
                const Icon(
                  Icons.history_outlined,
                  size: 20,
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
      ),
    );
  }
}
