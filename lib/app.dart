import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'data/sample_attendance_repository.dart';
import 'features/role_selection/role_selection_screen.dart';
import 'state/app_controller.dart';

class AttendanceApp extends StatefulWidget {
  const AttendanceApp({super.key, this.controller});

  final AppController? controller;

  @override
  State<AttendanceApp> createState() => _AttendanceAppState();
}

class _AttendanceAppState extends State<AttendanceApp> {
  late final AppController _controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
      _ownsController = false;
    } else {
      final repo = SampleAttendanceRepository();
      _controller = AppController(
        authRepository: repo,
        attendanceRepository: repo,
      );
      _ownsController = true;
    }
  }

  @override
  void dispose() {
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      controller: _controller,
      child: MaterialApp(
        title: 'Attendance App',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const RoleSelectionScreen(),
      ),
    );
  }
}
