import 'package:material_ui/material_ui.dart';

import '../../../../../theme/app_theme.dart';

class LandlordPhotoGallery extends StatelessWidget {
  const LandlordPhotoGallery({
    super.key,
    required this.photoUrls,
    required this.photoController,
    required this.selectedPhoto,
    required this.onPageChanged,
    required this.onOpenPhotoViewer,
  });

  final List<String> photoUrls;
  final PageController photoController;
  final int selectedPhoto;
  final ValueChanged<int> onPageChanged;
  final VoidCallback? onOpenPhotoViewer;

  @override
  Widget build(BuildContext context) {
    final photos = photoUrls;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.onSurface.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: photos.isEmpty ? null : onOpenPhotoViewer,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 16 / 10,
                child: photos.isEmpty
                    ? Container(
                        color: AppTheme.surfaceContainer,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.apartment_rounded,
                          size: 48,
                          color: AppTheme.outline,
                        ),
                      )
                    : Stack(
                        fit: StackFit.expand,
                        children: [
                          PageView.builder(
                            controller: photoController,
                            physics: const PageScrollPhysics(),
                            itemCount: photos.length,
                            onPageChanged: onPageChanged,
                            itemBuilder: (context, index) => Image.network(
                              photos[index],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    color: AppTheme.surfaceContainer,
                                    alignment: Alignment.center,
                                    child: const Icon(
                                      Icons.broken_image_outlined,
                                      size: 38,
                                      color: AppTheme.outline,
                                    ),
                                  ),
                            ),
                          ),
                          Positioned(
                            right: 10,
                            bottom: 10,
                            child: IgnorePointer(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.inverseSurface.withValues(
                                    alpha: 0.82,
                                  ),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  '${selectedPhoto + 1} / ${photos.length} Photos',
                                  style: Theme.of(context).textTheme.labelMedium
                                      ?.copyWith(
                                        color: AppTheme.surfaceContainerLowest,
                                      ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
          if (photos.length > 1) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: photos.length,
                separatorBuilder: (_, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) => InkWell(
                  onTap: () {
                    photoController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOut,
                    );
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 96,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: selectedPhoto == index
                            ? AppTheme.primaryContainer
                            : Colors.transparent,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: Image.network(
                        photos[index],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: AppTheme.surfaceContainer,
                          alignment: Alignment.center,
                          child: const Icon(Icons.broken_image_outlined),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
