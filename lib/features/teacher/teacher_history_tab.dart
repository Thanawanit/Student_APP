import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/responsive_layout.dart';
import '../../core/utils/thai_date_format.dart';
import '../../domain/models/attendance_status.dart';
import '../../shared/widgets/filter_chip_bar.dart';
import '../../shared/widgets/state_views.dart';
import '../../shared/widgets/student_attendance_row.dart';
import '../../state/app_controller.dart';
import '../shared/student_detail_screen.dart';

/// Screen F — Teacher attendance history by date (responsive desktop table / compact mobile).
class TeacherHistoryTab extends StatefulWidget {
  const TeacherHistoryTab({super.key});

  @override
  State<TeacherHistoryTab> createState() => _TeacherHistoryTabState();
}

class _TeacherHistoryTabState extends State<TeacherHistoryTab> {
  final TextEditingController _searchController = TextEditingController();
  AttendanceStatus? _statusFilter;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context, AppController controller) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: controller.historyDate,
      firstDate: controller.todayDate.subtract(const Duration(days: 180)),
      lastDate: controller.todayDate,
      helpText: 'เลือกวันที่ต้องการดูประวัติ',
      cancelText: 'ยกเลิก',
      confirmText: 'เลือกวันที่',
    );
    if (picked != null) {
      await controller.loadTeacherHistory(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final classroom = controller.selectedClassroom;
    final snapshot = controller.historySnapshot;
    final inset = ResponsiveContent.horizontalInset(context);
    final isDesktop = MediaQuery.sizeOf(context).width >= 640;
    final isWide = MediaQuery.sizeOf(context).width >= 760;
    final isToday =
        snapshot != null &&
        snapshot.date.year == controller.todayDate.year &&
        snapshot.date.month == controller.todayDate.month &&
        snapshot.date.day == controller.todayDate.day;

    return Scaffold(
      appBar: AppBar(title: const Text('ประวัติการเข้าเรียน')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.space6),
        children: <Widget>[
          ResponsiveContent(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (classroom != null)
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      inset,
                      AppSpacing.space1,
                      inset,
                      AppSpacing.space2,
                    ),
                    child: Text(
                      classroom.hierarchyLabel,
                      style: AppTypography.supporting.copyWith(
                        color: AppColors.brandPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                // Editorial date header band
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: AppColors.background,
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
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  ThaiFormat.fullDate(controller.historyDate),
                                  style: AppTypography.sectionTitle,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isToday
                                      ? (snapshot.isBeforeCutoff
                                            ? 'ข้อมูลวันนี้ • ยังไม่ตัดรอบเวลา 09:00 น.'
                                            : 'ข้อมูลวันนี้ • สรุปสถานะประจำวันแล้ว')
                                      : 'ประวัติการเข้าเรียนที่บันทึกไว้แล้ว',
                                  style: AppTypography.supporting,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.space2),
                          OutlinedButton.icon(
                            onPressed: () => _pickDate(context, controller),
                            icon: const Icon(
                              Icons.calendar_today_outlined,
                              size: 16,
                            ),
                            label: const Text('ปฏิทิน'),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.space3),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.surfaceSubtle,
                            borderRadius: BorderRadius.circular(
                              AppRadius.control,
                            ),
                            border: Border.all(color: AppColors.borderSubtle),
                          ),
                          padding: const EdgeInsets.all(3),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              _QuickDateSegment(
                                label: 'วันนี้',
                                isSelected: _isSameDay(
                                  controller.historyDate,
                                  controller.todayDate,
                                ),
                                onTap: () => controller.loadTeacherHistory(
                                  controller.todayDate,
                                ),
                              ),
                              _QuickDateSegment(
                                label: 'วันเรียนก่อนหน้า',
                                isSelected: _isSameDay(
                                  controller.historyDate,
                                  _previousSchoolDay(controller.todayDate, 1),
                                ),
                                onTap: () => controller.loadTeacherHistory(
                                  _previousSchoolDay(controller.todayDate, 1),
                                ),
                              ),
                              _QuickDateSegment(
                                label: '2 วันก่อน',
                                isSelected: _isSameDay(
                                  controller.historyDate,
                                  _previousSchoolDay(controller.todayDate, 2),
                                ),
                                onTap: () => controller.loadTeacherHistory(
                                  _previousSchoolDay(controller.todayDate, 2),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.space4),

                if (controller.isHistoryLoading)
                  const LoadingSkeletonList(showSummaryPlaceholder: false)
                else if (controller.historyError != null)
                  ErrorStateView(
                    message: controller.historyError!,
                    onRetry: () =>
                        controller.loadTeacherHistory(controller.historyDate),
                  )
                else if (snapshot == null || snapshot.students.isEmpty)
                  const EmptyStateView(
                    icon: Icons.event_busy_outlined,
                    title: 'ยังไม่มีข้อมูลการเข้าเรียนในวันที่เลือก',
                    description:
                        'วันที่เลือกอาจเป็นวันหยุดสุดสัปดาห์ วันหยุดโรงเรียน หรือยังไม่มีบันทึกการเข้าเรียน',
                  )
                else ...<Widget>[
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: inset),
                    child: isWide
                        ? Row(
                            children: <Widget>[
                              SizedBox(width: 280, child: _buildSearchField()),
                              const SizedBox(width: AppSpacing.space4),
                              Expanded(
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: _buildFilterBar(snapshot),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              _buildSearchField(),
                              const SizedBox(height: AppSpacing.space2),
                              _buildFilterBar(snapshot),
                            ],
                          ),
                  ),
                  const SizedBox(height: AppSpacing.space3),
                  Builder(
                    builder: (context) {
                      final filtered = snapshot.students.where((student) {
                        final matchesStatus =
                            _statusFilter == null ||
                            student.todayEntry.status == _statusFilter;
                        final q = _searchQuery.toLowerCase();
                        final matchesSearch =
                            q.isEmpty ||
                            student.fullName.toLowerCase().contains(q) ||
                            student.studentId.toLowerCase().contains(q);
                        return matchesStatus && matchesSearch;
                      }).toList();

                      if (filtered.isEmpty) {
                        return EmptyStateView(
                          icon: Icons.filter_list_off_outlined,
                          title: 'ไม่พบนักเรียนที่ตรงกับตัวกรอง',
                          actionLabel: 'แสดงทั้งหมด',
                          onAction: () {
                            _searchController.clear();
                            setState(() {
                              _statusFilter = null;
                              _searchQuery = '';
                            });
                          },
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          if (isDesktop)
                            Container(
                              width: double.infinity,
                              decoration: const BoxDecoration(
                                color: AppColors.surfaceSubtle,
                                border: Border(
                                  top: BorderSide(
                                    color: AppColors.borderSubtle,
                                  ),
                                  bottom: BorderSide(
                                    color: AppColors.borderSubtle,
                                  ),
                                ),
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: inset,
                                vertical: 8,
                              ),
                              child: Row(
                                children: <Widget>[
                                  SizedBox(
                                    width: 28,
                                    child: Text(
                                      '#',
                                      style: AppTypography.microLabel,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.space2),
                                  Expanded(
                                    child: Text(
                                      'รายชื่อนักเรียน (${filtered.length})',
                                      style: AppTypography.microLabel,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.space3),
                                  SizedBox(
                                    width: 84,
                                    child: Text(
                                      'รหัส',
                                      style: AppTypography.microLabel,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.space3),
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
                                    constraints: const BoxConstraints(
                                      minWidth: 112,
                                    ),
                                    child: Text(
                                      'สถานะ',
                                      textAlign: TextAlign.right,
                                      style: AppTypography.microLabel,
                                    ),
                                  ),
                                  const SizedBox(width: 26),
                                ],
                              ),
                            )
                          else
                            Padding(
                              padding: EdgeInsets.fromLTRB(
                                inset,
                                0,
                                inset,
                                AppSpacing.space2,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  Text(
                                    'รายชื่อนักเรียน',
                                    style: AppTypography.microLabel.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '${filtered.length} คน',
                                    style: AppTypography.microLabel,
                                  ),
                                ],
                              ),
                            ),
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              border: Border(
                                top: isDesktop
                                    ? BorderSide.none
                                    : const BorderSide(
                                        color: AppColors.borderSubtle,
                                      ),
                                bottom: const BorderSide(
                                  color: AppColors.borderSubtle,
                                ),
                              ),
                            ),
                            child: Column(
                              children: <Widget>[
                                for (
                                  var i = 0;
                                  i < filtered.length;
                                  i++
                                ) ...<Widget>[
                                  StudentAttendanceRow(
                                    record: filtered[i],
                                    entry: filtered[i].todayEntry,
                                    sequenceNumber: i + 1,
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute<void>(
                                          builder: (_) => StudentDetailScreen(
                                            studentId: filtered[i].studentId,
                                            initialDate: snapshot.date,
                                            isReadOnly: false,
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
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      style: AppTypography.body,
      onChanged: (value) {
        setState(() => _searchQuery = value.trim());
      },
      decoration: InputDecoration(
        hintText: 'ค้นหาชื่อหรือเลขประจำตัวนักเรียน',
        prefixIcon: const Icon(
          Icons.search,
          size: 20,
          color: AppColors.textSecondary,
        ),
        suffixIcon: _searchQuery.isEmpty
            ? null
            : IconButton(
                tooltip: 'ล้างคำค้นหา',
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
                icon: const Icon(Icons.close, size: 18),
              ),
      ),
    );
  }

  Widget _buildFilterBar(dynamic snapshot) {
    return StatusFilterBar(
      selectedStatus: _statusFilter,
      totalCount: snapshot.totalStudents as int,
      countsByStatus: <AttendanceStatus, int>{
        AttendanceStatus.present: snapshot.presentCount as int,
        AttendanceStatus.late: snapshot.lateCount as int,
        AttendanceStatus.absent: snapshot.absentCount as int,
        AttendanceStatus.leave: snapshot.leaveCount as int,
        AttendanceStatus.pending: snapshot.pendingCount as int,
      },
      availableStatuses: <AttendanceStatus>[
        AttendanceStatus.present,
        AttendanceStatus.late,
        AttendanceStatus.absent,
        AttendanceStatus.leave,
        if ((snapshot.pendingCount as int) > 0) AttendanceStatus.pending,
      ],
      onChanged: (value) {
        setState(() => _statusFilter = value);
      },
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  DateTime _previousSchoolDay(DateTime from, int count) {
    var d = from;
    var remaining = count;
    while (remaining > 0) {
      d = d.subtract(const Duration(days: 1));
      if (d.weekday != DateTime.saturday && d.weekday != DateTime.sunday) {
        remaining--;
      }
    }
    return d;
  }
}

class _QuickDateSegment extends StatelessWidget {
  const _QuickDateSegment({
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
        borderRadius: BorderRadius.circular(AppRadius.control - 2),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppSpacing.minTouchTarget - 6,
          ),
          child: AnimatedContainer(
            duration: AppMotion.resolve(context, AppMotion.fast),
            curve: AppMotion.gentleCurve,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space3,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.surface : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.control - 2),
              border: isSelected
                  ? Border.all(color: AppColors.borderSubtle)
                  : null,
            ),
            child: Center(
              child: Text(
                label,
                style: AppTypography.microLabel.copyWith(
                  fontSize: 12.5,
                  color: isSelected
                      ? AppColors.brandPrimary
                      : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
