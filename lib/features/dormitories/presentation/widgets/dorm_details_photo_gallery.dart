import 'package:dorm_the_explorer/theme/app_theme.dart';
import 'package:material_ui/material_ui.dart';

class DormDetailsPhotoGallery extends StatelessWidget {
  const DormDetailsPhotoGallery({
    super.key,
    required this.photoUrls,
    required this.pageController,
    required this.photoIndex,
    required this.onPageChanged,
    required this.onOpenPhotoViewer,
  });

  final List<String> photoUrls;
  final PageController pageController;
  final int photoIndex;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onOpenPhotoViewer;

  @override
  Widget build(BuildContext context) {
    final count = photoUrls.isEmpty ? 3 : photoUrls.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Column(
        children: [
          GestureDetector(
            onTap: photoUrls.isEmpty ? null : onOpenPhotoViewer,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: AspectRatio(
                aspectRatio: 16 / 10,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    PageView.builder(
                      controller: pageController,
                      physics: const PageScrollPhysics(),
                      itemCount: count,
                      onPageChanged: onPageChanged,
                      itemBuilder: (context, index) {
                        if (photoUrls.isEmpty) {
                          return const _PhotoPlaceholder(label: 'Dorm photo');
                        }
                        return Image.network(
                          photoUrls[index],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stack) =>
                              const _PhotoPlaceholder(
                            label: 'Photo unavailable',
                          ),
                        );
                      },
                    ),
                    IgnorePointer(
                      child: DecoratedBox(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [Color(0x77000000), Colors.transparent],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: _Tag(label: '${photoIndex + 1} / $count'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 72,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: count,
              separatorBuilder: (_, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) => GestureDetector(
                onTap: () => pageController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                ),
                child: Container(
                  width: 96,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: photoIndex == index
                          ? AppTheme.primaryContainer
                          : Colors.transparent,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: AspectRatio(
                      aspectRatio: 16 / 10,
                      child: photoUrls.isEmpty
                          ? const _PhotoPlaceholder(
                              label: 'Placeholder',
                              compact: true,
                            )
                          : Image.network(
                              photoUrls[index],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stack) =>
                                  const _PhotoPlaceholder(
                                label: 'Photo',
                                compact: true,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder({required this.label, this.compact = false});

  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
    color: AppTheme.surfaceContainerHigh,
    alignment: Alignment.center,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.apartment_rounded,
          size: compact ? 23 : 58,
          color: AppTheme.outline,
        ),
        if (!compact) ...[
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: AppTheme.onSurfaceVariant),
          ),
        ],
      ],
    ),
  );
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: AppTheme.surfaceContainerLowest.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      label,
      style: Theme.of(
        context,
      ).textTheme.labelSmall?.copyWith(color: AppTheme.onSurface),
    ),
  );
}
