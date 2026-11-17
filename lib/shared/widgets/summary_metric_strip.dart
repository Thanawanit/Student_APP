import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/thai_date_format.dart';
import '../../domain/models/attendance_models.dart';
import '../../domain/models/attendance_status.dart';

/// Classroom Intelligence Composition for the Teacher Dashboard:
/// - Left/Top: Primary detected count + percentage + cutoff phase (single source of truth)
/// - Right/Bottom: Unified multi-segment bar paired with interactive 1-line breakdown legend
/// - Below / Right column on wide screens: Two distinct attention streams
///   separating undetected/unresolved students from late arrivals.
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
      phaseLabel = 'รอซิงก์ข้อมูล';
    } else if (snapshot.isBeforeCutoff) {
      phaseLabel = 'ก่อน 09:00 น.';
    } else {
      phaseLabel = 'สรุปผลแล้ว';
    }

    // Separate unresolved/not-yet-detected students from late arrivals.
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

    final breakdown = <_DistributionItem>[
      _DistributionItem(AttendanceStatus.present, snapshot.presentCount),
      _DistributionItem(AttendanceStatus.late, snapshot.lateCount),
      if (snapshot.isBeforeCutoff || snapshot.pendingCount > 0)
        _DistributionItem(AttendanceStatus.pending, snapshot.pendingCount)
      else
        _DistributionItem(AttendanceStatus.absent, snapshot.absentCount),
      if (snapshot.leaveCount > 0)
        _DistributionItem(AttendanceStatus.leave, snapshot.leaveCount),
      if (snapshot.unknownCount > 0)
        _DistributionItem(AttendanceStatus.unknown, snapshot.unknownCount),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideDesktop = constraints.maxWidth >= 820;

        final intelligenceBlock = _AttendanceSplitVisual(
          inset: inset,
          checkedIn: checkedIn,
          total: total,
          ratePercent: ratePercent,
          phaseLabel: phaseLabel,
          breakdown: breakdown,
          onTapStatus: onOpenStudentList,
        );

        final triageBlock = _AttentionTriageArea(
          inset: inset,
          totalStudents: total,
          isBeforeCutoff: snapshot.isBeforeCutoff,
          undetectedStudents: undetectedStudents,
          lateStudents: lateStudents,
          onTapStudent: onTapStudent,
          onOpenStudentList: onOpenStudentList,
        );

        if (isWideDesktop) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: inset),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(flex: 5, child: intelligenceBlock),
                const SizedBox(width: AppSpacing.space6),
                Expanded(flex: 7, child: triageBlock),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            intelligenceBlock,
            const SizedBox(height: AppSpacing.space4),
            triageBlock,
          ],
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

class _AttendanceSplitVisual extends StatelessWidget {
  const _AttendanceSplitVisual({
    required this.inset,
    required this.checkedIn,
    required this.total,
    required this.ratePercent,
    required this.phaseLabel,
    required this.breakdown,
    this.onTapStatus,
  });

  final double inset;
  final int checkedIn;
  final int total;
  final int ratePercent;
  final String phaseLabel;
  final List<_DistributionItem> breakdown;
  final ValueChanged<AttendanceStatus?>? onTapStatus;

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final isWideContainer = MediaQuery.sizeOf(context).width >= 820;

