import 'package:material_ui/material_ui.dart';

import '../../../../../theme/app_theme.dart';

class SeekerNavigationBar extends StatelessWidget {
  const SeekerNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return DashboardNavigationBarShell(
      selectedIndex: selectedIndex,
      onSelected: onSelected,
      destinations: const [
        (Icons.home_outlined, 'Home'),
        (Icons.favorite_border_rounded, 'Favorites'),
        (Icons.person_outline_rounded, 'Profile'),
      ],
    );
  }
}

class LandlordNavigationBar extends StatelessWidget {
  const LandlordNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return DashboardNavigationBarShell(
      selectedIndex: selectedIndex,
      onSelected: onSelected,
      destinations: const [
        (Icons.home_outlined, 'Home'),
        (Icons.apartment_outlined, 'My Listings'),
        (Icons.person_outline_rounded, 'Profile'),
      ],
    );
  }
}

class DashboardNavigationBarShell extends StatelessWidget {
  const DashboardNavigationBarShell({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
    required this.destinations,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final List<(IconData, String)> destinations;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLowest.withValues(alpha: 0.97),
          boxShadow: [
            BoxShadow(
              color: AppTheme.onSurface.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            for (var index = 0; index < destinations.length; index++)
              Expanded(
                child: InkWell(
                  onTap: () => onSelected(index),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        destinations[index].$1,
                        size: 23,
                        color: selectedIndex == index
                            ? AppTheme.primaryContainer
                            : AppTheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        destinations[index].$2,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: selectedIndex == index
                              ? AppTheme.primaryContainer
                              : AppTheme.onSurfaceVariant,
                          fontWeight: selectedIndex == index
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
