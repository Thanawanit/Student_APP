import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/responsive_layout.dart';
import '../../core/utils/thai_date_format.dart';
import '../../domain/models/attendance_models.dart';
import '../../domain/models/attendance_status.dart';
import '../../shared/widgets/filter_chip_bar.dart';
import '../../shared/widgets/state_views.dart';
import '../../shared/widgets/status_chip.dart';
import '../shared/student_detail_screen.dart';

/// Shared read-only attendance history section for Parent Mode with month, date, and status filtering.
class ParentHistorySection extends StatefulWidget {
  const ParentHistorySection({
    super.key,
    required this.record,
    required this.todayDate,
    this.showSectionTitle = true,
    this.useContainerInset = true,
  });

  final StudentAttendanceRecord record;
  final DateTime todayDate;
  final bool showSectionTitle;
  final bool useContainerInset;

  @override
  State<ParentHistorySection> createState() => _ParentHistorySectionState();
}

class _ParentHistorySectionState extends State<ParentHistorySection> {
  String? _selectedMonthKey;
  DateTime? _selectedDateFilter;
  AttendanceStatus? _statusFilter;

  String _monthKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}';

  Future<void> _pickDate(BuildContext context) async {
    final firstDate = widget.record.history.isNotEmpty
        ? widget.record.history.last.date
        : widget.todayDate.subtract(const Duration(days: 180));
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateFilter ?? widget.todayDate,
      firstDate: firstDate.subtract(const Duration(days: 30)),
      lastDate: widget.todayDate,
      helpText: 'เลือกวันที่ต้องการตรวจสอบ',
      cancelText: 'ยกเลิก',
      confirmText: 'เลือกวันที่',
    );
    if (picked != null) {
      setState(() {
        _selectedDateFilter = DateTime(picked.year, picked.month, picked.day);
        _selectedMonthKey = _monthKey(_selectedDateFilter!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final inset = widget.useContainerInset
        ? ResponsiveContent.horizontalInset(context)
        : 0.0;
    final isDesktop = MediaQuery.sizeOf(context).width >= 640;

    // Build distinct months available in student's actual history (newest first).
    final monthEntries = <String, DateTime>{};
    for (final entry in widget.record.history) {
      final key = _monthKey(entry.date);
      monthEntries.putIfAbsent(key, () => entry.date);
    }

    // Filter by month and date first, so status counts accurately reflect the active period.
    final periodFiltered = widget.record.history.where((entry) {
      final matchesMonth =
          _selectedMonthKey == null ||
          _monthKey(entry.date) == _selectedMonthKey;
      final matchesDate =
          _selectedDateFilter == null ||
          (entry.date.year == _selectedDateFilter!.year &&
              entry.date.month == _selectedDateFilter!.month &&
              entry.date.day == _selectedDateFilter!.day);
      return matchesMonth && matchesDate;
    }).toList();

    final countsByStatus = <AttendanceStatus, int>{
      for (final s in AttendanceStatus.values)
        s: periodFiltered.where((e) => e.status == s).length,
    };

    final filtered = periodFiltered.where((entry) {
      return _statusFilter == null || entry.status == _statusFilter;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.symmetric(horizontal: inset),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (widget.showSectionTitle) ...<Widget>[
                SizedBox(
                  width: double.infinity,
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: AppSpacing.space2,
                    runSpacing: 2,
                    children: <Widget>[
                      Text(
                        'ประวัติการเข้าเรียน',
                        style: AppTypography.sectionTitle,
                      ),
                      Text(
                        '${filtered.length} วัน',
                        style: AppTypography.microLabel,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.space3),
              ],

              // Month selector + Date picker row
              Wrap(
                spacing: AppSpacing.space2,
                runSpacing: AppSpacing.space2,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  _MonthFilterStrip(
                    monthEntries: monthEntries,
                    selectedMonthKey: _selectedMonthKey,
                    onSelected: (key) {
                      setState(() {
                        _selectedMonthKey = key;
                        _selectedDateFilter = null;
                      });
                    },
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _pickDate(context),
                    icon: const Icon(Icons.calendar_today_outlined, size: 16),
                    label: Text(
                      _selectedDateFilter != null
                          ? ThaiFormat.shortDate(_selectedDateFilter!)
                          : 'เลือกวันที่',
                    ),
                  ),
                  if (_selectedDateFilter != null)
                    TextButton(
                      onPressed: () {
                        setState(() => _selectedDateFilter = null);
                      },
                      child: const Text('ล้างวันที่'),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.space2),
              StatusFilterBar(
                selectedStatus: _statusFilter,
                totalCount: periodFiltered.length,
                countsByStatus: countsByStatus,
                availableStatuses: <AttendanceStatus>[
                  AttendanceStatus.present,
                  AttendanceStatus.late,
                  AttendanceStatus.absent,
                  AttendanceStatus.leave,
                  if ((countsByStatus[AttendanceStatus.pending] ?? 0) > 0)
                    AttendanceStatus.pending,
                ],
                onChanged: (value) {
                  setState(() => _statusFilter = value);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.space3),

        if (filtered.isEmpty)
          EmptyStateView(
            icon: Icons.event_busy_outlined,
            title: 'ยังไม่มีประวัติในวันที่เลือก',
            description:
                'ลองเลือกเดือนหรือวันเรียนอื่น หรือล้างตัวกรองเพื่อดูประวัติทั้งหมด',
            actionLabel: 'ล้างตัวกรอง',
            onAction: () {
              setState(() {
                _selectedMonthKey = null;
                _selectedDateFilter = null;
                _statusFilter = null;
              });
            },
          )
        else ...<Widget>[
          if (isDesktop)
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppColors.surfaceSubtle,
                border: Border(
                  top: BorderSide(color: AppColors.borderSubtle),
                  bottom: BorderSide(color: AppColors.borderSubtle),
                ),
              ),
              padding: EdgeInsets.symmetric(horizontal: inset, vertical: 8),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text('วันที่', style: AppTypography.microLabel),
                  ),
                  SizedBox(
                    width: 72,
                    child: Text(
                      'เวลาสแกน',
                      textAlign: TextAlign.right,
                      style: AppTypography.microLabel,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space4),
                  ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 112),
                    child: Text(
                      'สถานะ',
                      textAlign: TextAlign.right,
                      style: AppTypography.microLabel,
                    ),
                  ),
                  const SizedBox(width: 26),
                ],
              ),
            ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(
                top: isDesktop
                    ? BorderSide.none
                    : const BorderSide(color: AppColors.borderSubtle),
                bottom: const BorderSide(color: AppColors.borderSubtle),
              ),
            ),
            child: Column(
              children: <Widget>[
                for (var i = 0; i < filtered.length; i++) ...<Widget>[
                  _ParentHistoryRow(
                    entry: filtered[i],
                    inset: inset,
                    isDesktop: isDesktop,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => StudentDetailScreen(
                            studentId: widget.record.studentId,
                            initialDate: filtered[i].date,
                            isReadOnly: true,
                          ),
                        ),
                      );
                    },
                  ),
                  if (i < filtered.length - 1)
                    Divider(indent: inset, endIndent: inset),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _MonthFilterStrip extends StatelessWidget {
  const _MonthFilterStrip({
    required this.monthEntries,
    required this.selectedMonthKey,
    required this.onSelected,
  });

  final Map<String, DateTime> monthEntries;
  final String? selectedMonthKey;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final options = <(String?, String)>[
      (null, 'ทุกเดือน'),
      for (final entry in monthEntries.entries)
        (entry.key, ThaiFormat.monthYearShort(entry.value)),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceSubtle,
          borderRadius: BorderRadius.circular(AppRadius.control),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        padding: const EdgeInsets.all(3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (final opt in options)
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onSelected(opt.$1),
                  borderRadius: BorderRadius.circular(AppRadius.control - 2),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: AppSpacing.minTouchTarget - 6,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.space3,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: selectedMonthKey == opt.$1
                            ? AppColors.surface
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(
                          AppRadius.control - 2,
                        ),
                        border: selectedMonthKey == opt.$1
                            ? Border.all(color: AppColors.borderSubtle)
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          opt.$2,
                          style: AppTypography.microLabel.copyWith(
                            fontSize: 12.5,
                            color: selectedMonthKey == opt.$1
                                ? AppColors.brandPrimary
                                : AppColors.textSecondary,
                            fontWeight: selectedMonthKey == opt.$1
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ParentHistoryRow extends StatelessWidget {
  const _ParentHistoryRow({
    required this.entry,
    required this.inset,
    required this.isDesktop,
    required this.onTap,
  });

  final DailyAttendanceEntry entry;
  final double inset;
  final bool isDesktop;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final String timeLabel = switch (entry.status) {
      AttendanceStatus.present || AttendanceStatus.late =>
        entry.firstScanAt != null ? ThaiFormat.time24(entry.firstScanAt!) : '—',
      AttendanceStatus.pending => 'รอสแกน',
      AttendanceStatus.absent => '—',
      AttendanceStatus.leave => 'ลา',
      AttendanceStatus.unknown => 'รอซิงก์',
    };

    final String mobileSubtitle = switch (entry.status) {
      AttendanceStatus.present || AttendanceStatus.late =>
        entry.firstScanAt != null
            ? 'สแกนเข้า ${ThaiFormat.time24(entry.firstScanAt!)}'
            : 'บันทึกแล้ว',
      AttendanceStatus.pending => 'ยังไม่พบการสแกน • รอยืนยัน',
      AttendanceStatus.absent => 'ไม่พบการสแกน',
      AttendanceStatus.leave => 'มีบันทึกการลา',
      AttendanceStatus.unknown => 'รอข้อมูลซิงก์',
    };

    return InkWell(
      onTap: onTap,
      hoverColor: AppColors.surfaceSubtle.withValues(alpha: 0.7),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: AppSpacing.minTouchTarget + 10,
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: inset,
            vertical: isDesktop ? 10 : 12,
          ),
          child: isDesktop
              ? Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        ThaiFormat.fullDate(entry.date),
                        style: AppTypography.bodyStrong,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.space3),
                    SizedBox(
                      width: 72,
                      child: Text(
                        timeLabel,
                        textAlign: TextAlign.right,
                        style: AppTypography.supporting.copyWith(
                          color: entry.firstScanAt != null
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                          fontWeight: entry.firstScanAt != null
                              ? FontWeight.w500
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.space4),
                    ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 112),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: AttendanceStatusChip(
                          status: entry.status,
                          compact: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.space2),
                    const Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: AppColors.textDisabled,
                    ),
                  ],
                )
              : Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            ThaiFormat.fullDate(entry.date),
                            style: AppTypography.bodyStrong,
                          ),
                          const SizedBox(height: 2),
                          Text(mobileSubtitle, style: AppTypography.microLabel),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.space2),
                    AttendanceStatusChip(status: entry.status, compact: true),
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
    );
  }
}