    return Container(
      margin: isWideContainer
          ? EdgeInsets.zero
          : EdgeInsets.symmetric(horizontal: inset),
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.panel),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: LayoutBuilder(
        builder: (context, box) {
          // Use asymmetric horizontal split on 360dp standard scale; stack cleanly on large accessibility text
          final canSplitHorizontal =
              box.maxWidth >= 280 && textScale <= 1.25 && !isWideContainer;

          final primaryMetric = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                'สแกนเข้าโรงเรียนแล้ว',
                style: AppTypography.microLabel.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Semantics(
                label:
                    'สแกนเข้าโรงเรียนแล้ว $checkedIn จาก $total คน คิดเป็นร้อยละ $ratePercent',
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.end,
                  spacing: 4,
                  children: <Widget>[
                    Text(
                      '$checkedIn',
                      style: AppTypography.display.copyWith(
                        fontSize: 40,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '/$total คน',
                      style: AppTypography.sectionTitle.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                        fontFeatures: const <FontFeature>[
                          FontFeature.tabularFigures(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
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
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      phaseLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.microLabel,
                    ),
                  ),
                ],
              ),
            ],
          );

          final distributionPanel = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _UnifiedProportionBar(items: breakdown),
              const SizedBox(height: AppSpacing.space3),
              for (var i = 0; i < breakdown.length; i++) ...<Widget>[
                _DistributionLegendRow(
                  item: breakdown[i],
                  onTap: onTapStatus != null
                      ? () => onTapStatus!(breakdown[i].status)
                      : null,
                ),
                if (i < breakdown.length - 1) const SizedBox(height: 2),
              ],
            ],
          );

          if (canSplitHorizontal) {
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Expanded(flex: 45, child: primaryMetric),
                  const VerticalDivider(
                    width: AppSpacing.space5,
                    thickness: 1,
                    color: AppColors.borderSubtle,
                  ),
                  Expanded(flex: 55, child: distributionPanel),
                ],
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              primaryMetric,
              const SizedBox(height: AppSpacing.space3),
              const Divider(),
              const SizedBox(height: AppSpacing.space3),
              distributionPanel,
            ],
          );
        },
      ),
    );
  }
}

class _UnifiedProportionBar extends StatelessWidget {
  const _UnifiedProportionBar({required this.items});

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

class _DistributionLegendRow extends StatelessWidget {
  const _DistributionLegendRow({required this.item, this.onTap});

  final _DistributionItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.badge),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          children: <Widget>[
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: item.status.foregroundColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppSpacing.space2),
            Expanded(
              child: Text(
                item.status.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.supporting.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              '${item.count}',
              style: AppTypography.bodyStrong.copyWith(
                fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttentionTriageArea extends StatelessWidget {
  const _AttentionTriageArea({
    required this.inset,
    required this.totalStudents,
    required this.isBeforeCutoff,
    required this.undetectedStudents,
    required this.lateStudents,
    this.onTapStudent,
    this.onOpenStudentList,
  });

  final double inset;
  final int totalStudents;
  final bool isBeforeCutoff;
  final List<StudentAttendanceRecord> undetectedStudents;
  final List<StudentAttendanceRecord> lateStudents;
  final ValueChanged<StudentAttendanceRecord>? onTapStudent;
  final ValueChanged<AttendanceStatus?>? onOpenStudentList;

  @override
  Widget build(BuildContext context) {
    final isWideContainer = MediaQuery.sizeOf(context).width >= 820;
    final horizontalPad = isWideContainer ? 0.0 : inset;
    final totalAttention = undetectedStudents.length + lateStudents.length;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPad),
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
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        'ต้องติดตามวันนี้',
                        style: AppTypography.sectionTitle,
                      ),
                    ),
                    if (totalAttention > 0) ...<Widget>[
                      const SizedBox(width: AppSpacing.space2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSubtle,
                          borderRadius: BorderRadius.circular(AppRadius.badge),
                        ),
                        child: Text(
                          '$totalAttention คน',
                          style: AppTypography.microLabel.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (onOpenStudentList != null)
                  TextButton(
                    onPressed: () => onOpenStudentList!(null),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.space2,
                      ),
                      minimumSize: const Size(0, 40),
                    ),
                    child: Text('รายชื่อทั้งหมด ($totalStudents) →'),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.space2),

          if (totalAttention == 0)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.space4),
              decoration: BoxDecoration(
                color: AppColors.presentBackground,
                borderRadius: BorderRadius.circular(AppRadius.panel),
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
            // Stream 1: Not yet detected / Absent / Sync unknown
            if (undetectedStudents.isNotEmpty)
              _TriageStreamGroup(
                title: isBeforeCutoff
                    ? 'ยังไม่พบการสแกน (${undetectedStudents.length})'
                    : 'ไม่พบการเข้าเรียน / ตรวจสอบ (${undetectedStudents.length})',
                accentColor: isBeforeCutoff
                    ? AppColors.pendingForeground
                    : AppColors.absentForeground,
                icon: isBeforeCutoff
                    ? Icons.hourglass_empty_outlined
                    : Icons.person_off_outlined,
                students: undetectedStudents,
                maxVisible: 2,
                subtitleBuilder: (student) =>
                    switch (student.todayEntry.status) {
                      AttendanceStatus.pending => 'รอยืนยัน',
                      AttendanceStatus.absent => 'ไม่พบใบลา',
                      AttendanceStatus.unknown => 'รอซิงก์',
                      _ => student.todayEntry.status.label,
                    },
                onTapStudent: onTapStudent,
                onViewMore:
                    undetectedStudents.length > 2 && onOpenStudentList != null
                    ? () => onOpenStudentList!(
                        undetectedStudents.first.todayEntry.status,
                      )
                    : null,
              ),

            if (undetectedStudents.isNotEmpty && lateStudents.isNotEmpty)
              const SizedBox(height: AppSpacing.space3),

            // Stream 2: Late arrivals (distinct from unscanned)
            if (lateStudents.isNotEmpty)
              _TriageStreamGroup(
                title: 'มาสายวันนี้ (${lateStudents.length})',
                accentColor: AppColors.lateForeground,
                icon: Icons.schedule_outlined,
                students: lateStudents,
                maxVisible: 2,
                subtitleBuilder: (student) =>
                    student.todayEntry.firstScanAt != null
                    ? 'เข้า ${ThaiFormat.time24(student.todayEntry.firstScanAt!)}'
                    : 'มาสาย',
                onTapStudent: onTapStudent,
                onViewMore: lateStudents.length > 2 && onOpenStudentList != null
                    ? () => onOpenStudentList!(AttendanceStatus.late)
                    : null,
              ),
          ],
        ],
      ),
    );
  }
}

