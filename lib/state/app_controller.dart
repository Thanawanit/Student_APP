import 'package:flutter/material.dart';

import '../data/sample_attendance_repository.dart';
import '../domain/models/attendance_models.dart';
import '../domain/models/attendance_status.dart';
import '../domain/models/school_structure.dart';
import '../domain/repositories/attendance_repository.dart';

class AppController extends ChangeNotifier {
  AppController({
    required AuthRepository authRepository,
    required AttendanceRepository attendanceRepository,
    DateTime? initialDate,
  }) : _authRepository = authRepository,
       _attendanceRepository = attendanceRepository,
       _todayDate = initialDate ?? DateTime(2026, 11, 16),
       _historyDate = initialDate ?? DateTime(2026, 11, 16);

  final AuthRepository _authRepository;
  final AttendanceRepository _attendanceRepository;

  final DateTime _todayDate;
  DateTime get todayDate => _todayDate;

  TeacherSession? _teacherSession;
  TeacherSession? get teacherSession => _teacherSession;

  ParentSession? _parentSession;
  ParentSession? get parentSession => _parentSession;

  ClassroomId? _selectedClassroom;
  ClassroomId? get selectedClassroom => _selectedClassroom;

  ClassroomAttendanceSnapshot? _classroomSnapshot;
  ClassroomAttendanceSnapshot? get classroomSnapshot => _classroomSnapshot;
  bool _isClassroomLoading = false;
  bool get isClassroomLoading => _isClassroomLoading;
  String? _classroomError;
  String? get classroomError => _classroomError;

  DateTime _historyDate;
  DateTime get historyDate => _historyDate;
  ClassroomAttendanceSnapshot? _historySnapshot;
  ClassroomAttendanceSnapshot? get historySnapshot => _historySnapshot;
  bool _isHistoryLoading = false;
  bool get isHistoryLoading => _isHistoryLoading;
  String? _historyError;
  String? get historyError => _historyError;

  StudentAttendanceRecord? _parentRecord;
  StudentAttendanceRecord? get parentRecord => _parentRecord;
  bool _isParentLoading = false;
  bool get isParentLoading => _isParentLoading;
  String? _parentError;
  String? get parentError => _parentError;

  List<ParentNotificationItem> _parentNotifications =
      const <ParentNotificationItem>[];
  List<ParentNotificationItem> get parentNotifications => _parentNotifications;

  int get unreadNotificationCount =>
      _parentNotifications.where((n) => !n.isRead).length;

  PrototypeTimeScenario get scenario => _attendanceRepository.scenario;

  Future<void> signInTeacher({
    required String identifier,
    required String password,
  }) async {
    _teacherSession = await _authRepository.signInTeacher(
      identifier: identifier,
      password: password,
    );
    _parentSession = null;
    notifyListeners();
  }

  Future<void> enterParent({required String studentId}) async {
    final session = await _authRepository.enterParentByStudentId(
      studentId: studentId,
    );
    _parentSession = session;
    _teacherSession = null;
    notifyListeners();
    await loadParentData();
  }

  void signOut() {
    _teacherSession = null;
    _parentSession = null;
    _selectedClassroom = null;
    _classroomSnapshot = null;
    _classroomError = null;
    _historySnapshot = null;
    _historyError = null;
    _parentRecord = null;
    _parentError = null;
    _parentNotifications = const <ParentNotificationItem>[];
    notifyListeners();
  }

  Future<void> selectClassroom(ClassroomId classroom) async {
    _selectedClassroom = classroom;
    notifyListeners();
    await Future.wait<void>(<Future<void>>[
      loadClassroomOverview(),
      loadTeacherHistory(_historyDate),
    ]);
  }

