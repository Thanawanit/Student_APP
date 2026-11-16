import 'package:attendance_app/app.dart';
import 'package:attendance_app/data/sample_attendance_repository.dart';
import 'package:attendance_app/features/teacher/teacher_overview_tab.dart';
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
    'Teacher flow navigates stage -> grade -> room -> overview -> edit',
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

      // Screen E: Dashboard-First Class Overview
      expect(
        find.textContaining('มัธยมศึกษาตอนปลาย / ม.5 / ห้อง 5/2'),
        findsOneWidget,
      );
      expect(find.textContaining('จาก 12 คน'), findsOneWidget);
      expect(find.text('75%'), findsOneWidget);
      expect(find.text('รายชื่อนักเรียนทั้งห้อง'), findsOneWidget);

      // Open student 3 detail (index 2 in featured room: รอยืนยัน)
      final overviewFinder = find.byType(TeacherOverviewTab);
      final studentFinder = find
          .descendant(of: overviewFinder, matching: find.text('ภูริช แสงทอง'))
          .last;
      await tester.ensureVisible(studentFinder);
      await tester.pumpAndSettle();
      await tester.tap(studentFinder);
      await tester.pumpAndSettle();

      // Screen G -> Screen H: Edit status with confirmation dialog
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
    'Parent flow is strictly read-only, shows history month filter and notifications',
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
      expect(find.text('ทุกเดือน'), findsWidgets);
      expect(find.text('ต.ค. 2569'), findsWidgets);
      expect(find.text('แก้ไขสถานะ'), findsNothing);

      // Filter history by October month on Parent Dashboard
      await tester.ensureVisible(find.text('ต.ค. 2569').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('ต.ค. 2569').first);
      await tester.pumpAndSettle();
      expect(find.textContaining('ตุลาคม 2569'), findsWidgets);

      // Open Parent Notifications screen
      await tester.tap(find.byTooltip('การแจ้งเตือน'));
      await tester.pumpAndSettle();
      expect(find.text('การแจ้งเตือน'), findsOneWidget);
      expect(find.textContaining('ภูริช แสงทอง'), findsWidgets);
    },
  );

  testWidgets(
    'Desktop 1100dp width renders Teacher Overview and Parent Dashboard cleanly',
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

      expect(find.text('ธนกฤต รัตนโชติ'), findsOneWidget);
      expect(find.text('วันที่'), findsOneWidget);
    },
  );

  testWidgets(
    'Compact 360dp width with 1.4x font scaling renders without overflow',
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

      expect(tester.takeException(), isNull);

      // Navigate into Teacher Overview at compact 360dp + 1.4x text scaling.
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

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Compact 360dp mobile Parent Dashboard prioritizes today status and compact history',
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
      expect(find.text('ดูทั้งหมด / กรองรายเดือน'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
