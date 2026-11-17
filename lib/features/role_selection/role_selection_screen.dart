import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/responsive_layout.dart';
import '../../shared/widgets/school_brand_mark.dart';
import '../../shared/widgets/state_views.dart';
import '../auth/parent_entry_screen.dart';
import '../auth/teacher_login_screen.dart';

/// Screen A — Architectural Swiss Role Selection with Obsidian School Masthead.
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
                        // Architectural Obsidian Masthead
                        Container(
                          width: double.infinity,
                          color: AppColors.inkSurface,
                          padding: EdgeInsets.fromLTRB(
                            inset,
                            AppSpacing.space4,
                            inset,
                            AppSpacing.space4,
                          ),
                          child: ResponsiveContent(
                            padding: EdgeInsets.zero,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Row(
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
                                            style: AppTypography.pageTitle
                                                .copyWith(
                                                  color: AppColors.inkText,
                                                ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Attendance App • ระบบติดตามการเข้าเรียนรายวัน',
                                            style: AppTypography.supporting
                                                .copyWith(
                                                  color: AppColors.inkTextMuted,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.space4),
                                Container(
                                  height: 1,
                                  color: AppColors.inkSurfaceDivider,
                                ),
                                const SizedBox(height: AppSpacing.space3),
                                Wrap(
                                  spacing: AppSpacing.space4,
                                  runSpacing: AppSpacing.space2,
                                  children: const <Widget>[
                                    _RuleTag(
                                      dotColor: AppColors.inkEmeraldAccent,
                                      text: 'ก่อน 08:00 มาเรียน',
                                    ),
                                    _RuleTag(
                                      dotColor: Color(0xFFFBBF24),
                                      text: '08:00+ มาสาย',
                                    ),
                                    _RuleTag(
                                      dotColor: Color(0xFF9CA8A3),
                                      text: 'ตัดรอบ 09:00 น.',
                                    ),
                                  ],
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'เลือกประเภทผู้ใช้งาน',
                                  style: AppTypography.microLabel.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.space3),
                                LayoutBuilder(
                                  builder: (context, box) {
                                    final useTwoCols = box.maxWidth >= 640;
                                    final teacherTile = _RoleActionTile(
                                      indexCode: '01',
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
                                    final parentTile = _RoleActionTile(
                                      indexCode: '02',
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

                                    if (useTwoCols) {
                                      return IntrinsicHeight(
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: <Widget>[
                                            Expanded(child: teacherTile),
                                            const SizedBox(
                                              width: AppSpacing.space4,
                                            ),
                                            Expanded(child: parentTile),
                                          ],
                                        ),
                                      );
                                    }

                                    return Column(
                                      children: <Widget>[
                                        teacherTile,
                                        const SizedBox(
                                          height: AppSpacing.space3,
                                        ),
                                        parentTile,
                                      ],
                                    );
                                  },
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

class _RuleTag extends StatelessWidget {
  const _RuleTag({required this.dotColor, required this.text});

  final Color dotColor;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: AppTypography.microLabel.copyWith(
            color: AppColors.inkTextMuted,
          ),
        ),
      ],
    );
  }
}

class _RoleActionTile extends StatelessWidget {
  const _RoleActionTile({
    required this.indexCode,
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final String indexCode;
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.panel),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.panel),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.space4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.panel),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Text(
                        indexCode,
                        style: AppTypography.microLabel.copyWith(
                          color: AppColors.brandPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.space2),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.brandPrimarySoft,
                          borderRadius: BorderRadius.circular(AppRadius.badge),
                        ),
                        child: Icon(
                          icon,
                          color: AppColors.brandPrimary,
                          size: 17,
                        ),
                      ),
                    ],
                  ),
                  const Icon(
                    Icons.north_east,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space3),
              Text(title, style: AppTypography.sectionTitle),
              const SizedBox(height: AppSpacing.space1),
              Text(description, style: AppTypography.supporting),
            ],
          ),
        ),
      ),
    );
  }
}
