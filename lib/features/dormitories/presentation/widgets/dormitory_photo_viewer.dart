import 'package:material_ui/material_ui.dart';

/// Opens the listing photos in a full-screen, swipeable viewer.
Future<void> showDormitoryPhotoViewer(
  BuildContext context, {
  required List<String> photoUrls,
  required int initialIndex,
}) {
  if (photoUrls.isEmpty) return Future<void>.value();

  return Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => DormitoryPhotoViewerPage(
        photoUrls: photoUrls,
        initialIndex: initialIndex,
      ),
    ),
  );
}

class DormitoryPhotoViewerPage extends StatefulWidget {
  const DormitoryPhotoViewerPage({
    super.key,
    required this.photoUrls,
    required this.initialIndex,
  });

  final List<String> photoUrls;
  final int initialIndex;

  @override
  State<DormitoryPhotoViewerPage> createState() =>
      _DormitoryPhotoViewerPageState();
}

class _DormitoryPhotoViewerPageState extends State<DormitoryPhotoViewerPage> {
  late final PageController _pageController = PageController(
    initialPage: widget.initialIndex,
  );
  late int _currentIndex = widget.initialIndex;
  bool _zoomed = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              physics: const PageScrollPhysics(),
              itemCount: widget.photoUrls.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                  _zoomed = false;
                });
              },
              itemBuilder: (context, index) => SizedBox.expand(
                child: GestureDetector(
                  onDoubleTap: () => setState(() => _zoomed = !_zoomed),
                  child: Center(
                    child: ClipRect(
                      child: SizedBox.expand(
                        child: AnimatedScale(
                          scale: _zoomed ? 2 : 1,
                          duration: const Duration(milliseconds: 180),
                          child: Image.network(
                            widget.photoUrls[index],
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                                  Icons.broken_image_outlined,
                                  color: Colors.white70,
                                  size: 48,
                                ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              left: 8,
              child: IconButton(
                tooltip: 'Close photo viewer',
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black54,
                ),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${_currentIndex + 1} / ${widget.photoUrls.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Text(
                  'Swipe to browse • Double-tap to zoom',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
