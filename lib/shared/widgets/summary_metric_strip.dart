import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/responsive_layout.dart';
import '../../domain/models/attendance_models.dart';
import '../../domain/models/attendance_status.dart';
import 'status_chip.dart';

/// Obsidian Hero Analytics + Swiss Distribution Ledger + Attention Preview.
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

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: inset),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWideDesktop = constraints.maxWidth >= 740;

          final heroBlock = _ObsidianHeroBlock(
            checkedIn: checkedIn,
            total: total,
            ratePercent: ratePercent,
            stateLabel: stateLabel,
            snapshot: snapshot,
          );

          final distributionBlock = Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.panel),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space3,
              vertical: AppSpacing.space3,
            ),
            child: _StatGrid(
              cells: cells,
              availableWidth: isWideDesktop
                  ? constraints.maxWidth * 0.46
                  : constraints.maxWidth - (AppSpacing.space3 * 2),
            ),
          );

          final attentionBlock = Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.panel),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            padding: const EdgeInsets.all(AppSpacing.space4),
            child: _AttentionSection(
              students: attentionList,
              isBeforeCutoff: snapshot.isBeforeCutoff,
              onTapStudent: onTapStudent,
              onFilterAttention: onFilterAttention,
            ),
          );

          if (isWideDesktop) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(flex: 6, child: heroBlock),
                const SizedBox(width: AppSpacing.space4),
                Expanded(
                  flex: 6,
                  child: Column(
                    children: <Widget>[
                      distributionBlock,
                      const SizedBox(height: AppSpacing.space3),
                      attentionBlock,
                    ],
                  ),
                ),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              heroBlock,
              const SizedBox(height: AppSpacing.space3),
              distributionBlock,
              const SizedBox(height: AppSpacing.space3),
              attentionBlock,
            ],
          );
        },
      ),
    );
  }
}

class _ObsidianHeroBlock extends StatelessWidget {
  const _ObsidianHeroBlock({
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.space5),
      decoration: BoxDecoration(
        color: AppColors.inkSurface,
        borderRadius: BorderRadius.circular(AppRadius.panel),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Expanded(
                child: Text(
                  'สแกนเข้าโรงเรียนแล้ว',
                  style: AppTypography.supporting.copyWith(
                    color: AppColors.inkTextMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.space2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.brandPrimary,
                  borderRadius: BorderRadius.circular(AppRadius.badge),
                ),
                child: Text(
                  '$ratePercent%',
                  style: AppTypography.microLabel.copyWith(
                    color: AppColors.surface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space2),
          Semantics(
            label:
                'สแกนเข้าโรงเรียนแล้ว $checkedIn จาก $total คน คิดเป็นร้อยละ $ratePercent',
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.end,
              spacing: AppSpacing.space2,
              children: <Widget>[
                Text(
                  '$checkedIn',
                  style: AppTypography.display.copyWith(
                    color: AppColors.inkText,
                  ),
                ),
                Text(
                  'จาก $total คน',
                  style: AppTypography.sectionTitle.copyWith(
                    color: AppColors.inkTextMuted,
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
              color: AppColors.inkText,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            stateLabel,
            style: AppTypography.microLabel.copyWith(
              color: AppColors.inkTextMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.space4),
          _ProportionalDistributionBar(snapshot: snapshot),
          const SizedBox(height: AppSpacing.space3),
          Wrap(
            spacing: AppSpacing.space3,
            runSpacing: 4,
            children: <Widget>[
              _DarkLegendDot(
                color: AppColors.inkEmeraldAccent,
                label: 'มาเรียน',
                count: snapshot.presentCount,
                total: total,
              ),
              _DarkLegendDot(
                color: const Color(0xFFFBBF24),
                label: 'มาสาย',
                count: snapshot.lateCount,
                total: total,
              ),
              if (snapshot.leaveCount > 0)
                _DarkLegendDot(
                  color: const Color(0xFF93A3F8),
                  label: 'ลา',
                  count: snapshot.leaveCount,
                  total: total,
                ),
              if (snapshot.pendingCount > 0)
                _DarkLegendDot(
                  color: const Color(0xFF9CA8A3),
                  label: 'รอยืนยัน',
                  count: snapshot.pendingCount,
                  total: total,
                ),
              if (snapshot.absentCount > 0)
                _DarkLegendDot(
                  color: const Color(0xFFF87171),
                  label: 'ขาดเรียน',
                  count: snapshot.absentCount,
                  total: total,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DarkLegendDot extends StatelessWidget {
  const _DarkLegendDot({
    required this.color,
    required this.label,
    required this.count,
    required this.total,
  });

  final Color color;
  final String label;
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
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          '$label $count ($pct%)',
          style: AppTypography.microLabel.copyWith(
            color: AppColors.inkTextMuted,
          ),
        ),
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
      (AppColors.inkEmeraldAccent, snapshot.presentCount),
      (const Color(0xFFFBBF24), snapshot.lateCount),
      (const Color(0xFF93A3F8), snapshot.leaveCount),
      (const Color(0xFF9CA8A3), snapshot.pendingCount),
      (const Color(0xFFF87171), snapshot.absentCount),
      (const Color(0xFF64748B), snapshot.unknownCount),
    ].where((s) => s.$2 > 0).toList();

    if (segments.isEmpty) {
      return Container(height: 7, color: AppColors.inkSurfaceDivider);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: SizedBox(
        height: 7,
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
            size: 18,
            color: AppColors.presentForeground,
          ),
          const SizedBox(width: AppSpacing.space2),
          Expanded(
            child: Text(
              'นักเรียนทุกคนในห้องมีสถานะเรียบร้อยแล้ว',
              style: AppTypography.supporting.copyWith(
                color: AppColors.presentForeground,
                fontWeight: FontWeight.w600,
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
                    ? 'รอตรวจสอบ / มาสาย (${students.length} คน)'
                    : 'นักเรียนที่ต้องติดตาม (${students.length} คน)',
                style: AppTypography.bodyStrong,
              ),
              if (onFilterAttention != null)
                InkWell(
                  onTap: () => onFilterAttention!(primaryStatus),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      remaining > 0
                          ? 'ดูทั้งหมด (+อีก $remaining คน)'
                          : 'เปิดในรายชื่อ',
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
        for (var i = 0; i < preview.length; i++) ...<Widget>[
          InkWell(
            onTap: onTapStudent != null
                ? () => onTapStudent!(preview[i])
                : null,
            borderRadius: BorderRadius.circular(AppRadius.badge),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      preview[i].fullName,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.supporting.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space2),
                  AttendanceStatusChip(
                    status: preview[i].todayEntry.status,
                    compact: true,
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
          if (i < preview.length - 1) const Divider(),
        ],
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
