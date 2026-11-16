import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/responsive_layout.dart';
import '../../core/utils/thai_date_format.dart';
import '../../shared/widgets/state_views.dart';
import '../../state/app_controller.dart';
import 'parent_history_section.dart';

/// Parent read-only attendance history tab with month, date, and status filtering.
class ParentHistoryTab extends StatelessWidget {
  const ParentHistoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final record = controller.parentRecord;
    final inset = ResponsiveContent.horizontalInset(context);

    return Scaffold(
      appBar: AppBar(title: const Text('ประวัติการเข้าเรียน')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.space6),
        children: <Widget>[
          ResponsiveContent(
            padding: EdgeInsets.zero,
            child: controller.isParentLoading && record == null
                ? const LoadingSkeletonList(showSummaryPlaceholder: false)
                : record == null
                ? const EmptyStateView(title: 'ยังไม่มีประวัติในวันที่เลือก')
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          inset,
                          AppSpacing.space1,
                          inset,
                          AppSpacing.space3,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              record.fullName,
                              style: AppTypography.bodyStrong,
                            ),
                            Text(
                              '${record.classroom.hierarchyLabel} • รหัส ${ThaiFormat.maskStudentId(record.studentId)}',
                              style: AppTypography.supporting,
                            ),
                          ],
                        ),
                      ),
                      ParentHistorySection(
                        record: record,
                        todayDate: controller.todayDate,
                        showSectionTitle: false,
                        useContainerInset: true,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
