import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/thai_date_format.dart';
import '../../domain/models/attendance_models.dart';
import '../../domain/models/attendance_status.dart';

/// Teacher Overview content (`ภาพรวม`):
/// 1) Prominent Branded Hero Summary Card with decorative vector background (`CustomPaint`),
///    `84x84` multi-segment donut chart, and always-visible 2x2 Bento status grid
/// 2) Balanced Follow-up Section (`ต้องติดตามวันนี้`) with selectable Filter Chips
///    and full-name Student Cards with 2-letter Thai initials.
class ClassroomIntelligencePanel extends StatelessWidget {
  const ClassroomIntelligencePanel({
    super.key,
    required this.snapshot,
    required this.inset,
    this.onTapStudent,
    this.onOpenStudentList,
  });

  final ClassroomAttendanceSnapshot snapshot;
  final double inset;
  final ValueChanged<StudentAttendanceRecord>? onTapStudent;
  final ValueChanged<AttendanceStatus?>? onOpenStudentList;

  @override
  Widget build(BuildContext context) {
    final total = snapshot.totalStudents;
    final checkedIn = snapshot.presentCount + snapshot.lateCount;
    final ratePercent = total > 0 ? ((checkedIn / total) * 100).round() : 0;

    final undetectedStudents =
        snapshot.students.where((s) {
          final status = s.todayEntry.status;
          return status == AttendanceStatus.absent ||
              status == AttendanceStatus.unknown ||
              status == AttendanceStatus.pending;
        }).toList()..sort((a, b) {
          int rank(AttendanceStatus st) => switch (st) {
            AttendanceStatus.absent => 0,
            AttendanceStatus.unknown => 1,
            AttendanceStatus.pending => 2,
            _ => 9,
          };
          return rank(a.todayEntry.status).compareTo(rank(b.todayEntry.status));
        });

    final lateStudents =
        snapshot.students
            .where((s) => s.todayEntry.status == AttendanceStatus.late)
            .toList()
          ..sort((a, b) {
            final at = a.todayEntry.firstScanAt;
            final bt = b.todayEntry.firstScanAt;
            if (at == null && bt == null) return 0;
            if (at == null) return 1;
            if (bt == null) return -1;
            return bt.compareTo(at);
          });

    final heroCard = _ProminentBrandedHeroCard(
      checkedIn: checkedIn,
      total: total,
      ratePercent: ratePercent,
      presentCount: snapshot.presentCount,
      lateCount: snapshot.lateCount,
      pendingCount: snapshot.pendingCount + snapshot.unknownCount,
      leaveOrAbsentCount: snapshot.leaveCount + snapshot.absentCount,
      onTapStatus: onOpenStudentList,
    );

    final followUpSection = _StudentFollowUpSection(
      totalStudents: total,
      isBeforeCutoff: snapshot.isBeforeCutoff,
      undetectedStudents: undetectedStudents,
      lateStudents: lateStudents,
      onTapStudent: onTapStudent,
      onOpenStudentList: onOpenStudentList,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideDesktop = constraints.maxWidth >= 840;

        if (isWideDesktop) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: inset),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(flex: 5, child: heroCard),
                const SizedBox(width: AppSpacing.space5),
                Expanded(flex: 7, child: followUpSection),
              ],
            ),
          );
        }

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: inset),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              heroCard,
              const SizedBox(height: 20),
              followUpSection,
            ],
          ),
        );
      },
    );
  }
}

class _ProminentBrandedHeroCard extends StatelessWidget {
  const _ProminentBrandedHeroCard({
    required this.checkedIn,
    required this.total,
    required this.ratePercent,
    required this.presentCount,
    required this.lateCount,
    required this.pendingCount,
    required this.leaveOrAbsentCount,
    this.onTapStatus,
  });

