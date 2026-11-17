import 'package:flutter/material.dart';

import '../../shared/widgets/adaptive_shell.dart';
import '../../state/app_controller.dart';
import 'parent_account_tab.dart';
import 'parent_history_tab.dart';
import 'parent_notifications_screen.dart';
import 'parent_overview_tab.dart';

/// Adaptive Parent shell: Overview, History, Notifications, Account.
class ParentShellScreen extends StatefulWidget {
  const ParentShellScreen({super.key});

  @override
  State<ParentShellScreen> createState() => _ParentShellScreenState();
}

class _ParentShellScreenState extends State<ParentShellScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final session = controller.parentSession;
    final unread = controller.unreadNotificationCount;

    return AdaptiveNavigationShell(
      selectedIndex: _selectedIndex,
      onSelected: (index) => setState(() => _selectedIndex = index),
      roleTitle: 'โหมดผู้ปกครอง',
      contextSubtitle: session != null
          ? '${session.studentName}\n${session.classroom.roomLabel}'
          : null,
      destinations: <AdaptiveDestination>[
        const AdaptiveDestination(
          icon: Icons.home_outlined,
          selectedIcon: Icons.home,
          label: 'ภาพรวม',
        ),
        const AdaptiveDestination(
          icon: Icons.history_outlined,
          selectedIcon: Icons.history,
          label: 'ประวัติ',
        ),
        AdaptiveDestination(
          icon: Icons.notifications_outlined,
          selectedIcon: Icons.notifications,
          label: 'แจ้งเตือน',
          badgeCount: unread,
        ),
        const AdaptiveDestination(
          icon: Icons.person_outline,
          selectedIcon: Icons.person,
          label: 'บัญชี',
        ),
      ],
      children: <Widget>[
        ParentOverviewTab(
          onOpenFullHistory: () => setState(() => _selectedIndex = 1),
          onOpenNotifications: () => setState(() => _selectedIndex = 2),
        ),
        const ParentHistoryTab(),
        const ParentNotificationsScreen(isEmbedded: true),
        const ParentAccountTab(),
      ],
    );
  }
}
