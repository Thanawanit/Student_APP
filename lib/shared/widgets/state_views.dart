import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/responsive_layout.dart';
import '../../core/utils/thai_date_format.dart';
import '../../domain/models/attendance_models.dart';

/// Restrained editorial skeleton placeholders without fake zero metrics (Section 10).
class LoadingSkeletonList extends StatelessWidget {
  const LoadingSkeletonList({
    super.key,
    this.itemCount = 5,
    this.showSummaryPlaceholder = true,
  });

  final int itemCount;
  final bool showSummaryPlaceholder;

  @override
  Widget build(BuildContext context) {
    final inset = ResponsiveContent.horizontalInset(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (showSummaryPlaceholder) ...<Widget>[
          Container(
            width: double.infinity,
            height: 112,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(
                top: BorderSide(color: AppColors.borderSubtle),
                bottom: BorderSide(color: AppColors.borderSubtle),
              ),
            ),
            padding: EdgeInsets.all(inset),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 120,
                  height: 28,
                  color: AppColors.surfaceSubtle,
                ),
                const SizedBox(height: AppSpacing.space3),
                Container(
                  width: double.infinity,
                  height: 5,
                  color: AppColors.surfaceSubtle,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.space4),
        ],
        Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(
              top: BorderSide(color: AppColors.borderSubtle),
              bottom: BorderSide(color: AppColors.borderSubtle),
            ),
          ),
          child: Column(
            children: <Widget>[
              for (var i = 0; i < itemCount; i++) ...<Widget>[
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: inset,
                    vertical: AppSpacing.space3,
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Container(
                              width: 150,
                              height: 15,
                              color: AppColors.surfaceSubtle,
                            ),
                            const SizedBox(height: 6),
                            Container(
                              width: 90,
                              height: 11,
                              color: AppColors.surfaceSubtle,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 68,
                        height: 24,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSubtle,
                          borderRadius: BorderRadius.circular(
                            AppRadius.control,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (i < itemCount - 1) const Divider(),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    super.key,
    required this.title,
    this.description,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? description;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final inset = ResponsiveContent.horizontalInset(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: inset,
        vertical: AppSpacing.space6,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.borderSubtle),
          bottom: BorderSide(color: AppColors.borderSubtle),
        ),
      ),
      child: Column(
        children: <Widget>[
          Icon(icon, size: 26, color: AppColors.textSecondary),
          const SizedBox(height: AppSpacing.space2),
          Text(
            title,
            style: AppTypography.bodyStrong,
            textAlign: TextAlign.center,
          ),
          if (description != null) ...<Widget>[
            const SizedBox(height: AppSpacing.space1),
            Text(
              description!,
              style: AppTypography.supporting,
              textAlign: TextAlign.center,
            ),
          ],
          if (actionLabel != null && onAction != null) ...<Widget>[
            const SizedBox(height: AppSpacing.space3),
            OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

class ErrorStateView extends StatelessWidget {
  const ErrorStateView({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final inset = ResponsiveContent.horizontalInset(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: inset,
        vertical: AppSpacing.space4,
      ),
      decoration: const BoxDecoration(
        color: AppColors.absentBackground,
        border: Border(
          top: BorderSide(color: AppColors.absentForeground, width: 1),
          bottom: BorderSide(color: AppColors.borderSubtle),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Icons.error_outline,
                size: 18,
                color: AppColors.absentForeground,
              ),
              const SizedBox(width: AppSpacing.space2),
              Text(
                'ไม่สามารถโหลดข้อมูลได้',
                style: AppTypography.bodyStrong.copyWith(
                  color: AppColors.absentForeground,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space2),
          Text(
            message,
            style: AppTypography.body.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.space3),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('ลองใหม่อีกครั้ง'),
          ),
        ],
      ),
    );
  }
}

class SyncStatusBanner extends StatelessWidget {
  const SyncStatusBanner({super.key, required this.syncMetadata});

  final SyncMetadata syncMetadata;

  @override
  Widget build(BuildContext context) {
    final isStale = syncMetadata.freshness != SyncFreshness.fresh;
    final syncTimeText = syncMetadata.lastSyncedAt != null
        ? ThaiFormat.time24(syncMetadata.lastSyncedAt!)
        : null;

    if (!isStale) {
      if (syncTimeText == null) {
        return const SizedBox.shrink();
      }
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(
            Icons.sync_outlined,
            size: 14,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: AppSpacing.space1),
          Text('อัปเดต $syncTimeText', style: AppTypography.microLabel),
        ],
      );
    }

    final inset = ResponsiveContent.horizontalInset(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: inset,
        vertical: AppSpacing.space3,
      ),
      decoration: const BoxDecoration(
        color: AppColors.unknownBackground,
        border: Border(
          top: BorderSide(color: AppColors.borderSubtle),
          bottom: BorderSide(color: AppColors.borderSubtle),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              Icons.sync_problem_outlined,
              size: 18,
              color: AppColors.unknownForeground,
            ),
          ),
          const SizedBox(width: AppSpacing.space2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  syncTimeText != null
                      ? 'ข้อมูลซิงก์ล่าสุดเมื่อ $syncTimeText (อาจยังไม่อัปเดต)'
                      : 'ยังไม่ได้รับข้อมูลการซิงก์ล่าสุด',
                  style: AppTypography.supporting.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (syncMetadata.message != null) ...<Widget>[
                  const SizedBox(height: 2),
                  Text(syncMetadata.message!, style: AppTypography.microLabel),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PrototypeSampleNotice extends StatelessWidget {
  const PrototypeSampleNotice({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space2,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(AppRadius.control),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Text(
        'โหมดตัวอย่าง (Sample Data)',
        style: AppTypography.microLabel.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