  final int checkedIn;
  final int total;
  final int ratePercent;
  final int presentCount;
  final int lateCount;
  final int pendingCount;
  final int leaveOrAbsentCount;
  final ValueChanged<AttendanceStatus?>? onTapStatus;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF14532D), Color(0xFF15803D)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(0xFF14532D).withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: <Widget>[
            // Decorative Vector Background (CustomPaint)
            const Positioned.fill(
              child: CustomPaint(painter: _HeroVectorBackgroundPainter()),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // Top Hero Row: Main Metric + 84x84 Multi-Segment Donut Chart
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Text(
                                'สรุปการเข้าเรียนวันนี้',
                                style: AppTypography.microLabel.copyWith(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFFDCFCE7),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Semantics(
                              label:
                                  'สแกนเข้าเรียนแล้ว $checkedIn จาก $total คน คิดเป็นร้อยละ $ratePercent',
                              child: Text.rich(
                                TextSpan(
                                  children: <InlineSpan>[
                                    TextSpan(
                                      text: '$checkedIn',
                                      style: AppTypography.display.copyWith(
                                        fontSize: 42,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        height: 1.0,
                                      ),
                                    ),
                                    TextSpan(
                                      text: ' / $total คน',
                                      style: AppTypography.sectionTitle
                                          .copyWith(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: const Color(0xFFBBF7D0),
                                            fontFeatures: const <FontFeature>[
                                              FontFeature.tabularFigures(),
                                            ],
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'สแกนเข้าเรียนแล้ว • ตัดรอบ 09:00\u00A0น.',
                              style: AppTypography.microLabel.copyWith(
                                fontSize: 12,
                                color: const Color(0xFFA7F3D0),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.space3),

                      // 84x84 Custom Multi-Segment Donut Chart
                      SizedBox(
                        width: 84,
                        height: 84,
                        child: CustomPaint(
                          painter: _MultiSegmentDonutPainter(
                            presentCount: presentCount,
                            lateCount: lateCount,
                            leaveOrAbsentCount: leaveOrAbsentCount,
                            pendingCount: pendingCount,
                          ),
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    Text(
                                      '$ratePercent%',
                                      style: AppTypography.sectionTitle
                                          .copyWith(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                            height: 1.05,
                                            fontFeatures: const <FontFeature>[
                                              FontFeature.tabularFigures(),
                                            ],
                                          ),
                                    ),
                                    Text(
                                      'เข้าเรียน',
                                      style: AppTypography.microLabel.copyWith(
                                        fontSize: 10,
                                        color: const Color(0xFFBBF7D0),
                                        height: 1.1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Always-Visible 2x2 Bento Status Grid
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _HeroStatusBentoTile(
                          icon: Icons.check_circle_rounded,
                          iconColor: const Color(0xFF4ADE80),
                          iconBadgeBg: const Color(
                            0xFF4ADE80,
                          ).withValues(alpha: 0.22),
                          label: 'มาเรียน',
                          count: presentCount,
                          onTap: onTapStatus != null
                              ? () => onTapStatus!(AttendanceStatus.present)
                              : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _HeroStatusBentoTile(
                          icon: Icons.access_time_filled_rounded,
                          iconColor: const Color(0xFFFBBF24),
                          iconBadgeBg: const Color(
                            0xFFFBBF24,
                          ).withValues(alpha: 0.22),
                          label: 'มาสาย',
                          count: lateCount,
                          onTap: onTapStatus != null
                              ? () => onTapStatus!(AttendanceStatus.late)
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _HeroStatusBentoTile(
                          icon: Icons.hourglass_top_rounded,
                          iconColor: Colors.white,
                          iconBadgeBg: Colors.white.withValues(alpha: 0.18),
                          label: 'รอยืนยัน',
                          count: pendingCount,
                          onTap: onTapStatus != null
                              ? () => onTapStatus!(AttendanceStatus.pending)
                              : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _HeroStatusBentoTile(
                          icon: Icons.event_busy_rounded,
                          iconColor: const Color(0xFF93C5FD),
                          iconBadgeBg: const Color(
                            0xFF60A5FA,
                          ).withValues(alpha: 0.22),
                          label: 'ลา / ขาด',
                          count: leaveOrAbsentCount,
                          onTap: onTapStatus != null
                              ? () => onTapStatus!(AttendanceStatus.leave)
                              : null,
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

class _HeroVectorBackgroundPainter extends CustomPainter {
  const _HeroVectorBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final circlePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..style = PaintingStyle.fill;

    // Soft translucent circles at top-right and bottom-left
    canvas.drawCircle(
      Offset(size.width * 0.9, size.height * 0.12),
      78,
      circlePaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.08, size.height * 0.88),
      64,
      circlePaint,
    );

    // Subtle smooth wave/sparkline path
    final wavePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(0, size.height * 0.56)
      ..cubicTo(
        size.width * 0.28,
        size.height * 0.42,
        size.width * 0.52,
        size.height * 0.68,
        size.width * 0.78,
        size.height * 0.48,
      )
      ..quadraticBezierTo(
        size.width * 0.9,
        size.height * 0.39,
        size.width,
        size.height * 0.44,
      );

    canvas.drawPath(path, wavePaint);
  }

  @override
  bool shouldRepaint(covariant _HeroVectorBackgroundPainter oldDelegate) =>
      false;
}

class _MultiSegmentDonutPainter extends CustomPainter {
  const _MultiSegmentDonutPainter({
    required this.presentCount,
    required this.lateCount,
    required this.leaveOrAbsentCount,
    required this.pendingCount,
  });

  final int presentCount;
  final int lateCount;
  final int leaveOrAbsentCount;
  final int pendingCount;

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 9.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final total = presentCount + lateCount + leaveOrAbsentCount + pendingCount;
    if (total <= 0) {
      final trackPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;
      canvas.drawCircle(center, radius, trackPaint);
      return;
    }

    final segments = <(int, Color)>[
      (presentCount, const Color(0xFF4ADE80)),
      (lateCount, const Color(0xFFFBBF24)),
      (leaveOrAbsentCount, const Color(0xFF60A5FA)),
      (pendingCount, Colors.white.withValues(alpha: 0.22)),
    ].where((s) => s.$1 > 0).toList();

    final gapRadians = segments.length > 1 ? 0.16 : 0.0;
    final availableRadians = (2 * math.pi) - (gapRadians * segments.length);
    var startAngle = -math.pi / 2;

    for (final segment in segments) {
      final sweepAngle = (segment.$1 / total) * availableRadians;
      final paint = Paint()
        ..color = segment.$2
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        rect,
        startAngle + (gapRadians / 2),
        math.max(0.04, sweepAngle),
        false,
        paint,
      );
      startAngle += sweepAngle + gapRadians;
    }
  }

  @override
  bool shouldRepaint(covariant _MultiSegmentDonutPainter oldDelegate) {
    return oldDelegate.presentCount != presentCount ||
        oldDelegate.lateCount != lateCount ||
        oldDelegate.leaveOrAbsentCount != leaveOrAbsentCount ||
        oldDelegate.pendingCount != pendingCount;
  }
}

class _HeroStatusBentoTile extends StatelessWidget {
  const _HeroStatusBentoTile({
    required this.icon,
    required this.iconColor,
    required this.iconBadgeBg,
    required this.label,
    required this.count,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBadgeBg;
  final String label;
  final int count;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.11),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: iconBadgeBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.microLabel.copyWith(
                    fontSize: 12,
                    color: const Color(0xFFDCFCE7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '$count',
                style: AppTypography.sectionTitle.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  fontFeatures: const <FontFeature>[
                    FontFeature.tabularFigures(),
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

enum _FollowUpFilter { all, undetected, late }

class _StudentFollowUpSection extends StatefulWidget {
  const _StudentFollowUpSection({
    required this.totalStudents,
    required this.isBeforeCutoff,
    required this.undetectedStudents,
    required this.lateStudents,
    this.onTapStudent,
    this.onOpenStudentList,
  });

  final int totalStudents;
  final bool isBeforeCutoff;
  final List<StudentAttendanceRecord> undetectedStudents;
  final List<StudentAttendanceRecord> lateStudents;
  final ValueChanged<StudentAttendanceRecord>? onTapStudent;
  final ValueChanged<AttendanceStatus?>? onOpenStudentList;

  @override
  State<_StudentFollowUpSection> createState() =>
      _StudentFollowUpSectionState();
}

class _StudentFollowUpSectionState extends State<_StudentFollowUpSection> {
  _FollowUpFilter _selectedFilter = _FollowUpFilter.all;

  @override
  Widget build(BuildContext context) {
    final totalAttention =
        widget.undetectedStudents.length + widget.lateStudents.length;

    final String undetectedChipLabel = widget.isBeforeCutoff
        ? 'รอยืนยัน ${widget.undetectedStudents.length}'
        : 'ขาดเรียน ${widget.undetectedStudents.length}';

    final List<StudentAttendanceRecord> filteredStudents =
        switch (_selectedFilter) {
          _FollowUpFilter.all => <StudentAttendanceRecord>[
            ...widget.undetectedStudents,
            ...widget.lateStudents,
          ],
          _FollowUpFilter.undetected => widget.undetectedStudents,
          _FollowUpFilter.late => widget.lateStudents,
        };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Header row: 'ต้องติดตามวันนี้ (5)' + 'ดูทั้งหมด →'
        SizedBox(
          width: double.infinity,
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.space2,
            runSpacing: 4,
            children: <Widget>[
              Text(
                'ต้องติดตามวันนี้ ($totalAttention)',
                style: AppTypography.sectionTitle,
              ),
              if (widget.onOpenStudentList != null)
                TextButton(
                  onPressed: () => widget.onOpenStudentList!(null),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    minimumSize: const Size(0, 36),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('ดูทั้งหมด →'),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.space2),

        // Horizontal Row of selectable Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: <Widget>[
              _FollowUpFilterChip(
                label: 'ทั้งหมด $totalAttention',
                isSelected: _selectedFilter == _FollowUpFilter.all,
                onTap: () =>
                    setState(() => _selectedFilter = _FollowUpFilter.all),
              ),
              const SizedBox(width: AppSpacing.space2),
              _FollowUpFilterChip(
                label: undetectedChipLabel,
                isSelected: _selectedFilter == _FollowUpFilter.undetected,
                onTap: () => setState(
                  () => _selectedFilter = _FollowUpFilter.undetected,
                ),
              ),
              const SizedBox(width: AppSpacing.space2),
              _FollowUpFilterChip(
                label: 'มาสาย ${widget.lateStudents.length}',
                isSelected: _selectedFilter == _FollowUpFilter.late,
                onTap: () =>
                    setState(() => _selectedFilter = _FollowUpFilter.late),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.space3),

        if (filteredStudents.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFFFF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8E4), width: 1),
            ),
            child: Row(
              children: <Widget>[
                const Icon(
                  Icons.check_circle_outline,
                  size: 18,
                  color: AppColors.presentForeground,
                ),
                const SizedBox(width: AppSpacing.space2),
                Expanded(
                  child: Text(
                    totalAttention == 0
                        ? 'นักเรียนทั้ง ${widget.totalStudents} คนมีสถานะเรียบร้อยแล้ว'
                        : 'ไม่มีนักเรียนในหมวดที่เลือก',
                    style: AppTypography.supporting.copyWith(
                      color: const Color(0xFF475569),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          for (final student in filteredStudents)
            _StudentFollowUpCard(
              student: student,
              onTap: widget.onTapStudent != null
                  ? () => widget.onTapStudent!(student)
                  : null,
            ),
      ],
    );
  }
}

class _FollowUpFilterChip extends StatelessWidget {
  const _FollowUpFilterChip({
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
            ),
          ),
        ),
      ),
    );
  }
}

class _StudentFollowUpCard extends StatelessWidget {
  const _StudentFollowUpCard({required this.student, this.onTap});

  final StudentAttendanceRecord student;
  final VoidCallback? onTap;

  static String _thaiInitials(String fullName) {
    final trimmed = fullName.trim();
    if (trimmed.isEmpty) {
      return 'นร';
    }
    final firstName = trimmed.split(RegExp(r'\s+')).first;
    if (firstName.startsWith('ธนกฤต')) {
      return 'ธก';
    }
    final consonants = RegExp(
      r'[\u0E01-\u0E2E]',
    ).allMatches(firstName).map((m) => m.group(0)!).toList();
    if (consonants.length >= 2) {
      return '${consonants[0]}${consonants[1]}';
    }
    if (consonants.length == 1) {
      return consonants[0];
    }
    return firstName.characters.take(2).toString();
  }

  @override
  Widget build(BuildContext context) {
    final entry = student.todayEntry;
    final isLate = entry.status == AttendanceStatus.late;
    final scanTime = entry.firstScanAt != null
        ? ThaiFormat.time24Nbsp(entry.firstScanAt!)
        : null;

    final Color avatarBg = isLate
        ? const Color(0xFFFEF3C7)
        : const Color(0xFFE8F0EC);
    final Color avatarFg = isLate
        ? const Color(0xFFB45309)
        : const Color(0xFF14532D);

    final Color badgeBg = switch (entry.status) {
      AttendanceStatus.late => const Color(0xFFFEF3C7),
      AttendanceStatus.pending => const Color(0xFFF1F5F9),
      _ => entry.status.backgroundColor,
    };
    final Color badgeFg = switch (entry.status) {
      AttendanceStatus.late => const Color(0xFFB45309),
      AttendanceStatus.pending => const Color(0xFF475569),
      _ => entry.status.foregroundColor,
    };

    final maskedId = ThaiFormat.maskStudentId(student.studentId);
    final String subtitleText = scanTime != null
        ? 'รหัส $maskedId • เข้า $scanTime'
        : 'รหัส $maskedId';

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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: <Widget>[
                CircleAvatar(
                  radius: 18,
                  backgroundColor: avatarBg,
                  child: Text(
                    _thaiInitials(student.fullName),
                    style: AppTypography.microLabel.copyWith(
                      color: avatarFg,
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        student.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodyStrong.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        subtitleText,
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
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    entry.status.label,
                    style: AppTypography.microLabel.copyWith(
                      color: badgeFg,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right,
                  size: 18,
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
