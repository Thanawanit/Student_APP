import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/responsive_layout.dart';
import '../../domain/models/school_structure.dart';
import '../../state/app_controller.dart';
import 'teacher_shell_screen.dart';

/// Screen D — Teacher stage -> grade -> classroom selection (editorial list rows).
class TeacherClassSelectionScreen extends StatefulWidget {
  const TeacherClassSelectionScreen({super.key, this.isSwitchingRoom = false});

  final bool isSwitchingRoom;

  @override
  State<TeacherClassSelectionScreen> createState() =>
      _TeacherClassSelectionScreenState();
}

class _TeacherClassSelectionScreenState
    extends State<TeacherClassSelectionScreen> {
  EducationStage? _selectedStage;
  int? _selectedGrade;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final current = AppScope.of(context).selectedClassroom;
      if (current != null) {
        setState(() {
          _selectedStage = current.stage;
          _selectedGrade = current.grade;
        });
      }
    });
  }

  Future<void> _selectRoom(ClassroomId classroom) async {
    final controller = AppScope.of(context);
    await controller.selectClassroom(classroom);
    if (!mounted) {
      return;
    }
    if (widget.isSwitchingRoom) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const TeacherShellScreen()),
    );
  }

  void _handleStepBack() {
    if (_selectedGrade != null) {
      setState(() => _selectedGrade = null);
    } else if (_selectedStage != null) {
      setState(() => _selectedStage = null);
    } else if (widget.isSwitchingRoom) {
      Navigator.of(context).pop();
    } else {
      AppScope.of(context).signOut();
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final inset = ResponsiveContent.horizontalInset(context);
    final canPopDirect = _selectedStage == null && _selectedGrade == null;

    final int currentStep = _selectedStage == null
        ? 1
        : _selectedGrade == null
        ? 2
        : 3;

    return PopScope(
      canPop: canPopDirect,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _handleStepBack();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('เลือกห้องเรียน'),
          leading: IconButton(
            tooltip: 'ย้อนกลับ',
            onPressed: _handleStepBack,
            icon: const Icon(Icons.arrow_back),
          ),
        ),
        body: SafeArea(
          child: ListView(
            children: <Widget>[
              // Compact Swiss breadcrumb bar
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppColors.surfaceSubtle,
                  border: Border(
                    top: BorderSide(color: AppColors.borderSubtle),
                    bottom: BorderSide(color: AppColors.borderSubtle),
                  ),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: inset,
                  vertical: AppSpacing.space3,
                ),
                child: ResponsiveContent(
                  padding: EdgeInsets.zero,
                  child: Row(
                    children: <Widget>[
                      Text(
                        'ขั้นตอน $currentStep/3',
                        style: AppTypography.microLabel.copyWith(
                          color: AppColors.brandPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.space3),
                      Expanded(
                        child: Text(
                          _selectedStage == null
                              ? 'เลือกช่วงชั้น'
                              : _selectedGrade == null
                              ? '${_selectedStage!.label} / เลือกระดับชั้น'
                              : '${_selectedStage!.label} / ม.$_selectedGrade / เลือกห้อง',
                          style: AppTypography.supporting.copyWith(
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Padding(
                padding: EdgeInsets.fromLTRB(
                  inset,
                  AppSpacing.space4,
                  inset,
                  AppSpacing.space2,
                ),
                child: ResponsiveContent(
                  padding: EdgeInsets.zero,
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: AppSpacing.space2,
                    runSpacing: AppSpacing.space1,
                    children: <Widget>[
                      Text(
                        _selectedStage == null
                            ? 'ช่วงชั้น'
                            : _selectedGrade == null
                            ? 'ระดับชั้น (${_selectedStage!.label})'
                            : 'ห้องเรียน (มัธยมศึกษาปีที่ $_selectedGrade)',
                        style: AppTypography.sectionTitle,
                      ),
                      if (_selectedStage != null)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              if (_selectedGrade != null) {
                                _selectedGrade = null;
                              } else {
                                _selectedStage = null;
                              }
                            });
                          },
                          child: Text(
                            _selectedGrade != null
                                ? 'เปลี่ยนระดับชั้น'
                                : 'เปลี่ยนช่วงชั้น',
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Full-width editorial list rows
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(
                    top: BorderSide(color: AppColors.borderSubtle),
                    bottom: BorderSide(color: AppColors.borderSubtle),
                  ),
                ),
                child: ResponsiveContent(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: <Widget>[
                      if (_selectedStage == null)
                        for (
                          var i = 0;
                          i < EducationStage.values.length;
                          i++
                        ) ...<Widget>[
                          _EditorialSelectionRow(
                            inset: inset,
                            code: '0${i + 1}',
                            title: EducationStage.values[i].label,
                            subtitle: EducationStage.values[i].subtitle,
                            isSelected: false,
                            onTap: () => setState(() {
                              _selectedStage = EducationStage.values[i];
                              _selectedGrade = null;
                            }),
                          ),
                          if (i < EducationStage.values.length - 1)
                            const Divider(),
                        ]
                      else if (_selectedGrade == null)
                        for (
                          var i = 0;
                          i < _selectedStage!.grades.length;
                          i++
                        ) ...<Widget>[
                          _EditorialSelectionRow(
                            inset: inset,
                            code: 'ม.${_selectedStage!.grades[i]}',
                            title:
                                'มัธยมศึกษาปีที่ ${_selectedStage!.grades[i]} (ม.${_selectedStage!.grades[i]})',
                            subtitle:
                                'ห้อง ${_selectedStage!.grades[i]}/1 – ${_selectedStage!.grades[i]}/${_selectedStage!.roomsPerGrade}',
                            isSelected: false,
                            onTap: () => setState(
                              () => _selectedGrade = _selectedStage!.grades[i],
                            ),
                          ),
                          if (i < _selectedStage!.grades.length - 1)
                            const Divider(),
                        ]
                      else ...<Widget>[
                        for (final (index, room) in ClassroomId.roomsForGrade(
                          _selectedStage!,
                          _selectedGrade!,
                        ).indexed) ...<Widget>[
                          _EditorialSelectionRow(
                            inset: inset,
                            code: room.code,
                            title: room.roomLabel,
                            subtitle: room.hierarchyLabel,
                            isSelected:
                                AppScope.of(context).selectedClassroom == room,
                            onTap: () => _selectRoom(room),
                          ),
                          if (index < _selectedStage!.roomsPerGrade - 1)
                            const Divider(),
                        ],
                      ],
                    ],
                  ),
                ),
              ),

              if (_selectedStage == null)
                Padding(
                  padding: EdgeInsets.all(inset),
                  child: ResponsiveContent(
                    padding: EdgeInsets.zero,
                    child: Text(
                      'คุณครูสามารถเข้าดูข้อมูลการเข้าเรียนได้ทุกห้องเรียนในโรงเรียนขุนยวมวิทยา',
                      style: AppTypography.supporting,
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

class _EditorialSelectionRow extends StatelessWidget {
  const _EditorialSelectionRow({
    required this.inset,
    required this.code,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  final double inset;
  final String code;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        color: isSelected ? AppColors.brandPrimarySoft : Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppSpacing.minTouchTarget + 12,
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: inset,
              vertical: AppSpacing.space3,
            ),
            child: Row(
              children: <Widget>[
                SizedBox(
                  width: 40,
                  child: Text(
                    code,
                    style: AppTypography.bodyStrong.copyWith(
                      color: isSelected
                          ? AppColors.brandPrimary
                          : AppColors.textSecondary,
                      fontFeatures: const <FontFeature>[
                        FontFeature.tabularFigures(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: AppTypography.bodyStrong.copyWith(
                          color: isSelected
                              ? AppColors.brandPrimary
                              : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(subtitle, style: AppTypography.supporting),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.space2),
                Icon(
                  isSelected ? Icons.check_circle : Icons.chevron_right,
                  size: 20,
                  color: isSelected
                      ? AppColors.brandPrimary
                      : AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
