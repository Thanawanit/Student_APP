import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Daily attendance statuses defined in ATTENDANCE_APP_DESIGN_SYSTEM.md (Section 3.1 & 6.1).
enum AttendanceStatus {
  present,
  late,
  absent,
  leave,
  pending,
  unknown;

  /// Only these 4 statuses are selectable when a teacher/admin edits a record.
  static const List<AttendanceStatus> editableValues = <AttendanceStatus>[
    AttendanceStatus.present,
    AttendanceStatus.late,
    AttendanceStatus.absent,
    AttendanceStatus.leave,
  ];

  String get label => switch (this) {
    AttendanceStatus.present => 'มาเรียน',
    AttendanceStatus.late => 'มาสาย',
    AttendanceStatus.absent => 'ขาดเรียน',
    AttendanceStatus.leave => 'ลา',
    AttendanceStatus.pending => 'รอยืนยัน',
    AttendanceStatus.unknown => 'ตรวจสอบข้อมูล',
  };

  String get detailDescription => switch (this) {
    AttendanceStatus.present => 'บันทึกการมาเรียนก่อนเวลา 08:00 น.',
    AttendanceStatus.late => 'บันทึกการเข้าเรียนตั้งแต่เวลา 08:00 น. เป็นต้นไป',
    AttendanceStatus.absent =>
      'ไม่พบการสแกนและไม่มีบันทึกการลาหลังเวลา 09:00 น.',
    AttendanceStatus.leave => 'มีการบันทึกสถานะลาเรียบร้อยแล้ว',
    AttendanceStatus.pending =>
      'ยังไม่พบการสแกน • รอยืนยันสถานะถึงเวลา 09:00 น.',
    AttendanceStatus.unknown =>
      'ข้อมูลยังไม่ล่าสุดหรืออยู่ระหว่างตรวจสอบ กรุณารอการซิงก์',
  };

  Color get foregroundColor => switch (this) {
    AttendanceStatus.present => AppColors.presentForeground,
    AttendanceStatus.late => AppColors.lateForeground,
    AttendanceStatus.absent => AppColors.absentForeground,
    AttendanceStatus.leave => AppColors.leaveForeground,
    AttendanceStatus.pending => AppColors.pendingForeground,
    AttendanceStatus.unknown => AppColors.unknownForeground,
  };

  Color get backgroundColor => switch (this) {
    AttendanceStatus.present => AppColors.presentBackground,
    AttendanceStatus.late => AppColors.lateBackground,
    AttendanceStatus.absent => AppColors.absentBackground,
    AttendanceStatus.leave => AppColors.leaveBackground,
    AttendanceStatus.pending => AppColors.pendingBackground,
    AttendanceStatus.unknown => AppColors.unknownBackground,
  };

  IconData get icon => switch (this) {
    AttendanceStatus.present => Icons.check_circle_outline,
    AttendanceStatus.late => Icons.schedule_outlined,
    AttendanceStatus.absent => Icons.highlight_off_outlined,
    AttendanceStatus.leave => Icons.event_note_outlined,
    AttendanceStatus.pending => Icons.hourglass_empty_outlined,
    AttendanceStatus.unknown => Icons.sync_problem_outlined,
  };
}
