import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/responsive_layout.dart';
import '../../core/utils/thai_date_format.dart';
import '../../domain/models/attendance_models.dart';
import '../../domain/models/attendance_status.dart';
import '../../shared/widgets/edit_attendance_sheet.dart';
import '../../shared/widgets/state_views.dart';
import '../../shared/widgets/status_chip.dart';
import '../../state/app_controller.dart';

/// Screen G — Single student attendance detail in Swiss Editorial layout.
class StudentDetailScreen extends StatefulWidget {
  const StudentDetailScreen({
    super.key,
    required this.studentId,
    required this.initialDate,
    required this.isReadOnly,
  });

  final String studentId;
  final DateTime initialDate;
  final bool isReadOnly;

  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen> {
  StudentAttendanceRecord? _record;
  late DateTime _selectedDate;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime(
      widget.initialDate.year,
      widget.initialDate.month,
      widget.initialDate.day,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final controller = AppScope.of(context);
      final result = await controller.fetchStudentDetail(widget.studentId);
      if (!mounted) {
        return;
      }
      setState(() {
        _record = result;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _errorMessage =
            'ไม่สามารถโหลดรายละเอียดนักเรียนได้ กรุณาลองใหม่อีกครั้ง';
      });
    }
  }

  DailyAttendanceEntry _resolveSelectedEntry(
    StudentAttendanceRecord record,
    DateTime todayDate,
  ) {
    if (_isSameDay(_selectedDate, todayDate)) {
      return record.todayEntry;
    }
    return record.history.firstWhere(
      (entry) => _isSameDay(entry.date, _selectedDate),
      orElse: () => DailyAttendanceEntry(
        date: _selectedDate,
        status: record.todayEntry.status,
        firstScanAt: record.todayEntry.firstScanAt,
        isFinalized: record.todayEntry.isFinalized,
        auditEntries: record.todayEntry.auditEntries,
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> _openEditSheet(
    StudentAttendanceRecord record,
    DailyAttendanceEntry entry,
  ) async {
    final controller = AppScope.of(context);
    final updated = await showEditAttendanceSheet(
      context: context,
      student: record,
      entry: entry,
      onSave: ({required newStatus, note}) {
        return controller.updateAttendanceStatus(
          studentId: record.studentId,
          date: entry.date,
          newStatus: newStatus,
          note: note,
        );
      },
    );
    if (updated != null && mounted) {
      setState(() => _record = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('บันทึกการแก้ไขสถานะเรียบร้อยแล้ว')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final todayDate = controller.todayDate;
    final canEditToday =
        controller.classroomSnapshot?.syncMetadata.canEditSafely ?? true;

    return Scaffold(
      appBar: AppBar(title: const Text('รายละเอียดการเข้าเรียน')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: AppSpacing.space6),
          children: <Widget>[
            ResponsiveContent(
              padding: EdgeInsets.zero,
              child: _isLoading
                  ? const LoadingSkeletonList(itemCount: 4)
                  : _errorMessage != null
                  ? ErrorStateView(message: _errorMessage!, onRetry: _load)
                  : _buildContent(context, _record!, todayDate, canEditToday),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    StudentAttendanceRecord record,
    DateTime todayDate,
    bool canEditToday,
  ) {
    final inset = ResponsiveContent.horizontalInset(context);
    final entry = _resolveSelectedEntry(record, todayDate);
    final isSelectedToday = _isSameDay(entry.date, todayDate);
    final editAllowed =
        !widget.isReadOnly && (!isSelectedToday || canEditToday);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Student identity masthead
        Padding(
          padding: EdgeInsets.fromLTRB(
            inset,
            AppSpacing.space2,
            inset,
            AppSpacing.space4,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(record.fullName, style: AppTypography.pageTitle),
              const SizedBox(height: 2),
              Text(
                '${record.classroom.hierarchyLabel} • รหัส ${ThaiFormat.maskStudentId(record.studentId)}',
                style: AppTypography.supporting,
              ),
            ],
          ),
        ),

        // Selected date hero status band with left semantic accent rule
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(
              top: const BorderSide(color: AppColors.borderSubtle),
              bottom: const BorderSide(color: AppColors.borderSubtle),
              left: BorderSide(color: entry.status.foregroundColor, width: 4),
            ),
          ),
          padding: EdgeInsets.fromLTRB(
            inset - 4,
            AppSpacing.space4,
            inset,
            AppSpacing.space4,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                ThaiFormat.fullDate(entry.date),
                style: AppTypography.supporting,
              ),
              const SizedBox(height: AppSpacing.space3),
              Wrap(
                spacing: AppSpacing.space3,
                runSpacing: AppSpacing.space2,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  AttendanceStatusChip(status: entry.status),
                  if (entry.firstScanAt != null)
                    Text(
                      'สแกนเข้า ${ThaiFormat.time24(entry.firstScanAt!)}',
                      style: AppTypography.sectionTitle.copyWith(
                        fontFeatures: const <FontFeature>[
                          FontFeature.tabularFigures(),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.space2),
              Text(
                entry.status.detailDescription,
                style: AppTypography.supporting,
              ),
              if (!widget.isReadOnly) ...<Widget>[
                const SizedBox(height: AppSpacing.space4),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: editAllowed
                        ? () => _openEditSheet(record, entry)
                        : null,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('แก้ไขสถานะ'),
                  ),
                ),
                if (!editAllowed) ...<Widget>[
                  const SizedBox(height: AppSpacing.space2),
                  Text(
                    'ไม่สามารถแก้ไขสถานะของวันนี้ได้ชั่วคราวเนื่องจากข้อมูลกำลังซิงก์ล่าช้า',
                    style: AppTypography.supporting.copyWith(
                      color: AppColors.unknownForeground,
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),

        // Audit trail (shown whenever edits exist)
        if (entry.auditEntries.isNotEmpty) ...<Widget>[
          Padding(
            padding: EdgeInsets.fromLTRB(
              inset,
              AppSpacing.space5,
              inset,
              AppSpacing.space2,
            ),
            child: Text(
              'ประวัติการแก้ไขสถานะ',
              style: AppTypography.sectionTitle,
            ),
          ),
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(
                top: BorderSide(color: AppColors.borderSubtle),
                bottom: BorderSide(color: AppColors.borderSubtle),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                for (var i = 0; i < entry.auditEntries.length; i++) ...<Widget>[
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: inset,
                      vertical: AppSpacing.space3,
                    ),
                    child: _AuditItemView(audit: entry.auditEntries[i]),
                  ),
                  if (i < entry.auditEntries.length - 1) const Divider(),
                ],
              ],
            ),
          ),
        ],

        // Swiss 3-column weekly summary
        Padding(
          padding: EdgeInsets.fromLTRB(
            inset,
            AppSpacing.space5,
            inset,
            AppSpacing.space2,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text('สรุปสัปดาห์นี้', style: AppTypography.sectionTitle),
              const SizedBox(width: AppSpacing.space2),
              Flexible(
                child: Text(
                  record.weeklySummary.weekLabel,
                  textAlign: TextAlign.right,
                  style: AppTypography.microLabel,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(
              top: BorderSide(color: AppColors.borderSubtle),
              bottom: BorderSide(color: AppColors.borderSubtle),
            ),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: inset,
            vertical: AppSpacing.space3,
          ),
          child: IntrinsicHeight(
            child: Row(
              children: <Widget>[
                Expanded(
                  child: _WeeklyCountColumn(
                    label: 'มาสาย',
                    count: record.weeklySummary.lateCount,
                    color: AttendanceStatus.late.foregroundColor,
                  ),
                ),
                const VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: AppColors.borderSubtle,
                ),
                Expanded(
                  child: _WeeklyCountColumn(
                    label: 'ขาดเรียน',
                    count: record.weeklySummary.absentCount,
                    color: AttendanceStatus.absent.foregroundColor,
                  ),
                ),
                const VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: AppColors.borderSubtle,
                ),
                Expanded(
                  child: _WeeklyCountColumn(
                    label: 'ลา',
                    count: record.weeklySummary.leaveCount,
                    color: AttendanceStatus.leave.foregroundColor,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Recent attendance history ledger
        Padding(
          padding: EdgeInsets.fromLTRB(
            inset,
            AppSpacing.space5,
            inset,
            AppSpacing.space2,
          ),
          child: Text(
            'ประวัติการเข้าเรียนย้อนหลัง',
            style: AppTypography.sectionTitle,
          ),
        ),
        Container(
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
              for (var i = 0; i < record.history.length; i++) ...<Widget>[
                InkWell(
                  onTap: () {
                    setState(() {
                      _selectedDate = record.history[i].date;
                    });
                  },
                  child: Container(
                    color: _isSameDay(record.history[i].date, _selectedDate)
                        ? AppColors.brandPrimarySoft.withValues(alpha: 0.45)
                        : Colors.transparent,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        minHeight: AppSpacing.minTouchTarget + 8,
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: inset,
                          vertical: 10,
                        ),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    ThaiFormat.fullDate(record.history[i].date),
                                    style: AppTypography.bodyStrong.copyWith(
                                      color:
                                          _isSameDay(
                                            record.history[i].date,
                                            _selectedDate,
                                          )
                                          ? AppColors.brandPrimary
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    record.history[i].firstScanAt != null
                                        ? 'สแกนเข้า ${ThaiFormat.time24(record.history[i].firstScanAt!)}'
                                        : (record.history[i].status ==
                                                  AttendanceStatus.pending
                                              ? 'ยังไม่พบการสแกน • รอยืนยัน'
                                              : 'ไม่มีบันทึกเวลาสแกน'),
                                    style: AppTypography.supporting,
                                  ),
                                ],
                              ),
                            ),
                            AttendanceStatusChip(
                              status: record.history[i].status,
                              compact: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (i < record.history.length - 1) const Divider(),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _WeeklyCountColumn extends StatelessWidget {
  const _WeeklyCountColumn({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: AppTypography.microLabel),
          const SizedBox(height: AppSpacing.space1),
          Text.rich(
            TextSpan(
              children: <InlineSpan>[
                TextSpan(
                  text: '$count',
                  style: AppTypography.pageTitle.copyWith(
                    color: color,
                    fontFeatures: const <FontFeature>[
                      FontFeature.tabularFigures(),
                    ],
                  ),
                ),
                TextSpan(text: ' ครั้ง', style: AppTypography.microLabel),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AuditItemView extends StatelessWidget {
  const _AuditItemView({required this.audit});

  final AttendanceAuditEntry audit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Wrap(
          spacing: AppSpacing.space2,
          runSpacing: AppSpacing.space2,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            AttendanceStatusChip(status: audit.previousStatus, compact: true),
            const Icon(
              Icons.arrow_forward,
              size: 16,
              color: AppColors.textSecondary,
            ),
            AttendanceStatusChip(status: audit.newStatus, compact: true),
          ],
        ),
        const SizedBox(height: AppSpacing.space2),
        Text(
          'แก้ไขโดย ${audit.editorName} (${audit.editorRoleLabel})',
          style: AppTypography.supporting.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          'เมื่อ ${ThaiFormat.shortDate(audit.editedAt)} เวลา ${ThaiFormat.time24(audit.editedAt)}',
          style: AppTypography.supporting,
        ),
        if (audit.note != null) ...<Widget>[
          const SizedBox(height: AppSpacing.space1),
          Text('หมายเหตุ: ${audit.note}', style: AppTypography.supporting),
        ],
      ],
    );
  }
}
