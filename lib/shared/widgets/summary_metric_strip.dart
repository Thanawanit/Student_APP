import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/responsive_layout.dart';
import '../../domain/models/attendance_models.dart';
import '../../domain/models/attendance_status.dart';
import 'dashboard_gradient_header.dart';
import 'status_chip.dart';

/// Dashboard-First Level 1 & Level 2 Teacher Intelligence Overview.
class SummaryMetricStrip extends StatelessWidget {
  const SummaryMetricStrip({
    super.key,
    required this.snapshot,
    this.onTapStudent,
    this.onFilterAttention,
  });

  final ClassroomAttendanceSnapshot snapshot;
  final ValueChanged<StudentAttendanceRecord>? onTapStudent;
  final ValueChanged<AttendanceStatus>? onFilterAttention;

  List<StudentAttendanceRecord> _attentionStudents() {
    final priorityOrder = <AttendanceStatus, int>{
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // LEVEL 1: Immediate Overview on top-to-bottom green-to-white gradient
        DashboardGradientBand(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: inset,
              vertical: AppSpacing.space4,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWideDesktop = constraints.maxWidth >= 760;
                if (isWideDesktop) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        flex: 6,
                        child: _HeroAttendanceProgress(
                          checkedIn: checkedIn,
                          total: total,
                          ratePercent: ratePercent,
                          stateLabel: stateLabel,
                          snapshot: snapshot,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.space5),
                      Container(
                        width: 1,
                        height: 112,
                        color: AppColors.borderSubtle,
                      ),
                      const SizedBox(width: AppSpacing.space5),
                      Expanded(
                        flex: 6,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            _StatGrid(
                              cells: cells,
                              availableWidth: constraints.maxWidth * 0.46,
                            ),
                            const SizedBox(height: AppSpacing.space3),
                            const Divider(),
                            const SizedBox(height: AppSpacing.space3),
                            _AttentionSection(
                              students: attentionList,
                              isBeforeCutoff: snapshot.isBeforeCutoff,
                              onTapStudent: onTapStudent,
                              onFilterAttention: onFilterAttention,
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _HeroAttendanceProgress(
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
                      availableWidth: constraints.maxWidth,
                    ),
                  ],
                );
              },
            ),
          ),
        ),

        // LEVEL 2 (Mobile): Students requiring attention band right below Level 1
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= 760) {
              return const SizedBox.shrink();
            }
            return Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  bottom: BorderSide(color: AppColors.borderSubtle),
                ),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: inset,
                vertical: AppSpacing.space3,
              ),
              child: _AttentionSection(
                students: attentionList,
                isBeforeCutoff: snapshot.isBeforeCutoff,
                onTapStudent: onTapStudent,
                onFilterAttention: onFilterAttention,
              ),
            );
          },
        ),
      ],
    );
  }
}

