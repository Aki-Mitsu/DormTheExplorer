import 'dart:async';

import 'package:dorm_the_explorer/theme/app_theme.dart';
import 'package:material_ui/material_ui.dart';

/// Shows a brief, branded notice without presenting a snackbar.
class AppNotice {
  AppNotice._();

  static OverlayEntry? _activeEntry;

  static void show(BuildContext context, String message) {
    final previousEntry = _activeEntry;
    _activeEntry = null;
    if (previousEntry?.mounted ?? false) previousEntry!.remove();

    final overlay = Overlay.of(context);
    final kind = _kindFor(message);
    final (background, foreground, icon) = switch (kind) {
      _NoticeKind.success => (
        AppTheme.secondaryContainer,
        AppTheme.onSecondaryContainer,
        Icons.check_circle_outline_rounded,
      ),
      _NoticeKind.error => (
        AppTheme.errorContainer,
        AppTheme.onErrorContainer,
        Icons.error_outline_rounded,
      ),
      _NoticeKind.info => (
        AppTheme.primaryFixed,
        AppTheme.onPrimaryFixed,
        Icons.info_outline_rounded,
      ),
    };

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (overlayContext) {
        final width = MediaQuery.sizeOf(overlayContext).width;
        return SafeArea(
          bottom: false,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: width - 32, minWidth: 0),
              child: _AnimatedAppNotice(
                message: message,
                background: background,
                foreground: foreground,
                icon: icon,
                onDismissed: () => _remove(entry),
              ),
            ),
          ),
        );
      },
    );

    _activeEntry = entry;
    overlay.insert(entry);
  }

  static void _remove(OverlayEntry entry) {
    if (!identical(_activeEntry, entry)) return;
    _activeEntry = null;
    if (entry.mounted) entry.remove();
  }

  static _NoticeKind _kindFor(String message) {
    final text = message.toLowerCase();
    if (text.contains('success') ||
        text.contains('sent.') ||
        text.contains('updated.') ||
        text.contains('deleted.') ||
        text.contains('added.') ||
        text.contains('submitted.') ||
        text.contains('verified.')) {
      return _NoticeKind.success;
    }
    if (text.contains('could not') ||
        text.contains('unable') ||
        text.contains('failed') ||
        text.contains('must be') ||
        text.contains('enter ') ||
        text.contains('add at least') ||
        text.contains('already ') ||
        text.contains('expired') ||
        text.contains('wait for') ||
        text.contains('try again') ||
        text.contains('too many') ||
        text.contains('check your internet') ||
        text.contains('not enabled') ||
        text.contains('not verified') ||
        text.contains('disabled') ||
        text.contains('incorrect') ||
        text.contains('before signing') ||
        text.contains('before posting')) {
      return _NoticeKind.error;
    }
    return _NoticeKind.info;
  }
}

class _AnimatedAppNotice extends StatefulWidget {
  const _AnimatedAppNotice({
    required this.message,
    required this.background,
    required this.foreground,
    required this.icon,
    required this.onDismissed,
  });

  final String message;
  final Color background;
  final Color foreground;
  final IconData icon;
  final VoidCallback onDismissed;

  @override
  State<_AnimatedAppNotice> createState() => _AnimatedAppNoticeState();
}

class _AnimatedAppNoticeState extends State<_AnimatedAppNotice>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final CurvedAnimation _scale;
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
    _scale = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInBack,
    );
    _controller.forward();
    _dismissTimer = Timer(const Duration(seconds: 4), _dismiss);
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
    _scale.dispose();
    _controller
      ..removeStatusListener(_handleAnimationStatus)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ScaleTransition(
    scale: _scale,
    alignment: Alignment.topCenter,
    child: FadeTransition(
      opacity: _controller,
      child: Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
        decoration: BoxDecoration(
          color: widget.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: widget.foreground.withValues(alpha: 0.14)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x18000000),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(widget.icon, color: widget.foreground, size: 22),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                widget.message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: widget.foreground,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Dismiss',
              visualDensity: VisualDensity.compact,
              onPressed: _dismiss,
              icon: Icon(
                Icons.close_rounded,
                color: widget.foreground,
                size: 19,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

enum _NoticeKind { success, error, info }
