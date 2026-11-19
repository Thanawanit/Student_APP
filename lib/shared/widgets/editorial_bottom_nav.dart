import 'dart:ui';

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

/// Floating iOS-inspired liquid glass bottom navigation bar with blur,
/// sliding pill indicator, animated icon scale, and horizontal drag switching.
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

  static const Color _activeColor = Color(0xFF047857);
  static const Color _inactiveColor = Color(0xFF71717A);

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        8,
        20,
        bottomInset > 0 ? bottomInset : 16,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final barWidth = constraints.maxWidth;
          final count = destinations.length;
          final itemWidth = count > 0 ? (barWidth - 8) / count : barWidth;

          return GestureDetector(
            onHorizontalDragEnd: (details) {
              final velocity = details.primaryVelocity ?? 0;
              if (velocity < -180 && selectedIndex < count - 1) {
                onSelected(selectedIndex + 1);
              } else if (velocity > 180 && selectedIndex > 0) {
                onSelected(selectedIndex - 1);
              }
            },
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.84),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.9),
                        width: 1.2,
                      ),
                    ),
                    child: Stack(
                      children: <Widget>[
                        // Sliding liquid pill indicator
                        AnimatedPositioned(
                          duration: AppMotion.resolve(
                            context,
                            const Duration(milliseconds: 250),
                          ),
                          curve: Curves.easeOutQuad,
                          left: selectedIndex * itemWidth,
                          top: 0,
                          bottom: 0,
                          width: itemWidth,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF10B981,
                              ).withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: const Color(
                                  0xFF10B981,
                                ).withValues(alpha: 0.25),
                                width: 1,
                              ),
                            ),
                          ),
                        ),
                        Row(
                          children: <Widget>[
                            for (var i = 0; i < count; i++)
                              Expanded(
                                child: _LiquidNavItem(
                                  destination: destinations[i],
                                  isSelected: i == selectedIndex,
                                  activeColor: _activeColor,
                                  inactiveColor: _inactiveColor,
                                  onTap: () => onSelected(i),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LiquidNavItem extends StatelessWidget {
  const _LiquidNavItem({
    required this.destination,
    required this.isSelected,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  });

  final EditorialNavDestination destination;
  final bool isSelected;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? activeColor : inactiveColor;
    final iconWidget = AnimatedScale(
      scale: isSelected ? 1.15 : 1.0,
      duration: AppMotion.resolve(context, const Duration(milliseconds: 220)),
      curve: Curves.easeOutQuad,
      child: Icon(
        isSelected ? destination.selectedIcon : destination.icon,
        size: 21,
        color: color,
      ),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            destination.badgeCount > 0
                ? Badge(
                    label: Text('${destination.badgeCount}'),
                    backgroundColor: AppColors.brandPrimary,
                    child: iconWidget,
                  )
                : iconWidget,
            const SizedBox(height: 2),
            Text(
              destination.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.microLabel.copyWith(
                fontSize: 11,
                color: color,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
