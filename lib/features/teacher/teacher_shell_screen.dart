import 'package:flutter/material.dart';

import '../../domain/models/attendance_status.dart';
import '../../shared/widgets/adaptive_shell.dart';
import '../../state/app_controller.dart';
import 'teacher_account_tab.dart';
import 'teacher_history_tab.dart';
import 'teacher_overview_tab.dart';
import 'teacher_students_tab.dart';

/// Adaptive Teacher shell: Overview, Student List, History, Account.
class TeacherShellScreen extends StatefulWidget {
  const TeacherShellScreen({super.key});

  @override
  State<TeacherShellScreen> createState() => _TeacherShellScreenState();
}

class _TeacherShellScreenState extends State<TeacherShellScreen> {
  int _selectedIndex = 0;
  AttendanceStatus? _requestedListFilter;
  int _filterRevision = 0;

  void _openStudentList([AttendanceStatus? filter]) {
    setState(() {
      _requestedListFilter = filter;
      _filterRevision++;
      _selectedIndex = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final classroom = controller.selectedClassroom;

    return AdaptiveNavigationShell(
      selectedIndex: _selectedIndex,
      onSelected: (index) => setState(() => _selectedIndex = index),
      roleTitle: 'โหมดคุณครู',
      contextSubtitle: classroom?.hierarchyLabel,
      destinations: const <AdaptiveDestination>[
        AdaptiveDestination(
          icon: Icons.dashboard_outlined,
          selectedIcon: Icons.dashboard,
          label: 'ภาพรวม',
        ),
        AdaptiveDestination(
          icon: Icons.people_outline,
          selectedIcon: Icons.people,
          label: 'รายชื่อ',
        ),
        AdaptiveDestination(
          icon: Icons.history_outlined,
          selectedIcon: Icons.history,
          label: 'ประวัติ',
        ),
        AdaptiveDestination(
          icon: Icons.person_outline,
          selectedIcon: Icons.person,
          label: 'บัญชี',
        ),
      ],
      children: <Widget>[
        TeacherOverviewTab(
          onOpenStudentList: _openStudentList,
          onOpenHistory: () => setState(() => _selectedIndex = 2),
        ),
        TeacherStudentsTab(
          requestedFilter: _requestedListFilter,
          filterRevision: _filterRevision,
        ),
        const TeacherHistoryTab(),
        const TeacherAccountTab(),
      ],
    );
  }
}
