import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/responsive_layout.dart';
import '../../core/utils/thai_date_format.dart';
import '../../shared/widgets/state_views.dart';
import '../../shared/widgets/status_chip.dart';
import '../../state/app_controller.dart';
import '../shared/student_detail_screen.dart';

/// Parent notification list identifying student, changed status, date/time, and info.
class ParentNotificationsScreen extends StatelessWidget {
  const ParentNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final notifications = controller.parentNotifications;
    final studentId = controller.parentSession?.studentId;
    final inset = ResponsiveContent.horizontalInset(context);

    return Scaffold(
      appBar: AppBar(title: const Text('การแจ้งเตือน')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: AppSpacing.space6),
          children: <Widget>[
            ResponsiveContent(
              padding: EdgeInsets.zero,
              child: notifications.isEmpty
                  ? const EmptyStateView(
                      icon: Icons.notifications_none_outlined,
                      title: 'ยังไม่มีการแจ้งเตือน',
                      description:
                          'เมื่อมีการบันทึกหรือเปลี่ยนแปลงสถานะการเข้าเรียน ระบบจะแจ้งเตือนที่นี่',
                    )
                  : Container(
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
                            i < notifications.length;
                            i++
                          ) ...<Widget>[
                            InkWell(
                              onTap: studentId == null
                                  ? null
                                  : () async {
                                      final item = notifications[i];
                                      if (!item.isRead) {
                                        await controller.markNotificationRead(
                                          item.id,
                                        );
                                      }
                                      if (!context.mounted) {
                                        return;
                                      }
                                      Navigator.of(context).push(
                                        MaterialPageRoute<void>(
                                          builder: (_) => StudentDetailScreen(
                                            studentId: studentId,
                                            initialDate: item.targetDate,
                                            isReadOnly: true,
                                          ),
                                        ),
                                      );
                                    },
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: inset,
                                  vertical: AppSpacing.space4,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: notifications[i].isRead
                                              ? AppColors.borderSubtle
                                              : AppColors.brandPrimary,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.space3),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Text(
                                            notifications[i].title,
                                            style: AppTypography.bodyStrong,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${notifications[i].studentName} (รหัส ${ThaiFormat.maskStudentId(notifications[i].studentId)})',
                                            style: AppTypography.supporting
                                                .copyWith(
                                                  color: AppColors.textPrimary,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            notifications[i].body,
                                            style: AppTypography.supporting,
                                          ),
                                          const SizedBox(
                                            height: AppSpacing.space2,
                                          ),
                                          Wrap(
                                            spacing: AppSpacing.space2,
                                            runSpacing: AppSpacing.space1,
                                            crossAxisAlignment:
                                                WrapCrossAlignment.center,
                                            children: <Widget>[
                                              if (notifications[i]
                                                      .previousStatus !=
                                                  null) ...<Widget>[
                                                AttendanceStatusChip(
                                                  status: notifications[i]
                                                      .previousStatus!,
                                                  compact: true,
                                                ),
                                                const Icon(
                                                  Icons.arrow_forward,
                                                  size: 14,
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                              ],
                                              AttendanceStatusChip(
                                                status:
                                                    notifications[i].newStatus,
                                                compact: true,
                                              ),
                                              Text(
                                                'วันที่ ${ThaiFormat.shortDate(notifications[i].targetDate)} • แจ้งเมื่อ ${ThaiFormat.time24(notifications[i].createdAt)}',
                                                style: AppTypography.microLabel,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(
                                      Icons.chevron_right,
                                      size: 20,
                                      color: AppColors.textSecondary,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (i < notifications.length - 1)
                              Divider(indent: inset, endIndent: inset),
                          ],
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
