import '../core/utils/thai_date_format.dart';
import '../domain/models/attendance_models.dart';
import '../domain/models/attendance_status.dart';
import '../domain/models/school_structure.dart';
import '../domain/repositories/attendance_repository.dart';

/// Clearly-marked sample implementation for the UI Prototype.
/// Replace with real API/database repositories without changing UI layers.
class SampleAttendanceRepository
    implements AuthRepository, AttendanceRepository {
  SampleAttendanceRepository({DateTime? referenceNow})
    : _referenceNow = referenceNow ?? DateTime(2026, 11, 16, 8, 25);

  final DateTime _referenceNow;

  @override
  PrototypeTimeScenario scenario = PrototypeTimeScenario.beforeCutoff;

  final Map<String, Map<String, DailyAttendanceEntry>> _overrideStore =
      <String, Map<String, DailyAttendanceEntry>>{};

  final Map<String, List<ParentNotificationItem>> _notificationsByStudent =
      <String, List<ParentNotificationItem>>{};

  static const List<String> _sampleFirstNames = <String>[
    'กิตติภพ',
    'ณัฐชา',
    'ธนกฤต',
    'ปภาวดี',
    'ภูริช',
    'รินรดา',
    'วริศรา',
    'ศุภวิชญ์',
    'สิริยากร',
    'อชิรวิทย์',
    'ชญานิษฐ์',
    'ธีรภัทร',
  ];

  static const List<String> _sampleLastNames = <String>[
    'ใจดี',
    'สุขสวัสดิ์',
    'วัฒนากูล',
    'ศรีสมบูรณ์',
    'ตั้งเจริญ',
    'รัตนโชติ',
    'วงศ์ประเสริฐ',
    'แสงทอง',
    'เจริญสุข',
    'พิทักษ์กุล',
    'มณีรัตน์',
    'อินทร์แก้ว',
  ];

  DateTime get _todayDateOnly =>
      DateTime(_referenceNow.year, _referenceNow.month, _referenceNow.day);

  String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  bool _isSameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Future<TeacherSession> signInTeacher({
    required String identifier,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    final cleanId = identifier.trim();
    if (cleanId.isEmpty || password.trim().isEmpty) {
      throw const RepositoryException('กรุณากรอกข้อมูลเข้าสู่ระบบให้ครบถ้วน');
    }
    if (cleanId == 'error' || password == 'wrong') {
      throw const RepositoryException(
        'ไม่พบบัญชีผู้ใช้หรือรหัสผ่านไม่ถูกต้อง กรุณาตรวจสอบอีกครั้ง',
      );
    }
    return TeacherSession(
      teacherId: 'T-SAMPLE-01',
      displayName: 'ครูอารยา วงศ์สุวรรณ (ตัวอย่าง)',
      roleLabel: 'คุณครู',
      credentialUsed: cleanId,
    );
  }

  @override
  Future<ParentSession> enterParentByStudentId({
    required String studentId,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final cleanId = studentId.trim();
    if (cleanId.isEmpty || !RegExp(r'^\d{5,10}$').hasMatch(cleanId)) {
      throw const RepositoryException(
        'กรุณากรอกเลขประจำตัวนักเรียนเป็นตัวเลข 5–10 หลัก',
      );
    }
    final match = _findStudentSeed(cleanId);
    if (match == null) {
      throw const RepositoryException(
        'ไม่พบข้อมูลนักเรียนจากเลขประจำตัวนี้ กรุณาตรวจสอบกับทางโรงเรียน',
      );
    }
    return ParentSession(
      studentId: match.studentId,
      studentName: match.fullName,
      classroom: match.classroom,
    );
  }

  @override
  Future<ClassroomAttendanceSnapshot> getClassroomAttendance({
    required ClassroomId classroom,
    required DateTime date,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    final targetDate = DateTime(date.year, date.month, date.day);

    // Weekends have no scheduled school attendance in sample data.
    if (targetDate.weekday == DateTime.saturday ||
        targetDate.weekday == DateTime.sunday ||
        targetDate.isAfter(_todayDateOnly)) {
      return ClassroomAttendanceSnapshot(
        classroom: classroom,
        date: targetDate,
        isBeforeCutoff: false,
        syncMetadata: SyncMetadata(
          freshness: SyncFreshness.fresh,
          lastSyncedAt: _referenceNow,
        ),
        students: const <StudentAttendanceRecord>[],
      );
    }

    final isToday = _isSameDate(targetDate, _todayDateOnly);
    final isBeforeCutoff =
        isToday && scenario == PrototypeTimeScenario.beforeCutoff;
    final isSyncDelayed =
        isToday && scenario == PrototypeTimeScenario.syncDelayed;

    final seeds = _seedsForClassroom(classroom);
    final records = seeds
        .map((seed) => _buildStudentRecord(seed, targetDate))
        .toList(growable: false);

    final syncMeta = isSyncDelayed
        ? SyncMetadata(
            freshness: SyncFreshness.unavailable,
            lastSyncedAt: _referenceNow.subtract(const Duration(minutes: 42)),
            message:
                'การเชื่อมต่อข้อมูลล่าสุดล่าช้าชั่วคราว จึงปิดการแก้ไขสถานะไว้ชั่วคราวเพื่อความถูกต้องของข้อมูล',
          )
        : SyncMetadata(
            freshness: SyncFreshness.fresh,
            lastSyncedAt: isToday
                ? (scenario == PrototypeTimeScenario.afterCutoff
                      ? DateTime(
                          _todayDateOnly.year,
                          _todayDateOnly.month,
                          _todayDateOnly.day,
                          9,
                          30,
                        )
                      : _referenceNow)
                : DateTime(
                    targetDate.year,
                    targetDate.month,
                    targetDate.day,
                    16,
                    0,
                  ),
          );

    return ClassroomAttendanceSnapshot(
      classroom: classroom,
      date: targetDate,
      isBeforeCutoff: isBeforeCutoff,
      syncMetadata: syncMeta,
      students: records,
    );
  }

  @override
  Future<StudentAttendanceRecord> getStudentAttendance({
    required String studentId,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 160));
    final seed = _findStudentSeed(studentId);
    if (seed == null) {
      throw const RepositoryException('ไม่พบข้อมูลนักเรียนที่ต้องการ');
    }
    return _buildStudentRecord(seed, _todayDateOnly);
  }

  @override
  Future<StudentAttendanceRecord> updateAttendanceStatus({
    required String studentId,
    required DateTime date,
    required AttendanceStatus newStatus,
    required TeacherSession editor,
    String? note,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    if (scenario == PrototypeTimeScenario.syncDelayed &&
        _isSameDate(date, _todayDateOnly)) {
      throw const RepositoryException(
        'ไม่สามารถบันทึกได้เนื่องจากข้อมูลกำลังซิงก์ล่าช้า กรุณาลองใหม่อีกครั้งเมื่อระบบพร้อม',
      );
    }
    if (!AttendanceStatus.editableValues.contains(newStatus)) {
      throw const RepositoryException('สถานะที่เลือกไม่รองรับการบันทึก');
    }

    final seed = _findStudentSeed(studentId);
    if (seed == null) {
      throw const RepositoryException('ไม่พบข้อมูลนักเรียน');
    }

    final targetDate = DateTime(date.year, date.month, date.day);
    final currentRecord = _buildStudentRecord(seed, targetDate);
    final currentEntry = _isSameDate(targetDate, _todayDateOnly)
        ? currentRecord.todayEntry
        : currentRecord.history.firstWhere(
            (e) => _isSameDate(e.date, targetDate),
            orElse: () => currentRecord.todayEntry,
          );

    final auditEntry = AttendanceAuditEntry(
      previousStatus: currentEntry.status,
      newStatus: newStatus,
      editorName: editor.displayName,
      editorRoleLabel: editor.roleLabel,
      editedAt: DateTime.now(),
      note: (note != null && note.trim().isNotEmpty) ? note.trim() : null,
    );

    final updatedEntry = currentEntry.copyWith(
      status: newStatus,
      isFinalized: true,
      auditEntries: <AttendanceAuditEntry>[
        auditEntry,
        ...currentEntry.auditEntries,
      ],
    );

    final dateKey = _dateKey(targetDate);
    _overrideStore.putIfAbsent(
      studentId,
      () => <String, DailyAttendanceEntry>{},
    )[dateKey] = updatedEntry;

    // Emit notification only after save confirmation (Section 5.10).
    final existingNotifications = _ensureNotifications(seed);
    existingNotifications.insert(
      0,
      ParentNotificationItem(
        id: 'notif-${DateTime.now().microsecondsSinceEpoch}',
        studentId: seed.studentId,
        studentName: seed.fullName,
        title: 'มีการเปลี่ยนแปลงสถานะการเข้าเรียน',
        body:
            'เปลี่ยนสถานะจาก "${currentEntry.status.label}" เป็น "${newStatus.label}" โดย${editor.displayName}',
        targetDate: targetDate,
        previousStatus: currentEntry.status,
        newStatus: newStatus,
        createdAt: DateTime.now(),
        isRead: false,
      ),
    );

    return _buildStudentRecord(seed, _todayDateOnly);
  }

  @override
  Future<List<ParentNotificationItem>> getParentNotifications({
    required String studentId,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    final seed = _findStudentSeed(studentId);
    if (seed == null) {
      return const <ParentNotificationItem>[];
    }
    return List<ParentNotificationItem>.unmodifiable(
      _ensureNotifications(seed),
    );
  }

  @override
  Future<void> markNotificationRead({
    required String studentId,
    required String notificationId,
  }) async {
    final list = _notificationsByStudent[studentId];
    if (list == null) {
      return;
    }
    for (var i = 0; i < list.length; i++) {
      if (list[i].id == notificationId) {
        list[i] = list[i].copyWith(isRead: true);
        break;
      }
    }
  }

  List<ParentNotificationItem> _ensureNotifications(_StudentSeed seed) {
    return _notificationsByStudent.putIfAbsent(seed.studentId, () {
      final yesterday = _prevSchoolDay(_todayDateOnly, 1);
      final earlier = _prevSchoolDay(_todayDateOnly, 3);
      return <ParentNotificationItem>[
        ParentNotificationItem(
          id: 'notif-seed-${seed.studentId}-1',
          studentId: seed.studentId,
          studentName: seed.fullName,
          title: 'บันทึกสถานะการมาเรียนของนักเรียนแล้ว',
          body: 'นักเรียนสแกนเข้าโรงเรียนเวลา 07:42 น. (สถานะมาเรียน)',
          targetDate: yesterday,
          newStatus: AttendanceStatus.present,
          createdAt: DateTime(
            yesterday.year,
            yesterday.month,
            yesterday.day,
            7,
            44,
          ),
          isRead: false,
        ),
        ParentNotificationItem(
          id: 'notif-seed-${seed.studentId}-2',
          studentId: seed.studentId,
          studentName: seed.fullName,
          title: 'บันทึกสถานะการมาเรียนของนักเรียนแล้ว',
          body: 'บันทึกสถานะประจำวันเรียบร้อยแล้ว',
          targetDate: earlier,
          newStatus: AttendanceStatus.present,
          createdAt: DateTime(earlier.year, earlier.month, earlier.day, 7, 40),
          isRead: true,
        ),
      ];
    });
  }

  StudentAttendanceRecord _buildStudentRecord(
    _StudentSeed seed,
    DateTime focusDate,
  ) {
    final todayEntry = _entryForDate(seed, focusDate, isFocusDate: true);

    final historyDates = <DateTime>[];
    var cursor = _todayDateOnly;
    while (historyDates.length < 25) {
      if (cursor.weekday != DateTime.saturday &&
          cursor.weekday != DateTime.sunday) {
        historyDates.add(cursor);
      }
      cursor = cursor.subtract(const Duration(days: 1));
    }

    final history = historyDates
        .map((d) => _entryForDate(seed, d, isFocusDate: false))
        .toList(growable: false);

    // Compute current school week summary from sample entries (Mon..today).
    final weekEntries = history.where((entry) {
      final diff = _todayDateOnly.difference(entry.date).inDays;
      return diff >= 0 && diff < _todayDateOnly.weekday;
    }).toList();

    final weeklySummary = WeeklySummary(
      weekLabel: 'สัปดาห์ ${ThaiFormat.schoolWeekRange(_todayDateOnly)}',
      presentCount: weekEntries
          .where((e) => e.status == AttendanceStatus.present)
          .length,
      lateCount: weekEntries
          .where((e) => e.status == AttendanceStatus.late)
          .length,
      absentCount: weekEntries
          .where((e) => e.status == AttendanceStatus.absent)
          .length,
      leaveCount: weekEntries
          .where((e) => e.status == AttendanceStatus.leave)
          .length,
    );

    return StudentAttendanceRecord(
      studentId: seed.studentId,
      fullName: seed.fullName,
      classroom: seed.classroom,
      todayEntry: todayEntry,
      weeklySummary: weeklySummary,
      history: history,
    );
  }

  DailyAttendanceEntry _entryForDate(
    _StudentSeed seed,
    DateTime date, {
    required bool isFocusDate,
  }) {
    final normalized = DateTime(date.year, date.month, date.day);
    final override = _overrideStore[seed.studentId]?[_dateKey(normalized)];
    if (override != null) {
      return override;
    }

    final isToday = _isSameDate(normalized, _todayDateOnly);
    if (isToday) {
      if (scenario == PrototypeTimeScenario.syncDelayed &&
          seed.index % 4 == 2) {
        return DailyAttendanceEntry(
          date: normalized,
          status: AttendanceStatus.unknown,
          isFinalized: false,
        );
      }

      switch (seed.todayPattern) {
        case _TodayPattern.present:
          return DailyAttendanceEntry(
            date: normalized,
            status: AttendanceStatus.present,
            firstScanAt: DateTime(
              normalized.year,
              normalized.month,
              normalized.day,
              7,
              32 + (seed.index % 20),
            ),
            isFinalized: true,
          );
        case _TodayPattern.late:
          return DailyAttendanceEntry(
            date: normalized,
            status: AttendanceStatus.late,
            firstScanAt: DateTime(
              normalized.year,
              normalized.month,
              normalized.day,
              8,
              5 + (seed.index % 18),
            ),
            isFinalized: true,
          );
        case _TodayPattern.leave:
          return DailyAttendanceEntry(
            date: normalized,
            status: AttendanceStatus.leave,
            isFinalized: true,
          );
        case _TodayPattern.noScanYet:
          if (scenario == PrototypeTimeScenario.beforeCutoff) {
            return DailyAttendanceEntry(
              date: normalized,
              status: AttendanceStatus.pending,
              isFinalized: false,
            );
          }
          if (scenario == PrototypeTimeScenario.syncDelayed) {
            return DailyAttendanceEntry(
              date: normalized,
              status: AttendanceStatus.unknown,
              isFinalized: false,
            );
          }
          return DailyAttendanceEntry(
            date: normalized,
            status: AttendanceStatus.absent,
            isFinalized: true,
          );
      }
    }

    // Deterministic historical records.
    final daySeed = (seed.index * 7 + normalized.day + normalized.month) % 10;
    if (daySeed == 1) {
      return DailyAttendanceEntry(
        date: normalized,
        status: AttendanceStatus.late,
        firstScanAt: DateTime(
          normalized.year,
          normalized.month,
          normalized.day,
          8,
          12,
        ),
        isFinalized: true,
      );
    }
    if (daySeed == 4) {
      return DailyAttendanceEntry(
        date: normalized,
        status: AttendanceStatus.absent,
        isFinalized: true,
      );
    }
    if (daySeed == 7) {
      return DailyAttendanceEntry(
        date: normalized,
        status: AttendanceStatus.leave,
        isFinalized: true,
      );
    }
    return DailyAttendanceEntry(
      date: normalized,
      status: AttendanceStatus.present,
      firstScanAt: DateTime(
        normalized.year,
        normalized.month,
        normalized.day,
        7,
        36 + (seed.index % 19),
      ),
      isFinalized: true,
    );
  }

  DateTime _prevSchoolDay(DateTime start, int count) {
    var d = start;
    var remaining = count;
    while (remaining > 0) {
      d = d.subtract(const Duration(days: 1));
      if (d.weekday != DateTime.saturday && d.weekday != DateTime.sunday) {
        remaining--;
      }
    }
    return d;
  }

  List<_StudentSeed> _seedsForClassroom(ClassroomId classroom) {
    final isFeaturedRoom = classroom.grade == 5 && classroom.room == 2;
    const count = 12;
    return List<_StudentSeed>.generate(count, (i) {
      final studentId = isFeaturedRoom
          ? '6501${(i + 1).toString().padLeft(2, '0')}'
          : '65${classroom.grade}${classroom.room}${(i + 1).toString().padLeft(2, '0')}';

      final first =
          _sampleFirstNames[(i + classroom.room) % _sampleFirstNames.length];
      final last =
          _sampleLastNames[(i + classroom.grade) % _sampleLastNames.length];

      final _TodayPattern pattern;
      if (isFeaturedRoom) {
        // Explicit showcase IDs for Parent Entry testing:
        // 650101: present, 650102: late, 650103: pending/absent, 650104: leave
        pattern = switch (i) {
          0 => _TodayPattern.present,
          1 => _TodayPattern.late,
          2 => _TodayPattern.noScanYet,
          3 => _TodayPattern.leave,
          4 => _TodayPattern.noScanYet,
          5 => _TodayPattern.late,
          _ => _TodayPattern.present,
        };
      } else {
        pattern = switch ((i + classroom.room) % 8) {
          1 => _TodayPattern.late,
          2 || 6 => _TodayPattern.noScanYet,
          4 => _TodayPattern.leave,
          _ => _TodayPattern.present,
        };
      }

      return _StudentSeed(
        index: i,
        studentId: studentId,
        fullName: '$first $last',
        classroom: classroom,
        todayPattern: pattern,
      );
    });
  }

  _StudentSeed? _findStudentSeed(String studentId) {
    for (final stage in EducationStage.values) {
      for (final grade in stage.grades) {
        for (final room in ClassroomId.roomsForGrade(stage, grade)) {
          for (final seed in _seedsForClassroom(room)) {
            if (seed.studentId == studentId) {
              return seed;
            }
          }
        }
      }
    }
    return null;
  }
}

class RepositoryException implements Exception {
  const RepositoryException(this.message);
  final String message;

  @override
  String toString() => message;
}

enum _TodayPattern { present, late, leave, noScanYet }

class _StudentSeed {
  const _StudentSeed({
    required this.index,
    required this.studentId,
    required this.fullName,
    required this.classroom,
    required this.todayPattern,
  });

  final int index;
  final String studentId;
  final String fullName;
  final ClassroomId classroom;
  final _TodayPattern todayPattern;
}