  Future<void> loadClassroomOverview() async {
    final classroom = _selectedClassroom;
    if (classroom == null) {
      return;
    }
    _isClassroomLoading = true;
    _classroomError = null;
    notifyListeners();
    try {
      _classroomSnapshot = await _attendanceRepository.getClassroomAttendance(
        classroom: classroom,
        date: _todayDate,
      );
    } on RepositoryException catch (e) {
      _classroomError = e.message;
    } catch (_) {
      _classroomError =
          'ไม่สามารถโหลดข้อมูลการเข้าเรียนได้ในขณะนี้ กรุณาลองใหม่อีกครั้ง';
    } finally {
      _isClassroomLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadTeacherHistory(DateTime date) async {
    final classroom = _selectedClassroom;
    if (classroom == null) {
      return;
    }
    _historyDate = DateTime(date.year, date.month, date.day);
    _isHistoryLoading = true;
    _historyError = null;
    notifyListeners();
    try {
      _historySnapshot = await _attendanceRepository.getClassroomAttendance(
        classroom: classroom,
        date: _historyDate,
      );
    } on RepositoryException catch (e) {
      _historyError = e.message;
    } catch (_) {
      _historyError =
          'ไม่สามารถโหลดประวัติการเข้าเรียนได้ในขณะนี้ กรุณาลองใหม่อีกครั้ง';
    } finally {
      _isHistoryLoading = false;
      notifyListeners();
    }
  }

  Future<StudentAttendanceRecord> fetchStudentDetail(String studentId) {
    return _attendanceRepository.getStudentAttendance(studentId: studentId);
  }

  Future<StudentAttendanceRecord> updateAttendanceStatus({
    required String studentId,
    required DateTime date,
    required AttendanceStatus newStatus,
    String? note,
  }) async {
    final editor = _teacherSession;
    if (editor == null) {
      throw const RepositoryException(
        'เฉพาะคุณครูหรือผู้ดูแลระบบเท่านั้นที่แก้ไขสถานะได้',
      );
    }
    final updated = await _attendanceRepository.updateAttendanceStatus(
      studentId: studentId,
      date: date,
      newStatus: newStatus,
      editor: editor,
      note: note,
    );
    await Future.wait<void>(<Future<void>>[
      loadClassroomOverview(),
      loadTeacherHistory(_historyDate),
    ]);
    return updated;
  }

  Future<void> loadParentData() async {
    final session = _parentSession;
    if (session == null) {
      return;
    }
    _isParentLoading = true;
    _parentError = null;
    notifyListeners();
    try {
      final results = await Future.wait<Object>(<Future<Object>>[
        _attendanceRepository.getStudentAttendance(
          studentId: session.studentId,
        ),
        _attendanceRepository.getParentNotifications(
          studentId: session.studentId,
        ),
      ]);
      _parentRecord = results[0] as StudentAttendanceRecord;
      _parentNotifications = results[1] as List<ParentNotificationItem>;
    } on RepositoryException catch (e) {
      _parentError = e.message;
    } catch (_) {
      _parentError =
          'ไม่สามารถโหลดข้อมูลนักเรียนได้ในขณะนี้ กรุณาลองใหม่อีกครั้ง';
    } finally {
      _isParentLoading = false;
      notifyListeners();
    }
  }

  Future<void> markNotificationRead(String notificationId) async {
    final session = _parentSession;
    if (session == null) {
      return;
    }
    await _attendanceRepository.markNotificationRead(
      studentId: session.studentId,
      notificationId: notificationId,
    );
    _parentNotifications = await _attendanceRepository.getParentNotifications(
      studentId: session.studentId,
    );
    notifyListeners();
  }

  Future<void> setPrototypeScenario(PrototypeTimeScenario value) async {
    _attendanceRepository.scenario = value;
    notifyListeners();
    if (_teacherSession != null && _selectedClassroom != null) {
      await Future.wait<void>(<Future<void>>[
        loadClassroomOverview(),
        loadTeacherHistory(_historyDate),
      ]);
    } else if (_parentSession != null) {
      await loadParentData();
    }
  }
}

class AppScope extends InheritedNotifier<AppController> {
  const AppScope({
    super.key,
    required AppController controller,
    required super.child,
  }) : super(notifier: controller);

  static AppController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found in widget tree');
    return scope!.notifier!;
  }
}
