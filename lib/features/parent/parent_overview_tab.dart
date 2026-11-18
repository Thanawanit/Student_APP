import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/responsive_layout.dart';
import '../../core/utils/thai_date_format.dart';
import '../../domain/models/attendance_models.dart';
import '../../domain/models/attendance_status.dart';
import '../../shared/widgets/state_views.dart';
import '../../shared/widgets/student_avatar.dart';
import '../../state/app_controller.dart';

/// Parent/Student Overview Screen (`ภาพรวม`) with:
/// 1) Student Initials CircleAvatar (42x42) + Current Date Pill
/// 2) Emotional Reassurance Emerald Hero Card (no duplicate status words)
/// 3) Cleaner Weekly Attendance Card with single-dot future days & summary bar
/// 4) Today's Scan Timeline Card + Parent Quick Action Card ('แจ้งลาเรียนล่วงหน้า')
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
    final inset = ResponsiveContent.horizontalInset(context);

    final studentName = record?.fullName ?? session?.studentName ?? 'นักเรียน';
    final subtitle = record != null
        ? 'ม.${record.classroom.grade}/${record.classroom.room} • รหัส ${ThaiFormat.maskStudentId(record.studentId)}'
        : session != null
        ? 'ม.${session.classroom.grade}/${session.classroom.room} • รหัส ${ThaiFormat.maskStudentId(session.studentId)}'
        : 'โรงเรียนขุนยวมวิทยา';

    return Scaffold(
      backgroundColor: const Color(0xFFF2F5F3),
      body: Column(
        children: <Widget>[
          _StudentHeader(
            inset: inset,
            studentName: studentName,
            subtitle: subtitle,
            todayDate: controller.todayDate,
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

                              final timelineCard = _TodayTimelineCard(
                                entry: record.todayEntry,
                              );

                              final quickActionCard =
                                  _LeaveRequestQuickActionCard(
                                    studentName: record.fullName,
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
                                            timelineCard,
                                            const SizedBox(
                                              height: AppSpacing.space3,
                                            ),
                                            quickActionCard,
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
                                    timelineCard,
                                    const SizedBox(height: AppSpacing.space3),
                                    quickActionCard,
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
    required this.todayDate,
  });

  final double inset;
  final String studentName;
  final String subtitle;
  final DateTime todayDate;

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
              StudentAvatar(fullName: studentName, size: 42),
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
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.microLabel.copyWith(
                        fontSize: 12,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.space2),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8E4),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  ThaiFormat.shortDateTwoDigitYear(todayDate),
                  style: AppTypography.microLabel.copyWith(
                    color: const Color(0xFF334155),
                    fontWeight: FontWeight.w600,
                  ),
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
    final isPresent = entry.status == AttendanceStatus.present;
    final isLate = entry.status == AttendanceStatus.late;
    final isPending = entry.status == AttendanceStatus.pending;

    final Color cardBg = switch (entry.status) {
      AttendanceStatus.present => const Color(0xFFECFDF5),
      AttendanceStatus.late => const Color(0xFFFFFBEB),
      _ => const Color(0xFFFFFFFF),
    };
    final Color cardBorder = switch (entry.status) {
      AttendanceStatus.present => const Color(0xFFA7F3D0),
      AttendanceStatus.late => const Color(0xFFFDE68A),
      _ => const Color(0xFFE2E8E4),
    };

    final Color badgeCircleBg = switch (entry.status) {
      AttendanceStatus.present => const Color(0xFF16A34A),
      AttendanceStatus.late => const Color(0xFFD97706),
      AttendanceStatus.pending => const Color(0xFFF1F5F9),
      _ => entry.status.backgroundColor,
    };
    final Color badgeCircleFg = switch (entry.status) {
      AttendanceStatus.present || AttendanceStatus.late => Colors.white,
      AttendanceStatus.pending => const Color(0xFF475569),
      _ => entry.status.foregroundColor,
    };
    final IconData badgeIcon = switch (entry.status) {
      AttendanceStatus.present => Icons.check_rounded,
      _ => entry.status.icon,
    };

    final String pillText = switch (entry.status) {
      AttendanceStatus.present => 'ตรงเวลา',
      _ => entry.status.label,
    };
    final Color pillBg = switch (entry.status) {
      AttendanceStatus.present => const Color(0xFFD1FAE5),
      AttendanceStatus.late => const Color(0xFFFEF3C7),
      AttendanceStatus.pending => const Color(0xFFF1F5F9),
      _ => entry.status.backgroundColor,
    };
    final Color pillFg = switch (entry.status) {
      AttendanceStatus.present => const Color(0xFF065F46),
      AttendanceStatus.late => const Color(0xFFB45309),
      AttendanceStatus.pending => const Color(0xFF475569),
      _ => entry.status.foregroundColor,
    };

    final String headlineText = switch (entry.status) {
      AttendanceStatus.present => 'ถึงโรงเรียนเรียบร้อยแล้ว',
      AttendanceStatus.late => 'สแกนเข้าเรียนแล้ว (สาย)',
      AttendanceStatus.pending => 'รอสแกนเข้าเรียน',
      AttendanceStatus.absent => 'ไม่พบข้อมูลการเข้าเรียนวันนี้',
      AttendanceStatus.leave => 'บันทึกการลาเรียนเรียบร้อยแล้ว',
      AttendanceStatus.unknown => 'อยู่ระหว่างตรวจสอบข้อมูล',
    };
    final Color headlineColor = switch (entry.status) {
      AttendanceStatus.present => const Color(0xFF064E3B),
      AttendanceStatus.late => const Color(0xFF78350F),
      _ => const Color(0xFF111827),
    };

    final String subtitleText = switch (entry.status) {
      AttendanceStatus.present => 'บันทึกเวลาเข้าเรียนก่อน 08:00\u00A0น.',
      AttendanceStatus.late =>
        'บันทึกเวลาเข้าเรียนตั้งแต่ 08:00\u00A0น. เป็นต้นไป',
      AttendanceStatus.pending =>
        'ยังไม่พบการสแกน • รอยืนยันสถานะถึง 09:00\u00A0น.',
      AttendanceStatus.absent =>
        'ไม่พบการสแกนและไม่มีบันทึกการลาหลัง 09:00\u00A0น.',
      AttendanceStatus.leave => 'ครูที่ปรึกษาบันทึกสถานะลาเรียบร้อยแล้ว',
      AttendanceStatus.unknown =>
        'ข้อมูลยังไม่ล่าสุดหรืออยู่ระหว่างตรวจสอบ กรุณารอการซิงก์',
    };
    final Color subtitleColor = switch (entry.status) {
      AttendanceStatus.present => const Color(0xFF047857),
      AttendanceStatus.late => const Color(0xFF92400E),
      _ => const Color(0xFF6B7280),
    };

    final scanTimeText = entry.firstScanAt != null
        ? 'เข้า ${ThaiFormat.time24Nbsp(entry.firstScanAt!)}'
        : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: cardBorder,
          width: isPresent || isLate ? 1.2 : 1.0,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: badgeCircleBg,
              shape: BoxShape.circle,
            ),
            child: Icon(
              badgeIcon,
              size: isPending ? 24 : 28,
              color: badgeCircleFg,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Wrap(
                  spacing: 8,
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
                        pillText,
                        style: AppTypography.microLabel.copyWith(
                          fontSize: 11,
                          color: pillFg,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (scanTimeText != null)
                      Text(
                        scanTimeText,
                        style: AppTypography.supporting.copyWith(
                          fontSize: 13,
                          color: isLate
                              ? const Color(0xFFB45309)
                              : const Color(0xFF15803D),
                          fontWeight: FontWeight.w700,
                          fontFeatures: const <FontFeature>[
                            FontFeature.tabularFigures(),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  headlineText,
                  style: AppTypography.sectionTitle.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: headlineColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitleText,
                  style: AppTypography.supporting.copyWith(
                    fontSize: 12,
                    color: subtitleColor,
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

    final attendedDays = summary.presentCount + summary.lateCount;
    final recordedTotal =
        (attendedDays + summary.absentCount + summary.leaveCount).clamp(1, 5);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(20),
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
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                for (var d = 0; d < 5; d++) ...<Widget>[
                  Expanded(
                    child: _DayPillBox(
                      dayName: dayNames[d],
                      date: monday.add(Duration(days: d)),
                      isActive:
                          monday.add(Duration(days: d)).year ==
                              todayDate.year &&
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
          ),
          const SizedBox(height: AppSpacing.space3),

          // Cleaner summary bar (#F8FAFC, borderRadius: 12)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpacing.space2,
              runSpacing: 4,
              children: <Widget>[
                Text(
                  'เข้าเรียนสัปดาห์นี้ $attendedDays/$recordedTotal วัน',
                  style: AppTypography.supporting.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF334155),
                  ),
                ),
                Text(
                  'สาย ${summary.lateCount} • ขาด ${summary.absentCount} • ลา ${summary.leaveCount}',
                  style: AppTypography.microLabel.copyWith(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
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
    final isEmptyDay = status == null;

    final Color fgColor = isActive
        ? const Color(0xFF14532D)
        : const Color(0xFF94A3B8);

    final String? detailText;
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
      detailText = null;
    }

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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
          if (isEmptyDay)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                '•',
                style: TextStyle(
                  fontSize: 16,
                  height: 1.0,
                  color: Color(0xFFCBD5E1),
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          else ...<Widget>[
            Icon(status.icon, size: 16, color: fgColor),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                detailText!,
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
        ],
      ),
    );
  }
}

class _TodayTimelineCard extends StatelessWidget {
  const _TodayTimelineCard({required this.entry});

  final DailyAttendanceEntry entry;

  @override
  Widget build(BuildContext context) {
    final hasCheckIn = entry.firstScanAt != null;
    final checkInRightText = hasCheckIn
        ? ThaiFormat.time24Nbsp(entry.firstScanAt!)
        : entry.status == AttendanceStatus.leave
        ? 'ลาเรียน'
        : 'รอดำเนินการ';

    final Color checkInRightColor = hasCheckIn
        ? const Color(0xFF15803D)
        : const Color(0xFF94A3B8);

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
          Text(
            'ไทม์ไลน์วันนี้',
            style: AppTypography.sectionTitle.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.space3),

          // Row 1: สแกนเข้าโรงเรียน
          Row(
            children: <Widget>[
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: hasCheckIn
                      ? const Color(0xFF16A34A)
                      : const Color(0xFFCBD5E1),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'สแกนเข้าโรงเรียน',
                  style: AppTypography.supporting.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                checkInRightText,
                style: AppTypography.supporting.copyWith(
                  color: checkInRightColor,
                  fontWeight: hasCheckIn ? FontWeight.w600 : FontWeight.w400,
                  fontFeatures: const <FontFeature>[
                    FontFeature.tabularFigures(),
                  ],
                ),
              ),
            ],
          ),

          // Vertical connector
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Container(
              width: 2,
              height: 14,
              color: const Color(0xFFE2E8E4),
            ),
          ),

          // Row 2: สแกนกลับบ้าน (Pending)
          Row(
            children: <Widget>[
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF94A3B8), width: 2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'สแกนกลับบ้าน',
                  style: AppTypography.supporting.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                'รอดำเนินการ',
                style: AppTypography.supporting.copyWith(
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LeaveRequestQuickActionCard extends StatelessWidget {
  const _LeaveRequestQuickActionCard({required this.studentName});

  final String studentName;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'แบบฟอร์มแจ้งลาเรียนสำหรับ $studentName (โหมดตัวอย่าง)',
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: <Widget>[
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5EE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.edit_calendar_rounded,
                    color: Color(0xFF15803D),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'แจ้งลาเรียนล่วงหน้า',
                        style: AppTypography.bodyStrong.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'ส่งคำขอลาป่วยหรือลากิจถึงครูที่ปรึกษา',
                        style: AppTypography.microLabel.copyWith(
                          fontSize: 12,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.space2),
                const Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: Color(0xFF94A3B8),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
