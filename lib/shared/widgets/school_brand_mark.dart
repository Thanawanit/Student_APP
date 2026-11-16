import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Khunyuam Wittaya School circular emblem rendered cleanly on light surfaces.
class SchoolLogoMark extends StatelessWidget {
  const SchoolLogoMark({super.key, this.size = 44});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'ตราสัญลักษณ์โรงเรียนขุนยวมวิทยา',
      image: true,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.borderSubtle),
        ),
        clipBehavior: Clip.antiAlias,
        padding: const EdgeInsets.all(2),
        child: ClipOval(
          child: Image.asset(
            'assets/images/school_logo.png',
            width: size - 4,
            height: size - 4,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
