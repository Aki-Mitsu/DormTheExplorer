import 'package:dorm_the_explorer/theme/app_theme.dart';
import 'package:dorm_the_explorer/features/dormitories/presentation/widgets/dorm_details_section.dart';
import 'package:material_ui/material_ui.dart';

class DormDetailsAmenitiesSection extends StatelessWidget {
  const DormDetailsAmenitiesSection({
    super.key,
    required this.amenities,
  });

  final List<String> amenities;

  @override
  Widget build(BuildContext context) {
    const options = <(String, IconData)>[
      ('WiFi', Icons.wifi_rounded),
      ('Own CR', Icons.bathtub_outlined),
      ('Air Conditioning', Icons.ac_unit_rounded),
      ('Kitchen', Icons.countertops_outlined),
      ('Laundry', Icons.local_laundry_service_outlined),
      ('Parking', Icons.local_parking_rounded),
    ];
    final availableAmenities = amenities
        .map((value) => value.toLowerCase())
        .toSet();

    return DormDetailsSection(
      'Amenities Overview',
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: options.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisExtent: 62,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemBuilder: (context, index) {
          final (name, icon) = options[index];
          final available = availableAmenities.contains(name.toLowerCase());
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 19,
                  color: available ? AppTheme.secondary : AppTheme.outline,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: available
                          ? AppTheme.onSurface
                          : AppTheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Icon(
                  available
                      ? Icons.check_circle_rounded
                      : Icons.remove_circle_outline_rounded,
                  size: 17,
                  color: available ? AppTheme.secondary : AppTheme.outline,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
