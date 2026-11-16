import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/responsive_layout.dart';
import '../../shared/widgets/dashboard_gradient_header.dart';
import '../../shared/widgets/school_brand_mark.dart';
import '../../shared/widgets/state_views.dart';
import '../auth/parent_entry_screen.dart';
import '../auth/teacher_login_screen.dart';

/// Screen A — Role selection with Khunyuam Wittaya editorial masthead.
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
                        // Editorial school masthead with top-to-bottom green-to-white wash
                        DashboardGradientBand(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                              inset,
                              AppSpacing.space5,
                              inset,
                              AppSpacing.space5,
                            ),
                            child: ResponsiveContent(
                              padding: EdgeInsets.zero,
                              child: Row(
                                children: <Widget>[
                                  const SchoolLogoMark(size: 52),
                                  const SizedBox(width: AppSpacing.space4),
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
                        ),

                        const SizedBox(height: AppSpacing.space5),

                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: inset),
                          child: ResponsiveContent(
                            padding: EdgeInsets.zero,
                            child: Text(
                              'เลือกประเภทผู้ใช้งาน',
                              style: AppTypography.microLabel.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.space2),

                        // Equal-weight editorial role bands separated by crisp hairlines
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
                            child: Column(
                              children: <Widget>[
                                _EditorialRoleRow(
                                  inset: inset,
                                  icon: Icons.school_outlined,
                                  title: 'เข้าสู่ระบบคุณครู',
                                  description:
                                      'เลือกชั้นเรียน ตรวจสอบสรุปการเข้าเรียนรายวัน ประวัติย้อนหลัง และแก้ไขสถานะ',
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) =>
                                            const TeacherLoginScreen(),
                                      ),
                                    );
                                  },
                                ),
                                const Divider(),
                                _EditorialRoleRow(
                                  inset: inset,
                                  icon: Icons.person_outline,
                                  title: 'เข้าสู่ระบบผู้ปกครอง',
                                  description:
                                      'ตรวจสอบสถานะการมาเรียนวันนี้ สรุปรายสัปดาห์ และประวัติย้อนหลังของนักเรียน',
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) =>
                                            const ParentEntryScreen(),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: AppSpacing.space4),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: inset),
                          child: ResponsiveContent(
                            padding: EdgeInsets.zero,
                            child: Text(
                              'หมายเหตุ: ก่อนเวลา 09:00 น. นักเรียนที่ยังไม่พบการสแกนเข้าโรงเรียนจะแสดงเป็น "รอยืนยัน" และยังไม่ถูกนับเป็นขาดเรียน',
                              style: AppTypography.supporting,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Quiet footer metadata
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

class _EditorialRoleRow extends StatelessWidget {
  const _EditorialRoleRow({
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
        constraints: const BoxConstraints(minHeight: 88),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: inset,
            vertical: AppSpacing.space4,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.brandPrimarySoft,
                  borderRadius: BorderRadius.circular(AppRadius.control),
                ),
                child: Icon(icon, color: AppColors.brandPrimary, size: 22),
              ),
              const SizedBox(width: AppSpacing.space4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(title, style: AppTypography.sectionTitle),
                    const SizedBox(height: 3),
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
