import 'package:attendance_app/app.dart';
import 'package:attendance_app/data/sample_attendance_repository.dart';
import 'package:attendance_app/features/teacher/teacher_overview_tab.dart';
import 'package:attendance_app/features/teacher/teacher_students_tab.dart';
import 'package:attendance_app/state/app_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  AppController createTestController() {
    final repo = SampleAttendanceRepository();
    return AppController(authRepository: repo, attendanceRepository: repo);
  }

  testWidgets(
    'Role selection shows Khunyuam Wittaya branding and equal role choices',
    (tester) async {
      await tester.pumpWidget(
        AttendanceApp(controller: createTestController()),
      );
      await tester.pumpAndSettle();

      expect(find.text('โรงเรียนขุนยวมวิทยา'), findsOneWidget);
      expect(find.text('เข้าสู่ระบบคุณครู'), findsOneWidget);
      expect(find.text('เข้าสู่ระบบผู้ปกครอง'), findsOneWidget);
    },
  );

  testWidgets(
    'Teacher IA: Overview separates summary from dedicated Student List and supports editing',
    (tester) async {
      await tester.pumpWidget(
        AttendanceApp(controller: createTestController()),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('เข้าสู่ระบบคุณครู'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('กรอกบัญชีคุณครูตัวอย่าง'));
      await tester.pump();
      await tester.tap(find.text('เข้าสู่ระบบ'));
      await tester.pumpAndSettle();

      // Screen D: Stage -> Grade -> Room
      await tester.ensureVisible(find.text('มัธยมศึกษาตอนปลาย'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('มัธยมศึกษาตอนปลาย'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('มัธยมศึกษาปีที่ 5 (ม.5)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('มัธยมศึกษาปีที่ 5 (ม.5)'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('ห้อง 5/2'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ห้อง 5/2'));
      await tester.pumpAndSettle();

      // Screen A: Teacher Overview (no full 12-student table here)
      expect(
        find.textContaining('มัธยมศึกษาตอนปลาย / ม.5 / ห้อง 5/2'),
        findsWidgets,
      );
      expect(find.textContaining('จาก 12 คน'), findsOneWidget);
      expect(find.text('75%'), findsOneWidget);
      expect(find.text('สแกนเข้าโรงเรียนแล้ว'), findsOneWidget);
      expect(find.text('ดูรายชื่อทั้งหมด (12)'), findsOneWidget);

      // Open dedicated Student List screen
      await tester.ensureVisible(find.text('ดูรายชื่อทั้งหมด (12)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ดูรายชื่อทั้งหมด (12)'));
      await tester.pumpAndSettle();

      // Screen B: Dedicated Student List
      final studentsTabFinder = find.byType(TeacherStudentsTab);
      final studentFinder = find.descendant(
        of: studentsTabFinder,
        matching: find.text('ภูริช แสงทอง'),
      );
      await tester.ensureVisible(studentFinder);
      await tester.pumpAndSettle();
      await tester.tap(studentFinder);
      await tester.pumpAndSettle();

      // Student Detail -> Edit Status -> Confirm
      await tester.tap(find.text('แก้ไขสถานะ'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('ลา').last);
      await tester.pump();
      await tester.ensureVisible(find.text('บันทึกการแก้ไข'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('บันทึกการแก้ไข'));
      await tester.pumpAndSettle();

      expect(find.text('ยืนยันการแก้ไขสถานะ'), findsOneWidget);
      await tester.tap(find.text('ยืนยันบันทึก'));
      await tester.pumpAndSettle();

      expect(find.text('บันทึกการแก้ไขสถานะเรียบร้อยแล้ว'), findsOneWidget);
      expect(find.text('ประวัติการแก้ไขสถานะ'), findsOneWidget);
    },
  );

  testWidgets(
    'Parent IA: Overview shows 3-item preview and navigates to dedicated History & Notifications',
    (tester) async {
      await tester.pumpWidget(
        AttendanceApp(controller: createTestController()),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('เข้าสู่ระบบผู้ปกครอง'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '650103');
      await tester.tap(find.text('เข้าสู่ระบบ'));
      await tester.pumpAndSettle();

      expect(find.text('ภูริช แสงทอง'), findsOneWidget);
      expect(find.text('สรุปสัปดาห์นี้'), findsOneWidget);
      expect(find.text('สัปดาห์ 16–20 พ.ย. 2569'), findsOneWidget);
      expect(find.text('รอยืนยัน'), findsWidgets);
      expect(find.text('ดูประวัติการเข้าเรียนย้อนหลัง'), findsOneWidget);
      expect(find.text('แก้ไขสถานะ'), findsNothing);

      // Navigate to dedicated Parent History screen and filter by October
      await tester.ensureVisible(find.text('ดูประวัติการเข้าเรียนย้อนหลัง'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ดูประวัติการเข้าเรียนย้อนหลัง'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('ต.ค. 2569').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('ต.ค. 2569').first);
      await tester.pumpAndSettle();
      expect(find.textContaining('ตุลาคม 2569'), findsWidgets);

      // Open Parent Notifications screen via navigation rail/bar
      await tester.tap(find.text('แจ้งเตือน').first);
      await tester.pumpAndSettle();
      expect(find.textContaining('ภูริช แสงทอง'), findsWidgets);
    },
  );

  testWidgets(
    'Expanded 1100dp Windows layout renders sidebar and multi-column overview cleanly',
    (tester) async {
      tester.view.physicalSize = const Size(1100, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        AttendanceApp(controller: createTestController()),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('เข้าสู่ระบบผู้ปกครอง'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '650101');
      await tester.tap(find.text('เข้าสู่ระบบ'));
      await tester.pumpAndSettle();

      expect(find.text('โหมดผู้ปกครอง'), findsOneWidget);
      expect(find.text('ธนกฤต รัตนโชติ'), findsWidgets);
      expect(find.text('ดูประวัติการเข้าเรียนย้อนหลัง'), findsOneWidget);
    },
  );

  testWidgets('Medium 700dp tablet width renders NavigationRail cleanly', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(700, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(AttendanceApp(controller: createTestController()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('เข้าสู่ระบบผู้ปกครอง'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '650101');
    await tester.tap(find.text('เข้าสู่ระบบ'));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationRail), findsOneWidget);
  });

  testWidgets(
    'Compact 360dp width with 1.4x font scaling renders Teacher Overview without overflow',
    (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.4)),
          child: AttendanceApp(controller: createTestController()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('เข้าสู่ระบบคุณครู'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('กรอกบัญชีคุณครูตัวอย่าง'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('กรอกบัญชีคุณครูตัวอย่าง'));
      await tester.pump();
      await tester.ensureVisible(find.text('เข้าสู่ระบบ'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('เข้าสู่ระบบ'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('มัธยมศึกษาตอนปลาย'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('มัธยมศึกษาตอนปลาย'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('มัธยมศึกษาปีที่ 5 (ม.5)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('มัธยมศึกษาปีที่ 5 (ม.5)'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('ห้อง 5/2'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ห้อง 5/2'));
      await tester.pumpAndSettle();

      expect(find.byType(TeacherOverviewTab), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Compact 360dp mobile Parent Overview prioritizes today status and compact preview',
    (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        AttendanceApp(controller: createTestController()),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('เข้าสู่ระบบผู้ปกครอง'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '650101');
      await tester.tap(find.text('เข้าสู่ระบบ'));
      await tester.pumpAndSettle();

      expect(find.text('ธนกฤต รัตนโชติ'), findsOneWidget);
      expect(find.text('ถึงโรงเรียนแล้ว (ตรงเวลา)'), findsOneWidget);
      expect(find.text('สรุปสัปดาห์นี้'), findsOneWidget);
      expect(find.text('ดูประวัติการเข้าเรียนย้อนหลัง'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
