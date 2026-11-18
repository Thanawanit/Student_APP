import 'package:flutter/material.dart';

/// Minimalist cartoon avatar for male and female students.
class StudentAvatar extends StatelessWidget {
  const StudentAvatar({
    super.key,
    required this.fullName,
    this.size = 38,
    this.isFemale,
    this.borderColor = const Color(0xFFD5E4DA),
  });

  final String fullName;
  final double size;
  final bool? isFemale;
  final Color borderColor;

  static const String maleAssetPath = 'assets/images/student_avatar_male.jpg';
  static const String femaleAssetPath =
      'assets/images/student_avatar_female.jpg';

  static const Set<String> _femaleFirstNames = <String>{
    'ณัฐชา',
    'ปภาวดี',
    'รินรดา',
    'วริศรา',
    'สิริยากร',
    'ชญานิษฐ์',
  };

  /// Infers whether a student name corresponds to the female avatar asset.
  static bool inferFemaleFromName(String fullName) {
    final trimmed = fullName.trim();
    if (trimmed.startsWith('เด็กหญิง') ||
        trimmed.startsWith('ด.ญ.') ||
        trimmed.startsWith('นางสาว') ||
        trimmed.startsWith('น.ส.')) {
      return true;
    }
    final firstName = trimmed.split(RegExp(r'\s+')).first;
    return _femaleFirstNames.contains(firstName);
  }

  @override
  Widget build(BuildContext context) {
    final female = isFemale ?? inferFemaleFromName(fullName);
    final assetPath = female ? femaleAssetPath : maleAssetPath;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFE6F2EA),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: ClipOval(
        child: Image.asset(
          assetPath,
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
