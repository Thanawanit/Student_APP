import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/responsive_layout.dart';
import '../../core/utils/thai_date_format.dart';
import '../../domain/models/attendance_models.dart';
import '../../shared/widgets/school_brand_mark.dart';
import '../../state/app_controller.dart';
import '../role_selection/role_selection_screen.dart';
import 'parent_notifications_screen.dart';

/// Parent account & privacy summary tab (strictly read-only).
class ParentAccountTab extends StatelessWidget {
  const ParentAccountTab({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final session = controller.parentSession;
    final inset = ResponsiveContent.horizontalInset(context);

    return Scaffold(
      appBar: AppBar(title: const Text('บัญชีผู้ปกครอง')),
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
                                  session?.studentName ?? 'นักเรียน',
                                  style: AppTypography.sectionTitle,
                                ),
                                if (session != null)
                                  Text(
                                    '${session.classroom.hierarchyLabel} • รหัส ${ThaiFormat.maskStudentId(session.studentId)}',
                                    style: AppTypography.supporting,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.space3),
                      const Divider(),
                      const SizedBox(height: AppSpacing.space3),
                      Text(
                        'สิทธิ์การใช้งาน: ดูข้อมูลการเข้าเรียนแบบอ่านอย่างเดียว',
                        style: AppTypography.supporting,
                      ),
                      const SizedBox(height: AppSpacing.space3),
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const ParentNotificationsScreen(),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.notifications_outlined,
                          size: 18,
                        ),
                        label: const Text('ดูประวัติการแจ้งเตือน'),
                      ),
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
                  child: Text(
                    'ตัวจำลองช่วงเวลา (สำหรับทดสอบ UI Prototype)',
                    style: AppTypography.sectionTitle,
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
                        _ParentScenarioRow(
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
                        'เปลี่ยนนักเรียน / ออกจากระบบ',
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

class _ParentScenarioRow extends StatelessWidget {
  const _ParentScenarioRow({
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
