import 'package:material_ui/material_ui.dart';

import '../../../app_notice.dart';
import '../../../core/formatters.dart';
import '../../../theme/app_theme.dart';
import '../data/dormitory_repository.dart';
import '../domain/dormitory.dart';
import '../domain/dormitory_search_filters.dart';
import 'dorm_dashboard_view_model.dart';
import 'add_dormitory_screen.dart';
import 'dorm_details_screen.dart';
import 'landlord_dormitory_details_screen.dart';
import 'search_filters_screen.dart';
import 'profile_dashboard_screen.dart';
import 'widgets/dashboard/dashboard_header.dart';
import 'widgets/dashboard/dashboard_navigation_bars.dart';
import 'widgets/dashboard/dormitory_card.dart';

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
  late final TextEditingController _searchController;

  bool get _isLandlord => widget.accountRole == 'landlord';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
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
    _searchController.dispose();
    super.dispose();
  }

  void _selectDestination(int index) {
    setState(() => _selectedDestination = index);
    if (_isLandlord) {
      _viewModel.showLandlordListings(index == 1);
      return;
    }

    if (index == 0) {
      _viewModel.showAllDormitories();
    } else if (index == 1) {
      _viewModel.toggleFavoritesOnly();
    }
  }

  Future<void> _openAddDormitory({Dormitory? existingDormitory}) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => AddDormitoryScreen(
          userId: widget.userId,
          existingDormitory: existingDormitory,
        ),
      ),
    );
    if (!mounted || saved != true) return;
    AppNotice.show(
      context,
      existingDormitory == null
          ? 'Dormitory listing added.'
          : 'Dormitory listing updated.',
    );
  }

  Future<void> _setListingAvailability(
    Dormitory dormitory,
    bool isAvailable,
  ) async {
    try {
      await _viewModel.repository.setAvailability(
        dormitoryId: dormitory.id,
        landlordId: widget.userId,
        availableSlots: isAvailable ? dormitory.totalSlots : 0,
      );
    } catch (error) {
      if (!mounted) return;
      AppNotice.show(context, 'Could not update availability: $error');
    }
  }

  Future<void> _deleteListing(Dormitory dormitory) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.delete_forever_rounded),
        iconColor: AppTheme.error,
        iconPadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
        title: const Text('Delete Dormitory Listing?'),
        titlePadding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
        content: Text(
          'Are you sure you want to delete "${dormitory.name}"? This action cannot be undone.',
        ),
        contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  style: TextButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    backgroundColor: AppTheme.error,
                    foregroundColor: AppTheme.onError,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Delete'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _viewModel.repository.deleteDormitory(
        dormitoryId: dormitory.id,
        landlordId: widget.userId,
      );
      if (!mounted) return;
      AppNotice.show(context, 'Dorm deleted.');
    } catch (error) {
      if (!mounted) return;
      AppNotice.show(context, 'Could not delete listing: $error');
    }
  }

  Future<void> _openSearchFilters() async {
    final filters = await Navigator.of(context).push<DormitorySearchFilters>(
      MaterialPageRoute<DormitorySearchFilters>(
        builder: (_) => SearchFiltersScreen(
          initialFilters: _viewModel.searchFilters,
          initialQuery: _viewModel.searchQuery,
        ),
      ),
    );
    if (!mounted || filters == null) return;

    _searchController.value = TextEditingValue(
      text: filters.query,
      selection: TextSelection.collapsed(offset: filters.query.length),
    );
    _viewModel.applySearchFilters(filters);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            if (_selectedDestination != 2)
              DashboardHeader(
                isLandlord: _isLandlord && _selectedDestination == 1,
              ),
            Expanded(
              child: _selectedDestination == 2
                  ? ProfileDashboardScreen(
                      userId: widget.userId,
                      accountRole: widget.accountRole,
                    )
                  : LayoutBuilder(
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
                              child: _isLandlord && _selectedDestination == 1
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
          ? LandlordNavigationBar(
              selectedIndex: _selectedDestination,
              onSelected: _selectDestination,
            )
          : SeekerNavigationBar(
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
          _isLandlord ? 'Explore Dormitories' : 'Find your next dorm',
          style: Theme.of(context).textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.3),
        ),
        const SizedBox(height: 4),
        Text(
          _isLandlord
              ? 'Browse available student accommodations across Batangas City'
              : 'Browse student accommodations across Batangas City',
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
                  controller: _searchController,
                  onChanged: _viewModel.updateSearch,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search dormitories',
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
                onPressed: _openSearchFilters,
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
                        : 'Showing ${dormitories.length} approved dorms available for rent',
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
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppTheme.onSurface.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'My Listings',
                style: Theme.of(context).textTheme.headlineMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                'Manage your posted dormitories and room availability',
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: AppTheme.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _openAddDormitory,
                icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                label: const Text('+ Add Dormitory'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${dormitories.length} Dormitories Posted',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppTheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (dormitories.isNotEmpty)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      size: 16,
                      color: AppTheme.primaryContainer,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Batangas City',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppTheme.primaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
            ],
          ),
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
      return DashboardMessage(
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

      return DashboardMessage(
        icon: isLandlord ? Icons.apartment_outlined : Icons.search_off_rounded,
        title: isLandlord
            ? 'No dormitories added yet'
            : 'No favorites saved yet',
        message: isLandlord
            ? 'Your submitted listings will appear here.'
            : 'Tap the heart on a dormitory to save it here.',
      );
    }

    if (isLandlord) {
      return Column(
        children: [
          for (var index = 0; index < dormitories.length; index++) ...[
            if (index > 0) const SizedBox(height: 16),
            _LandlordListingCard(
              key: ValueKey(dormitories[index].id),
              dormitory: dormitories[index],
              onAvailabilityChanged: (value) =>
                  _setListingAvailability(dormitories[index], value),
              onTap: () =>
                  _showDormitoryDetails(dormitories[index], isOwnListing: true),
              onEdit: () => _openAddDormitory(
                existingDormitory: dormitories[index],
              ),
              onDelete: () => _deleteListing(dormitories[index]),
            ),
          ],
        ],
      );
    }

    final useSingleColumn = availableWidth < 320;
    final maxCardWidth = useSingleColumn
        ? availableWidth
        : availableWidth < 600
        ? 220.0
        : 340.0;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: dormitories.length,
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: maxCardWidth,
        mainAxisExtent: useSingleColumn ? 260 : 235,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (context, index) {
        final dormitory = dormitories[index];
        return DormitoryCard(
          dormitory: dormitory,
          isLandlord: false,
          showFavorite: !_isLandlord,
          isFavorite: _viewModel.isFavorite(dormitory.id),
          onFavorite: () => _viewModel.toggleFavorite(dormitory.id),
          onTap: () => _showDormitoryDetails(
            dormitory,
            isOwnListing: _isLandlord && dormitory.landlordId == widget.userId,
          ),
        );
      },
    );
  }

  Future<void> _showDormitoryDetails(
    Dormitory dormitory, {
    required bool isOwnListing,
  }) async {
    final wasDeleted = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) => _isLandlord && isOwnListing
            ? LandlordDormitoryDetailsScreen(
                dormitory: dormitory,
                userId: widget.userId,
              )
            : DormDetailsScreen(
                dormitory: dormitory,
                canReview: !_isLandlord,
                canBookmark: !_isLandlord,
                canReport: !_isLandlord,
                isFavorite: _viewModel.isFavorite(dormitory.id),
                onFavoriteChanged: (isFavorite) =>
                    _viewModel.setFavorite(dormitory.id, isFavorite),
              ),
      ),
    );

    if (!mounted || wasDeleted != true) return;
    AppNotice.show(context, 'Dorm deleted.');
  }
}

