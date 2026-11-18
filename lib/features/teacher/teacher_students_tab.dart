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
import '../../state/app_controller.dart';
import '../shared/student_detail_screen.dart';
import 'class_selection_screen.dart';

/// Screen B — Dedicated Classroom Student List with search, status filter, and edit navigation.
class TeacherStudentsTab extends StatefulWidget {
  const TeacherStudentsTab({
    super.key,
    this.requestedFilter,
    this.filterRevision = 0,
  });

  final AttendanceStatus? requestedFilter;
  final int filterRevision;

  @override
  State<TeacherStudentsTab> createState() => _TeacherStudentsTabState();
}

class _TeacherStudentsTabState extends State<TeacherStudentsTab> {
  final TextEditingController _searchController = TextEditingController();
  AttendanceStatus? _statusFilter;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _statusFilter = widget.requestedFilter;
  }

  @override
  void didUpdateWidget(covariant TeacherStudentsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.filterRevision != oldWidget.filterRevision) {
      setState(() {
        _statusFilter = widget.requestedFilter;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final classroom = controller.selectedClassroom;
    final snapshot = controller.classroomSnapshot;
    final inset = ResponsiveContent.horizontalInset(context);
    final isWide = MediaQuery.sizeOf(context).width >= 760;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: inset,
        title: const Text('รายชื่อนักเรียน'),
        actions: <Widget>[
          if (classroom != null)
            Padding(
              padding: EdgeInsets.only(right: inset),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const TeacherClassSelectionScreen(
                          isSwitchingRoom: true,
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(99),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: const Color(0xFFE2E8E4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Icon(
                          Icons.swap_horiz,
                          size: 16,
                          color: Color(0xFF14532D),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'ห้อง ${classroom.code}',
                          style: AppTypography.microLabel.copyWith(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF14532D),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.brandPrimary,
        onRefresh: controller.loadClassroomOverview,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
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
                        AppSpacing.space3,
                      ),
                      child: Text(
                        'ม.${classroom.grade} • ${ThaiFormat.weekdayShortDate(controller.todayDate)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.microLabel.copyWith(
                          fontSize: 12,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ),

                  if (controller.isClassroomLoading && snapshot == null)
                    const LoadingSkeletonList(showSummaryPlaceholder: false)
                  else if (controller.classroomError != null &&
                      snapshot == null)
                    ErrorStateView(
                      message: controller.classroomError!,
                      onRetry: controller.loadClassroomOverview,
                    )
                  else if (snapshot == null || snapshot.students.isEmpty)
                    const EmptyStateView(
                      title: 'ไม่พบนักเรียนในห้องนี้',
                      description:
                          'ยังไม่มีรายชื่อนักเรียนหรือกำหนดการเรียนในวันที่เลือก',
                    )
                  else ...<Widget>[
                    if (snapshot.syncMetadata.freshness != SyncFreshness.fresh)
                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: AppSpacing.space3,
                        ),
                        child: SyncStatusBanner(
                          syncMetadata: snapshot.syncMetadata,
                        ),
                      ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: inset),
                      child: _StudentsToolbar(
                        isWide: isWide,
                        searchController: _searchController,
                        searchQuery: _searchQuery,
                        onSearchChanged: (value) {
                          setState(() => _searchQuery = value.trim());
                        },
                        onClearSearch: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                        snapshot: snapshot,
                        statusFilter: _statusFilter,
                        onFilterChanged: (value) {
                          setState(() => _statusFilter = value);
                        },
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space3),
                    _StudentRosterList(
                      snapshot: snapshot,
                      statusFilter: _statusFilter,
                      searchQuery: _searchQuery,
                      onResetFilters: () {
                        _searchController.clear();
                        setState(() {
                          _statusFilter = null;
                          _searchQuery = '';
                        });
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StudentsToolbar extends StatelessWidget {
  const _StudentsToolbar({
    required this.isWide,
    required this.searchController,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.snapshot,
    required this.statusFilter,
    required this.onFilterChanged,
  });

  final bool isWide;
  final TextEditingController searchController;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final ClassroomAttendanceSnapshot snapshot;
  final AttendanceStatus? statusFilter;
  final ValueChanged<AttendanceStatus?> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    final searchField = TextField(
      controller: searchController,
      style: AppTypography.body,
      onChanged: onSearchChanged,
      decoration: InputDecoration(
        hintText: 'ค้นหาชื่อหรือเลขประจำตัวนักเรียน',
        prefixIcon: const Icon(
          Icons.search,
          size: 20,
          color: AppColors.textSecondary,
        ),
        suffixIcon: searchQuery.isEmpty
            ? null
            : IconButton(
                tooltip: 'ล้างคำค้นหา',
                onPressed: onClearSearch,
                icon: const Icon(Icons.close, size: 18),
              ),
      ),
    );

    final filterBar = StatusFilterBar(
      selectedStatus: statusFilter,
      totalCount: snapshot.totalStudents,
      countsByStatus: <AttendanceStatus, int>{
        AttendanceStatus.present: snapshot.presentCount,
        AttendanceStatus.late: snapshot.lateCount,
        AttendanceStatus.absent: snapshot.absentCount,
        AttendanceStatus.leave: snapshot.leaveCount,
        AttendanceStatus.pending: snapshot.pendingCount,
        AttendanceStatus.unknown: snapshot.unknownCount,
      },
      availableStatuses: <AttendanceStatus>[
        AttendanceStatus.pending,
        AttendanceStatus.present,
        AttendanceStatus.late,
        AttendanceStatus.leave,
        AttendanceStatus.absent,
        if (snapshot.unknownCount > 0) AttendanceStatus.unknown,
      ],
      onChanged: onFilterChanged,
    );

    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          SizedBox(width: 280, child: searchField),
          const SizedBox(width: AppSpacing.space4),
          Expanded(
            child: Align(alignment: Alignment.centerRight, child: filterBar),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        searchField,
        const SizedBox(height: AppSpacing.space2),
        filterBar,
      ],
    );
  }
}

class _StudentRosterList extends StatelessWidget {
  const _StudentRosterList({
    required this.snapshot,
    required this.statusFilter,
    required this.searchQuery,
    required this.onResetFilters,
  });

  final ClassroomAttendanceSnapshot snapshot;
  final AttendanceStatus? statusFilter;
  final String searchQuery;
  final VoidCallback onResetFilters;

  @override
  Widget build(BuildContext context) {
    final students = snapshot.students.where((student) {
      final matchesStatus =
          statusFilter == null || student.todayEntry.status == statusFilter;
      final query = searchQuery.toLowerCase();
      final matchesQuery =
          query.isEmpty ||
          student.fullName.toLowerCase().contains(query) ||
          student.studentId.toLowerCase().contains(query);
      return matchesStatus && matchesQuery;
    }).toList();

    if (students.isEmpty) {
      return EmptyStateView(
        icon: Icons.filter_list_off_outlined,
        title: 'ไม่พบนักเรียนที่ตรงกับตัวกรอง',
        description: 'ลองล้างคำค้นหาหรือเลือกดูสถานะทั้งหมด',
        actionLabel: 'แสดงทั้งหมด',
        onAction: onResetFilters,
      );
    }

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFFFFFF),
        border: Border(
          top: BorderSide(color: Color(0xFFE2E8E4)),
          bottom: BorderSide(color: Color(0xFFE2E8E4)),
        ),
      ),
      child: Column(
        children: <Widget>[
          for (var i = 0; i < students.length; i++) ...<Widget>[
            _RosterStudentRow(
              rollNumber: i + 1,
              student: students[i],
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => StudentDetailScreen(
                      studentId: students[i].studentId,
                      initialDate: snapshot.date,
                      isReadOnly: false,
                    ),
                  ),
                );
              },
            ),
            if (i < students.length - 1)
              const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
          ],
        ],
      ),
    );
  }
}

