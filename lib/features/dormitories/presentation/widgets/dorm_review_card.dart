import 'package:material_ui/material_ui.dart';

import '../../../../theme/app_theme.dart';
import '../../domain/dorm_review.dart';

class DormReviewCard extends StatelessWidget {
  const DormReviewCard({super.key, required this.review});

  final DormReview review;

  @override
  Widget build(BuildContext context) {
    final trimmedName = review.authorName.trim();
    final initials = trimmedName.isEmpty ? '?' : trimmedName[0].toUpperCase();
    final photoUrl = review.authorPhotoUrl?.trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 17,
                backgroundColor: AppTheme.primaryFixed,
                child: photoUrl == null || photoUrl.isEmpty
                    ? _avatarInitials(initials)
                    : ClipOval(
                        child: Image.network(
                          photoUrl,
                          width: 34,
                          height: 34,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _avatarInitials(initials),
                        ),
                      ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.authorName,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    Text(
                      review.authorSubtitle,
                      style: Theme.of(context).textTheme.labelSmall
                          ?.copyWith(color: AppTheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...List.generate(
                    5,
                    (index) => Icon(
                      index < review.rating
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: AppTheme.tertiaryAccent,
                      size: 15,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            review.comment,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _formatPostedAt(context),
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: AppTheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  String _formatPostedAt(BuildContext context) {
    if (review.createdAt.millisecondsSinceEpoch == 0) {
      return 'Posted date unavailable';
    }

    final postedAt = review.createdAt.toLocal();
    final localizations = MaterialLocalizations.of(context);
    final date = localizations.formatMediumDate(postedAt);
    final time = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(postedAt),
    );
    return 'Posted $date at $time';
  }

  Widget _avatarInitials(String initials) => Text(
    initials,
    style: const TextStyle(
      color: AppTheme.primaryContainer,
      fontWeight: FontWeight.w700,
    ),
  );
}
