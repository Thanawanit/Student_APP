import 'package:attendance_app/core/utils/thai_date_format.dart';
import 'package:attendance_app/data/sample_attendance_repository.dart';
import 'package:attendance_app/domain/models/attendance_models.dart';
import 'package:attendance_app/domain/models/attendance_status.dart';
import 'package:attendance_app/domain/models/school_structure.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SchoolStructure', () {
    test('contains 18 lower-secondary and 21 upper-secondary classrooms', () {
      final lowerRooms = EducationStage.lowerSecondary.grades
          .expand(
            (g) => ClassroomId.roomsForGrade(EducationStage.lowerSecondary, g),
          )
          .toList();
      final upperRooms = EducationStage.upperSecondary.grades
          .expand(
            (g) => ClassroomId.roomsForGrade(EducationStage.upperSecondary, g),
          )
          .toList();

      expect(lowerRooms.length, 18);
      expect(upperRooms.length, 21);
      expect(lowerRooms.length + upperRooms.length, 39);
      expect(
        const ClassroomId(
          stage: EducationStage.upperSecondary,
          grade: 5,
          room: 2,
        ).hierarchyLabel,
        'มัธยมศึกษาตอนปลาย / ม.5 / ห้อง 5/2',
      );
    });
  });

  group('Attendance status integrity rules', () {
    test(
      'before 09:00 unscanned students are pending and excluded from absentCount',
      () async {
        final repo = SampleAttendanceRepository();
        repo.scenario = PrototypeTimeScenario.beforeCutoff;

        final snapshot = await repo.getClassroomAttendance(
          classroom: const ClassroomId(
            stage: EducationStage.upperSecondary,
            grade: 5,
            room: 2,
          ),
          date: DateTime(2026, 11, 16),
        );

        expect(snapshot.isBeforeCutoff, isTrue);
        expect(snapshot.pendingCount, greaterThan(0));
        expect(snapshot.absentCount, 0);
      },
    );

    test(
      'after 09:00 unscanned students without leave become absent',
      () async {
        final repo = SampleAttendanceRepository();
        repo.scenario = PrototypeTimeScenario.afterCutoff;

        final snapshot = await repo.getClassroomAttendance(
          classroom: const ClassroomId(
            stage: EducationStage.upperSecondary,
            grade: 5,
            room: 2,
          ),
          date: DateTime(2026, 11, 16),
        );

        expect(snapshot.isBeforeCutoff, isFalse);
        expect(snapshot.pendingCount, 0);
        expect(snapshot.absentCount, greaterThan(0));
      },
    );

    test(
      'sync delay marks unknown instead of absent and blocks unsafe editing',
      () async {
        final repo = SampleAttendanceRepository();
        repo.scenario = PrototypeTimeScenario.syncDelayed;

        final snapshot = await repo.getClassroomAttendance(
          classroom: const ClassroomId(
            stage: EducationStage.upperSecondary,
            grade: 5,
            room: 2,
          ),
          date: DateTime(2026, 11, 16),
        );

        expect(snapshot.syncMetadata.freshness, SyncFreshness.unavailable);
        expect(snapshot.syncMetadata.canEditSafely, isFalse);
        expect(snapshot.unknownCount, greaterThan(0));
        expect(snapshot.absentCount, 0);

        final teacher = await repo.signInTeacher(
          identifier: 'teacher.sample',
          password: 'pw',
        );
        expect(
          () => repo.updateAttendanceStatus(
            studentId: '650103',
            date: DateTime(2026, 11, 16),
            newStatus: AttendanceStatus.present,
            editor: teacher,
          ),
          throwsA(isA<RepositoryException>()),
        );
      },
    );

    test(
      'confirmed edit creates audit entry and unread parent notification',
      () async {
        final repo = SampleAttendanceRepository();
        final teacher = await repo.signInTeacher(
          identifier: 'teacher.sample',
          password: 'pw',
        );

        final updated = await repo.updateAttendanceStatus(
          studentId: '650103',
          date: DateTime(2026, 11, 16),
          newStatus: AttendanceStatus.leave,
          editor: teacher,
          note: 'ผู้ปกครองแจ้งลาป่วย',
        );

        expect(updated.todayEntry.status, AttendanceStatus.leave);
        expect(updated.todayEntry.auditEntries, hasLength(1));
        expect(
          updated.todayEntry.auditEntries.first.previousStatus,
          AttendanceStatus.pending,
        );
        expect(
          updated.todayEntry.auditEntries.first.newStatus,
          AttendanceStatus.leave,
        );

        final notifications = await repo.getParentNotifications(
          studentId: '650103',
        );
        expect(notifications.first.isRead, isFalse);
        expect(notifications.first.newStatus, AttendanceStatus.leave);
      },
    );
  });

  group('ThaiFormat', () {
    test(
      'formats 24-hour time, Buddhist Era date, week range, and masked student ID',
      () {
        final dt = DateTime(2026, 11, 16, 7, 42);
        expect(ThaiFormat.time24(dt), '07:42 น.');
        expect(ThaiFormat.fullDate(dt), 'วันจันทร์ที่ 16 พฤศจิกายน 2569');
        expect(ThaiFormat.monthYearShort(dt), 'พ.ย. 2569');
        expect(ThaiFormat.schoolWeekRange(dt), '16–20 พ.ย. 2569');
        expect(ThaiFormat.maskStudentId('650101'), '•••101');
      },
    );
  });
}