class _RosterStudentRow extends StatelessWidget {
  const _RosterStudentRow({
    required this.rollNumber,
    required this.student,
    required this.onTap,
  });

  final int rollNumber;
  final StudentAttendanceRecord student;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final entry = student.todayEntry;
    final rollLabel = rollNumber.toString().padLeft(2, '0');
    final maskedId = ThaiFormat.maskStudentId(student.studentId);

    final String timestampLabel = switch (entry.status) {
      AttendanceStatus.present || AttendanceStatus.late =>
        entry.firstScanAt != null
            ? ThaiFormat.time24Nbsp(entry.firstScanAt!)
            : 'บันทึกแล้ว',
      AttendanceStatus.pending => 'รอสแกน',
      AttendanceStatus.absent => 'ไม่พบการสแกน',
      AttendanceStatus.leave => 'แจ้งลา',
      AttendanceStatus.unknown => 'รอซิงก์',
    };

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              SizedBox(
                width: 32,
                child: Text(
                  rollLabel,
                  style: AppTypography.bodyStrong.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF64748B),
                    fontFeatures: const <FontFeature>[
                      FontFeature.tabularFigures(),
                    ],
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
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'รหัส $maskedId',
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
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  AttendanceStatusChip(status: entry.status, compact: true),
                  const SizedBox(height: 3),
                  Text(
                    timestampLabel,
                    style: AppTypography.microLabel.copyWith(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF64748B),
                      fontFeatures: const <FontFeature>[
                        FontFeature.tabularFigures(),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
