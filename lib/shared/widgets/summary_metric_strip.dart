import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/thai_date_format.dart';
import '../../domain/models/attendance_models.dart';
import '../../domain/models/attendance_status.dart';

/// Teacher Overview content (`ภาพรวม`):
/// 1) Clean White Hero Bento Card with crisp percentage badge, iOS-style segmented
///    horizontal bar, and high-contrast 2x2 light-surface metric grid
/// 2) Follow-up Section (`ต้องติดตามวันนี้`) with selectable Filter Chips
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

    final heroCard = _WhiteHeroBentoCard(
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

class _WhiteHeroBentoCard extends StatelessWidget {
  const _WhiteHeroBentoCard({
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
    final segments = <(int, Color)>[
      (presentCount, const Color(0xFF16A34A)),
      (lateCount, const Color(0xFFF59E0B)),
      (leaveOrAbsentCount, const Color(0xFF3B82F6)),
      (pendingCount, const Color(0xFFE2E8F0)),
    ].where((s) => s.$1 > 0).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8E4), width: 1),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // 1. Top Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'สแกนเข้าเรียนแล้ว',
                      style: AppTypography.supporting.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Semantics(
                      label:
                          'สแกนเข้าเรียนแล้ว $checkedIn จาก $total คน คิดเป็นร้อยละ $ratePercent',
                      child: Text.rich(
                        TextSpan(
                          children: <InlineSpan>[
                            TextSpan(
                              text: '$checkedIn',
                              style: AppTypography.display.copyWith(
                                fontSize: 40,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0F172A),
                                height: 1.05,
                              ),
                            ),
                            TextSpan(
                              text: ' / $total คน',
                              style: AppTypography.sectionTitle.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF64748B),
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
                      'ตัดรอบเวลา 09:00\u00A0น.',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.microLabel.copyWith(
                        fontSize: 12,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.space3),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$ratePercent%',
                  style: AppTypography.sectionTitle.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF15803D),
                    fontFeatures: const <FontFeature>[
                      FontFeature.tabularFigures(),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 2. iOS-Style Segmented Horizontal Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: SizedBox(
              height: 10,
              child: segments.isEmpty
                  ? Container(color: const Color(0xFFE2E8F0))
                  : Row(
                      children: <Widget>[
                        for (var i = 0; i < segments.length; i++) ...<Widget>[
                          Expanded(
                            flex: segments[i].$1,
                            child: Container(color: segments[i].$2),
                          ),
                          if (i < segments.length - 1)
                            Container(width: 2, color: Colors.white),
                        ],
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 16),

          // 3. Crisp 2x2 Metric Grid
          Row(
            children: <Widget>[
              Expanded(
                child: _MetricGridCell(
                  dotColor: const Color(0xFF16A34A),
                  label: 'มาเรียน',
                  count: presentCount,
                  onTap: onTapStatus != null
                      ? () => onTapStatus!(AttendanceStatus.present)
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MetricGridCell(
                  dotColor: const Color(0xFFF59E0B),
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
                child: _MetricGridCell(
                  dotColor: const Color(0xFF94A3B8),
                  label: 'รอยืนยัน',
                  count: pendingCount,
                  onTap: onTapStatus != null
                      ? () => onTapStatus!(AttendanceStatus.pending)
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MetricGridCell(
                  dotColor: const Color(0xFF3B82F6),
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
    );
  }
}

class _MetricGridCell extends StatelessWidget {
  const _MetricGridCell({
    required this.dotColor,
    required this.label,
    required this.count,
    this.onTap,
  });

  final Color dotColor;
  final String label;
  final int count;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFF1F5F9)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Expanded(
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: dotColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.supporting.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF475569),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '$count',
                style: AppTypography.sectionTitle.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
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
