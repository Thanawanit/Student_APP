import 'package:flutter/material.dart';

import '../../core/theme/app_typography.dart';
import '../../core/utils/responsive_layout.dart';
import '../../domain/models/school_structure.dart';
import '../../state/app_controller.dart';
import 'teacher_shell_screen.dart';

/// Hierarchical 3-step Classroom Selection flow (`ช่วงชั้น` -> `ระดับชั้น` -> `ห้องเรียน`).
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
        backgroundColor: const Color(0xFFF2F5F3),
        appBar: AppBar(
          backgroundColor: const Color(0xFFFFFFFF),
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            tooltip: 'ย้อนกลับ',
            onPressed: _handleStepBack,
            icon: const Icon(Icons.arrow_back),
          ),
          title: Text(
            'เลือกห้องเรียน',
            style: AppTypography.sectionTitle.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
        ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ResponsiveContent(
                padding: EdgeInsets.zero,
                child: _BreadcrumbStepper(
                  currentStep: currentStep,
                  selectedStage: _selectedStage,
                  selectedGrade: _selectedGrade,
                  onTapStep1: () => setState(() {
                    _selectedStage = null;
                    _selectedGrade = null;
                  }),
                  onTapStep2: () => setState(() {
                    _selectedGrade = null;
                  }),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: <Widget>[
                    ResponsiveContent(
                      padding: EdgeInsets.zero,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          if (currentStep == 1) ...<Widget>[
                            Text(
                              'เลือกช่วงชั้น',
                              style: AppTypography.pageTitle.copyWith(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'เลือกระดับการศึกษาที่ต้องการตรวจสอบ',
                              style: AppTypography.supporting.copyWith(
                                fontSize: 13,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 14),
                            for (
                              var i = 0;
                              i < EducationStage.values.length;
                              i++
                            ) ...<Widget>[
                              _StageVerticalCard(
                                stage: EducationStage.values[i],
                                onTap: () => setState(() {
                                  _selectedStage = EducationStage.values[i];
                                  _selectedGrade = null;
                                }),
                              ),
                              if (i < EducationStage.values.length - 1)
                                const SizedBox(height: 10),
                            ],
                          ] else if (currentStep == 2) ...<Widget>[
                            Text(
                              'เลือกระดับชั้น',
                              style: AppTypography.pageTitle.copyWith(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 14),
                            for (
                              var i = 0;
                              i < _selectedStage!.grades.length;
                              i++
                            ) ...<Widget>[
                              _GradeVerticalCard(
                                grade: _selectedStage!.grades[i],
                                roomCount: _selectedStage!.roomsPerGrade,
                                onTap: () => setState(
                                  () => _selectedGrade =
                                      _selectedStage!.grades[i],
                                ),
                              ),
                              if (i < _selectedStage!.grades.length - 1)
                                const SizedBox(height: 10),
                            ],
                          ] else ...<Widget>[
                            Text(
                              'เลือกห้องเรียน',
                              style: AppTypography.pageTitle.copyWith(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 14),
                            for (final entry in ClassroomId.roomsForGrade(
                              _selectedStage!,
                              _selectedGrade!,
                            ).asMap().entries) ...<Widget>[
                              _RoomVerticalCard(
                                room: entry.value,
                                isSelected:
                                    AppScope.of(context).selectedClassroom ==
                                    entry.value,
                                onTap: () => _selectRoom(entry.value),
                              ),
                              if (entry.key < _selectedStage!.roomsPerGrade - 1)
                                const SizedBox(height: 10),
                            ],
                          ],
                        ],
                      ),
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

class _BreadcrumbStepper extends StatelessWidget {
  const _BreadcrumbStepper({
    required this.currentStep,
    required this.selectedStage,
    required this.selectedGrade,
    required this.onTapStep1,
    required this.onTapStep2,
  });

  final int currentStep;
  final EducationStage? selectedStage;
  final int? selectedGrade;
  final VoidCallback onTapStep1;
  final VoidCallback onTapStep2;

  @override
  Widget build(BuildContext context) {
    final String stageShort = selectedStage == EducationStage.lowerSecondary
        ? 'ม.ต้น'
        : 'ม.ปลาย';

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: <Widget>[
          _BreadcrumbPill(
            label: currentStep > 1 ? stageShort : '01 ช่วงชั้น',
            isActive: currentStep == 1,
            isCompleted: currentStep > 1,
            onTap: currentStep > 1 ? onTapStep1 : null,
          ),
          Container(
            width: 16,
            height: 1.5,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            color: currentStep > 1
                ? const Color(0xFF86EFAC)
                : const Color(0xFFE2E8E4),
          ),
          _BreadcrumbPill(
            label: currentStep > 2 && selectedGrade != null
                ? 'ม.$selectedGrade'
                : '02 ระดับชั้น',
            isActive: currentStep == 2,
            isCompleted: currentStep > 2,
            onTap: currentStep > 2 ? onTapStep2 : null,
          ),
          Container(
            width: 16,
            height: 1.5,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            color: currentStep > 2
                ? const Color(0xFF86EFAC)
                : const Color(0xFFE2E8E4),
          ),
          _BreadcrumbPill(
            label: '03 ห้องเรียน',
            isActive: currentStep == 3,
            isCompleted: false,
          ),
        ],
      ),
    );
  }
}

class _BreadcrumbPill extends StatelessWidget {
  const _BreadcrumbPill({
    required this.label,
    required this.isActive,
    required this.isCompleted,
    this.onTap,
  });

  final String label;
  final bool isActive;
  final bool isCompleted;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color bgColor = isActive
        ? const Color(0xFF14532D)
        : isCompleted
        ? const Color(0xFFDCFCE7)
        : const Color(0xFFFFFFFF);
    final Color textColor = isActive
        ? Colors.white
        : isCompleted
        ? const Color(0xFF15803D)
        : const Color(0xFF94A3B8);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(99),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(99),
            border: !isActive && !isCompleted
                ? Border.all(color: const Color(0xFFE2E8E4))
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (isCompleted) ...<Widget>[
                const Icon(
                  Icons.check_rounded,
                  size: 14,
                  color: Color(0xFF15803D),
                ),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: AppTypography.microLabel.copyWith(
                  fontSize: 12.5,
                  color: textColor,
                  fontWeight: isActive
                      ? FontWeight.w700
                      : isCompleted
                      ? FontWeight.w600
                      : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StageVerticalCard extends StatelessWidget {
  const _StageVerticalCard({required this.stage, required this.onTap});

  final EducationStage stage;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isLower = stage == EducationStage.lowerSecondary;
    final badgeText = isLower ? 'ม.ต้น' : 'ม.ปลาย';
    final subtitleText = isLower
        ? 'ม.1 – ม.3 • ระดับชั้นละ 6 ห้อง (รวม 18 ห้อง)'
        : 'ม.4 – ม.6 • ระดับชั้นละ 7 ห้อง (รวม 21 ห้อง)';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFFFF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8E4)),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    badgeText,
                    style: AppTypography.microLabel.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF15803D),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      stage.label,
                      style: AppTypography.sectionTitle.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitleText,
                      style: AppTypography.supporting.copyWith(
                        fontSize: 12.5,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
            ],
          ),
        ),
      ),
    );
  }
}

