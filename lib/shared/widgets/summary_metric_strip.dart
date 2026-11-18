import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/thai_date_format.dart';
import '../../domain/models/attendance_models.dart';
import '../../domain/models/attendance_status.dart';
import 'status_chip.dart';

/// Light Editorial × Swiss Data Design overview for Teacher Dashboard.
/// Replaces Bento cards with open editorial sections, large tabular typography,
/// one segmented progress bar, a 4-column inline distribution, and one unified
/// attention list divided by thin horizontal hairlines.
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
      phaseLabel = 'ก่อนตัดรอบ 09:00 น.';
    } else {
      phaseLabel = 'สรุปผลประจำวันแล้ว';
    }

    // Group A: Students not yet detected / absent / sync unknown.
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

    // Group B: Late students (detected >= 08:00).
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

    final overviewSection = _EditorialAttendanceOverview(
      checkedIn: checkedIn,
      total: total,
      ratePercent: ratePercent,
      phaseLabel: phaseLabel,
      items: fourColumnItems,
      onTapStatus: onOpenStudentList,
    );

    final attentionSection = _UnifiedAttentionSection(
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
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(flex: 5, child: overviewSection),
                  const VerticalDivider(
                    width: AppSpacing.space8,
                    thickness: 1,
                    color: AppColors.borderSubtle,
                  ),
                  Expanded(flex: 7, child: attentionSection),
                ],
              ),
            ),
          );
        }

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: inset),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              overviewSection,
              const SizedBox(height: AppSpacing.space6),
              const Divider(),
              const SizedBox(height: AppSpacing.space5),
              attentionSection,
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

class _EditorialAttendanceOverview extends StatelessWidget {
  const _EditorialAttendanceOverview({
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // TOP: Label left, Percentage badge right
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Expanded(
              child: Text(
                'สแกนเข้าโรงเรียนแล้ว',
                style: AppTypography.supporting.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.space2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.brandPrimarySoft,
                borderRadius: BorderRadius.circular(AppRadius.badge),
              ),
              child: Text(
                '$ratePercent%',
                style: AppTypography.microLabel.copyWith(
                  color: AppColors.brandPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space1),

        // PRIMARY METRIC: Large figure + "จาก 12 คน" beside it
        Semantics(
          label:
              'สแกนเข้าโรงเรียนแล้ว $checkedIn จาก $total คน คิดเป็นร้อยละ $ratePercent',
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: AppSpacing.space2,
            runSpacing: 2,
            children: <Widget>[
              Text(
                '$checkedIn',
                style: AppTypography.display.copyWith(
                  fontSize: 46,
                  color: AppColors.textPrimary,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
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
                padding: const EdgeInsets.only(bottom: 7),
                child: Text('· $phaseLabel', style: AppTypography.microLabel),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.space3),

        // BELOW: One horizontal segmented progress bar
        _SegmentedProgressBar(items: items),
        const SizedBox(height: AppSpacing.space3),

        // BELOW THE BAR: Compact 4-column attendance distribution (open, no cards)
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
                    color: AppColors.borderSubtle,
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SegmentedProgressBar extends StatelessWidget {
  const _SegmentedProgressBar({required this.items});

  final List<_DistributionItem> items;

  @override
  Widget build(BuildContext context) {
    final active = items.where((item) => item.count > 0).toList();
    if (active.isEmpty) {
      return Container(
        height: 8,
        decoration: BoxDecoration(
          color: AppColors.surfaceSubtle,
          borderRadius: BorderRadius.circular(4),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        height: 8,
        child: Row(
          children: <Widget>[
            for (var i = 0; i < active.length; i++) ...<Widget>[
              Expanded(
                flex: active[i].count,
                child: Container(color: active[i].status.foregroundColor),
              ),
              if (i < active.length - 1) const SizedBox(width: 2),
            ],
          ],
        ),
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

class _UnifiedAttentionSection extends StatelessWidget {
  const _UnifiedAttentionSection({
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
        // Unified section header: "ต้องติดตามวันนี้" + "5 คน" + "ดูรายชื่อทั้งหมด →"
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
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.space3),
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
          // GROUP A: "ยังไม่พบการสแกน" — N คน
          if (undetectedStudents.isNotEmpty) ...<Widget>[
            _AttentionGroupHeader(
              label: isBeforeCutoff
                  ? 'ยังไม่พบการสแกน — ${undetectedStudents.length} คน'
                  : 'ไม่พบการเข้าเรียน — ${undetectedStudents.length} คน',
              color: isBeforeCutoff
                  ? AppColors.pendingForeground
                  : AppColors.absentForeground,
            ),
            const SizedBox(height: AppSpacing.space1),
            const Divider(),
            for (var i = 0; i < undetectedStudents.length; i++) ...<Widget>[
              _AttentionStudentRow(
                student: undetectedStudents[i],
                onTap: onTapStudent != null
                    ? () => onTapStudent!(undetectedStudents[i])
                    : null,
              ),
              const Divider(),
            ],
          ],

          if (undetectedStudents.isNotEmpty && lateStudents.isNotEmpty)
            const SizedBox(height: AppSpacing.space4),

          // GROUP B: "มาสายวันนี้" — N คน
          if (lateStudents.isNotEmpty) ...<Widget>[
            _AttentionGroupHeader(
              label: 'มาสายวันนี้ — ${lateStudents.length} คน',
              color: AppColors.lateForeground,
            ),
            const SizedBox(height: AppSpacing.space1),
            const Divider(),
            for (var i = 0; i < lateStudents.length; i++) ...<Widget>[
              _AttentionStudentRow(
                student: lateStudents[i],
                onTap: onTapStudent != null
                    ? () => onTapStudent!(lateStudents[i])
                    : null,
              ),
              const Divider(),
            ],
          ],
        ],
      ],
    );
  }
}

class _AttentionGroupHeader extends StatelessWidget {
  const _AttentionGroupHeader({required this.label, required this.color});

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

class _AttentionStudentRow extends StatelessWidget {
  const _AttentionStudentRow({required this.student, this.onTap});

  final StudentAttendanceRecord student;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final entry = student.todayEntry;
    final scanTime = entry.firstScanAt != null
        ? ThaiFormat.time24(entry.firstScanAt!)
        : null;

    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 46),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: <Widget>[
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
              if (scanTime != null) ...<Widget>[
                Text(
                  scanTime,
                  style: AppTypography.supporting.copyWith(
                    color: AppColors.lateForeground,
                    fontWeight: FontWeight.w600,
                    fontFeatures: const <FontFeature>[
                      FontFeature.tabularFigures(),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.space2),
              ],
              AttendanceStatusChip(status: entry.status, compact: true),
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
    );
  }
}
