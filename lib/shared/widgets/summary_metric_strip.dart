import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/thai_date_format.dart';
import '../../domain/models/attendance_models.dart';
import '../../domain/models/attendance_status.dart';

/// Teacher Overview content:
/// 1) Single White Summary Card (with inline percentage pill, 2-color progress bar, and 4-item legend)
/// 2) Student Follow-up List with individual White Cards, 2-letter Thai initials CircleAvatar,
///    and stadium status pills.
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

    final String phaseLabel;
    if (snapshot.syncMetadata.freshness == SyncFreshness.unavailable) {
      phaseLabel = 'รอข้อมูลซิงก์ล่าสุด';
    } else if (snapshot.isBeforeCutoff) {
      phaseLabel = 'ก่อนตัดรอบ 09:00\u00A0น.';
    } else {
      phaseLabel = 'สรุปผลประจำวันแล้ว';
    }

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

    final fourColumnItems = <_DistributionItem>[
      _DistributionItem(AttendanceStatus.present, snapshot.presentCount),
      _DistributionItem(AttendanceStatus.late, snapshot.lateCount),
      if (snapshot.unknownCount > 0)
        _DistributionItem(AttendanceStatus.unknown, snapshot.unknownCount)
      else if (snapshot.isBeforeCutoff || snapshot.pendingCount > 0)
        _DistributionItem(AttendanceStatus.pending, snapshot.pendingCount)
      else
        _DistributionItem(AttendanceStatus.absent, snapshot.absentCount),
      _DistributionItem(AttendanceStatus.leave, snapshot.leaveCount),
    ];

    final summaryCard = _TeacherSummaryCard(
      checkedIn: checkedIn,
      total: total,
      ratePercent: ratePercent,
      phaseLabel: phaseLabel,
      items: fourColumnItems,
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
                Expanded(flex: 5, child: summaryCard),
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
              summaryCard,
              const SizedBox(height: AppSpacing.space5),
              followUpSection,
            ],
          ),
        );
      },
    );
  }
}

class _DistributionItem {
  const _DistributionItem(this.status, this.count);

  final AttendanceStatus status;
  final int count;
}

class _TeacherSummaryCard extends StatelessWidget {
  const _TeacherSummaryCard({
    required this.checkedIn,
    required this.total,
    required this.ratePercent,
    required this.phaseLabel,
    required this.items,
    this.onTapStatus,
  });

  final int checkedIn;
  final int total;
  final int ratePercent;
  final String phaseLabel;
  final List<_DistributionItem> items;
  final ValueChanged<AttendanceStatus?>? onTapStatus;

  @override
  Widget build(BuildContext context) {
    final remaining = (total - checkedIn).clamp(0, total);

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
            'สแกนเข้าโรงเรียนแล้ว',
            style: AppTypography.supporting.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpacing.space1),

