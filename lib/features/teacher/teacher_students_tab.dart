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
import '../../shared/widgets/student_attendance_row.dart';
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
        titleSpacing: inset,
        title: const Text('รายชื่อนักเรียน'),
        actions: <Widget>[
          if (classroom != null)
            TextButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const TeacherClassSelectionScreen(
                      isSwitchingRoom: true,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.swap_horiz, size: 18),
              label: Text('ห้อง ${classroom.code}'),
            ),
          const SizedBox(width: AppSpacing.space2),
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
                        '${classroom.hierarchyLabel} • ${ThaiFormat.fullDate(controller.todayDate)}',
                        style: AppTypography.supporting,
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
        AttendanceStatus.present,
        AttendanceStatus.late,
        AttendanceStatus.absent,
        AttendanceStatus.leave,
        if (snapshot.pendingCount > 0 || snapshot.isBeforeCutoff)
          AttendanceStatus.pending,
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
    final inset = ResponsiveContent.horizontalInset(context);
    final isDesktop = MediaQuery.sizeOf(context).width >= 640;

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
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
                SizedBox(
                  width: 28,
                  child: Text('#', style: AppTypography.microLabel),
                ),
                const SizedBox(width: AppSpacing.space2),
                Expanded(
                  child: Text(
                    'รายชื่อนักเรียน (${students.length})',
                    style: AppTypography.microLabel,
                  ),
                ),
                const SizedBox(width: AppSpacing.space3),
                SizedBox(
                  width: 84,
                  child: Text('รหัส', style: AppTypography.microLabel),
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
          )
        else
          Padding(
            padding: EdgeInsets.fromLTRB(inset, 0, inset, AppSpacing.space2),
            child: Text(
              'แสดงผล ${students.length} จาก ${snapshot.totalStudents} คน',
              style: AppTypography.microLabel,
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
              for (var i = 0; i < students.length; i++) ...<Widget>[
                StudentAttendanceRow(
                  record: students[i],
                  entry: students[i].todayEntry,
                  sequenceNumber: i + 1,
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
                  Divider(indent: inset, endIndent: inset),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
