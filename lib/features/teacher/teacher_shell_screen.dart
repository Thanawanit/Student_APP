import 'package:flutter/material.dart';

import '../../shared/widgets/editorial_bottom_nav.dart';
import 'teacher_account_tab.dart';
import 'teacher_history_tab.dart';
import 'teacher_overview_tab.dart';

/// Main Teacher shell with slim editorial bottom bar: ภาพรวม, ประวัติ, บัญชี.
class TeacherShellScreen extends StatefulWidget {
  const TeacherShellScreen({super.key});

  @override
  State<TeacherShellScreen> createState() => _TeacherShellScreenState();
}

class _TeacherShellScreenState extends State<TeacherShellScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: const <Widget>[
          TeacherOverviewTab(),
          TeacherHistoryTab(),
          TeacherAccountTab(),
        ],
      ),
      bottomNavigationBar: EditorialBottomNav(
        selectedIndex: _selectedIndex,
        onSelected: (index) => setState(() => _selectedIndex = index),
        destinations: const <EditorialNavDestination>[
          EditorialNavDestination(
            icon: Icons.fact_check_outlined,
            selectedIcon: Icons.fact_check,
            label: 'ภาพรวม',
          ),
          EditorialNavDestination(
            icon: Icons.history_outlined,
            selectedIcon: Icons.history,
            label: 'ประวัติ',
          ),
          EditorialNavDestination(
            icon: Icons.person_outline,
            selectedIcon: Icons.person,
            label: 'บัญชี',
          ),
        ],
      ),
    );
  }
}
