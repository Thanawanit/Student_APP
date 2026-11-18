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

/// Teacher Dashboard Overview screen (`ภาพรวม`) with compact 2-line header,
/// collapsible hero summary card, and filterable student follow-up cards.
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
          _CompactTeacherHeader(
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

class _CompactTeacherHeader extends StatelessWidget {
  const _CompactTeacherHeader({
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

    final String syncLabel = switch (freshness) {
      SyncFreshness.fresh =>
        lastSynced != null
            ? 'อัปเดต ${ThaiFormat.time24Nbsp(lastSynced)}'
            : 'อัปเดตล่าสุด',
      SyncFreshness.delayed => 'ซิงก์ล่าช้า',
      SyncFreshness.unavailable => 'รอการซิงก์',
      null => 'กำลังโหลด',
    };

    final String subtitleText = currentRoom != null
        ? 'ม.${currentRoom.grade} • $syncLabel'
        : syncLabel;

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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              const SchoolLogoMark(size: 30),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (currentRoom != null)
                      InkWell(
                        onTap: onSwitchRoom,
                        borderRadius: BorderRadius.circular(AppRadius.badge),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Flexible(
                                child: Text(
                                  currentRoom.roomLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.sectionTitle.copyWith(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 2),
                              const Icon(
                                Icons.keyboard_arrow_down,
                                size: 20,
                                color: AppColors.brandPrimary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    Text(
                      subtitleText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.microLabel.copyWith(
                        fontSize: 12,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.space2),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8E4),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  ThaiFormat.shortDateTwoDigitYear(todayDate),
                  style: AppTypography.microLabel.copyWith(
                    color: const Color(0xFF334155),
                    fontWeight: FontWeight.w600,
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
