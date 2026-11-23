import 'package:material_ui/material_ui.dart';

import '../../../../../core/formatters.dart';
import '../../../../../theme/app_theme.dart';
import '../../../domain/dormitory.dart';

class DormitoryCard extends StatelessWidget {
  const DormitoryCard({
    super.key,
    required this.dormitory,
    required this.isLandlord,
    required this.showFavorite,
    required this.isFavorite,
    required this.onFavorite,
    required this.onTap,
  });

  final Dormitory dormitory;
  final bool isLandlord;
  final bool showFavorite;
  final bool isFavorite;
  final VoidCallback onFavorite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final coverUrl = dormitory.photoUrls.isEmpty
        ? null
        : dormitory.photoUrls.first;

    return Material(
      color: AppTheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                SizedBox(
                  height: 128,
                  width: double.infinity,
                  child: coverUrl == null
                      ? const DormitoryPhotoPlaceholder()
                      : Image.network(
                          coverUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const DormitoryPhotoPlaceholder(),
                        ),
                ),
                if (showFavorite)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Material(
                      color: AppTheme.surfaceContainerLowest.withValues(
                        alpha: 0.92,
                      ),
                      shape: const CircleBorder(),
                      child: IconButton(
                        onPressed: onFavorite,
                        tooltip: isFavorite
                            ? 'Remove from favorites'
                            : 'Add to favorites',
                        visualDensity: VisualDensity.compact,
                        constraints: const BoxConstraints.tightFor(
                          width: 34,
                          height: 34,
                        ),
                        icon: Icon(
                          isFavorite
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          size: 18,
                          color: isFavorite
                              ? AppTheme.primaryContainer
                              : AppTheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  left: 8,
                  bottom: 8,
                  child: DormitoryBadge(
                    text: isLandlord
                        ? dormitory.status.toUpperCase()
                        : dormitory.availableSlots <= 0
                        ? 'FULL'
                        : '${dormitory.availableSlots} ${dormitory.availableSlots == 1 ? 'slot' : 'slots'} available',
                    color: isLandlord
                        ? _statusColor(dormitory.status)
                        : dormitory.availableSlots <= 0
                        ? AppTheme.error
                        : dormitory.availableSlots == 1
                        ? AppTheme.tertiaryContainer
                        : AppTheme.secondary,
                  ),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (dormitory.proximityLabel?.isNotEmpty ?? false)
                      Row(
                        children: [
                          const Icon(
                            Icons.near_me_rounded,
                            color: AppTheme.primaryContainer,
                            size: 13,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              dormitory.proximityLabel!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: AppTheme.primaryContainer,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    Text(
                      dormitory.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.onSurface,
                      ),
                    ),
                    Text(
                      dormitory.address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Divider(height: 10, thickness: 0.7),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: RichText(
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            text: TextSpan(
                              style: Theme.of(context).textTheme.titleSmall,
                              children: [
                                TextSpan(
                                  text: formatPeso(dormitory.monthlyPrice),
                                  style: const TextStyle(
                                    color: AppTheme.primaryContainer,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                TextSpan(
                                  text: '/mo',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: AppTheme.onSurfaceVariant,
                                        fontSize: 10,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(
                              dormitory.averageRating == null
                                  ? Icons.star_outline_rounded
                                  : Icons.star_rounded,
                              color: dormitory.averageRating == null
                                  ? AppTheme.onSurfaceVariant
                                  : AppTheme.tertiaryContainer,
                              size: 14,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              dormitory.averageRating?.toStringAsFixed(1) ??
                                  'New',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: dormitory.averageRating == null
                                        ? AppTheme.onSurfaceVariant
                                        : AppTheme.tertiaryContainer,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ],
                        ),
                      ],
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

  Color _statusColor(String status) => switch (status.toLowerCase()) {
    'approved' || 'active' => AppTheme.secondary,
    'rejected' => AppTheme.error,
    _ => AppTheme.tertiaryContainer,
  };
}

class DormitoryPhotoPlaceholder extends StatelessWidget {
  const DormitoryPhotoPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.surfaceContainer,
      alignment: Alignment.center,
      child: Icon(
        Icons.apartment_rounded,
        size: 38,
        color: AppTheme.outline.withValues(alpha: 0.72),
      ),
    );
  }
}

class DormitoryBadge extends StatelessWidget {
  const DormitoryBadge({super.key, required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class LandlordStatusChip extends StatelessWidget {
  const LandlordStatusChip({
    super.key,
    required this.icon,
    required this.label,
    required this.foreground,
  });

  final IconData icon;
  final String label;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 190),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: AppTheme.onSurface.withValues(alpha: 0.08),
            blurRadius: 6,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: foreground),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(color: foreground, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
