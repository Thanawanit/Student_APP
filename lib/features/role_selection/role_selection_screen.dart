import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/responsive_layout.dart';
import '../../shared/widgets/school_brand_mark.dart';
import '../../shared/widgets/state_views.dart';
import '../auth/parent_entry_screen.dart';
import '../auth/teacher_login_screen.dart';

/// Screen A — Light Editorial Role Selection (Apple Health / Linear inspired).
class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final inset = ResponsiveContent.horizontalInset(context);

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        // Clean Light Editorial Masthead
                        Container(
                          width: double.infinity,
                          color: AppColors.surface,
                          padding: EdgeInsets.fromLTRB(
                            inset,
                            AppSpacing.space5,
                            inset,
                            AppSpacing.space4,
                          ),
                          child: ResponsiveContent(
                            padding: EdgeInsets.zero,
                            child: Row(
                              children: <Widget>[
                                const SchoolLogoMark(size: 46),
                                const SizedBox(width: AppSpacing.space3),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        'โรงเรียนขุนยวมวิทยา',
                                        style: AppTypography.pageTitle,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Attendance App • ระบบติดตามการเข้าเรียนรายวัน',
                                        style: AppTypography.supporting,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Divider(),

                        const SizedBox(height: AppSpacing.space5),

                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: inset),
                          child: ResponsiveContent(
                            padding: EdgeInsets.zero,
                            child: Text(
                              'เลือกประเภทผู้ใช้งาน',
                              style: AppTypography.microLabel.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.space2),

                        // Full-width hairline-separated role list
                        Container(
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            color: AppColors.surface,
                            border: Border(
                              top: BorderSide(color: AppColors.borderSubtle),
                              bottom: BorderSide(color: AppColors.borderSubtle),
                            ),
                          ),
                          child: ResponsiveContent(
                            padding: EdgeInsets.zero,
                            child: LayoutBuilder(
                              builder: (context, box) {
                                final teacherRow = _RoleRow(
                                  inset: inset,
                                  icon: Icons.school_outlined,
                                  title: 'เข้าสู่ระบบคุณครู',
                                  description:
                                      'ดูภาพรวมการเข้าเรียนรายห้อง รายชื่อนักเรียน ประวัติย้อนหลัง และแก้ไขสถานะ',
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) =>
                                            const TeacherLoginScreen(),
                                      ),
                                    );
                                  },
                                );
                                final parentRow = _RoleRow(
                                  inset: inset,
                                  icon: Icons.person_outline,
                                  title: 'เข้าสู่ระบบผู้ปกครอง',
                                  description:
                                      'ตรวจสอบสถานะวันนี้ เวลาสแกนเข้า สรุปรายสัปดาห์ และประวัติย้อนหลัง',
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) =>
                                            const ParentEntryScreen(),
                                      ),
                                    );
                                  },
                                );

                                if (box.maxWidth >= 680) {
                                  return IntrinsicHeight(
                                    child: Row(
                                      children: <Widget>[
                                        Expanded(child: teacherRow),
                                        const VerticalDivider(
                                          width: 1,
                                          thickness: 1,
                                          color: AppColors.borderSubtle,
                                        ),
                                        Expanded(child: parentRow),
                                      ],
                                    ),
                                  );
                                }

                                return Column(
                                  children: <Widget>[
                                    teacherRow,
                                    Divider(indent: inset, endIndent: inset),
                                    parentRow,
                                  ],
                                );
                              },
                            ),
                          ),
                        ),

                        const SizedBox(height: AppSpacing.space4),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: inset),
                          child: ResponsiveContent(
                            padding: EdgeInsets.zero,
                            child: Wrap(
                              spacing: AppSpacing.space4,
                              runSpacing: AppSpacing.space1,
                              children: const <Widget>[
                                _RuleLegend(
                                  color: AppColors.presentForeground,
                                  text: 'ก่อน 08:00 มาเรียน',
                                ),
                                _RuleLegend(
                                  color: AppColors.lateForeground,
                                  text: '08:00+ มาสาย',
                                ),
                                _RuleLegend(
                                  color: AppColors.pendingForeground,
                                  text: 'ตัดรอบขาดเรียน 09:00 น.',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        inset,
                        AppSpacing.space6,
                        inset,
                        AppSpacing.space4,
                      ),
                      child: const ResponsiveContent(
                        padding: EdgeInsets.zero,
                        child: PrototypeSampleNotice(),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _RuleLegend extends StatelessWidget {
  const _RuleLegend({required this.color, required this.text});

  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Flexible(child: Text(text, style: AppTypography.microLabel)),
      ],
    );
  }
}

class _RoleRow extends StatelessWidget {
  const _RoleRow({
    required this.inset,
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final double inset;
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 84),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: inset,
            vertical: AppSpacing.space4,
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.brandPrimarySoft,
                  borderRadius: BorderRadius.circular(AppRadius.control),
                ),
                child: Icon(icon, color: AppColors.brandPrimary, size: 20),
              ),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(title, style: AppTypography.sectionTitle),
                    const SizedBox(height: 2),
                    Text(description, style: AppTypography.supporting),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.space2),
              const Icon(
                Icons.chevron_right,
                size: 20,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
