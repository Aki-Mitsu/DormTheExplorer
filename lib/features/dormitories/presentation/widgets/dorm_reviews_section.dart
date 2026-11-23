import 'package:material_ui/material_ui.dart';

import '../../../../theme/app_theme.dart';
import '../../domain/dorm_review.dart';
import 'dorm_details_section.dart';
import 'dorm_review_card.dart';
import 'review_success_banner.dart';
import 'write_review_composer.dart';

class DormReviewsSection extends StatelessWidget {
  const DormReviewsSection({
    super.key,
    required this.reviews,
    required this.averageRating,
    required this.canReview,
    required this.hasReviewed,
    required this.reviewController,
    required this.selectedRating,
    required this.isSubmittingReview,
    required this.successMessage,
    required this.onRatingChanged,
    required this.onSubmitReview,
    required this.onDismissSuccess,
  });

  final List<DormReview> reviews;
  final double averageRating;
  final bool canReview;
  final bool hasReviewed;
  final TextEditingController reviewController;
  final int selectedRating;
  final bool isSubmittingReview;
  final String? successMessage;
  final ValueChanged<int> onRatingChanged;
  final VoidCallback onSubmitReview;
  final VoidCallback onDismissSuccess;

  @override
  Widget build(BuildContext context) => DormDetailsSection(
    'Reviews',
    Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (canReview && !hasReviewed)
          WriteReviewComposer(
            controller: reviewController,
            selectedRating: selectedRating,
            isSubmitting: isSubmittingReview,
            onRatingChanged: onRatingChanged,
            onSubmit: onSubmitReview,
          )
        else if (canReview)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'You have already reviewed this dormitory.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.onSurfaceVariant,
              ),
            ),
          ),
        if (successMessage != null)
          ReviewSuccessBanner(
            message: successMessage!,
            onDismissed: onDismissSuccess,
          ),
        for (final review in reviews) DormReviewCard(review: review),
      ],
    ),
    titleAccessory: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.star_rounded,
          size: 17,
          color: AppTheme.tertiaryAccent,
        ),
        const SizedBox(width: 3),
        Text(
          '${reviews.isEmpty ? '—' : averageRating.toStringAsFixed(1)}/5',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: AppTheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
    trailing: Text(
      '${reviews.length} ${reviews.length == 1 ? 'review' : 'reviews'}',
      style: Theme.of(context).textTheme.bodySmall
          ?.copyWith(color: AppTheme.onSurfaceVariant),
      textAlign: TextAlign.end,
    ),
  );
}
