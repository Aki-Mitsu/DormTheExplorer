import 'package:material_ui/material_ui.dart';

import '../../../../theme/app_theme.dart';
import '../../domain/route_destination.dart';

class CampusRouteDropdown extends StatelessWidget {
  const CampusRouteDropdown({
    super.key,
    required this.selectedCampus,
    required this.onChanged,
  });

  final RouteDestination selectedCampus;
  final ValueChanged<RouteDestination> onChanged;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final menuWidth = constraints.maxWidth;
      return MenuAnchor(
        key: const ValueKey('campus-route-dropdown'),
        alignmentOffset: const Offset(0, 48),
        style: MenuStyle(
          alignment: AlignmentDirectional.topStart,
          backgroundColor: const WidgetStatePropertyAll(
            AppTheme.surfaceContainerLowest,
          ),
          maximumSize: WidgetStatePropertyAll(Size(menuWidth, 280)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(vertical: 4),
          ),
        ),
        menuChildren: [
          for (final campus in RouteDestination.campuses)
            SizedBox(
              width: menuWidth,
              child: MenuItemButton(
                style: ButtonStyle(
                  backgroundColor: const WidgetStatePropertyAll(
                    AppTheme.surfaceContainerLowest,
                  ),
                  foregroundColor: const WidgetStatePropertyAll(
                    AppTheme.onSurface,
                  ),
                  overlayColor: WidgetStatePropertyAll(
                    AppTheme.primary.withValues(alpha: 0.08),
                  ),
                ),
                trailingIcon: campus == selectedCampus
                    ? const Icon(
                        Icons.check_rounded,
                        color: AppTheme.primary,
                      )
                    : null,
                onPressed: () => onChanged(campus),
                child: Text(campus.name, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ),
        ],
        builder: (context, controller, _) => Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () async {
              if (controller.isOpen) {
                controller.close();
                return;
              }
              await Scrollable.ensureVisible(
                context,
                alignment: 0.12,
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeInOut,
              );
              if (context.mounted) controller.open();
            },
            child: InputDecorator(
              isEmpty: false,
              decoration: InputDecoration(
                labelText: 'Route to',
                prefixIcon: const Icon(
                  Icons.school_outlined,
                  color: AppTheme.primary,
                ),
                suffixIcon: Icon(
                  controller.isOpen
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: AppTheme.primary,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.primary),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppTheme.primary,
                    width: 1.5,
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.primary),
                ),
              ),
              child: Text(
                selectedCampus.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      );
    },
  );
}
