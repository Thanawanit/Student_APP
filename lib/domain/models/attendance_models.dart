import 'attendance_status.dart';
import 'school_structure.dart';

enum UserRole { teacher, parent }

enum SyncFreshness { fresh, delayed, unavailable }

/// Prototype simulation mode for testing pre-cutoff, post-cutoff, and sync-delay states.
enum PrototypeTimeScenario {
  beforeCutoff,
  afterCutoff,
  syncDelayed;

  String get label => switch (this) {
    PrototypeTimeScenario.beforeCutoff => 'ก่อน 09:00 น. (รอยืนยัน)',
    PrototypeTimeScenario.afterCutoff => 'หลัง 09:00 น. (สรุปผลแล้ว)',
    PrototypeTimeScenario.syncDelayed => 'ข้อมูลซิงก์ล่าช้า',
  };
}

class SyncMetadata {
  const SyncMetadata({
    required this.freshness,
    this.lastSyncedAt,
    this.message,
  });

  final SyncFreshness freshness;
  final DateTime? lastSyncedAt;
  final String? message;

  bool get canEditSafely => freshness != SyncFreshness.unavailable;
}

class AttendanceAuditEntry {
  const AttendanceAuditEntry({
    required this.previousStatus,
    required this.newStatus,
    required this.editorName,
    required this.editorRoleLabel,
    required this.editedAt,
    this.note,
  });

  final AttendanceStatus previousStatus;
  final AttendanceStatus newStatus;
  final String editorName;
  final String editorRoleLabel;
  final DateTime editedAt;
  final String? note;
}

class DailyAttendanceEntry {
  const DailyAttendanceEntry({
    required this.date,
    required this.status,
    this.firstScanAt,
    required this.isFinalized,
    this.auditEntries = const <AttendanceAuditEntry>[],
  });

  final DateTime date;
  final AttendanceStatus status;
  final DateTime? firstScanAt;
  final bool isFinalized;
  final List<AttendanceAuditEntry> auditEntries;

  DailyAttendanceEntry copyWith({
    AttendanceStatus? status,
    DateTime? firstScanAt,
    bool? isFinalized,
    List<AttendanceAuditEntry>? auditEntries,
  }) {
    return DailyAttendanceEntry(
      date: date,
      status: status ?? this.status,
      firstScanAt: firstScanAt ?? this.firstScanAt,
      isFinalized: isFinalized ?? this.isFinalized,
      auditEntries: auditEntries ?? this.auditEntries,
    );
  }
}

class StudentAttendanceRecord {
  const StudentAttendanceRecord({
    required this.studentId,
    required this.fullName,
    required this.classroom,
    required this.todayEntry,
    required this.weeklySummary,
    required this.history,
  });

  final String studentId;
  final String fullName;
  final ClassroomId classroom;
  final DailyAttendanceEntry todayEntry;
  final WeeklySummary weeklySummary;
  final List<DailyAttendanceEntry> history;
}

class WeeklySummary {
  const WeeklySummary({
    required this.weekLabel,
    required this.lateCount,
    required this.absentCount,
    required this.leaveCount,
    required this.presentCount,
  });

  final String weekLabel;
  final int lateCount;
  final int absentCount;
  final int leaveCount;
  final int presentCount;
}

class ClassroomAttendanceSnapshot {
  const ClassroomAttendanceSnapshot({
    required this.classroom,
    required this.date,
    required this.isBeforeCutoff,
    required this.syncMetadata,
    required this.students,
  });

  final ClassroomId classroom;
  final DateTime date;
  final bool isBeforeCutoff;
  final SyncMetadata syncMetadata;
  final List<StudentAttendanceRecord> students;

  int get totalStudents => students.length;

  int countByStatus(AttendanceStatus status) =>
      students.where((s) => s.todayEntry.status == status).length;

  int get presentCount => countByStatus(AttendanceStatus.present);
  int get lateCount => countByStatus(AttendanceStatus.late);

  /// Pending students must never be included in absentCount (Section 6.4).
  int get absentCount => countByStatus(AttendanceStatus.absent);
  int get leaveCount => countByStatus(AttendanceStatus.leave);
  int get pendingCount => countByStatus(AttendanceStatus.pending);
  int get unknownCount => countByStatus(AttendanceStatus.unknown);
}

class ParentNotificationItem {
  const ParentNotificationItem({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.title,
    required this.body,
    required this.targetDate,
    required this.newStatus,
    this.previousStatus,
    required this.createdAt,
    required this.isRead,
  });

  final String id;
  final String studentId;
  final String studentName;
  final String title;
  final String body;
  final DateTime targetDate;
  final AttendanceStatus newStatus;
  final AttendanceStatus? previousStatus;
  final DateTime createdAt;
  final bool isRead;

  ParentNotificationItem copyWith({bool? isRead}) {
    return ParentNotificationItem(
      id: id,
      studentId: studentId,
      studentName: studentName,
      title: title,
      body: body,
      targetDate: targetDate,
      newStatus: newStatus,
      previousStatus: previousStatus,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
    );
  }
}

class TeacherSession {
  const TeacherSession({
    required this.teacherId,
    required this.displayName,
    required this.roleLabel,
    required this.credentialUsed,
  });

  final String teacherId;
  final String displayName;
  final String roleLabel;
  final String credentialUsed;
}

class ParentSession {
  const ParentSession({
    required this.studentId,
    required this.studentName,
    required this.classroom,
  });

  final String studentId;
  final String studentName;
  final ClassroomId classroom;
}
