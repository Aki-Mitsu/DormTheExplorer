import 'package:material_ui/material_ui.dart';

import '../../../../../theme/app_theme.dart';

class PhotosSection extends StatelessWidget {
  const PhotosSection({
    super.key,
    required this.photoUrls,
    required this.maxPhotos,
    required this.isUploading,
    required this.isSaving,
    required this.onPickPhotos,
    required this.onMakeCover,
    required this.onRemovePhoto,
  });

  final List<String> photoUrls;
  final int maxPhotos;
  final bool isUploading;
  final bool isSaving;
  final VoidCallback onPickPhotos;
  final ValueChanged<int> onMakeCover;
  final ValueChanged<int> onRemovePhoto;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 10),
        InkWell(
          onTap: isUploading || isSaving ? null : onPickPhotos,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryContainer.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppTheme.primaryContainer.withValues(alpha: 0.12),
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerLowest,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.onSurface.withValues(alpha: 0.08),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.add_a_photo_outlined,
                    color: AppTheme.primaryContainer,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isUploading
                      ? 'Uploading photos…'
                      : 'Tap to select photos from gallery',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppTheme.primaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Room, study area and bathroom photos help students compare listings.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: AppTheme.onSurfaceVariant),
                ),
                const SizedBox(height: 4),
                Text(
                  'JPG, PNG or WebP · up to 10 MB each · max $maxPhotos',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall
                      ?.copyWith(color: AppTheme.onSurfaceVariant),
                ),
                if (isUploading) ...[
                  const SizedBox(height: 10),
                  const LinearProgressIndicator(minHeight: 2),
                ],
              ],
            ),
          ),
        ),
        if (photoUrls.isNotEmpty) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 116,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount:
                  photoUrls.length + (photoUrls.length < maxPhotos ? 1 : 0),
              separatorBuilder: (_, index) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                if (index == photoUrls.length) {
                  return AddMoreTile(
                    isDisabled: isUploading || isSaving,
                    onPickPhotos: onPickPhotos,
                  );
                }
                return PhotoTile(
                  url: photoUrls[index],
                  isCover: index == 0,
                  isSaving: isSaving,
                  onMakeCover: () => onMakeCover(index),
                  onRemove: () => onRemovePhoto(index),
                );
              },
            ),
          ),
        ] else ...[
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: isUploading || isSaving ? null : onPickPhotos,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add photos'),
          ),
        ],
      ],
    );
  }
}

class PhotoTile extends StatelessWidget {
  const PhotoTile({
    super.key,
    required this.url,
    required this.isCover,
    required this.isSaving,
    required this.onMakeCover,
    required this.onRemove,
  });

  final String url;
  final bool isCover;
  final bool isSaving;
  final VoidCallback onMakeCover;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 112,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: AppTheme.surfaceContainerHigh,
                alignment: Alignment.center,
                child: const Icon(Icons.broken_image_outlined),
              ),
            ),
          ),
          if (isCover)
            Positioned(
              left: 6,
              bottom: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Cover',
                  style: Theme.of(context).textTheme.labelSmall
                      ?.copyWith(color: AppTheme.onPrimary),
                ),
              ),
            )
          else
            Positioned(
              left: 4,
              bottom: 2,
              child: IconButton(
                tooltip: 'Set as cover photo',
                onPressed: isSaving ? null : onMakeCover,
                icon: const Icon(Icons.photo_outlined, size: 18),
                color: AppTheme.onPrimary,
              ),
            ),
          Positioned(
            top: 2,
            right: 2,
            child: IconButton.filledTonal(
              tooltip: 'Remove photo',
              onPressed: isSaving ? null : onRemove,
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.close_rounded, size: 17),
              style: IconButton.styleFrom(
                backgroundColor: AppTheme.onSurface.withValues(alpha: 0.72),
                foregroundColor: AppTheme.onPrimary,
                minimumSize: const Size(30, 30),
                padding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AddMoreTile extends StatelessWidget {
  const AddMoreTile({
    super.key,
    required this.isDisabled,
    required this.onPickPhotos,
  });

  final bool isDisabled;
  final VoidCallback onPickPhotos;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 112,
      child: OutlinedButton(
        onPressed: isDisabled ? null : onPickPhotos,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppTheme.surfaceContainerLow,
          side: BorderSide.none,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, color: AppTheme.primaryContainer),
            const SizedBox(height: 3),
            Text(
              'Add More',
              maxLines: 1,
              softWrap: false,
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(color: AppTheme.primaryContainer),
            ),
          ],
        ),
      ),
    );
  }
}
