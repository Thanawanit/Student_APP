import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/responsive_layout.dart';
import '../../domain/models/attendance_models.dart';
import '../../domain/models/attendance_status.dart';
import 'status_chip.dart';

/// Light Editorial × Data Intelligence overview for Teacher Dashboard.
/// Uses typography-led hierarchy and hairline separators instead of heavy cards.
class SummaryMetricStrip extends StatelessWidget {
  const SummaryMetricStrip({
    super.key,
    required this.snapshot,
    this.onTapStudent,
    this.onOpenStudentList,
  });

  final ClassroomAttendanceSnapshot snapshot;
  final ValueChanged<StudentAttendanceRecord>? onTapStudent;
  final ValueChanged<AttendanceStatus?>? onOpenStudentList;

  List<StudentAttendanceRecord> _attentionStudents() {
    const priorityOrder = <AttendanceStatus, int>{
      AttendanceStatus.absent: 0,
      AttendanceStatus.unknown: 1,
      AttendanceStatus.late: 2,
      AttendanceStatus.pending: 3,
    };

    final list = snapshot.students
        .where((s) => priorityOrder.containsKey(s.todayEntry.status))
        .toList();
    list.sort(
      (a, b) => (priorityOrder[a.todayEntry.status] ?? 9).compareTo(
        priorityOrder[b.todayEntry.status] ?? 9,
      ),
    );
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final total = snapshot.totalStudents;
    final checkedIn = snapshot.presentCount + snapshot.lateCount;
    final ratePercent = total > 0 ? ((checkedIn / total) * 100).round() : 0;
    final inset = ResponsiveContent.horizontalInset(context);

    final String stateLabel;
    if (snapshot.syncMetadata.freshness == SyncFreshness.unavailable) {
      stateLabel = 'ข้อมูลบางส่วนรอการซิงก์';
    } else if (snapshot.isBeforeCutoff) {
      stateLabel = 'ก่อนตัดรอบ 09:00 น. • ยังไม่สรุปขาดเรียน';
    } else {
      stateLabel = 'สรุปสถานะประจำวันแล้ว';
    }

    final cells = <_StatCellData>[
      _StatCellData(AttendanceStatus.present, snapshot.presentCount, total),
      _StatCellData(AttendanceStatus.late, snapshot.lateCount, total),
      _StatCellData(AttendanceStatus.leave, snapshot.leaveCount, total),
      if (snapshot.isBeforeCutoff || snapshot.pendingCount > 0)
        _StatCellData(AttendanceStatus.pending, snapshot.pendingCount, total)
      else
        _StatCellData(AttendanceStatus.absent, snapshot.absentCount, total),
      if (snapshot.unknownCount > 0)
        _StatCellData(AttendanceStatus.unknown, snapshot.unknownCount, total),
    ];

    final attentionList = _attentionStudents();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideDesktop = constraints.maxWidth >= 800;

        final overviewBand = Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(
              top: BorderSide(color: AppColors.borderSubtle),
              bottom: BorderSide(color: AppColors.borderSubtle),
            ),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: inset,
            vertical: AppSpacing.space4,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _ProgressMetricHeader(
                checkedIn: checkedIn,
                total: total,
                ratePercent: ratePercent,
                stateLabel: stateLabel,
                snapshot: snapshot,
              ),
              const SizedBox(height: AppSpacing.space4),
              const Divider(),
              const SizedBox(height: AppSpacing.space3),
              _StatGrid(
                cells: cells,
                availableWidth: isWideDesktop
                    ? constraints.maxWidth * 0.48
                    : constraints.maxWidth - (inset * 2),
              ),
            ],
          ),
        );

        final attentionBand = _AttentionSection(
          inset: inset,
          totalStudents: total,
          students: attentionList,
          isBeforeCutoff: snapshot.isBeforeCutoff,
          onTapStudent: onTapStudent,
          onOpenStudentList: onOpenStudentList,
        );

        if (isWideDesktop) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(flex: 6, child: overviewBand),
              Container(width: 1, color: AppColors.borderSubtle),
              Expanded(flex: 6, child: attentionBand),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            overviewBand,
            const SizedBox(height: AppSpacing.space4),
            attentionBand,
          ],
        );
      },
    );
  }
}

class _ProgressMetricHeader extends StatelessWidget {
  const _ProgressMetricHeader({
    required this.checkedIn,
    required this.total,
    required this.ratePercent,
    required this.stateLabel,
    required this.snapshot,
  });

