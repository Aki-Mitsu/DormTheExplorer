import 'package:material_ui/material_ui.dart';

import '../../../theme/app_theme.dart';
import '../data/dormitory_repository.dart';
import '../domain/dormitory.dart';
import 'dorm_dashboard_view_model.dart';
import 'dorm_details_screen.dart';

class DormDashboardScreen extends StatefulWidget {
  const DormDashboardScreen({
    super.key,
    required this.accountRole,
    required this.userId,
  });

  final String accountRole;
  final String userId;

  @override
  State<DormDashboardScreen> createState() => _DormDashboardScreenState();
}

class _DormDashboardScreenState extends State<DormDashboardScreen> {
  late final DormDashboardViewModel _viewModel;
  int _selectedDestination = 0;

  bool get _isLandlord => widget.accountRole == 'landlord';

  @override
  void initState() {
    super.initState();
    _viewModel = DormDashboardViewModel(
      repository: DormitoryRepository(),
      accountRole: widget.accountRole,
      userId: widget.userId,
    )..addListener(_handleViewModelChanged);
  }

  void _handleViewModelChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _viewModel
      ..removeListener(_handleViewModelChanged)
      ..dispose();
    super.dispose();
  }

  void _selectDestination(int index) {
    setState(() => _selectedDestination = index);
    if (_isLandlord) {
      if (index == 1) _showComingSoon();
      if (index == 2) _showProfilePlaceholder();
      return;
    }

    if (index == 0) {
      _viewModel.showAllDormitories();
    } else if (index == 1) {
      _viewModel.toggleFavoritesOnly();
    } else {
      _showProfilePlaceholder();
    }
  }

  void _showComingSoon() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('The Add Dormitory form is coming soon.')),
      );
  }

  void _showProfilePlaceholder() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Profile', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                _isLandlord ? 'Landlord account' : 'Seeker account',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Profile settings will be available soon.',
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: AppTheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _DashboardHeader(isLandlord: _isLandlord),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final contentWidth = constraints.maxWidth > 1032
                      ? 1000.0
                      : constraints.maxWidth - 32;

                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: SizedBox(
                        width: contentWidth,
                        child: _isLandlord
                            ? _buildLandlordContent()
                            : _buildSeekerContent(contentWidth),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _isLandlord
          ? _LandlordNavigationBar(
              selectedIndex: _selectedDestination,
              onSelected: _selectDestination,
            )
          : _SeekerNavigationBar(
              selectedIndex: _selectedDestination,
              onSelected: _selectDestination,
            ),
    );
  }

  Widget _buildSeekerContent(double availableWidth) {
    final dormitories = _viewModel.visibleDormitories;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Find your next dorm',
          style: Theme.of(context).textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.3),
        ),
        const SizedBox(height: 4),
        Text(
          'Browse student accommodations across Batangas City',
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: AppTheme.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 48,
                child: TextField(
                  onChanged: _viewModel.updateSearch,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search dormitories in Batangas City...',
                    hintStyle: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: AppTheme.outline),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppTheme.outline,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    filled: true,
                    fillColor: AppTheme.surfaceContainerLowest,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: AppTheme.primaryContainer,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 48,
              child: FilledButton.icon(
                onPressed: _showComingSoon,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(94, 48),
                  backgroundColor: AppTheme.primaryContainer,
                  foregroundColor: AppTheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                ),
                icon: const Icon(Icons.tune_rounded, size: 18),
                label: const Text('Filters'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _viewModel.showFavoritesOnly
                        ? 'Your Favorites'
                        : 'Dormitories in Batangas City',
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _viewModel.showFavoritesOnly
                        ? '${dormitories.length} saved dormitories'
                        : 'Showing ${dormitories.length} verified dorms available for rent',
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: AppTheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildDormitoryResults(
          dormitories: dormitories,
          availableWidth: availableWidth,
          isLandlord: false,
        ),
      ],
    );
  }

  Widget _buildLandlordContent() {
    final dormitories = _viewModel.visibleDormitories;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'My Dormitories',
          style: Theme.of(context).textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          'Manage your dorm listings in Batangas City',
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: AppTheme.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        _AddDormitoryPlaceholder(onPressed: _showComingSoon),
        const SizedBox(height: 24),
        Text(
          'Your Listings',
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        _buildDormitoryResults(
          dormitories: dormitories,
          availableWidth: MediaQuery.sizeOf(context).width,
          isLandlord: true,
        ),
      ],
    );
  }

  Widget _buildDormitoryResults({
    required List<Dormitory> dormitories,
    required double availableWidth,
    required bool isLandlord,
  }) {
    if (_viewModel.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_viewModel.error != null) {
      return _DashboardMessage(
        icon: Icons.cloud_off_outlined,
        title: 'Could not load dormitories',
        message: 'Check your connection and Firestore access, then try again.',
        actionLabel: 'Try again',
        onAction: _viewModel.retry,
      );
    }

    if (dormitories.isEmpty) {
      if (!isLandlord && !_viewModel.showFavoritesOnly) {
        return const SizedBox.shrink();
      }

      return _DashboardMessage(
        icon: isLandlord ? Icons.apartment_outlined : Icons.search_off_rounded,
        title: isLandlord
            ? 'No dormitories added yet'
            : 'No favorites saved yet',
        message: isLandlord
            ? 'Your listings will appear here after the Add Dormitory form is ready.'
            : 'Tap the heart on a dormitory to save it here.',
        actionLabel: isLandlord ? 'Add Dormitory' : null,
        onAction: isLandlord ? _showComingSoon : null,
      );
    }

    final maxCardWidth = availableWidth < 600 ? 220.0 : 260.0;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: dormitories.length,
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: maxCardWidth,
        mainAxisExtent: 250,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (context, index) {
        final dormitory = dormitories[index];
        return _DormitoryCard(
          dormitory: dormitory,
          isLandlord: isLandlord,
          isFavorite: _viewModel.isFavorite(dormitory.id),
          onFavorite: () => _viewModel.toggleFavorite(dormitory.id),
          onTap: () => _showDormitoryDetails(dormitory),
        );
      },
    );
  }

  void _showDormitoryDetails(Dormitory dormitory) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => DormDetailsScreen(
          dormitory: dormitory,
          canEditLocation: _isLandlord,
          canReview: !_isLandlord,
        ),
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({required this.isLandlord});

  final bool isLandlord;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest.withValues(alpha: 0.96),
        boxShadow: [
          BoxShadow(
            color: AppTheme.onSurface.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.apartment_rounded,
              color: AppTheme.onPrimary,
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'DormTheExplorer',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.primaryContainer,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
          if (isLandlord)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.primaryFixed,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'LANDLORD',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppTheme.primaryDeep,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AddDormitoryPlaceholder extends StatelessWidget {
  const _AddDormitoryPlaceholder({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppTheme.outlineVariant.withValues(alpha: 0.6),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.onSurface.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.primaryFixed,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.add_home_work_outlined,
              color: AppTheme.primaryDeep,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add a dormitory',
                  style: Theme.of(context).textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  'Dorm details will be saved in Firestore. Photos will use Firebase Storage.',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: AppTheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: onPressed,
            tooltip: 'Add Dormitory form coming soon',
            icon: const Icon(Icons.add_rounded),
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.primaryContainer,
              foregroundColor: AppTheme.onPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _DormitoryCard extends StatelessWidget {
  const _DormitoryCard({
    required this.dormitory,
    required this.isLandlord,
    required this.isFavorite,
    required this.onFavorite,
    required this.onTap,
  });

  final Dormitory dormitory;
  final bool isLandlord;
  final bool isFavorite;
  final VoidCallback onFavorite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final coverUrl = dormitory.photoUrls.isEmpty
        ? null
        : dormitory.photoUrls.first;

    return Material(
      color: AppTheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                SizedBox(
                  height: 128,
                  width: double.infinity,
                  child: coverUrl == null
                      ? const _DormitoryPhotoPlaceholder()
                      : Image.network(
                          coverUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const _DormitoryPhotoPlaceholder(),
                        ),
                ),
                if (!isLandlord)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Material(
                      color: AppTheme.surfaceContainerLowest.withValues(
                        alpha: 0.92,
                      ),
                      shape: const CircleBorder(),
                      child: IconButton(
                        onPressed: onFavorite,
                        tooltip: isFavorite
                            ? 'Remove from favorites'
                            : 'Add to favorites',
                        visualDensity: VisualDensity.compact,
                        constraints: const BoxConstraints.tightFor(
                          width: 34,
                          height: 34,
                        ),
                        icon: Icon(
                          isFavorite
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          size: 18,
                          color: isFavorite
                              ? AppTheme.primaryContainer
                              : AppTheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  left: 8,
                  bottom: 8,
                  child: _DormitoryBadge(
                    text: isLandlord
                        ? dormitory.status.toUpperCase()
                        : dormitory.availableSlots <= 0
                        ? 'FULL'
                        : dormitory.availableSlots == 1
                        ? '1 slot left'
                        : '${dormitory.availableSlots} slots left',
                    color: isLandlord
                        ? _statusColor(dormitory.status)
                        : dormitory.availableSlots <= 0
                        ? AppTheme.error
                        : dormitory.availableSlots == 1
                        ? AppTheme.tertiaryContainer
                        : AppTheme.secondary,
                  ),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (dormitory.proximityLabel?.isNotEmpty ?? false)
                      Row(
                        children: [
                          const Icon(
                            Icons.near_me_rounded,
                            color: AppTheme.primaryContainer,
                            size: 13,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              dormitory.proximityLabel!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: AppTheme.primaryContainer,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    Text(
                      dormitory.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.onSurface,
                      ),
                    ),
                    Text(
                      dormitory.address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    const Divider(height: 10, thickness: 0.7),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: RichText(
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            text: TextSpan(
                              style: Theme.of(context).textTheme.titleSmall,
                              children: [
                                TextSpan(
                                  text: _formatPrice(dormitory.monthlyPrice),
                                  style: const TextStyle(
                                    color: AppTheme.primaryContainer,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                TextSpan(
                                  text: '/mo',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: AppTheme.onSurfaceVariant,
                                        fontSize: 10,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (dormitory.averageRating != null) ...[
                          const Icon(
                            Icons.star_rounded,
                            color: AppTheme.tertiaryContainer,
                            size: 14,
                          ),
                          Text(
                            dormitory.averageRating!.toStringAsFixed(1),
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: AppTheme.tertiaryContainer,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) => switch (status.toLowerCase()) {
    'approved' || 'active' => AppTheme.secondary,
    'rejected' => AppTheme.error,
    _ => AppTheme.tertiaryContainer,
  };
}

class _DormitoryPhotoPlaceholder extends StatelessWidget {
  const _DormitoryPhotoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.surfaceContainer,
      alignment: Alignment.center,
      child: Icon(
        Icons.apartment_rounded,
        size: 38,
        color: AppTheme.outline.withValues(alpha: 0.72),
      ),
    );
  }
}

class _DormitoryBadge extends StatelessWidget {
  const _DormitoryBadge({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _DashboardMessage extends StatelessWidget {
  const _DashboardMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 38, color: AppTheme.primaryContainer),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: AppTheme.onSurfaceVariant),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

class _SeekerNavigationBar extends StatelessWidget {
  const _SeekerNavigationBar({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return _DashboardNavigationBarShell(
      selectedIndex: selectedIndex,
      onSelected: onSelected,
      destinations: const [
        (Icons.home_outlined, 'Home'),
        (Icons.favorite_border_rounded, 'Favorites'),
        (Icons.person_outline_rounded, 'Profile'),
      ],
    );
  }
}

class _LandlordNavigationBar extends StatelessWidget {
  const _LandlordNavigationBar({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return _DashboardNavigationBarShell(
      selectedIndex: selectedIndex,
      onSelected: onSelected,
      destinations: const [
        (Icons.apartment_outlined, 'My Listings'),
        (Icons.add_home_work_outlined, 'Add Dorm'),
        (Icons.person_outline_rounded, 'Profile'),
      ],
    );
  }
}

class _DashboardNavigationBarShell extends StatelessWidget {
  const _DashboardNavigationBarShell({
    required this.selectedIndex,
    required this.onSelected,
    required this.destinations,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final List<(IconData, String)> destinations;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLowest.withValues(alpha: 0.97),
          boxShadow: [
            BoxShadow(
              color: AppTheme.onSurface.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            for (var index = 0; index < destinations.length; index++)
              Expanded(
                child: InkWell(
                  onTap: () => onSelected(index),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        destinations[index].$1,
                        size: 23,
                        color: selectedIndex == index
                            ? AppTheme.primaryContainer
                            : AppTheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        destinations[index].$2,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: selectedIndex == index
                              ? AppTheme.primaryContainer
                              : AppTheme.onSurfaceVariant,
                          fontWeight: selectedIndex == index
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

String _formatPrice(num price) {
  final roundedPrice = price.round().toString();
  final groupedPrice = roundedPrice.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  return '₱$groupedPrice';
}
