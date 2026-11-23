import 'package:material_ui/material_ui.dart';

import '../../../../../theme/app_theme.dart';

class AmenitiesSection extends StatelessWidget {
  const AmenitiesSection({
    super.key,
    required this.amenities,
    required this.options,
    required this.onToggle,
  });

  final Set<String> amenities;
  final List<(String, String, IconData)> options;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Select all available',
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: AppTheme.onSurfaceVariant),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth < 370 ? 1 : 2;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: options.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                mainAxisExtent: 48,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemBuilder: (context, index) {
                final (key, label, icon) = options[index];
                final selected = amenities.contains(key);
                return InkWell(
                  onTap: () => onToggle(key),
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppTheme.primaryContainer
                          : AppTheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          icon,
                          size: 19,
                          color: selected
                              ? AppTheme.onPrimary
                              : AppTheme.onSurface,
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            label,
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color: selected
                                      ? AppTheme.onPrimary
                                      : AppTheme.onSurface,
                                ),
                          ),
                        ),
                        Icon(
                          selected
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                          size: 18,
                          color: selected
                              ? AppTheme.onPrimary
                              : AppTheme.outline,
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class DescriptionSection extends StatelessWidget {
  const DescriptionSection({
    super.key,
    required this.controller,
    required this.fieldKey,
    required this.maxLength,
    required this.validator,
  });

  final TextEditingController controller;
  final GlobalKey<FormFieldState<String>> fieldKey;
  final int maxLength;
  final FormFieldValidator<String> validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          key: fieldKey,
          controller: controller,
          maxLength: maxLength,
          minLines: 4,
          maxLines: 6,
          textCapitalization: TextCapitalization.sentences,
          validator: validator,
          decoration: InputDecoration(
            hintText:
                'Describe room inclusions, study areas, water/electricity terms, curfew rules, and distance to nearby universities...',
            filled: true,
            fillColor: AppTheme.surfaceContainerLow,
            alignLabelWithHint: true,
            contentPadding: const EdgeInsets.all(14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: AppTheme.primaryContainer,
                width: 2,
              ),
            ),
            counterStyle: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: AppTheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}
