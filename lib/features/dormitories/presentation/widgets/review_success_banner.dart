import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../../../theme/app_theme.dart';

class ReviewSuccessBanner extends StatefulWidget {
  const ReviewSuccessBanner({
    super.key,
    required this.message,
    required this.onDismissed,
  });

  final String message;
  final VoidCallback onDismissed;

  @override
  State<ReviewSuccessBanner> createState() => _ReviewSuccessBannerState();
}

class _ReviewSuccessBannerState extends State<ReviewSuccessBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _dismissTimer;
  bool _didDismiss = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
      reverseDuration: const Duration(milliseconds: 200),
    )..addStatusListener(_handleAnimationStatus);
    _controller.forward();
    _dismissTimer = Timer(const Duration(seconds: 3), _dismiss);
  }

  void _handleAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.dismissed && !_didDismiss) {
      _didDismiss = true;
      widget.onDismissed();
    }
  }

  void _dismiss() {
    _dismissTimer?.cancel();
    if (_controller.status != AnimationStatus.reverse &&
        _controller.status != AnimationStatus.dismissed) {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller
      ..removeStatusListener(_handleAnimationStatus)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInBack,
    );

    return ScaleTransition(
      scale: scale,
      alignment: Alignment.topCenter,
      child: FadeTransition(
        opacity: _controller,
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
          decoration: BoxDecoration(
            color: AppTheme.secondaryContainer,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.check_circle_outline_rounded,
                color: AppTheme.onSecondaryContainer,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.onSecondaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Dismiss',
                visualDensity: VisualDensity.compact,
                onPressed: _dismiss,
                icon: const Icon(
                  Icons.close_rounded,
                  color: AppTheme.onSecondaryContainer,
                  size: 19,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
