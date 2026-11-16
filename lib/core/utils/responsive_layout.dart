import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// Full-bleed on phones with restrained padding; centered up to 920 dp on wide tablets.
class ResponsiveContent extends StatelessWidget {
  const ResponsiveContent({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  static double horizontalInset(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 600) {
      return AppSpacing.space4;
    }
    if (width < 900) {
      return AppSpacing.space5;
    }
    return AppSpacing.space6;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final inset = horizontalInset(context);

    final inner = Padding(
      padding: padding ?? EdgeInsets.symmetric(horizontal: inset),
      child: child,
    );

    if (width <= AppSpacing.maxContentWidth) {
      return inner;
    }

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
        child: inner,
      ),
    );
  }
}
