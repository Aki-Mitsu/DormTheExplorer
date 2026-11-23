import 'package:material_ui/material_ui.dart';

import '../../../../theme/app_theme.dart';
import 'dorm_details_section.dart';

class DormLandlordContactSection extends StatelessWidget {
  const DormLandlordContactSection({
    super.key,
    required this.name,
    required this.phone,
    required this.photoUrl,
  });

  final String? name;
  final String? phone;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) => DormDetailsSection(
    'Landlord Contact',
    Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppTheme.surfaceContainer,
            child: photoUrl == null || photoUrl!.isEmpty
                ? const Icon(Icons.person_rounded, color: AppTheme.outline)
                : ClipOval(
                    child: Image.network(
                      photoUrl!,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(
                            Icons.person_rounded,
                            color: AppTheme.outline,
                          ),
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name?.isNotEmpty == true ? name! : 'Landlord name pending',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  'Property owner',
                  style: Theme.of(context).textTheme.labelSmall
                      ?.copyWith(color: AppTheme.onSurfaceVariant),
                ),
                const SizedBox(height: 4),
                Text(
                  phone?.isNotEmpty == true
                      ? phone!
                      : 'Contact number not provided',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: AppTheme.primaryContainer),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class DormContactBar extends StatelessWidget {
  const DormContactBar({
    super.key,
    required this.phone,
    required this.onLaunchContact,
    required this.onShowRoute,
  });

  final String? phone;
  final Future<void> Function(String scheme, String phone) onLaunchContact;
  final VoidCallback onShowRoute;

  @override
  Widget build(BuildContext context) {
    final canContact = phone?.isNotEmpty == true;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLowest,
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryContainer.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: canContact
                    ? () => onLaunchContact('tel', phone!)
                    : null,
                style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
                icon: const Icon(Icons.call_rounded, size: 18),
                label: const Text('Call'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.icon(
                onPressed: canContact
                    ? () => onLaunchContact('sms', phone!)
                    : null,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  backgroundColor: AppTheme.surfaceContainer,
                  foregroundColor: AppTheme.onSurface,
                ),
                icon: const Icon(Icons.sms_outlined, size: 18),
                label: const Text('SMS'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.icon(
                onPressed: onShowRoute,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  backgroundColor: AppTheme.secondaryContainer,
                  foregroundColor: AppTheme.onSecondaryContainer,
                ),
                icon: const Icon(Icons.directions_rounded, size: 18),
                label: const Text('Route'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
