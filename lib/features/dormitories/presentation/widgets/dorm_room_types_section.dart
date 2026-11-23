import 'package:dorm_the_explorer/theme/app_theme.dart';
import 'package:dorm_the_explorer/features/dormitories/presentation/widgets/dorm_details_section.dart';
import 'package:material_ui/material_ui.dart';

class DormRoomTypesSection extends StatelessWidget {
  const DormRoomTypesSection({super.key, required this.roomTypes});

  final List<String> roomTypes;

  @override
  Widget build(BuildContext context) => DormDetailsSection(
    'Room Types',
    roomTypes.isEmpty
        ? const _EmptyNote(
            icon: Icons.bed_outlined,
            text: 'Room options will appear when the listing is added.',
          )
        : Column(
            children: List.generate(
              roomTypes.length,
              (index) {
                final roomType = roomTypes[index];
                final isLast = index == roomTypes.length - 1;

                return Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 52),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.bed_outlined,
                          size: 20,
                          color: AppTheme.secondary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            roomType,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: AppTheme.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                        const Icon(
                          Icons.check_circle_rounded,
                          size: 18,
                          color: AppTheme.secondary,
                        ),
                      ],
                    ),
                  ),
                );
              },
              growable: false,
            ),
          ),
  );
}

class _EmptyNote extends StatelessWidget {
  const _EmptyNote({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppTheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        Icon(icon, color: AppTheme.outline),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: AppTheme.onSurfaceVariant),
          ),
        ),
      ],
    ),
  );
}
