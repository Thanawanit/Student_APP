import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Top-to-bottom green-to-white editorial gradient surface for dashboard headers.
class DashboardGradientBand extends StatelessWidget {
  const DashboardGradientBand({
    super.key,
    required this.child,
    this.showBottomBorder = true,
  });

  final Widget child;
  final bool showBottomBorder;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppColors.topGreenToWhiteGradient,
        border: showBottomBorder
            ? const Border(bottom: BorderSide(color: AppColors.borderSubtle))
            : null,
      ),
      child: child,
    );
  }
}