  final int checkedIn;
  final int total;
  final int ratePercent;
  final String stateLabel;
  final ClassroomAttendanceSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
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
            Text(
              '$ratePercent%',
              style: AppTypography.bodyStrong.copyWith(
                color: AppColors.brandPrimary,
                fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space1),
        Semantics(
          label:
              'สแกนเข้าโรงเรียนแล้ว $checkedIn จาก $total คน คิดเป็นร้อยละ $ratePercent',
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: AppSpacing.space2,
            children: <Widget>[
              Text('$checkedIn', style: AppTypography.display),
              Text(
                'จาก $total คน',
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
        const SizedBox(height: AppSpacing.space1),
        Text(
          'มาเรียน ${snapshot.presentCount} คน • มาสาย ${snapshot.lateCount} คน',
          style: AppTypography.supporting.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(stateLabel, style: AppTypography.microLabel),
        const SizedBox(height: AppSpacing.space3),
        _ProportionalDistributionBar(snapshot: snapshot),
      ],
    );
  }
}

class _ProportionalDistributionBar extends StatelessWidget {
  const _ProportionalDistributionBar({required this.snapshot});

  final ClassroomAttendanceSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final segments = <(Color, int)>[
      (AppColors.presentForeground, snapshot.presentCount),
      (AppColors.lateForeground, snapshot.lateCount),
      (AppColors.leaveForeground, snapshot.leaveCount),
      (
        AppColors.pendingForeground.withValues(alpha: 0.45),
        snapshot.pendingCount,
      ),
      (AppColors.absentForeground, snapshot.absentCount),
      (AppColors.unknownForeground, snapshot.unknownCount),
    ].where((s) => s.$2 > 0).toList();

    if (segments.isEmpty) {
      return Container(height: 6, color: AppColors.surfaceSubtle);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: SizedBox(
        height: 6,
        child: Row(
          children: <Widget>[
            for (var i = 0; i < segments.length; i++) ...<Widget>[
              Expanded(
                flex: segments[i].$2,
                child: Container(color: segments[i].$1),
              ),
              if (i < segments.length - 1) const SizedBox(width: 2),
            ],
          ],
        ),
      ),
    );
  }
}

class _AttentionSection extends StatelessWidget {
  const _AttentionSection({
    required this.inset,
    required this.totalStudents,
    required this.students,
    required this.isBeforeCutoff,
    this.onTapStudent,
    this.onOpenStudentList,
  });

  final double inset;
  final int totalStudents;
  final List<StudentAttendanceRecord> students;
  final bool isBeforeCutoff;
  final ValueChanged<StudentAttendanceRecord>? onTapStudent;
  final ValueChanged<AttendanceStatus?>? onOpenStudentList;

  @override
  Widget build(BuildContext context) {
    final preview = students.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.symmetric(horizontal: inset),
          child: SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpacing.space2,
              children: <Widget>[
                Text(
                  isBeforeCutoff
                      ? 'รอตรวจสอบ / มาสาย (${students.length})'
                      : 'นักเรียนที่ต้องติดตาม (${students.length})',
                  style: AppTypography.sectionTitle,
                ),
                if (onOpenStudentList != null)
                  TextButton(
                    onPressed: () => onOpenStudentList!(null),
                    child: Text('ดูรายชื่อทั้งหมด ($totalStudents)'),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.space1),
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(
              top: BorderSide(color: AppColors.borderSubtle),
              bottom: BorderSide(color: AppColors.borderSubtle),
            ),
          ),
          child: students.isEmpty
              ? Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: inset,
                    vertical: AppSpacing.space4,
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
                          'นักเรียนทุกคนในห้องมีสถานะเรียบร้อยแล้ว',
                          style: AppTypography.supporting.copyWith(
                            color: AppColors.presentForeground,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: <Widget>[
                    for (var i = 0; i < preview.length; i++) ...<Widget>[
                      InkWell(
                        onTap: onTapStudent != null
                            ? () => onTapStudent!(preview[i])
                            : null,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            minHeight: AppSpacing.minTouchTarget + 4,
                          ),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: inset,
                              vertical: 10,
                            ),
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                  child: Text(
                                    preview[i].fullName,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.bodyStrong,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.space2),
                                AttendanceStatusChip(
                                  status: preview[i].todayEntry.status,
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
                      if (i < preview.length - 1)
                        Divider(indent: inset, endIndent: inset),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.cells, required this.availableWidth});

  final List<_StatCellData> cells;
  final double availableWidth;

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final useTwoColumns =
        cells.length > 3 && (availableWidth / cells.length) < (74 * textScale);

    if (!useTwoColumns) {
      return IntrinsicHeight(
        child: Row(
          children: <Widget>[
            for (var i = 0; i < cells.length; i++) ...<Widget>[
              Expanded(child: _SwissStatCell(data: cells[i])),
              if (i < cells.length - 1)
                const VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: AppColors.borderSubtle,
                ),
            ],
          ],
        ),
      );
    }

    final rows = <List<_StatCellData>>[];
    for (var i = 0; i < cells.length; i += 2) {
      rows.add(cells.sublist(i, i + 2 > cells.length ? cells.length : i + 2));
    }
    return Column(
      children: <Widget>[
        for (var r = 0; r < rows.length; r++) ...<Widget>[
          IntrinsicHeight(
            child: Row(
              children: <Widget>[
                Expanded(child: _SwissStatCell(data: rows[r][0])),
                const VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: AppColors.borderSubtle,
                ),
                Expanded(
                  child: rows[r].length > 1
                      ? _SwissStatCell(data: rows[r][1])
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          if (r < rows.length - 1) ...<Widget>[
            const SizedBox(height: AppSpacing.space3),
            const Divider(),
            const SizedBox(height: AppSpacing.space3),
          ],
        ],
      ],
    );
  }
}

class _StatCellData {
  const _StatCellData(this.status, this.count, this.total);

  final AttendanceStatus status;
  final int count;
  final int total;
}

class _SwissStatCell extends StatelessWidget {
  const _SwissStatCell({required this.data});

  final _StatCellData data;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${data.status.label} ${data.count} จาก ${data.total} คน',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: data.status.foregroundColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSpacing.space1),
                Expanded(
                  child: Text(
                    data.status.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.microLabel,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text.rich(
              TextSpan(
                children: <InlineSpan>[
                  TextSpan(
                    text: '${data.count}',
                    style: AppTypography.sectionTitle.copyWith(
                      color: AppColors.textPrimary,
                      fontFeatures: const <FontFeature>[
                        FontFeature.tabularFigures(),
                      ],
                    ),
                  ),
                  TextSpan(
                    text: '/${data.total}',
                    style: AppTypography.microLabel,
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
