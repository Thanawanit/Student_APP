import 'package:flutter/material.dart';

import '../../shared/widgets/editorial_bottom_nav.dart';
import 'parent_account_tab.dart';
import 'parent_history_tab.dart';
import 'parent_overview_tab.dart';

/// Main Parent shell with slim editorial bottom bar: ภาพรวม, ประวัติ, บัญชี.
class ParentShellScreen extends StatefulWidget {
  const ParentShellScreen({super.key});

  @override
  State<ParentShellScreen> createState() => _ParentShellScreenState();
}

class _ParentShellScreenState extends State<ParentShellScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: <Widget>[
          ParentOverviewTab(
            onOpenFullHistory: () => setState(() => _selectedIndex = 1),
          ),
          const ParentHistoryTab(),
          const ParentAccountTab(),
        ],
      ),
      bottomNavigationBar: EditorialBottomNav(
        selectedIndex: _selectedIndex,
        onSelected: (index) => setState(() => _selectedIndex = index),
        destinations: const <EditorialNavDestination>[
          EditorialNavDestination(
            icon: Icons.home_outlined,
            selectedIcon: Icons.home,
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
