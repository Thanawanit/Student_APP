import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';
import 'editorial_bottom_nav.dart';
import 'school_brand_mark.dart';

enum WindowSizeClass { compact, medium, expanded }

WindowSizeClass windowSizeClassOf(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  if (width >= 840) {
    return WindowSizeClass.expanded;
  }
  if (width >= 600) {
    return WindowSizeClass.medium;
  }
  return WindowSizeClass.compact;
}

class AdaptiveDestination {
  const AdaptiveDestination({
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

/// Adaptive shell implementing Material 3 window size classes:
/// - Compact (< 600): slim bottom navigation
/// - Medium (600–839): NavigationRail
/// - Expanded (>= 840): persistent editorial sidebar
class AdaptiveNavigationShell extends StatelessWidget {
  const AdaptiveNavigationShell({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
    required this.destinations,
    required this.children,
    required this.roleTitle,
    this.contextSubtitle,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final List<AdaptiveDestination> destinations;
  final List<Widget> children;
  final String roleTitle;
  final String? contextSubtitle;

  @override
  Widget build(BuildContext context) {
    final sizeClass = windowSizeClassOf(context);
    final body = IndexedStack(index: selectedIndex, children: children);

    if (sizeClass == WindowSizeClass.compact) {
      return Scaffold(
        extendBody: true,
        body: body,
        bottomNavigationBar: EditorialBottomNav(
          selectedIndex: selectedIndex,
          onSelected: onSelected,
          destinations: <EditorialNavDestination>[
            for (final d in destinations)
              EditorialNavDestination(
                icon: d.icon,
                selectedIcon: d.selectedIcon,
                label: d.label,
                badgeCount: d.badgeCount,
              ),
          ],
        ),
      );
    }

    if (sizeClass == WindowSizeClass.medium) {
      return Scaffold(
        body: Row(
          children: <Widget>[
            Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  right: BorderSide(color: AppColors.borderSubtle),
                ),
              ),
              child: SafeArea(
                right: false,
                child: NavigationRail(
                  backgroundColor: AppColors.surface,
                  indicatorColor: AppColors.brandPrimarySoft,
                  selectedIndex: selectedIndex,
                  onDestinationSelected: onSelected,
                  labelType: NavigationRailLabelType.all,
                  leading: const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.space3),
                    child: SchoolLogoMark(size: 32),
                  ),
                  selectedLabelTextStyle: AppTypography.microLabel.copyWith(
                    color: AppColors.brandPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelTextStyle: AppTypography.microLabel.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  selectedIconTheme: const IconThemeData(
                    color: AppColors.brandPrimary,
                    size: 20,
                  ),
                  unselectedIconTheme: const IconThemeData(
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  destinations: <NavigationRailDestination>[
                    for (final d in destinations)
                      NavigationRailDestination(
                        icon: _buildBadgedIcon(d.icon, d.badgeCount),
                        selectedIcon: _buildBadgedIcon(
                          d.selectedIcon,
                          d.badgeCount,
                        ),
                        label: Text(d.label),
                      ),
                  ],
                ),
              ),
            ),
            Expanded(child: body),
          ],
        ),
      );
    }

    // Expanded (>= 840 dp): Linear-style crisp editorial sidebar
    return Scaffold(
      body: Row(
        children: <Widget>[
          Container(
            width: 232,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(right: BorderSide(color: AppColors.borderSubtle)),
            ),
            child: SafeArea(
              right: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.space4,
                      AppSpacing.space4,
                      AppSpacing.space4,
                      AppSpacing.space3,
                    ),
                    child: Row(
                      children: <Widget>[
                        const SchoolLogoMark(size: 32),
                        const SizedBox(width: AppSpacing.space3),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'โรงเรียนขุนยวมวิทยา',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.supporting.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(roleTitle, style: AppTypography.microLabel),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (contextSubtitle != null) ...<Widget>[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.space4,
                        0,
                        AppSpacing.space4,
                        AppSpacing.space3,
                      ),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.space3,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSubtle,
                          borderRadius: BorderRadius.circular(
                            AppRadius.control,
                          ),
                        ),
                        child: Text(
                          contextSubtitle!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.microLabel.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                  const Divider(),
                  const SizedBox(height: AppSpacing.space2),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.space2,
                      ),
                      children: <Widget>[
                        for (var i = 0; i < destinations.length; i++)
                          _SidebarNavItem(
                            destination: destinations[i],
                            isSelected: i == selectedIndex,
                            onTap: () => onSelected(i),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(child: body),
        ],
      ),
    );
  }

  Widget _buildBadgedIcon(IconData icon, int count) {
    if (count <= 0) {
      return Icon(icon);
    }
    return Badge.count(
      count: count,
      backgroundColor: AppColors.brandPrimary,
      child: Icon(icon),
    );
  }
}

class _SidebarNavItem extends StatelessWidget {
  const _SidebarNavItem({
    required this.destination,
    required this.isSelected,
    required this.onTap,
  });

  final AdaptiveDestination destination;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: isSelected ? AppColors.brandPrimarySoft : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.control),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.control),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppSpacing.minTouchTarget,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space3,
                vertical: AppSpacing.space2,
              ),
              child: Row(
                children: <Widget>[
                  Icon(
                    isSelected ? destination.selectedIcon : destination.icon,
                    size: 19,
                    color: isSelected
                        ? AppColors.brandPrimary
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppSpacing.space3),
                  Expanded(
                    child: Text(
                      destination.label,
                      style: AppTypography.supporting.copyWith(
                        color: isSelected
                            ? AppColors.brandPrimary
                            : AppColors.textPrimary,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                  if (destination.badgeCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.brandPrimary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${destination.badgeCount}',
                        style: AppTypography.microLabel.copyWith(
                          color: AppColors.surface,
                          fontSize: 10.5,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
