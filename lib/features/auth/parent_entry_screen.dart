import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/responsive_layout.dart';
import '../../data/sample_attendance_repository.dart';
import '../../shared/widgets/labeled_text_field.dart';
import '../../shared/widgets/school_brand_mark.dart';
import '../../state/app_controller.dart';
import '../parent/parent_shell_screen.dart';

/// Screen C — Parent entry via student ID (Section 4.4 & 5.3).
class ParentEntryScreen extends StatefulWidget {
  const ParentEntryScreen({super.key});

  @override
  State<ParentEntryScreen> createState() => _ParentEntryScreenState();
}

class _ParentEntryScreenState extends State<ParentEntryScreen> {
  final TextEditingController _studentIdController = TextEditingController();
  bool _isSubmitting = false;
  bool _hasSubmitted = false;
  String? _fieldError;
  String? _lookupError;

  static const List<(String id, String note)> _sampleIds = <(String, String)>[
    ('650101', 'มาเรียน'),
    ('650102', 'มาสาย'),
    ('650103', 'รอยืนยัน / ขาดเรียน'),
    ('650104', 'ลา'),
  ];

  @override
  void dispose() {
    _studentIdController.dispose();
    super.dispose();
  }

  void _validate() {
    final value = _studentIdController.text.trim();
    setState(() {
      if (value.isEmpty) {
        _fieldError = 'กรุณากรอกเลขประจำตัวนักเรียน';
      } else if (!RegExp(r'^\d{5,10}$').hasMatch(value)) {
        _fieldError = 'เลขประจำตัวนักเรียนควรเป็นตัวเลข 5–10 หลัก';
      } else {
        _fieldError = null;
      }
    });
  }

  Future<void> _submit() async {
    setState(() {
      _hasSubmitted = true;
      _lookupError = null;
    });
    _validate();
    if (_fieldError != null) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final controller = AppScope.of(context);
      await controller.enterParent(studentId: _studentIdController.text);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const ParentShellScreen()),
      );
    } on RepositoryException catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSubmitting = false;
        _lookupError = e.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSubmitting = false;
        _lookupError = 'ไม่สามารถตรวจสอบข้อมูลได้ในขณะนี้ กรุณาลองใหม่อีกครั้ง';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final inset = ResponsiveContent.horizontalInset(context);

    return Scaffold(
      appBar: AppBar(title: const Text('เข้าสู่ระบบผู้ปกครอง')),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.fromLTRB(
                  inset,
                  AppSpacing.space2,
                  inset,
                  AppSpacing.space4,
                ),
                child: ResponsiveContent(
                  padding: EdgeInsets.zero,
                  child: Row(
                    children: <Widget>[
                      const SchoolLogoMark(size: 32),
                      const SizedBox(width: AppSpacing.space3),
                      Expanded(
                        child: Text(
                          'โรงเรียนขุนยวมวิทยา • ตรวจสอบข้อมูลการเข้าเรียนแบบอ่านอย่างเดียว',
                          style: AppTypography.supporting,
                        ),
                      ),
                    ],
                  ),
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
                  vertical: AppSpacing.space5,
                ),
                child: ResponsiveContent(
                  padding: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      LabeledTextField(
                        label: 'เลขประจำตัวนักเรียน',
                        controller: _studentIdController,
                        hintText: 'เช่น 650101',
                        errorText: _fieldError,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _submit(),
                        onChanged: (_) {
                          if (_hasSubmitted) {
                            _validate();
                          }
                        },
                      ),
                      if (_lookupError != null) ...<Widget>[
                        const SizedBox(height: AppSpacing.space4),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSpacing.space3),
                          decoration: BoxDecoration(
                            color: AppColors.absentBackground,
                            borderRadius: BorderRadius.circular(
                              AppRadius.control,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              const Icon(
                                Icons.error_outline,
                                size: 18,
                                color: AppColors.absentForeground,
                              ),
                              const SizedBox(width: AppSpacing.space2),
                              Expanded(
                                child: Text(
                                  _lookupError!,
                                  style: AppTypography.supporting.copyWith(
                                    color: AppColors.absentForeground,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.space5),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _isSubmitting ? null : _submit,
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.surface,
                                  ),
                                )
                              : const Text('เข้าสู่ระบบ'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(inset),
                child: ResponsiveContent(
                  padding: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'หมายเหตุ: โหมดตัวอย่างใช้เลขประจำตัวนักเรียนเพื่อเข้าดูข้อมูลเฉพาะของนักเรียนคนดังกล่าวเท่านั้น',
                        style: AppTypography.supporting,
                      ),
                      const SizedBox(height: AppSpacing.space4),
                      const Divider(),
                      const SizedBox(height: AppSpacing.space3),
                      Text(
                        'เลขประจำตัวตัวอย่างสำหรับทดสอบ UI',
                        style: AppTypography.microLabel,
                      ),
                      const SizedBox(height: AppSpacing.space2),
                      Wrap(
                        spacing: AppSpacing.space2,
                        runSpacing: AppSpacing.space2,
                        children: <Widget>[
                          for (final item in _sampleIds)
                            OutlinedButton(
                              onPressed: _isSubmitting
                                  ? null
                                  : () {
                                      HapticFeedback.selectionClick();
                                      _studentIdController.text = item.$1;
                                      setState(() {
                                        _fieldError = null;
                                        _lookupError = null;
                                      });
                                    },
                              child: Text('${item.$1} (${item.$2})'),
                            ),
                        ],
                      ),
                    ],
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
