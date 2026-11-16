import '../models/attendance_models.dart';
import '../models/attendance_status.dart';
import '../models/school_structure.dart';

/// Backend-agnostic authentication boundary.
/// Replace implementation with actual school auth API without altering UI screens.
abstract interface class AuthRepository {
  Future<TeacherSession> signInTeacher({
    required String identifier,
    required String password,
  });

  Future<ParentSession> enterParentByStudentId({required String studentId});
}

/// Backend-agnostic attendance data boundary.
/// Preserves backend ownership of attendance calculations, cutoffs, and calendar rules.
abstract interface class AttendanceRepository {
  PrototypeTimeScenario get scenario;
  set scenario(PrototypeTimeScenario value);

  Future<ClassroomAttendanceSnapshot> getClassroomAttendance({
    required ClassroomId classroom,
    required DateTime date,
  });

  Future<StudentAttendanceRecord> getStudentAttendance({
    required String studentId,
  });

  Future<StudentAttendanceRecord> updateAttendanceStatus({
    required String studentId,
    required DateTime date,
    required AttendanceStatus newStatus,
    required TeacherSession editor,
    String? note,
  });

  Future<List<ParentNotificationItem>> getParentNotifications({
    required String studentId,
  });

  Future<void> markNotificationRead({
    required String studentId,
    required String notificationId,
  });
}
