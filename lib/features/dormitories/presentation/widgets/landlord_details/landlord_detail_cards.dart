import 'package:material_ui/material_ui.dart';

import '../../../../../core/formatters.dart';
import '../../../../../theme/app_theme.dart';
import '../../../domain/amenity_utils.dart';
import '../../../domain/dormitory.dart';
import 'landlord_detail_parts.dart';

class LandlordAvailabilityCard extends StatelessWidget {
  const LandlordAvailabilityCard({
    super.key,
    required this.isAvailable,
    required this.isUpdating,
    required this.availableSlots,
    required this.onToggleAvailability,
    required this.onChooseAvailableSlots,
  });

  final bool isAvailable;
  final bool isUpdating;
  final int availableSlots;
  final ValueChanged<bool> onToggleAvailability;
  final VoidCallback onChooseAvailableSlots;

  @override
  Widget build(BuildContext context) {
    return DetailSectionCard(
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 19,
                backgroundColor: AppTheme.primaryFixed,
                child: const Icon(
                  Icons.toggle_on_rounded,
                  color: AppTheme.primaryContainer,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Availability Status',
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      'Manage room availability',
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: AppTheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              if (isUpdating)
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Switch(
                  value: isAvailable,
                  onChanged: onToggleAvailability,
                  activeThumbColor: AppTheme.surfaceContainerLowest,
                  activeTrackColor: AppTheme.secondary,
                  inactiveThumbColor: AppTheme.surfaceContainerLowest,
                  inactiveTrackColor: AppTheme.surfaceContainerHighest,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isAvailable
                        ? AppTheme.secondaryContainer.withValues(alpha: 0.4)
                        : AppTheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isAvailable
                            ? Icons.check_circle_rounded
                            : Icons.do_not_disturb_on_outlined,
                        size: 16,
                        color: isAvailable
                            ? AppTheme.onSecondaryContainer
                            : AppTheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          isAvailable
                              ? '$availableSlots ${availableSlots == 1 ? 'slot' : 'slots'} available'
                              : 'No slots available',
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: isAvailable
                                ? AppTheme.onSecondaryContainer
                                : AppTheme.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: isUpdating ? null : onChooseAvailableSlots,
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Set slots'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Full dormitories remain visible to seekers and show as full.',
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: AppTheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

class LandlordOverviewCard extends StatelessWidget {
  const LandlordOverviewCard({super.key, required this.dormitory});

  final Dormitory dormitory;

  @override
  Widget build(BuildContext context) {
    final roomTypes = DormRoomType.currentLabels(dormitory.roomTypes);

    return DetailSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            dormitory.name,
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.3),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.location_on_rounded,
                size: 18,
                color: AppTheme.primaryContainer,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  dormitory.address.isEmpty
                      ? 'Address not provided'
                      : dormitory.address,
                  style: Theme.of(context).textTheme.bodyLarge
                      ?.copyWith(color: AppTheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final metricWidth = (constraints.maxWidth - 10) / 2;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  SizedBox(
                    width: metricWidth,
                    child: DetailMetricTile(
                      label: 'MONTHLY RENT',
                      value: formatPeso(dormitory.monthlyPrice),
                      subtitle: 'per month / slot',
                      color: AppTheme.primaryContainer,
                    ),
                  ),
                  SizedBox(
                    width: metricWidth,
                    child: DetailMetricTile(
                      label: 'CAPACITY SLOTS',
                      value: '${dormitory.availableSlots} Available',
                      subtitle: '${dormitory.totalSlots} total occupancy',
                      color: dormitory.availableSlots > 0
                          ? AppTheme.secondary
                          : AppTheme.error,
                    ),
                  ),
                  if (roomTypes.isNotEmpty)
                    SizedBox(
                      width: constraints.maxWidth,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.bed_outlined,
                              size: 18,
                              color: AppTheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'ROOM TYPE',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: AppTheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.6,
                                  ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                roomTypes.join(' • '),
                                textAlign: TextAlign.end,
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class LandlordDescriptionCard extends StatelessWidget {
  const LandlordDescriptionCard({super.key, required this.description});

  final String description;

  @override
  Widget build(BuildContext context) {
    final trimmedDescription = description.trim();
    return DetailSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DetailSectionTitle(
            icon: Icons.description_outlined,
            title: 'About the Property',
          ),
          const SizedBox(height: 8),
          Text(
            trimmedDescription.isEmpty
                ? 'No property description provided.'
                : trimmedDescription,
            style: Theme.of(context).textTheme.bodyLarge
                ?.copyWith(color: AppTheme.onSurfaceVariant, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class LandlordAmenitiesCard extends StatelessWidget {
  const LandlordAmenitiesCard({
    super.key,
    required this.amenities,
    required this.amenityOptions,
  });

  final List<String> amenities;
  final List<(String, String, IconData)> amenityOptions;

  @override
  Widget build(BuildContext context) {
    final selected = amenities.map(canonicalAmenity).toSet();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Amenities Overview',
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: amenityOptions.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisExtent: 62,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemBuilder: (context, index) {
            final (key, label, icon) = amenityOptions[index];
            return DetailAmenityTile(
              label: label,
              icon: icon,
              available: selected.contains(key),
            );
          },
        ),
      ],
    );
  }
}
