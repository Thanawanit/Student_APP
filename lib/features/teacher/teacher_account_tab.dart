import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/responsive_layout.dart';
import '../../domain/models/attendance_models.dart';
import '../../shared/widgets/school_brand_mark.dart';
import '../../state/app_controller.dart';
import '../role_selection/role_selection_screen.dart';
import 'class_selection_screen.dart';

/// Teacher account, classroom switcher, and prototype time-scenario controls.
class TeacherAccountTab extends StatelessWidget {
  const TeacherAccountTab({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final teacher = controller.teacherSession;
    final classroom = controller.selectedClassroom;
    final inset = ResponsiveContent.horizontalInset(context);

    return Scaffold(
      appBar: AppBar(title: const Text('บัญชีและห้องเรียน')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.space6),
        children: <Widget>[
          ResponsiveContent(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    border: Border(
                      top: BorderSide(color: AppColors.borderSubtle),
                      bottom: BorderSide(color: AppColors.borderSubtle),
                    ),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: inset,
                    vertical: AppSpacing.space4,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          const SchoolLogoMark(size: 40),
                          const SizedBox(width: AppSpacing.space3),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  teacher?.displayName ?? 'คุณครู',
                                  style: AppTypography.sectionTitle,
                                ),
                                Text(
                                  'โรงเรียนขุนยวมวิทยา • ${teacher?.roleLabel ?? 'คุณครู'}',
                                  style: AppTypography.supporting,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (classroom != null) ...<Widget>[
                        const SizedBox(height: AppSpacing.space4),
                        const Divider(),
                        const SizedBox(height: AppSpacing.space3),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    'ห้องเรียนที่กำลังดูอยู่',
                                    style: AppTypography.microLabel,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    classroom.hierarchyLabel,
                                    style: AppTypography.bodyStrong,
                                  ),
                                ],
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) =>
                                        const TeacherClassSelectionScreen(
                                          isSwitchingRoom: true,
                                        ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.swap_horiz, size: 18),
                              label: const Text('เปลี่ยนห้อง'),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                Padding(
                  padding: EdgeInsets.fromLTRB(
                    inset,
                    AppSpacing.space5,
                    inset,
                    AppSpacing.space2,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'ตัวจำลองช่วงเวลา (สำหรับทดสอบ UI Prototype)',
                        style: AppTypography.sectionTitle,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'สลับสถานการณ์เพื่อดูสถานะก่อน 09:00 น. (รอยืนยัน), หลัง 09:00 น. (สรุปผล) และกรณีข้อมูลซิงก์ล่าช้า',
                        style: AppTypography.supporting,
                      ),
                    ],
                  ),
                ),

                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    border: Border(
                      top: BorderSide(color: AppColors.borderSubtle),
                      bottom: BorderSide(color: AppColors.borderSubtle),
                    ),
                  ),
                  child: Column(
                    children: <Widget>[
                      for (
                        var i = 0;
                        i < PrototypeTimeScenario.values.length;
                        i++
                      ) ...<Widget>[
                        _ScenarioRowTile(
                          inset: inset,
                          scenario: PrototypeTimeScenario.values[i],
                          isSelected:
                              controller.scenario ==
                              PrototypeTimeScenario.values[i],
                          onTap: () => controller.setPrototypeScenario(
                            PrototypeTimeScenario.values[i],
                          ),
                        ),
                        if (i < PrototypeTimeScenario.values.length - 1)
                          const Divider(),
                      ],
                    ],
                  ),
                ),

                Padding(
                  padding: EdgeInsets.fromLTRB(
                    inset,
                    AppSpacing.space5,
                    inset,
                    AppSpacing.space2,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        controller.signOut();
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute<void>(
                            builder: (_) => const RoleSelectionScreen(),
                          ),
                          (_) => false,
                        );
                      },
                      icon: const Icon(
                        Icons.logout,
                        size: 18,
                        color: AppColors.absentForeground,
                      ),
                      label: Text(
                        'ออกจากระบบ',
                        style: AppTypography.bodyStrong.copyWith(
                          color: AppColors.absentForeground,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScenarioRowTile extends StatelessWidget {
  const _ScenarioRowTile({
    required this.inset,
    required this.scenario,
    required this.isSelected,
    required this.onTap,
  });

  final double inset;
  final PrototypeTimeScenario scenario;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSpacing.minTouchTarget),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: inset,
            vertical: AppSpacing.space3,
          ),
          child: Row(
            children: <Widget>[
              Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                size: 20,
                color: isSelected
                    ? AppColors.brandPrimary
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: Text(
                  scenario.label,
                  style: AppTypography.body.copyWith(
                    color: isSelected
                        ? AppColors.brandPrimary
                        : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
