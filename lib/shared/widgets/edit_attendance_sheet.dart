import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/thai_date_format.dart';
import '../../data/sample_attendance_repository.dart';
import '../../domain/models/attendance_models.dart';
import '../../domain/models/attendance_status.dart';
import 'labeled_text_field.dart';
import 'status_chip.dart';

typedef SaveAttendanceCallback =
    Future<StudentAttendanceRecord> Function({
      required AttendanceStatus newStatus,
      String? note,
    });

/// Bottom sheet + confirmation dialog for Screen H (Section 5.8).
Future<StudentAttendanceRecord?> showEditAttendanceSheet({
  required BuildContext context,
  required StudentAttendanceRecord student,
  required DailyAttendanceEntry entry,
  required SaveAttendanceCallback onSave,
}) {
  return showModalBottomSheet<StudentAttendanceRecord>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) {
      return _EditAttendanceSheetBody(
        student: student,
        entry: entry,
        onSave: onSave,
      );
    },
  );
}

class _EditAttendanceSheetBody extends StatefulWidget {
  const _EditAttendanceSheetBody({
    required this.student,
    required this.entry,
    required this.onSave,
  });

  final StudentAttendanceRecord student;
  final DailyAttendanceEntry entry;
  final SaveAttendanceCallback onSave;

  @override
  State<_EditAttendanceSheetBody> createState() =>
      _EditAttendanceSheetBodyState();
}

class _EditAttendanceSheetBodyState extends State<_EditAttendanceSheetBody> {
  late AttendanceStatus _selectedStatus;
  final TextEditingController _noteController = TextEditingController();
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedStatus =
        AttendanceStatus.editableValues.contains(widget.entry.status)
        ? widget.entry.status
        : AttendanceStatus.present;
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _handleSavePressed() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('ยืนยันการแก้ไขสถานะ'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(widget.student.fullName, style: AppTypography.bodyStrong),
              const SizedBox(height: AppSpacing.space1),
              Text(
                ThaiFormat.fullDate(widget.entry.date),
                style: AppTypography.supporting,
              ),
              const SizedBox(height: AppSpacing.space4),
              Wrap(
                spacing: AppSpacing.space2,
                runSpacing: AppSpacing.space2,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  AttendanceStatusChip(
                    status: widget.entry.status,
                    compact: true,
                  ),
                  const Icon(
                    Icons.arrow_forward,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  AttendanceStatusChip(status: _selectedStatus, compact: true),
                ],
              ),
              const SizedBox(height: AppSpacing.space4),
              Text(
                'ระบบจะบันทึกประวัติผู้แก้ไขและแจ้งเตือนผู้ปกครองเมื่อบันทึกข้อมูลสำเร็จแล้ว',
                style: AppTypography.supporting,
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('ยกเลิก'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('ยืนยันบันทึก'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final updated = await widget.onSave(
        newStatus: _selectedStatus,
        note: _noteController.text,
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(updated);
    } on RepositoryException catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSaving = false;
        _errorMessage = e.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSaving = false;
        _errorMessage = 'ไม่สามารถบันทึกการแก้ไขได้ กรุณาลองใหม่อีกครั้ง';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.space5,
        0,
        AppSpacing.space5,
        AppSpacing.space5 + bottomInset,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('แก้ไขสถานะการเข้าเรียน', style: AppTypography.sectionTitle),
            const SizedBox(height: AppSpacing.space1),
            Text(
              '${widget.student.fullName} • ${ThaiFormat.fullDate(widget.entry.date)}',
              style: AppTypography.supporting,
            ),
            const SizedBox(height: AppSpacing.space4),
            Row(
              children: <Widget>[
                Text('สถานะปัจจุบัน: ', style: AppTypography.supporting),
                const SizedBox(width: AppSpacing.space1),
                AttendanceStatusChip(
                  status: widget.entry.status,
                  compact: true,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.space4),
            Text('เลือกสถานะใหม่', style: AppTypography.bodyStrong),
            const SizedBox(height: AppSpacing.space2),
            for (final status in AttendanceStatus.editableValues) ...<Widget>[
              _StatusRadioTile(
                status: status,
                isSelected: _selectedStatus == status,
                onTap: _isSaving
                    ? null
                    : () => setState(() => _selectedStatus = status),
              ),
              const SizedBox(height: AppSpacing.space2),
            ],
            const SizedBox(height: AppSpacing.space2),
            LabeledTextField(
              label: 'หมายเหตุเพิ่มเติม (ไม่บังคับ)',
              controller: _noteController,
              hintText: 'ระบุเหตุผลสั้น ๆ หากต้องการบันทึกในประวัติ',
              textInputAction: TextInputAction.done,
            ),
            if (_errorMessage != null) ...<Widget>[
              const SizedBox(height: AppSpacing.space3),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.space3),
                decoration: BoxDecoration(
                  color: AppColors.absentBackground,
                  borderRadius: BorderRadius.circular(AppRadius.control),
                ),
                child: Text(
                  _errorMessage!,
                  style: AppTypography.supporting.copyWith(
                    color: AppColors.absentForeground,
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.space5),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isSaving ? null : _handleSavePressed,
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.surface,
                        ),
                      )
                    : const Text('บันทึกการแก้ไข'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusRadioTile extends StatelessWidget {
  const _StatusRadioTile({
    required this.status,
    required this.isSelected,
    required this.onTap,
  });

  final AttendanceStatus status;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.control),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSpacing.minTouchTarget),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space3,
            vertical: AppSpacing.space2,
          ),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.brandPrimarySoft : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.control),
            border: Border.all(
              color: isSelected
                  ? AppColors.brandPrimary
                  : AppColors.borderSubtle,
              width: isSelected ? 1.5 : AppBorders.width,
            ),
          ),
          child: Row(
            children: <Widget>[
              Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                size: 20,
                color: isSelected
                    ? AppColors.brandPrimary
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.space3),
              AttendanceStatusChip(status: status, compact: true),
            ],
          ),
        ),
      ),
    );
  }
}
