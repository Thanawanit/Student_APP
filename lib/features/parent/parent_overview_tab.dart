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

/// Parent/Student Overview Screen (`ภาพรวม`):
/// 1) Clean Student Header (no notification bell)
/// 2) Hero Peace-of-Mind Arrival Card with ambient emerald glow
/// 3) Weekly Habit Strip (5-day fitness-style cards + summary ticker)
/// 4) Today's Timeline (`ไทม์ไลน์วันนี้` - titles & times only)
/// 5) One-Tap Leave Request Card (no teacher call card)
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
        ? 'ชั้น ม.${record.classroom.grade}/${record.classroom.room} • เลขประจำตัว ${ThaiFormat.maskStudentId(record.studentId)}'
        : session != null
        ? 'ชั้น ม.${session.classroom.grade}/${session.classroom.room} • เลขประจำตัว ${ThaiFormat.maskStudentId(session.studentId)}'
        : 'โรงเรียนขุนยวมวิทยา';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: <Widget>[
          _StudentHeader(
            inset: inset,
            studentName: studentName,
            subtitle: subtitle,
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.brandPrimary,
              onRefresh: controller.loadParentData,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(
                  top: AppSpacing.space4,
                  bottom: 104,
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
                                todayDate: controller.todayDate,
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
  });

  final double inset;
  final String studentName;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        border: const Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
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
              Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  StudentAvatar(fullName: studentName, size: 46),
                  Positioned(
                    bottom: -1,
                    right: -1,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: const Color(0xFF047857),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Center(
                        child: Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
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
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 1),
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
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroStatusCard extends StatelessWidget {
  const _HeroStatusCard({required this.entry, required this.todayDate});

  final DailyAttendanceEntry entry;
  final DateTime todayDate;

  @override
  Widget build(BuildContext context) {
    final isPresent = entry.status == AttendanceStatus.present;
    final isLate = entry.status == AttendanceStatus.late;

    final Color cardBorder = switch (entry.status) {
      AttendanceStatus.present => const Color(0xFFA7F3D0),
      AttendanceStatus.late => const Color(0xFFFDE68A),
      _ => const Color(0xFFE2E8F0),
    };

    final List<Color> badgeGradient = switch (entry.status) {
      AttendanceStatus.present => const <Color>[
        Color(0xFF047857),
        Color(0xFF0D9488),
      ],
      AttendanceStatus.late => const <Color>[
        Color(0xFFD97706),
        Color(0xFFF59E0B),
      ],
      _ => const <Color>[Color(0xFF64748B), Color(0xFF94A3B8)],
    };

    final IconData badgeIcon = switch (entry.status) {
      AttendanceStatus.present => Icons.check_circle_rounded,
      _ => entry.status.icon,
    };

    final Color pillBg = switch (entry.status) {
      AttendanceStatus.present => const Color(0xFFECFDF5),
      AttendanceStatus.late => const Color(0xFFFFFBEB),
      _ => const Color(0xFFF1F5F9),
    };
    final Color pillBorder = switch (entry.status) {
      AttendanceStatus.present => const Color(0xFFA7F3D0),
      AttendanceStatus.late => const Color(0xFFFDE68A),
      _ => const Color(0xFFE2E8F0),
    };
    final Color pillDot = switch (entry.status) {
      AttendanceStatus.present => const Color(0xFF047857),
      AttendanceStatus.late => const Color(0xFFD97706),
      _ => const Color(0xFF64748B),
    };
    final Color pillFg = switch (entry.status) {
      AttendanceStatus.present => const Color(0xFF065F46),
      AttendanceStatus.late => const Color(0xFF92400E),
      _ => const Color(0xFF334155),
    };

    final scanTime = entry.firstScanAt != null
        ? ThaiFormat.time24Nbsp(entry.firstScanAt!)
        : null;

    final String pillText = switch (entry.status) {
      AttendanceStatus.present =>
        scanTime != null ? 'ตรงเวลา • สแกน $scanTime' : 'ตรงเวลา',
      AttendanceStatus.late =>
        scanTime != null ? 'มาสาย • สแกน $scanTime' : 'มาสาย',
      _ => entry.status.label,
    };

    final String headlineText = switch (entry.status) {
      AttendanceStatus.present => 'ถึงโรงเรียนเรียบร้อยแล้ว',
      AttendanceStatus.late => 'สแกนเข้าเรียนแล้ว (สาย)',
      AttendanceStatus.pending => 'รอสแกนเข้าเรียน',
      AttendanceStatus.absent => 'ไม่พบข้อมูลการเข้าเรียนวันนี้',
      AttendanceStatus.leave => 'บันทึกการลาเรียนเรียบร้อยแล้ว',
      AttendanceStatus.unknown => 'อยู่ระหว่างตรวจสอบข้อมูล',
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

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardBorder, width: 1.2),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: <Widget>[
            if (isPresent)
              Positioned(
                bottom: -40,
                right: -40,
                child: IgnorePointer(
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: <Color>[
                          const Color(0xFF10B981).withValues(alpha: 0.12),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: pillBg,
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(color: pillBorder),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: pillDot,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  pillText,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.microLabel.copyWith(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: pillFg,
                                    fontFeatures: const <FontFeature>[
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        ThaiFormat.shortDate(todayDate),
                        style: AppTypography.microLabel.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomLeft,
                            end: Alignment.topRight,
                            colors: badgeGradient,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color:
                                  (isLate
                                          ? const Color(0xFFD97706)
                                          : const Color(0xFF064E3B))
                                      .withValues(alpha: 0.20),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(badgeIcon, size: 30, color: Colors.white),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              headlineText,
                              style: AppTypography.sectionTitle.copyWith(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subtitleText,
                              style: AppTypography.supporting.copyWith(
                                fontSize: 12.5,
                                color: const Color(0xFF475569),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
    final onTimePct = recordedTotal > 0
        ? ((summary.presentCount / recordedTotal) * 100).round()
        : 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Expanded(
                child: Text(
                  'การเข้าเรียนสัปดาห์นี้',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.sectionTitle.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: Text(
                  '$onTimePct% ตรงเวลา',
                  style: AppTypography.microLabel.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF065F46),
                    fontFeatures: const <FontFeature>[
                      FontFeature.tabularFigures(),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 5-day fitness-style habit grid
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
          const SizedBox(height: 12),

          const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.space2,
            runSpacing: 4,
            children: <Widget>[
              Text(
                'เข้าเรียนสัปดาห์นี้ $attendedDays/$recordedTotal วัน',
                style: AppTypography.supporting.copyWith(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF334155),
                ),
              ),
              Text.rich(
                TextSpan(
                  style: AppTypography.microLabel.copyWith(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                  ),
                  children: <InlineSpan>[
                    const TextSpan(text: 'สาย '),
                    TextSpan(
                      text: '${summary.lateCount}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF92400E),
                      ),
                    ),
                    const TextSpan(text: ' • ขาด '),
                    TextSpan(
                      text: '${summary.absentCount}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFDC2626),
                      ),
                    ),
                    const TextSpan(text: ' • ลา '),
                    TextSpan(
                      text: '${summary.leaveCount}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1D4ED8),
                      ),
                    ),
                  ],
                ),
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
    final isEmptyDay = status == null;

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
      detailText = '-';
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFECFDF5) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? const Color(0xFF059669) : const Color(0xFFE2E8F0),
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
                fontSize: 12,
                color: isActive
                    ? const Color(0xFF064E3B)
                    : const Color(0xFF334155),
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 6),
          if (isEmptyDay)
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: Color(0xFFE2E8F0),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF64748B),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            )
          else
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: status == AttendanceStatus.present
                    ? const Color(0xFF047857)
                    : status == AttendanceStatus.late
                    ? const Color(0xFFD97706)
                    : const Color(0xFF64748B),
                shape: BoxShape.circle,
              ),
              child: Icon(
                status == AttendanceStatus.present
                    ? Icons.check_rounded
                    : status.icon,
                size: 16,
                color: Colors.white,
              ),
            ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              detailText,
              style: AppTypography.microLabel.copyWith(
                fontSize: 11.5,
                color: isActive
                    ? const Color(0xFF065F46)
                    : const Color(0xFF64748B),
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
              ),
            ),
          ),
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

    final bool homeroomDone = hasCheckIn;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'ไทม์ไลน์วันนี้',
            style: AppTypography.sectionTitle.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 14),

          Stack(
            children: <Widget>[
              Positioned(
                left: 13,
                top: 14,
                bottom: 14,
                child: Container(width: 2, color: const Color(0xFFE2E8F0)),
              ),
              Column(
                children: <Widget>[
                  _TimelineStepRow(
                    icon: Icons.sensors_rounded,
                    isCompleted: hasCheckIn,
                    title: 'สแกนเข้าโรงเรียน',
                    trailingText: checkInRightText,
                    isPillTrailing: !hasCheckIn,
                  ),
                  const SizedBox(height: 14),
                  _TimelineStepRow(
                    icon: Icons.flag_rounded,
                    isCompleted: homeroomDone,
                    title: 'เข้าแถวเคารพธงชาติ & โฮมรูม',
                    trailingText: homeroomDone
                        ? '08:00\u00A0น.'
                        : 'รอดำเนินการ',
                    isPillTrailing: !homeroomDone,
                  ),
                  const SizedBox(height: 14),
                  const _TimelineStepRow(
                    icon: Icons.meeting_room_outlined,
                    isCompleted: false,
                    title: 'สแกนออกจากโรงเรียน',
                    trailingText: 'รอดำเนินการ',
                    isPillTrailing: true,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimelineStepRow extends StatelessWidget {
  const _TimelineStepRow({
    required this.icon,
    required this.isCompleted,
    required this.title,
    required this.trailingText,
    required this.isPillTrailing,
  });

  final IconData icon;
  final bool isCompleted;
  final String title;
  final String trailingText;
  final bool isPillTrailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isCompleted
                ? const Color(0xFF047857)
                : const Color(0xFFE2E8F0),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Icon(
            icon,
            size: 14,
            color: isCompleted ? Colors.white : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: AppTypography.bodyStrong.copyWith(
              fontSize: 14,
              fontWeight: isCompleted ? FontWeight.w600 : FontWeight.w500,
              color: isCompleted
                  ? const Color(0xFF0F172A)
                  : const Color(0xFF475569),
            ),
          ),
        ),
        const SizedBox(width: 8),
        if (isPillTrailing)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8E4)),
            ),
            child: Text(
              trailingText,
              style: AppTypography.microLabel.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF475569),
              ),
            ),
          )
        else
          Text(
            trailingText,
            style: AppTypography.bodyStrong.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF065F46),
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
      ],
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFA7F3D0)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
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
            padding: const EdgeInsets.all(16),
            child: Row(
              children: <Widget>[
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.bottomLeft,
                      end: Alignment.topRight,
                      colors: <Color>[Color(0xFF065F46), Color(0xFF0F766E)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: const Color(0xFF064E3B).withValues(alpha: 0.16),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.edit_calendar_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'แจ้งลาเรียนล่วงหน้า',
                        style: AppTypography.bodyStrong.copyWith(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'ส่งคำขอลาป่วยหรือลากิจถึงครูที่ปรึกษาออนไลน์',
                        style: AppTypography.microLabel.copyWith(
                          fontSize: 12,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: Color(0xFF065F46),
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