class _GradeVerticalCard extends StatelessWidget {
  const _GradeVerticalCard({
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
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFFFF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8E4)),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    'ม.$grade',
                    style: AppTypography.sectionTitle.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF14532D),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'มัธยมศึกษาปีที่ $grade',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.sectionTitle.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$roomCount ห้องเรียน (ห้อง $grade/1 – $grade/$roomCount)',
                      style: AppTypography.supporting.copyWith(
                        fontSize: 12.5,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoomVerticalCard extends StatelessWidget {
  const _RoomVerticalCard({
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
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFECFDF5)
                : const Color(0xFFFFFFFF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF16A34A)
                  : const Color(0xFFE2E8E4),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF16A34A)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    room.code,
                    style: AppTypography.bodyStrong.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF334155),
                      fontFeatures: const <FontFeature>[
                        FontFeature.tabularFigures(),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      room.roomLabel,
                      style: AppTypography.sectionTitle.copyWith(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isSelected
                          ? 'นักเรียน 12 คน • กำลังแสดงผล'
                          : 'นักเรียน 12 คน',
                      style: AppTypography.microLabel.copyWith(
                        fontSize: 12,
                        color: isSelected
                            ? const Color(0xFF15803D)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                isSelected
                    ? Icons.check_circle_rounded
                    : Icons.chevron_right_rounded,
                size: isSelected ? 22 : 24,
                color: isSelected
                    ? const Color(0xFF16A34A)
                    : const Color(0xFF94A3B8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
