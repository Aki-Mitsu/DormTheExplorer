import 'package:material_ui/material_ui.dart';

import '../../../../theme/app_theme.dart';

class DormReportButton extends StatelessWidget {
  const DormReportButton({
    super.key,
    required this.isSubmitting,
    required this.onPressed,
  });

  final bool isSubmitting;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Center(
        child: OutlinedButton.icon(
          onPressed: isSubmitting ? null : onPressed,
          icon: isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.flag_outlined, size: 18),
          label: Text(isSubmitting ? 'Submitting…' : 'Report Listing'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 40),
            foregroundColor: AppTheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
