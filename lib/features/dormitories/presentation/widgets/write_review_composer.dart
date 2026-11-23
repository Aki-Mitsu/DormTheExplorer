import 'package:material_ui/material_ui.dart';

import '../../../../theme/app_theme.dart';

class WriteReviewComposer extends StatelessWidget {
  const WriteReviewComposer({
    super.key,
    required this.controller,
    required this.selectedRating,
    required this.isSubmitting,
    required this.onRatingChanged,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final int selectedRating;
  final bool isSubmitting;
  final ValueChanged<int> onRatingChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppTheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Write a review',
          style: Theme.of(context).textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              selectedRating == 0 ? 'Tap to rate' : '$selectedRating/5',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppTheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            ...List.generate(
              5,
              (index) => IconButton(
                onPressed: () => onRatingChanged(index + 1),
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints.tightFor(
                  width: 34,
                  height: 34,
                ),
                padding: EdgeInsets.zero,
                tooltip: 'Rate ${index + 1} out of 5 stars',
                icon: Icon(
                  index < selectedRating
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  color: AppTheme.tertiaryAccent,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          minLines: 3,
          maxLines: 5,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: 'Share what future students should know...',
            alignLabelWithHint: true,
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: isSubmitting ? null : onSubmit,
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            icon: isSubmitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send_rounded, size: 17),
            label: const Text('Post Review'),
          ),
        ),
      ],
    ),
  );
}