class _TriageStreamGroup extends StatelessWidget {
  const _TriageStreamGroup({
    required this.title,
    required this.accentColor,
    required this.icon,
    required this.students,
    required this.maxVisible,
    required this.subtitleBuilder,
    this.onTapStudent,
    this.onViewMore,
  });

  final String title;
  final Color accentColor;
  final IconData icon;
  final List<StudentAttendanceRecord> students;
  final int maxVisible;
  final String Function(StudentAttendanceRecord) subtitleBuilder;
  final ValueChanged<StudentAttendanceRecord>? onTapStudent;
  final VoidCallback? onViewMore;

  @override
  Widget build(BuildContext context) {
    final visible = students.take(maxVisible).toList();
    final remaining = students.length - visible.length;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.panel),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space3,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceSubtle.withValues(alpha: 0.6),
              border: Border(
                left: BorderSide(color: accentColor, width: 3),
                bottom: const BorderSide(color: AppColors.borderSubtle),
              ),
            ),
            child: Row(
              children: <Widget>[
                Icon(icon, size: 14, color: accentColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.microLabel.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          for (var i = 0; i < visible.length; i++) ...<Widget>[
            InkWell(
              onTap: onTapStudent != null
                  ? () => onTapStudent!(visible[i])
                  : null,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: AppSpacing.minTouchTarget,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.space3,
                    vertical: 9,
                  ),
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: visible[i].todayEntry.status.foregroundColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.space2),
                      Expanded(
                        child: Text(
                          visible[i].fullName,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodyStrong,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.space2),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 112),
                        child: Text(
                          subtitleBuilder(visible[i]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                          style: AppTypography.microLabel.copyWith(
                            color: accentColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.chevron_right,
                        size: 16,
                        color: AppColors.textDisabled,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (i < visible.length - 1 || remaining > 0) const Divider(),
          ],
          if (remaining > 0 && onViewMore != null)
            InkWell(
              onTap: onViewMore,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space3,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    Text(
                      'ดูอีก $remaining คนในรายชื่อ →',
                      style: AppTypography.microLabel.copyWith(
                        color: AppColors.brandPrimary,
                        fontWeight: FontWeight.w600,
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
