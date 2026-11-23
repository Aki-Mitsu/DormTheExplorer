import 'package:dorm_the_explorer/theme/app_theme.dart';
import 'package:dorm_the_explorer/features/dormitories/presentation/widgets/dorm_details_section.dart';
import 'package:material_ui/material_ui.dart';

class DormDetailsDescriptionSection extends StatelessWidget {
  const DormDetailsDescriptionSection({
    super.key,
    required this.dormName,
    required this.description,
  });

  final String dormName;
  final String description;

  @override
  Widget build(BuildContext context) {
    final trimmedDescription = description.trim();

    return DormDetailsSection(
      'About $dormName',
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          trimmedDescription.isEmpty
              ? 'The landlord has not added a description yet.'
              : trimmedDescription,
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: AppTheme.onSurfaceVariant, height: 1.55),
        ),
      ),
    );
  }
}