class _LandlordListingCard extends StatefulWidget {
  const _LandlordListingCard({
    super.key,
    required this.dormitory,
    required this.onAvailabilityChanged,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final Dormitory dormitory;
  final Future<void> Function(bool isAvailable) onAvailabilityChanged;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  State<_LandlordListingCard> createState() => _LandlordListingCardState();
}

class _LandlordListingCardState extends State<_LandlordListingCard> {
  bool _isUpdatingAvailability = false;

  Future<void> _toggleAvailability(bool value) async {
    setState(() => _isUpdatingAvailability = true);
    try {
      await widget.onAvailabilityChanged(value);
    } finally {
      if (mounted) setState(() => _isUpdatingAvailability = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dormitory = widget.dormitory;
    final isAvailable = dormitory.availableSlots > 0;
    final photoUrl = dormitory.photoUrls.isEmpty
        ? null
        : dormitory.photoUrls.first;
    final availabilityLabel = isAvailable ? 'Active' : 'Full';
    final status = dormitory.status.toLowerCase() == 'approved'
        ? availabilityLabel
        : '${dormitory.status} • $availabilityLabel';

    return Material(
      color: AppTheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      elevation: 1,
      child: InkWell(
        onTap: widget.onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 176,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (photoUrl == null)
                    Container(
                      color: AppTheme.surfaceContainer,
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.apartment_rounded,
                        size: 42,
                        color: AppTheme.outline,
                      ),
                    )
                  else
                    Image.network(
                      photoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: AppTheme.surfaceContainer,
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.broken_image_outlined,
                          size: 38,
                          color: AppTheme.outline,
                        ),
                      ),
                    ),
                  if (dormitory.proximityLabel?.isNotEmpty ?? false)
                    Positioned(
                      left: 12,
                      top: 12,
                      child: LandlordStatusChip(
                        icon: Icons.school_outlined,
                        label: dormitory.proximityLabel!,
                        foreground: AppTheme.primaryContainer,
                      ),
                    ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: LandlordStatusChip(
                      icon: !isAvailable ? Icons.cancel_outlined : Icons.circle,
                      label: status,
                      foreground: !isAvailable
                          ? AppTheme.error
                          : dormitory.status.toLowerCase() == 'approved'
                          ? AppTheme.secondary
                          : AppTheme.tertiaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    dormitory.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700, height: 1.2),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: AppTheme.outline,
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          dormitory.address,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppTheme.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'MONTHLY RENT',
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: AppTheme.onSurfaceVariant,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: formatPeso(
                                        dormitory.monthlyPrice,
                                      ),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            color: AppTheme.primaryContainer,
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                    TextSpan(
                                      text: '/mo',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: AppTheme.onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'SLOTS',
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: AppTheme.onSurfaceVariant,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${dormitory.availableSlots} Available / '
                                '${dormitory.totalSlots} Total Slots',
                                maxLines: 2,
                                textAlign: TextAlign.end,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: isAvailable
                                          ? AppTheme.secondary
                                          : AppTheme.error,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceBright,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isAvailable
                              ? Icons.check_circle_outline_rounded
                              : Icons.cancel_outlined,
                          size: 18,
                          color: isAvailable
                              ? AppTheme.secondary
                              : AppTheme.outline,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isAvailable ? 'Available' : 'Full',
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: isAvailable
                                      ? AppTheme.onSurface
                                      : AppTheme.onSurfaceVariant,
                                ),
                          ),
                        ),
                        if (_isUpdatingAvailability)
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          Switch(
                            value: isAvailable,
                            onChanged: _toggleAvailability,
                            activeThumbColor: AppTheme.surfaceContainerLowest,
                            activeTrackColor: AppTheme.secondary,
                            inactiveThumbColor: AppTheme.surfaceContainerLowest,
                            inactiveTrackColor:
                                AppTheme.surfaceContainerHighest,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: widget.onEdit,
                          icon: const Icon(Icons.edit_outlined, size: 17),
                          label: const Text('Edit Property'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.onSurface,
                            backgroundColor: AppTheme.surfaceContainer,
                            side: BorderSide.none,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: const Size(0, 40),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: widget.onDelete,
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 17,
                        ),
                        label: const Text('Delete'),
                        style: FilledButton.styleFrom(
                          foregroundColor: AppTheme.onErrorContainer,
                          backgroundColor: AppTheme.errorContainer,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          minimumSize: const Size(0, 40),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
