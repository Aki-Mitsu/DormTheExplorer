import 'package:dorm_the_explorer/theme/app_theme.dart';
import 'package:material_ui/material_ui.dart';

class AuthPageHeader extends StatelessWidget {
  const AuthPageHeader({super.key, required this.title, this.onBack});

  final String title;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.92),
        boxShadow: [
          BoxShadow(
            color: AppTheme.onSurface.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Go back',
            onPressed: onBack ?? () => Navigator.maybePop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          ),
          const SizedBox(width: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(color: AppTheme.onSurface),
          ),
        ],
      ),
    );
  }
}

class AuthBrandHeader extends StatelessWidget {
  const AuthBrandHeader({
    super.key,
    required this.title,
    required this.description,
    this.logoSize = 112,
    this.compact = false,
    this.showPortalBadge = true,
  });

  final String title;
  final String description;
  final double logoSize;
  final bool compact;
  final bool showPortalBadge;

  static const _logoUrl =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuAieKrAEy0KUbnqu-VlFSVqoU6UsaYbMftDxU0Jt8LubR1GuPV7a2RIiFQw_Ob1G44yFWBoYwqsx795rw9IijtqUrScniNBzwxMXxgB-FHIs9GY3mCLpWtXBcM5LNdbqtRyKQdu2yTu7okHuKLG_LRS7blwYXof_L6arc02mFtCoLfsvxERQvwj3DSF-qk-Pu0d9Pso4RfXbSloy_Z4_5vcOrD2SmexEEMoPQFF4HeCKt4XfUOxYSpm';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        compact ? 12 : 20,
        16,
        compact ? 12 : 24,
      ),
      child: Column(
        children: [
          Container(
            width: logoSize + 16,
            height: logoSize + 16,
            padding: const EdgeInsets.all(8),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLow,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.onSurface.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Image.network(
              _logoUrl,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.home_work_outlined,
                color: AppTheme.primaryContainer,
                size: logoSize * 0.52,
              ),
            ),
          ),
          if (showPortalBadge) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.primaryFixed.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.onSurface.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.apartment_rounded,
                    size: 14,
                    color: AppTheme.onPrimaryFixedVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'SEEKER & LANDLORD PORTAL',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppTheme.onPrimaryFixedVariant,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
          SizedBox(height: compact ? 8 : 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style:
                (compact
                        ? Theme.of(context).textTheme.headlineMedium
                        : Theme.of(context).textTheme.headlineLarge)
                    ?.copyWith(color: AppTheme.onSurface),
          ),
          const SizedBox(height: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: Text(
              description,
              textAlign: TextAlign.center,
              style:
                  (compact
                          ? Theme.of(context).textTheme.bodySmall
                          : Theme.of(context).textTheme.bodyMedium)
                      ?.copyWith(color: AppTheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

class AuthFormCard extends StatelessWidget {
  const AuthFormCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.radius = 24,
    this.showShadow = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(radius),
        border: showShadow
            ? null
            : Border.all(color: AppTheme.divider.withValues(alpha: 0.35)),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: AppTheme.onSurface.withValues(alpha: 0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: child,
    );
  }
}

class AuthFieldLabel extends StatelessWidget {
  const AuthFieldLabel({super.key, required this.text, this.trailing});

  final String text;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          text,
          style: Theme.of(context).textTheme.labelMedium
              ?.copyWith(color: AppTheme.onSurfaceVariant),
        ),
        if (trailing != null)
          Text(
            trailing!,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppTheme.onSurfaceVariant.withValues(alpha: 0.7),
              fontWeight: FontWeight.w400,
            ),
          ),
      ],
    );
  }
}

InputDecoration authInputDecoration(
  BuildContext context, {
  required String hint,
  required IconData icon,
  Widget? suffixIcon,
}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: Theme.of(context).textTheme.bodyMedium
        ?.copyWith(color: AppTheme.onSurfaceVariant.withValues(alpha: 0.38)),
    prefixIcon: Icon(
      icon,
      color: AppTheme.onSurfaceVariant.withValues(alpha: 0.75),
      size: 20,
    ),
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: AppTheme.surfaceContainerLow,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppTheme.primaryContainer, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppTheme.error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppTheme.error, width: 2),
    ),
  );
}
