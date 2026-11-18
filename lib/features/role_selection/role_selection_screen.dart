import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_typography.dart';
import '../../core/utils/responsive_layout.dart';
import '../../shared/widgets/school_brand_mark.dart';
import '../auth/parent_entry_screen.dart';
import '../auth/teacher_login_screen.dart';

/// Landing / Role Selection Screen (`โรงเรียนขุนยวมวิทยา`) with Green-White
/// gradient header, separate elevated role cards, structured attendance
/// criteria card, and centered sample data pill.
class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final inset = ResponsiveContent.horizontalInset(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F5F3),
        body: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      // 1. Top Header Container (Green-to-White Gradient)
                      Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: <Color>[
                              Color(0xFF8FC7A6),
                              Color(0xFFB4DAC3),
                              Color(0xFFDCEEE3),
                              Color(0xFFF2F5F3),
                            ],
                            stops: <double>[0.0, 0.4, 0.78, 1.0],
                          ),
                        ),
                        child: SafeArea(
                          bottom: false,
                          child: ResponsiveContent(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[
                                Container(
                                  width: 60,
                                  height: 60,
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: <BoxShadow>[
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.06,
                                        ),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Center(
                                    child: SchoolLogoMark(size: 52),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        'โรงเรียนขุนยวมวิทยา',
                                        style: AppTypography.pageTitle.copyWith(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF14532D),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'ระบบติดตามการเข้าเรียนรายวัน',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTypography.supporting
                                            .copyWith(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: const Color(0xFF4B6355),
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // 2. Role Selection Cards & 3. Attendance Criteria Card
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: inset),
                        child: ResponsiveContent(
                          padding: EdgeInsets.zero,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'เลือกประเภทผู้ใช้งาน',
                                style: AppTypography.sectionTitle.copyWith(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF334155),
                                ),
                              ),
                              const SizedBox(height: 12),

                              if (constraints.maxWidth >= 720)
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Expanded(
                                      child: _ElevatedRoleCard(
                                        icon: Icons.school_outlined,
                                        iconBg: const Color(0xFFDCFCE7),
                                        iconColor: const Color(0xFF15803D),
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
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _ElevatedRoleCard(
                                        icon: Icons.person_outline,
                                        iconBg: const Color(0xFFE0F2FE),
                                        iconColor: const Color(0xFF0369A1),
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
                                      ),
                                    ),
                                  ],
                                )
                              else ...<Widget>[
                                _ElevatedRoleCard(
                                  icon: Icons.school_outlined,
                                  iconBg: const Color(0xFFDCFCE7),
                                  iconColor: const Color(0xFF15803D),
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
                                ),
                                _ElevatedRoleCard(
                                  icon: Icons.person_outline,
                                  iconBg: const Color(0xFFE0F2FE),
                                  iconColor: const Color(0xFF0369A1),
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
                                ),
                              ],

                              const SizedBox(height: 4),

                              // 3. Structured Attendance Criteria Card
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFFFFFFFF,
                                  ).withValues(alpha: 0.85),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: const Color(0xFFE2E8E4),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: <Widget>[
                                        const Icon(
                                          Icons.access_time_rounded,
                                          size: 15,
                                          color: Color(0xFF64748B),
                                        ),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            'เกณฑ์เวลาบันทึกสถานะ',
                                            style: AppTypography.microLabel
                                                .copyWith(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                  color: const Color(
                                                    0xFF475569,
                                                  ),
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    const Wrap(
                                      spacing: 14,
                                      runSpacing: 6,
                                      children: <Widget>[
                                        _RuleDotItem(
                                          color: Color(0xFF16A34A),
                                          text: 'ก่อน 08:00\u00A0น. มาเรียน',
                                        ),
                                        _RuleDotItem(
                                          color: Color(0xFFD97706),
                                          text: 'หลัง 08:00\u00A0น. มาสาย',
                                        ),
                                        _RuleDotItem(
                                          color: Color(0xFF64748B),
                                          text: 'ตัดรอบขาดเรียน 09:00\u00A0น.',
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const Spacer(),

                      // 4. Centered Footer Sample Data Pill
                      SafeArea(
                        top: false,
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(inset, 24, inset, 16),
                          child: Align(
                            alignment: Alignment.center,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE2E8E4),
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  const Icon(
                                    Icons.science_outlined,
                                    size: 14,
                                    color: Color(0xFF475569),
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      'โหมดตัวอย่าง (Sample Data)',
                                      style: AppTypography.microLabel.copyWith(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF475569),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ElevatedRoleCard extends StatelessWidget {
  const _ElevatedRoleCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8E4), width: 1),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: <Widget>[
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: AppTypography.sectionTitle.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        description,
                        style: AppTypography.supporting.copyWith(
                          fontSize: 12.5,
                          color: const Color(0xFF64748B),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RuleDotItem extends StatelessWidget {
  const _RuleDotItem({required this.color, required this.text});

  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            style: AppTypography.microLabel.copyWith(
              color: const Color(0xFF475569),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
