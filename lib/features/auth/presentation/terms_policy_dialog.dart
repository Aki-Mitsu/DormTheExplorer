import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// Shows the Terms and Conditions and Privacy Policy and returns true only
/// after the user reaches the end and explicitly accepts them.
Future<bool?> showTermsPolicyDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _TermsPolicyDialog(),
  );
}

class _TermsPolicyDialog extends StatefulWidget {
  const _TermsPolicyDialog();

  @override
  State<_TermsPolicyDialog> createState() => _TermsPolicyDialogState();
}

class _TermsPolicyDialogState extends State<_TermsPolicyDialog> {
  static const _assetPath =
      'UI-DORM-THE-EXPLORER/Dorm the Explorer — Terms and Conditions and Privacy Policy.md';

  final ScrollController _scrollController = ScrollController();
  String? _document;
  Object? _loadError;
  bool _hasReachedEnd = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateReachedEnd);
    _loadDocument();
  }

  Future<void> _loadDocument() async {
    try {
      final fullDocument = await rootBundle.loadString(_assetPath);
      final agreement = fullDocument.split('# Part 3: Short Texts for the App Screens').first;
      if (mounted) setState(() => _document = agreement);
    } catch (error) {
      if (mounted) setState(() => _loadError = error);
    }
  }

  void _updateReachedEnd() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    final reachedEnd =
        position.maxScrollExtent <= 0 ||
        position.pixels >= position.maxScrollExtent - 24;
    if (reachedEnd != _hasReachedEnd && mounted) {
      setState(() => _hasReachedEnd = reachedEnd);
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_updateReachedEnd)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 680,
          maxHeight: size.height * 0.88,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      'Terms and Conditions\nand Privacy Policy',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Cancel',
                    onPressed: () => Navigator.of(context).pop(false),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Expanded(child: _buildDocument(context)),
              const SizedBox(height: 8),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final cancelButton = OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    );
                    final acceptButton = FilledButton(
                      onPressed: _hasReachedEnd
                          ? () => Navigator.of(context).pop(true)
                          : null,
                      child: const Text('Accept'),
                    );
                    if (constraints.maxWidth < 360) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          acceptButton,
                          const SizedBox(height: 8),
                          cancelButton,
                        ],
                      );
                    }
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        cancelButton,
                        const SizedBox(width: 12),
                        acceptButton,
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDocument(BuildContext context) {
    if (_loadError != null) {
      return Center(
        child: Text(
          'Could not load the Terms and Privacy Policy. Close this dialog and try again.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }
    final document = _document;
    if (document == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return NotificationListener<ScrollMetricsNotification>(
      onNotification: (notification) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _updateReachedEnd();
        });
        return false;
      },
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(4, 8, 12, 16),
        child: _MarkdownAgreement(document: document),
      ),
    );
  }
}

class _MarkdownAgreement extends StatelessWidget {
  const _MarkdownAgreement({required this.document});

  final String document;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final blocks = <Widget>[];

    for (final rawLine in document.split('\n')) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;

      if (line.startsWith('# ')) {
        blocks.add(
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 6),
            child: Text(
              _plainText(line.substring(2)),
              style: theme.textTheme.headlineSmall,
            ),
          ),
        );
      } else if (line.startsWith('## ')) {
        blocks.add(
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 4),
            child: Text(
              _plainText(line.substring(3)),
              style: theme.textTheme.titleMedium,
            ),
          ),
        );
      } else if (line.startsWith('- ')) {
        blocks.add(
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('•  '),
                Expanded(
                  child: Text(
                    _plainText(line.substring(2)),
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        blocks.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              _plainText(line),
              style: theme.textTheme.bodyMedium,
            ),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: blocks,
    );
  }

  String _plainText(String value) =>
      value.replaceAll('**', '').replaceAll('\\[', '[').replaceAll('\\]', ']');
}
