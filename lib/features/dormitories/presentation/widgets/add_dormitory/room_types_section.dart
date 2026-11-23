import 'package:material_ui/material_ui.dart';

import '../../../../../theme/app_theme.dart';
import '../../../domain/dormitory.dart';

class RoomTypesSection extends StatelessWidget {
  const RoomTypesSection({
    super.key,
    required this.selectedRoomType,
    required this.isSaving,
    required this.onSelect,
  });

  final DormRoomType? selectedRoomType;
  final bool isSaving;
  final ValueChanged<DormRoomType> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose one room type.',
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: AppTheme.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: DormRoomType.values
              .map(
                (roomType) => RoomTypeOption(
                  roomType: roomType,
                  selected: selectedRoomType == roomType,
                  isSaving: isSaving,
                  onTap: () => onSelect(roomType),
                ),
              )
              .toList(growable: false),
        ),
      ],
    );
  }
}

class RoomTypeOption extends StatelessWidget {
  const RoomTypeOption({
    super.key,
    required this.roomType,
    required this.selected,
    required this.isSaving,
    required this.onTap,
  });

  final DormRoomType roomType;
  final bool selected;
  final bool isSaving;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppTheme.primaryContainer
          : AppTheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: isSaving ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: const BoxConstraints(minHeight: 42),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? AppTheme.primaryContainer
                  : AppTheme.outline.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                roomType.label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: selected ? AppTheme.onPrimary : AppTheme.onSurface,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 18,
                color: selected ? AppTheme.onPrimary : AppTheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
