import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/responsive_layout.dart';
import '../../core/utils/thai_date_format.dart';
import '../../domain/models/attendance_models.dart';
import '../../domain/models/attendance_status.dart';
import '../../domain/models/school_structure.dart';
import '../../shared/widgets/school_brand_mark.dart';
import '../../shared/widgets/state_views.dart';
import '../../shared/widgets/summary_metric_strip.dart';
import '../../state/app_controller.dart';
import '../shared/student_detail_screen.dart';
import 'class_selection_screen.dart';

/// Teacher Dashboard Overview screen with soft greenish-gray canvas (#F2F5F3)
/// and elevated white card hierarchy.
class TeacherOverviewTab extends StatelessWidget {
  const TeacherOverviewTab({
    super.key,
    required this.onOpenStudentList,
    required this.onOpenHistory,
  });

  final ValueChanged<AttendanceStatus?> onOpenStudentList;
  final VoidCallback onOpenHistory;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final classroom = controller.selectedClassroom;
    final snapshot = controller.classroomSnapshot;
    final inset = ResponsiveContent.horizontalInset(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F5F3),
      body: Column(
        children: <Widget>[
          _TeacherHeader(
            inset: inset,
            classroom: classroom,
            todayDate: controller.todayDate,
            syncMetadata: snapshot?.syncMetadata,
            onSwitchRoom: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      const TeacherClassSelectionScreen(isSwitchingRoom: true),
                ),
              );
            },
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.brandPrimary,
              onRefresh: controller.loadClassroomOverview,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(
                  top: AppSpacing.space4,
                  bottom: AppSpacing.space6,
                ),
                children: <Widget>[
                  ResponsiveContent(
                    padding: EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        if (controller.isClassroomLoading && snapshot == null)
                          const LoadingSkeletonList()
                        else if (controller.classroomError != null &&
                            snapshot == null)
                          ErrorStateView(
                            message: controller.classroomError!,
                            onRetry: controller.loadClassroomOverview,
                          )
                        else if (snapshot != null) ...<Widget>[
                          if (snapshot.syncMetadata.freshness !=
                              SyncFreshness.fresh)
                            Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.space4,
                              ),
                              child: SyncStatusBanner(
                                syncMetadata: snapshot.syncMetadata,
                              ),
                            ),
                          if (snapshot.students.isEmpty)
                            const EmptyStateView(
                              title: 'ไม่พบนักเรียนในห้องนี้',
                              description:
                                  'ยังไม่มีรายชื่อนักเรียนหรือกำหนดการเรียนในวันที่เลือก',
                            )
                          else
                            ClassroomIntelligencePanel(
                              snapshot: snapshot,
                              inset: inset,
                              onTapStudent: (student) {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => StudentDetailScreen(
                                      studentId: student.studentId,
                                      initialDate: snapshot.date,
                                      isReadOnly: false,
                                    ),
                                  ),
                                );
                              },
                              onOpenStudentList: onOpenStudentList,
                            ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TeacherHeader extends StatelessWidget {
  const _TeacherHeader({
    required this.inset,
    required this.classroom,
    required this.todayDate,
    required this.syncMetadata,
    required this.onSwitchRoom,
  });

  final double inset;
  final ClassroomId? classroom;
  final DateTime todayDate;
  final SyncMetadata? syncMetadata;
  final VoidCallback onSwitchRoom;

  @override
  Widget build(BuildContext context) {
    final currentRoom = classroom;
    final freshness = syncMetadata?.freshness;
    final lastSynced = syncMetadata?.lastSyncedAt;
    final buddhistYear = todayDate.year + 543;

    final Color freshnessColor = switch (freshness) {
      SyncFreshness.fresh => AppColors.presentForeground,
      SyncFreshness.delayed => AppColors.lateForeground,
      SyncFreshness.unavailable => AppColors.absentForeground,
      null => AppColors.textDisabled,
    };

    final String freshnessText = switch (freshness) {
      SyncFreshness.fresh =>
        lastSynced != null
            ? 'อัปเดต ${ThaiFormat.time24Nbsp(lastSynced)}'
            : 'ล่าสุด',
      SyncFreshness.delayed => 'ซิงก์ล่าช้า',
      SyncFreshness.unavailable => 'รอการซิงก์',
      null => 'กำลังโหลด',
    };

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFFFFFFFF),
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8E4))),
      ),
      child: SafeArea(
        bottom: false,
        child: ResponsiveContent(
          padding: EdgeInsets.fromLTRB(
            inset,
            AppSpacing.space2,
            inset,
            AppSpacing.space3,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const SchoolLogoMark(size: 26),
                  const SizedBox(width: AppSpacing.space2),
                  if (currentRoom != null)
                    InkWell(
                      onTap: onSwitchRoom,
                      borderRadius: BorderRadius.circular(AppRadius.control),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 40),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.space2,
                            vertical: 4,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Text(
                                currentRoom.roomLabel,
                                style: AppTypography.sectionTitle.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 2),
                              const Icon(
                                Icons.keyboard_arrow_down,
                                size: 18,
                                color: AppColors.brandPrimary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  const Spacer(),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        Text(
                          ThaiFormat.shortDate(todayDate),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.supporting.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: freshnessColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                freshnessText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.microLabel,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (currentRoom != null) ...<Widget>[
                const SizedBox(height: 2),
                Text(
                  'ชั้นมัธยมศึกษาปีที่ ${currentRoom.grade} • ปีการศึกษา $buddhistYear',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.microLabel,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
