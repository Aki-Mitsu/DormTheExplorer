import 'package:material_ui/material_ui.dart';

import '../../../../theme/app_theme.dart';

class DormListingReportSubmission {
  const DormListingReportSubmission({
    required this.reason,
    required this.details,
  });

  final String reason;
  final String details;
}

class DormListingReportDialog extends StatefulWidget {
  const DormListingReportDialog({super.key});

  @override
  State<DormListingReportDialog> createState() =>
      _DormListingReportDialogState();
}

class _DormListingReportDialogState extends State<DormListingReportDialog> {
  static const _reasons = <(String, String)>[
    ('incorrect_information', 'Incorrect listing information'),
    ('unavailable_property', 'Property is unavailable'),
    ('misleading_photos', 'Photos are misleading'),
    ('inappropriate_content', 'Inappropriate content'),
    ('suspicious_listing', 'Suspicious or potentially fraudulent'),
    ('other', 'Other'),
  ];

  final _detailsController = TextEditingController();
  String _selectedReason = _reasons.first.$1;
  bool _didSubmit = false;
  bool _showDetailsError = false;

  bool get _requiresSpecificReason => _selectedReason == 'other';

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_didSubmit) return;
    if (_requiresSpecificReason && _detailsController.text.trim().isEmpty) {
      setState(() => _showDetailsError = true);
      return;
    }
    _didSubmit = true;
    Navigator.of(context).pop(
      DormListingReportSubmission(
        reason: _selectedReason,
        details: _detailsController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reportRed = AppTheme.primary;
    final mediaQuery = MediaQuery.of(context);
    final usableHeight =
        mediaQuery.size.height - mediaQuery.viewInsets.bottom - 32;
    final dialogMaxHeight = usableHeight > 0 ? usableHeight * 0.9 : 240.0;
    final reasonMenuWidth = mediaQuery.size.width > 460
        ? 372.0
        : mediaQuery.size.width - 88;

    return AlertDialog(
      scrollable: true,
      alignment: Alignment.center,
      constraints: BoxConstraints(
        maxWidth: 420,
        maxHeight: dialogMaxHeight,
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      backgroundColor: AppTheme.surfaceContainerLowest,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      iconPadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      icon: Container(
        width: 52,
        height: 52,
        decoration: const BoxDecoration(
          color: AppTheme.errorContainer,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: const Icon(
          Icons.flag_rounded,
          color: AppTheme.error,
          size: 25,
        ),
      ),
      title: Text(
        'Report this listing',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: AppTheme.onSurface,
        ),
      ),
      titlePadding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Help us keep the community safe. Select the reason that best '
            'describes the issue. Your report will remain private.',
            textAlign: TextAlign.justify,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              height: 1.45,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          InputDecorator(
            isEmpty: false,
            decoration: InputDecoration(
              labelText: 'Reason',
              labelStyle: TextStyle(color: reportRed),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: reportRed),
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: reportRed, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedReason,
                isExpanded: true,
                menuWidth: reasonMenuWidth,
                icon: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: reportRed,
                ),
                dropdownColor: Colors.white,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.onSurface,
                ),
                items: [
                  for (final (value, label) in _reasons)
                    DropdownMenuItem(
                      value: value,
                      child: Text(label, maxLines: 2, softWrap: true),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedReason = value;
                      _showDetailsError = false;
                    });
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _detailsController,
            maxLength: 1000,
            maxLines: 4,
            minLines: 3,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (value) {
              if (_showDetailsError && value.trim().isNotEmpty) {
                setState(() => _showDetailsError = false);
              }
            },
            decoration: InputDecoration(
              labelText: _requiresSpecificReason
                  ? 'Specific reason (required)'
                  : 'Additional details (optional)',
              alignLabelWithHint: true,
              hintText: _requiresSpecificReason
                  ? 'Please explain the specific issue...'
                  : 'Describe what seems wrong...',
              errorText: _requiresSpecificReason && _showDetailsError
                  ? 'Please enter a specific reason.'
                  : null,
              filled: true,
              fillColor: AppTheme.surfaceContainerLow,
              contentPadding: const EdgeInsets.fromLTRB(14, 16, 14, 10),
              counterStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppTheme.onSurfaceVariant,
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: AppTheme.outlineVariant),
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: reportRed, width: 1.5),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
      actionsPadding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: reportRed,
                foregroundColor: AppTheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _didSubmit ? null : _submit,
              icon: const Icon(Icons.outlined_flag_rounded, size: 18),
              label: const Text('Submit Report'),
            ),
            const SizedBox(height: 6),
            TextButton(
              style: TextButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
                foregroundColor: AppTheme.onSurfaceVariant,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ],
    );
  }
}
