/// School stage, grade, and classroom structure (Section 4.3).
enum EducationStage {
  lowerSecondary,
  upperSecondary;

  String get label => switch (this) {
    EducationStage.lowerSecondary => 'มัธยมศึกษาตอนต้น',
    EducationStage.upperSecondary => 'มัธยมศึกษาตอนปลาย',
  };

  String get subtitle => switch (this) {
    EducationStage.lowerSecondary => 'ม.1 – ม.3 (ระดับชั้นละ 6 ห้อง)',
    EducationStage.upperSecondary => 'ม.4 – ม.6 (ระดับชั้นละ 7 ห้อง)',
  };

  List<int> get grades => switch (this) {
    EducationStage.lowerSecondary => const <int>[1, 2, 3],
    EducationStage.upperSecondary => const <int>[4, 5, 6],
  };

  int get roomsPerGrade => switch (this) {
    EducationStage.lowerSecondary => 6,
    EducationStage.upperSecondary => 7,
  };
}

class ClassroomId {
  const ClassroomId({
    required this.stage,
    required this.grade,
    required this.room,
  });

  final EducationStage stage;
  final int grade;
  final int room;

  String get gradeLabel => 'ม.$grade';
  String get code => '$grade/$room';
  String get roomLabel => 'ห้อง $code';
  String get hierarchyLabel => '${stage.label} / $gradeLabel / $roomLabel';

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ClassroomId &&
            other.stage == stage &&
            other.grade == grade &&
            other.room == room;
  }

  @override
  int get hashCode => Object.hash(stage, grade, room);

  static List<ClassroomId> roomsForGrade(EducationStage stage, int grade) {
    return List<ClassroomId>.generate(
      stage.roomsPerGrade,
      (index) => ClassroomId(stage: stage, grade: grade, room: index + 1),
    );
  }
}
