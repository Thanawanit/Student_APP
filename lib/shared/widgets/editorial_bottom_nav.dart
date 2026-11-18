import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';

class EditorialNavDestination {
  const EditorialNavDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.badgeCount = 0,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final int badgeCount;
}

/// Material 3 NavigationBar style bottom bar with horizontal 64x32 StadiumBorder pill indicator.
class EditorialBottomNav extends StatelessWidget {
  const EditorialBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
    required this.destinations,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final List<EditorialNavDestination> destinations;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      child: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.borderSubtle)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 62,
            child: Row(
              children: <Widget>[
                for (var i = 0; i < destinations.length; i++)
                  Expanded(
                    child: _NavItem(
                      destination: destinations[i],
                      isSelected: i == selectedIndex,
                      onTap: () => onSelected(i),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.destination,
    required this.isSelected,
    required this.onTap,
  });

  final EditorialNavDestination destination;
  final bool isSelected;
  final VoidCallback onTap;

  static const Color _activeColor = Color(0xFF14532D);
  static const Color _indicatorColor = Color(0xFFDCECE2);

  @override
  Widget build(BuildContext context) {
    final iconColor = isSelected ? _activeColor : AppColors.textSecondary;
    final iconWidget = Icon(
      isSelected ? destination.selectedIcon : destination.icon,
      size: 20,
      color: iconColor,
    );

    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSpacing.minTouchTarget),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            AnimatedContainer(
              duration: AppMotion.resolve(context, AppMotion.fast),
              curve: AppMotion.gentleCurve,
              width: 64,
              height: 32,
              decoration: ShapeDecoration(
                color: isSelected ? _indicatorColor : Colors.transparent,
                shape: const StadiumBorder(),
              ),
              child: Center(
                child: destination.badgeCount > 0
                    ? Badge(
                        label: Text('${destination.badgeCount}'),
                        backgroundColor: AppColors.brandPrimary,
                        child: iconWidget,
                      )
                    : iconWidget,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              destination.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.microLabel.copyWith(
                color: isSelected ? _activeColor : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
