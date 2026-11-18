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

              // Month selector + Date picker on a single horizontal row
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: _MonthFilterStrip(
                      monthEntries: monthEntries,
                      selectedMonthKey: _selectedMonthKey,
                      onSelected: (key) {
                        setState(() {
                          _selectedMonthKey = key;
                          _selectedDateFilter = null;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => _pickDate(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      minimumSize: const Size(0, 36),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      side: const BorderSide(color: Color(0xFFE2E8E4)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.calendar_today_outlined, size: 15),
                    label: Text(
                      _selectedDateFilter != null
                          ? ThaiFormat.shortDateTwoDigitYear(
                              _selectedDateFilter!,
                            )
                          : 'เลือกวันที่',
                      style: AppTypography.microLabel.copyWith(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  if (_selectedDateFilter != null) ...<Widget>[
                    const SizedBox(width: 4),
                    IconButton(
                      tooltip: 'ล้างวันที่',
                      onPressed: () {
                        setState(() => _selectedDateFilter = null);
                      },
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      padding: EdgeInsets.zero,
                      icon: const Icon(
                        Icons.close,
                        size: 16,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
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
                  AttendanceStatus.leave,
                  AttendanceStatus.absent,
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
        else
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFFFFFFFF),
              border: Border(
                top: BorderSide(color: Color(0xFFE2E8E4)),
                bottom: BorderSide(color: Color(0xFFE2E8E4)),
              ),
            ),
            child: Column(
              children: <Widget>[
                for (var i = 0; i < filtered.length; i++) ...<Widget>[
                  _ParentHistoryRow(
                    entry: filtered[i],
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
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFFF1F5F9),
                    ),
                ],
              ],
            ),
          ),
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
        (entry.key, ThaiFormat.monthYearTwoDigit(entry.value)),
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
  const _ParentHistoryRow({required this.entry, required this.onTap});

  final DailyAttendanceEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final localDate = ThaiFormat.toBangkok(entry.date);

    final String scanSubtitle = switch (entry.status) {
      AttendanceStatus.present || AttendanceStatus.late =>
        entry.firstScanAt != null
            ? 'สแกนเข้า ${ThaiFormat.time24Nbsp(entry.firstScanAt!)}'
            : 'บันทึกแล้ว',
      AttendanceStatus.pending => 'ยังไม่พบการสแกน',
      AttendanceStatus.absent => 'ไม่พบการสแกน',
      AttendanceStatus.leave => 'มีบันทึกการลา',
      AttendanceStatus.unknown => 'รอข้อมูลซิงก์',
    };

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              SizedBox(
                width: 52,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      '${localDate.day}',
                      style: AppTypography.sectionTitle.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                        height: 1.1,
                        fontFeatures: const <FontFeature>[
                          FontFeature.tabularFigures(),
                        ],
                      ),
                    ),
                    Text(
                      ThaiFormat.shortMonth(entry.date),
                      style: AppTypography.microLabel.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 32,
                color: const Color(0xFFE2E8E4),
                margin: const EdgeInsets.symmetric(horizontal: 12),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      ThaiFormat.weekdayAndYear(entry.date),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyStrong.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      scanSubtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.microLabel.copyWith(
                        fontSize: 12,
                        color: const Color(0xFF64748B),
                        fontFeatures: const <FontFeature>[
                          FontFeature.tabularFigures(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AttendanceStatusChip(status: entry.status, compact: true),
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
    );
  }
}
