import 'package:dorm_the_explorer/theme/app_theme.dart';
import 'package:dorm_the_explorer/features/dormitories/domain/dormitory.dart';
import 'package:material_ui/material_ui.dart';

class DormDetailsInfoSection extends StatelessWidget {
  const DormDetailsInfoSection({
    super.key,
    required this.dormitory,
    required this.dormName,
    required this.monthlyRentLabel,
  });

  final Dormitory dormitory;
  final String dormName;
  final String monthlyRentLabel;

  @override
  Widget build(BuildContext context) {
    final address = dormitory.address.trim();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            dormName,
            style: Theme.of(context).textTheme.headlineLarge
                ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.4),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.location_on_rounded,
                size: 18,
                color: AppTheme.primaryContainer,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  address.isEmpty
                      ? 'Address will be added by the landlord'
                      : address,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: AppTheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        'MONTHLY RENT',
                        style: Theme.of(context).textTheme.labelSmall
                            ?.copyWith(color: AppTheme.onSurfaceVariant),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _AvailabilityBadge(
                      available: dormitory.availableSlots,
                      total: dormitory.totalSlots,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  monthlyRentLabel,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.primaryContainer,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dormitory.utilitiesIncluded
                      ? '✓ Water & electricity included'
                      : 'Utility details not provided',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: dormitory.utilitiesIncluded
                        ? AppTheme.secondary
                        : AppTheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AvailabilityBadge extends StatelessWidget {
  const _AvailabilityBadge({required this.available, required this.total});

  final int available;
  final int total;

  @override
  Widget build(BuildContext context) {
    final full = total > 0 && available <= 0;
    final label = total <= 0
        ? 'Availability pending'
        : full
        ? 'Fully booked'
        : '$available ${available == 1 ? 'slot' : 'slots'} available';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: full ? AppTheme.errorContainer : AppTheme.secondaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: full
              ? AppTheme.onErrorContainer
              : AppTheme.onSecondaryContainer,
        ),
      ),
    );
  }
}
