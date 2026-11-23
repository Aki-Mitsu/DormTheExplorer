import 'package:material_ui/material_ui.dart';

import '../../../../../theme/app_theme.dart';

class DetailSectionCard extends StatelessWidget {
  const DetailSectionCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppTheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(
          color: AppTheme.onSurface.withValues(alpha: 0.04),
          blurRadius: 12,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: child,
  );
}

class DetailSectionTitle extends StatelessWidget {
  const DetailSectionTitle({
    super.key,
    required this.icon,
    required this.title,
  });

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 19, color: AppTheme.primaryContainer),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
    ],
  );
}

class DetailMetricTile extends StatelessWidget {
  const DetailMetricTile({
    super.key,
    required this.label,
    required this.value,
    required this.subtitle,
    required this.color,
    this.icon,
  });

  final String label;
  final String value;
  final String subtitle;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 80),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppTheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(11),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppTheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
            ),
            if (icon != null)
              Icon(icon, size: 16, color: AppTheme.onSurfaceVariant),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall
              ?.copyWith(color: color, fontWeight: FontWeight.w700),
        ),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: AppTheme.onSurfaceVariant),
          ),
        ],
      ],
    ),
  );
}

class DetailAmenityTile extends StatelessWidget {
  const DetailAmenityTile({
    super.key,
    required this.label,
    required this.icon,
    required this.available,
  });

  final String label;
  final IconData icon;
  final bool available;

  @override
  Widget build(BuildContext context) => Container(
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
            label,
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
}
