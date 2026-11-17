import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/responsive_layout.dart';
import '../../core/utils/thai_date_format.dart';
import '../../domain/models/attendance_models.dart';
import '../../domain/models/attendance_status.dart';
import '../../shared/widgets/school_brand_mark.dart';
import '../../shared/widgets/state_views.dart';
import '../../shared/widgets/summary_metric_strip.dart';
import '../../state/app_controller.dart';
import '../shared/student_detail_screen.dart';
import 'class_selection_screen.dart';

/// Screen A — Light Editorial Teacher Overview (no classroom-management clutter).
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
      appBar: AppBar(
        titleSpacing: inset,
        title: const Row(
          children: <Widget>[
            SchoolLogoMark(size: 26),
            SizedBox(width: AppSpacing.space2),
            Flexible(
              child: Text(
                'ภาพรวมการเข้าเรียน',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: <Widget>[
          if (classroom != null)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.space2),
              child: InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const TeacherClassSelectionScreen(
                        isSwitchingRoom: true,
                      ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(AppRadius.control),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: AppSpacing.minTouchTarget,
                  ),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.space3,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSubtle,
                        borderRadius: BorderRadius.circular(AppRadius.control),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            'ห้อง ${classroom.code}',
                            style: AppTypography.microLabel.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(
                            Icons.keyboard_arrow_down,
                            size: 16,
                            color: AppColors.textPrimary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.brandPrimary,
        onRefresh: controller.loadClassroomOverview,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: AppSpacing.space6),
          children: <Widget>[
            ResponsiveContent(
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // 01. Classroom identity, date, and sync indicator
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      inset,
                      AppSpacing.space3,
                      inset,
                      AppSpacing.space3,
                    ),
                    child: Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: AppSpacing.space2,
                      runSpacing: 4,
                      children: <Widget>[
                        Text(
                          classroom != null
                              ? '${classroom.hierarchyLabel} • ${ThaiFormat.fullDate(controller.todayDate)}'
                              : ThaiFormat.fullDate(controller.todayDate),
                          style: AppTypography.supporting.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (snapshot != null &&
                            snapshot.syncMetadata.freshness ==
                                SyncFreshness.fresh)
                          SyncStatusBanner(syncMetadata: snapshot.syncMetadata),
                      ],
                    ),
                  ),

                  if (controller.isClassroomLoading && snapshot == null)
                    const LoadingSkeletonList()
                  else if (controller.classroomError != null &&
                      snapshot == null)
                    ErrorStateView(
                      message: controller.classroomError!,
                      onRetry: controller.loadClassroomOverview,
                    )
                  else if (snapshot != null) ...<Widget>[
                    if (snapshot.syncMetadata.freshness != SyncFreshness.fresh)
                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: AppSpacing.space3,
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
                      SummaryMetricStrip(
                        snapshot: snapshot,
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
    );
  }
}
