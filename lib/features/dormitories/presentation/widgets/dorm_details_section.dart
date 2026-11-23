import 'package:material_ui/material_ui.dart';

class DormDetailsSection extends StatelessWidget {
  const DormDetailsSection(
    this.title,
    this.child, {
    super.key,
    this.trailing,
    this.titleAccessory,
  });

  final String title;
  final Widget child;
  final Widget? trailing;
  final Widget? titleAccessory;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  if (titleAccessory != null) ...[
                    const SizedBox(width: 6),
                    titleAccessory!,
                  ],
                ],
              ),
            ),
            ?trailing,
          ],
        ),
        const SizedBox(height: 10),
        child,
      ],
    ),
  );
}