class _HeroAttendanceProgress extends StatelessWidget {
  const _HeroAttendanceProgress({
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
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.end,
          alignment: WrapAlignment.spaceBetween,
          spacing: AppSpacing.space3,
          runSpacing: 4,
          children: <Widget>[
            Semantics(
              label:
                  'มาเรียนและมาสาย $checkedIn จาก $total คน คิดเป็นร้อยละ $ratePercent',
              child: Wrap(
                spacing: AppSpacing.space2,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: <Widget>[
                      Text('$checkedIn', style: AppTypography.display),
                      const SizedBox(width: AppSpacing.space1),
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
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Text(
                      '$ratePercent%',
                      style: AppTypography.microLabel.copyWith(
                        color: AppColors.presentForeground,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'สแกนเข้าโรงเรียนแล้ว',
                  style: AppTypography.supporting.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'มาเรียน ${snapshot.presentCount} คน • มาสาย ${snapshot.lateCount} คน',
                  style: AppTypography.microLabel.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(stateLabel, style: AppTypography.microLabel),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space3),
        _ProportionalDistributionBar(snapshot: snapshot),
        const SizedBox(height: AppSpacing.space2),
        Wrap(
          spacing: AppSpacing.space3,
          runSpacing: 4,
          children: <Widget>[
            _LegendDot(
              status: AttendanceStatus.present,
              count: snapshot.presentCount,
              total: total,
            ),
            _LegendDot(
              status: AttendanceStatus.late,
              count: snapshot.lateCount,
              total: total,
            ),
            if (snapshot.leaveCount > 0)
              _LegendDot(
                status: AttendanceStatus.leave,
                count: snapshot.leaveCount,
                total: total,
              ),
            if (snapshot.pendingCount > 0)
              _LegendDot(
                status: AttendanceStatus.pending,
                count: snapshot.pendingCount,
                total: total,
              ),
            if (snapshot.absentCount > 0)
              _LegendDot(
                status: AttendanceStatus.absent,
                count: snapshot.absentCount,
                total: total,
              ),
            if (snapshot.unknownCount > 0)
              _LegendDot(
                status: AttendanceStatus.unknown,
                count: snapshot.unknownCount,
                total: total,
              ),
          ],
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({
    required this.status,
    required this.count,
    required this.total,
  });

  final AttendanceStatus status;
  final int count;
  final int total;

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? ((count / total) * 100).round() : 0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: status.foregroundColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '${status.label} $count ($pct%)',
          style: AppTypography.microLabel.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _AttentionSection extends StatelessWidget {
  const _AttentionSection({
    required this.students,
    required this.isBeforeCutoff,
    this.onTapStudent,
    this.onFilterAttention,
  });

  final List<StudentAttendanceRecord> students;
  final bool isBeforeCutoff;
  final ValueChanged<StudentAttendanceRecord>? onTapStudent;
  final ValueChanged<AttendanceStatus>? onFilterAttention;

  @override
  Widget build(BuildContext context) {
    if (students.isEmpty) {
      return Row(
        children: <Widget>[
          const Icon(
            Icons.check_circle_outline,
            size: 16,
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
      );
    }

    final preview = students.take(3).toList();
    final remaining = students.length - preview.length;
    final primaryStatus = preview.first.todayEntry.status;

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
                isBeforeCutoff
                    ? 'นักเรียนที่รอตรวจสอบ / มาสาย (${students.length} คน)'
                    : 'นักเรียนที่ต้องติดตาม (${students.length} คน)',
                style: AppTypography.supporting.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (onFilterAttention != null)
                InkWell(
                  onTap: () => onFilterAttention!(primaryStatus),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      remaining > 0
                          ? 'ดูทั้งหมด (+อีก $remaining คน)'
                          : 'เปิดในรายชื่อนักเรียน',
                      style: AppTypography.microLabel.copyWith(
                        color: AppColors.brandPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.space2),
        Wrap(
          spacing: AppSpacing.space2,
          runSpacing: AppSpacing.space2,
          children: <Widget>[
            for (final student in preview)
              Material(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.control),
                child: InkWell(
                  onTap: onTapStudent != null
                      ? () => onTapStudent!(student)
                      : null,
                  borderRadius: BorderRadius.circular(AppRadius.control),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.space2,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.control),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            student.fullName,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.microLabel.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        AttendanceStatusChip(
                          status: student.todayEntry.status,
                          compact: true,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
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

class _ProportionalDistributionBar extends StatelessWidget {
  const _ProportionalDistributionBar({required this.snapshot});

  final ClassroomAttendanceSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final segments = <(AttendanceStatus, int)>[
      (AttendanceStatus.present, snapshot.presentCount),
      (AttendanceStatus.late, snapshot.lateCount),
      (AttendanceStatus.leave, snapshot.leaveCount),
      (AttendanceStatus.pending, snapshot.pendingCount),
      (AttendanceStatus.absent, snapshot.absentCount),
      (AttendanceStatus.unknown, snapshot.unknownCount),
    ].where((s) => s.$2 > 0).toList();

    if (segments.isEmpty) {
      return Container(height: 8, color: AppColors.surfaceSubtle);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        height: 8,
        child: Row(
          children: <Widget>[
            for (var i = 0; i < segments.length; i++) ...<Widget>[
              Expanded(
                flex: segments[i].$2,
                child: Container(color: segments[i].$1.foregroundColor),
              ),
              if (i < segments.length - 1) const SizedBox(width: 2),
            ],
          ],
        ),
      ),
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