          // Main metric row with '58%' soft green pill aligned inline on the same row as '7 จาก 12 คน'
          Semantics(
            label:
                'สแกนเข้าโรงเรียนแล้ว $checkedIn จาก $total คน คิดเป็นร้อยละ $ratePercent',
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Expanded(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.end,
                    spacing: AppSpacing.space2,
                    runSpacing: 2,
                    children: <Widget>[
                      Text(
                        '$checkedIn',
                        style: AppTypography.display.copyWith(
                          fontSize: 44,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          'จาก $total คน',
                          style: AppTypography.sectionTitle.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                            fontFeatures: const <FontFeature>[
                              FontFeature.tabularFigures(),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          '• $phaseLabel',
                          style: AppTypography.microLabel,
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
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    '$ratePercent%',
                    style: AppTypography.supporting.copyWith(
                      color: const Color(0xFF15803D),
                      fontWeight: FontWeight.w700,
                      fontFeatures: const <FontFeature>[
                        FontFeature.tabularFigures(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.space3),

          // Simplified 2-color rounded progress bar (height: 8, borderRadius: 99)
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: SizedBox(
              height: 8,
              child: Row(
                children: <Widget>[
                  if (checkedIn > 0)
                    Expanded(
                      flex: checkedIn,
                      child: Container(color: const Color(0xFF16A34A)),
                    ),
                  if (remaining > 0)
                    Expanded(
                      flex: remaining,
                      child: Container(color: const Color(0xFFE2E8E4)),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.space3),

          // 4 status counts in a clean row inside the same card
          IntrinsicHeight(
            child: Row(
              children: <Widget>[
                for (var i = 0; i < items.length; i++) ...<Widget>[
                  Expanded(
                    child: _CompactDistributionColumn(
                      item: items[i],
                      onTap: onTapStatus != null
                          ? () => onTapStatus!(items[i].status)
                          : null,
                    ),
                  ),
                  if (i < items.length - 1)
                    const VerticalDivider(
                      width: AppSpacing.space3,
                      thickness: 1,
                      color: Color(0xFFE2E8E4),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactDistributionColumn extends StatelessWidget {
  const _CompactDistributionColumn({required this.item, this.onTap});

  final _DistributionItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.badge),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: item.status.foregroundColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                item.status.label,
                style: AppTypography.microLabel.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                '${item.count}',
                style: AppTypography.bodyStrong.copyWith(
                  color: AppColors.textPrimary,
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

class _StudentFollowUpSection extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final totalAttention = undetectedStudents.length + lateStudents.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: double.infinity,
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.space2,
            runSpacing: 4,
            children: <Widget>[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Flexible(
                    child: Text(
                      'ต้องติดตามวันนี้',
                      style: AppTypography.sectionTitle,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space2),
                  Text(
                    '$totalAttention คน',
                    style: AppTypography.supporting.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              if (onOpenStudentList != null)
                TextButton(
                  onPressed: () => onOpenStudentList!(null),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    minimumSize: const Size(0, 36),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('ดูรายชื่อทั้งหมด →'),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.space3),

        if (totalAttention == 0)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
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
                    'นักเรียนทั้ง $totalStudents คนมีสถานะเรียบร้อยแล้ว',
                    style: AppTypography.supporting.copyWith(
                      color: AppColors.presentForeground,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          )
        else ...<Widget>[
          if (undetectedStudents.isNotEmpty) ...<Widget>[
            _FollowUpGroupHeader(
              label: isBeforeCutoff
                  ? 'ยังไม่พบการสแกน — ${undetectedStudents.length} คน'
                  : 'ไม่พบการเข้าเรียน — ${undetectedStudents.length} คน',
              color: isBeforeCutoff
                  ? const Color(0xFF475569)
                  : AppColors.absentForeground,
            ),
            const SizedBox(height: AppSpacing.space2),
            for (final student in undetectedStudents)
              _StudentFollowUpCard(
                student: student,
                onTap: onTapStudent != null
                    ? () => onTapStudent!(student)
                    : null,
              ),
          ],

          if (undetectedStudents.isNotEmpty && lateStudents.isNotEmpty)
            const SizedBox(height: AppSpacing.space3),

          if (lateStudents.isNotEmpty) ...<Widget>[
            _FollowUpGroupHeader(
              label: 'มาสายวันนี้ — ${lateStudents.length} คน',
              color: const Color(0xFFB45309),
            ),
            const SizedBox(height: AppSpacing.space2),
            for (final student in lateStudents)
              _StudentFollowUpCard(
                student: student,
                onTap: onTapStudent != null
                    ? () => onTapStudent!(student)
                    : null,
              ),
          ],
        ],
      ],
    );
  }
}

class _FollowUpGroupHeader extends StatelessWidget {
  const _FollowUpGroupHeader({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: AppTypography.microLabel.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        student.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodyStrong,
                      ),
                      Text(
                        'รหัส ${ThaiFormat.maskStudentId(student.studentId)}',
                        style: AppTypography.microLabel,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.space2),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 136),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        if (scanTime != null) ...<Widget>[
                          Text(
                            scanTime,
                            style: AppTypography.supporting.copyWith(
                              color: const Color(0xFFB45309),
                              fontWeight: FontWeight.w600,
                              fontFeatures: const <FontFeature>[
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.space2),
                        ],
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
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 4),
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
    );
  }
}
