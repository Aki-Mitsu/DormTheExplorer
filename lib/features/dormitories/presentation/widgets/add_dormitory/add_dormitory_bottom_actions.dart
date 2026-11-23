import 'package:material_ui/material_ui.dart';

import '../../../../../theme/app_theme.dart';

class AddDormitoryBottomActions extends StatelessWidget {
  const AddDormitoryBottomActions({
    super.key,
    required this.isSaving,
    required this.isUploadingPhotos,
    required this.isEditing,
    required this.onCancel,
    required this.onSubmit,
  });

  final bool isSaving;
  final bool isUploadingPhotos;
  final bool isEditing;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLowest.withValues(alpha: 0.96),
          boxShadow: [
            BoxShadow(
              color: AppTheme.onSurface.withValues(alpha: 0.10),
              blurRadius: 24,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: FilledButton(
                    onPressed: isSaving || isUploadingPhotos ? null : onCancel,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.surfaceContainerHigh,
                      foregroundColor: AppTheme.onSurface,
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: isSaving || isUploadingPhotos ? null : onSubmit,
                    icon: isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.onPrimary,
                            ),
                          )
                        : const Icon(Icons.arrow_forward_rounded, size: 20),
                    label: Text(
                      isSaving
                          ? 'Saving…'
                          : isEditing
                          ? 'Save Changes'
                          : 'Add Dormitory',
                    ),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      backgroundColor: AppTheme.primaryContainer,
                      foregroundColor: AppTheme.onPrimary,
                      elevation: 2,
                      shadowColor: AppTheme.primaryContainer.withValues(
                        alpha: 0.3,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
