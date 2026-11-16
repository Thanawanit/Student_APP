import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/responsive_layout.dart';
import '../../data/sample_attendance_repository.dart';
import '../../shared/widgets/labeled_text_field.dart';
import '../../shared/widgets/school_brand_mark.dart';
import '../../state/app_controller.dart';
import '../teacher/class_selection_screen.dart';

/// Screen B — Teacher login (Section 5.2).
/// Credential identifier label stays neutral because exact format is UNDECIDED (Section 14.1).
class TeacherLoginScreen extends StatefulWidget {
  const TeacherLoginScreen({super.key});

  @override
  State<TeacherLoginScreen> createState() => _TeacherLoginScreenState();
}

class _TeacherLoginScreenState extends State<TeacherLoginScreen> {
  final TextEditingController _identifierController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isSubmitting = false;
  bool _hasSubmitted = false;
  String? _identifierError;
  String? _passwordError;
  String? _authError;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _validateFields() {
    final id = _identifierController.text.trim();
    final pw = _passwordController.text;
    setState(() {
      _identifierError = id.isEmpty ? 'กรุณากรอกรหัสผู้ใช้หรืออีเมล' : null;
      _passwordError = pw.isEmpty ? 'กรุณากรอกรหัสผ่าน' : null;
    });
  }

  Future<void> _submit() async {
    setState(() {
      _hasSubmitted = true;
      _authError = null;
    });
    _validateFields();
    if (_identifierError != null || _passwordError != null) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final controller = AppScope.of(context);
      await controller.signInTeacher(
        identifier: _identifierController.text,
        password: _passwordController.text,
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => const TeacherClassSelectionScreen(),
        ),
      );
    } on RepositoryException catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSubmitting = false;
        _authError = e.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSubmitting = false;
        _authError = 'ไม่สามารถเข้าสู่ระบบได้ในขณะนี้ กรุณาลองใหม่อีกครั้ง';
      });
    }
  }

  void _fillSampleAccount() {
    _identifierController.text = 'teacher.sample';
    _passwordController.text = 'sample1234';
    if (_hasSubmitted) {
      _validateFields();
    }
    setState(() => _authError = null);
  }

  @override
  Widget build(BuildContext context) {
    final inset = ResponsiveContent.horizontalInset(context);

    return Scaffold(
      appBar: AppBar(title: const Text('เข้าสู่ระบบคุณครู')),
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
                          'โรงเรียนขุนยวมวิทยา • ลงชื่อเข้าใช้งานด้วยบัญชีที่โรงเรียนออกให้',
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
                        label: 'บัญชีผู้ใช้งาน (รหัสผู้ใช้หรืออีเมล)',
                        controller: _identifierController,
                        hintText: 'กรอกบัญชีผู้ใช้งานที่ได้รับจากโรงเรียน',
                        errorText: _identifierError,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        onChanged: (_) {
                          if (_hasSubmitted) {
                            _validateFields();
                          }
                        },
                      ),
                      const SizedBox(height: AppSpacing.space4),
                      LabeledTextField(
                        label: 'รหัสผ่าน',
                        controller: _passwordController,
                        hintText: 'กรอกรหัสผ่าน',
                        errorText: _passwordError,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _submit(),
                        onChanged: (_) {
                          if (_hasSubmitted) {
                            _validateFields();
                          }
                        },
                        suffixIcon: IconButton(
                          tooltip: _obscurePassword
                              ? 'แสดงรหัสผ่าน'
                              : 'ซ่อนรหัสผ่าน',
                          onPressed: () {
                            setState(
                              () => _obscurePassword = !_obscurePassword,
                            );
                          },
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      if (_authError != null) ...<Widget>[
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
                                  _authError!,
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
                        'สำหรับทดสอบ UI Prototype',
                        style: AppTypography.microLabel,
                      ),
                      const SizedBox(height: AppSpacing.space2),
                      OutlinedButton.icon(
                        onPressed: _isSubmitting ? null : _fillSampleAccount,
                        icon: const Icon(
                          Icons.auto_fix_high_outlined,
                          size: 18,
                        ),
                        label: const Text('กรอกบัญชีคุณครูตัวอย่าง'),
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
