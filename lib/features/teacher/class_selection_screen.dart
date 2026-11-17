import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/responsive_layout.dart';
import '../../domain/models/school_structure.dart';
import '../../state/app_controller.dart';
import 'teacher_shell_screen.dart';

/// Screen D — Swiss Step Matrix for Stage -> Grade -> Classroom selection.
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
    final currentStep = _selectedStage == null
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
            padding: EdgeInsets.all(inset),
            children: <Widget>[
              ResponsiveContent(
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // Step indicator bar
                    Wrap(
                      spacing: AppSpacing.space2,
                      runSpacing: AppSpacing.space2,
                      children: <Widget>[
                        _StepPill(
                          number: '01',
                          label: 'ช่วงชั้น',
                          active: currentStep == 1,
                          completed: currentStep > 1,
                        ),
                        _StepPill(
                          number: '02',
                          label: 'ระดับชั้น',
                          active: currentStep == 2,
                          completed: currentStep > 2,
                        ),
                        _StepPill(
                          number: '03',
                          label: 'ห้องเรียน',
                          active: currentStep == 3,
                          completed: false,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.space5),

                    SizedBox(
                      width: double.infinity,
                      child: Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: AppSpacing.space2,
                        runSpacing: AppSpacing.space1,
                        children: <Widget>[
                          Text(
                            _selectedStage == null
                                ? 'เลือกช่วงชั้น'
                                : _selectedGrade == null
                                ? 'ระดับชั้น (${_selectedStage!.label})'
                                : 'ห้องเรียน (มัธยมศึกษาปีที่ $_selectedGrade)',
                            style: AppTypography.pageTitle,
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
                    const SizedBox(height: AppSpacing.space4),

                    if (_selectedStage == null)
                      for (final stage in EducationStage.values) ...<Widget>[
                        _StageTile(
                          stage: stage,
                          onTap: () => setState(() {
                            _selectedStage = stage;
                            _selectedGrade = null;
                          }),
                        ),
                        const SizedBox(height: AppSpacing.space3),
                      ]
                    else if (_selectedGrade == null)
                      _ResponsiveTileGrid(
                        items: <Widget>[
                          for (final grade in _selectedStage!.grades)
                            _GradeGridTile(
                              grade: grade,
                              roomCount: _selectedStage!.roomsPerGrade,
                              onTap: () =>
                                  setState(() => _selectedGrade = grade),
                            ),
                        ],
                      )
                    else
                      _ResponsiveTileGrid(
                        items: <Widget>[
                          for (final room in ClassroomId.roomsForGrade(
                            _selectedStage!,
                            _selectedGrade!,
                          ))
                            _RoomGridTile(
                              room: room,
                              isSelected:
                                  AppScope.of(context).selectedClassroom ==
                                  room,
                              onTap: () => _selectRoom(room),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepPill extends StatelessWidget {
  const _StepPill({
    required this.number,
    required this.label,
    required this.active,
    required this.completed,
  });

  final String number;
  final String label;
  final bool active;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space3,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: active
            ? AppColors.brandPrimary
            : completed
            ? AppColors.brandPrimarySoft
            : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.control),
        border: Border.all(
          color: active
              ? AppColors.brandPrimary
              : completed
              ? AppColors.brandPrimary.withValues(alpha: 0.3)
              : AppColors.borderSubtle,
        ),
      ),
      child: Text(
        '$number $label',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: AppTypography.microLabel.copyWith(
          color: active
              ? AppColors.surface
              : completed
              ? AppColors.brandPrimary
              : AppColors.textSecondary,
          fontWeight: active || completed ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
    );
  }
}

class _StageTile extends StatelessWidget {
  const _StageTile({required this.stage, required this.onTap});

  final EducationStage stage;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.panel),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.panel),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.space5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.panel),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(stage.label, style: AppTypography.sectionTitle),
                    const SizedBox(height: 2),
                    Text(stage.subtitle, style: AppTypography.supporting),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResponsiveTileGrid extends StatelessWidget {
  const _ResponsiveTileGrid({required this.items});

  final List<Widget> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final effectiveWidth =
            constraints.maxWidth / MediaQuery.textScalerOf(context).scale(1);
        final cols = constraints.maxWidth >= 600
            ? 3
            : effectiveWidth >= 280
            ? 2
            : 1;
        const gap = AppSpacing.space3;
        final itemWidth = (constraints.maxWidth - (gap * (cols - 1))) / cols;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: <Widget>[
            for (final item in items) SizedBox(width: itemWidth, child: item),
          ],
        );
      },
    );
  }
}

class _GradeGridTile extends StatelessWidget {
  const _GradeGridTile({
    required this.grade,
    required this.roomCount,
    required this.onTap,
  });

  final int grade;
  final int roomCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.panel),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.panel),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.space4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.panel),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'มัธยมศึกษาปีที่ $grade (ม.$grade)',
                style: AppTypography.bodyStrong,
              ),
              const SizedBox(height: 4),
              Text(
                '$roomCount ห้อง ($grade/1–$grade/$roomCount)',
                style: AppTypography.microLabel,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoomGridTile extends StatelessWidget {
  const _RoomGridTile({
    required this.room,
    required this.isSelected,
    required this.onTap,
  });

  final ClassroomId room;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppColors.brandPrimarySoft : AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.panel),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.panel),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.space4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.panel),
            border: Border.all(
              color: isSelected
                  ? AppColors.brandPrimary
                  : AppColors.borderSubtle,
              width: isSelected ? 1.5 : AppBorders.width,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Expanded(
                child: Text(
                  room.roomLabel,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.sectionTitle.copyWith(
                    color: isSelected
                        ? AppColors.brandPrimary
                        : AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.space2),
              Icon(
                isSelected ? Icons.check_circle : Icons.chevron_right,
                size: 18,
                color: isSelected
                    ? AppColors.brandPrimary
                    : AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
