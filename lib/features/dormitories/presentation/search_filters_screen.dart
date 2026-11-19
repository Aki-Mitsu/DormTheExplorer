import 'dart:ui' show ImageFilter;

import 'package:material_ui/material_ui.dart';

import '../../../theme/app_theme.dart';
import '../domain/dormitory_search_filters.dart';
import 'search_filters_view_model.dart';

class SearchFiltersScreen extends StatefulWidget {
  const SearchFiltersScreen({
    super.key,
    this.initialFilters,
    this.initialQuery = '',
  });

  final DormitorySearchFilters? initialFilters;
  final String initialQuery;

  @override
  State<SearchFiltersScreen> createState() => _SearchFiltersScreenState();
}

class _SearchFiltersScreenState extends State<SearchFiltersScreen> {
  late final SearchFiltersViewModel _viewModel;
  late final TextEditingController _searchController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _viewModel = SearchFiltersViewModel(
      initialFilters: widget.initialFilters,
      initialQuery: widget.initialQuery,
    );
    _searchController = TextEditingController(text: _viewModel.query);
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _clearAll() {
    _searchController.clear();
    _viewModel.clearAll();
  }

  void _applyFilters() {
    FocusScope.of(context).unfocus();
    Navigator.of(context).pop(_viewModel.filters);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _viewModel,
    builder: (context, _) => Scaffold(
      extendBody: true,
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _header(),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final maxWidth = constraints.maxWidth > 760
                      ? 760.0
                      : constraints.maxWidth;
                  return Align(
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      width: maxWidth,
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 1, 16, 112),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _searchField(),
                            _priceFilter(),
                            _slotFilter(),
                            _amenitiesFilter(),
                            _campusFilter(),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _bottomActions(),
    ),
  );

  Widget _header() => ClipRect(
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: AppTheme.surface.withValues(alpha: 0.85),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 8,
              offset: Offset(0, 1),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Go back',
              onPressed: () => Navigator.of(context).maybePop(),
              style: IconButton.styleFrom(
                minimumSize: const Size(44, 44),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: AppTheme.onSurface,
              ),
              icon: const Icon(Icons.arrow_back_rounded, size: 24),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DormTheExplorer',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppTheme.primaryDeep,
                      fontSize: 10,
                      height: 14 / 10,
                      letterSpacing: 0.8,
                    ),
                  ),
                  Text(
                    'Search & Filters',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppTheme.onSurface,
                      fontSize: 18,
                      height: 24 / 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: _clearAll,
              style: TextButton.styleFrom(
                minimumSize: const Size(44, 44),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                foregroundColor: AppTheme.primaryDeep,
                shape: const StadiumBorder(),
                textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontSize: 14,
                  height: 20 / 14,
                ),
              ),
              child: const Text('Reset'),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _searchField() => Padding(
    padding: const EdgeInsets.only(top: 4, bottom: 8),
    child: Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.search_rounded,
            color: AppTheme.primaryDeep,
            size: 22,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: _viewModel.updateQuery,
              textInputAction: TextInputAction.search,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.onSurface,
                fontSize: 14,
                height: 20 / 14,
              ),
              decoration: InputDecoration(
                hintText: 'Search by name or address...',
                hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.outline,
                  fontSize: 14,
                  height: 20 / 14,
                ),
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _priceFilter() => _FilterGroup(
    title: 'Price Range',
    child: Row(
      children: [
        Expanded(
          child: _RangeButton<DormPriceRange>(
            label: '₱1,000–₱3,000',
            selected: _viewModel.priceRange == DormPriceRange.budget,
            onTap: () => _viewModel.selectPriceRange(
              _viewModel.priceRange == DormPriceRange.budget
                  ? null
                  : DormPriceRange.budget,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _RangeButton<DormPriceRange>(
            label: '₱3,000–₱5,000',
            selected: _viewModel.priceRange == DormPriceRange.midRange,
            onTap: () => _viewModel.selectPriceRange(
              _viewModel.priceRange == DormPriceRange.midRange
                  ? null
                  : DormPriceRange.midRange,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _RangeButton<DormPriceRange>(
            label: '₱5,000+',
            selected: _viewModel.priceRange == DormPriceRange.premium,
            onTap: () => _viewModel.selectPriceRange(
              _viewModel.priceRange == DormPriceRange.premium
                  ? null
                  : DormPriceRange.premium,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _slotFilter() => _FilterGroup(
    title: 'Available Slots',
    child: Row(
      children: [
        Expanded(
          child: _RangeButton<DormSlotRange>(
            label: '1–2',
            selected: _viewModel.slotRange == DormSlotRange.oneToTwo,
            onTap: () => _viewModel.selectSlotRange(
              _viewModel.slotRange == DormSlotRange.oneToTwo
                  ? null
                  : DormSlotRange.oneToTwo,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _RangeButton<DormSlotRange>(
            label: '3–4',
            selected: _viewModel.slotRange == DormSlotRange.threeToFour,
            onTap: () => _viewModel.selectSlotRange(
              _viewModel.slotRange == DormSlotRange.threeToFour
                  ? null
                  : DormSlotRange.threeToFour,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _RangeButton<DormSlotRange>(
            label: '5+',
            selected: _viewModel.slotRange == DormSlotRange.fiveOrMore,
            onTap: () => _viewModel.selectSlotRange(
              _viewModel.slotRange == DormSlotRange.fiveOrMore
                  ? null
                  : DormSlotRange.fiveOrMore,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _amenitiesFilter() => _FilterGroup(
    title: 'Amenities',
    trailing: Text(
      'Select all that apply',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: AppTheme.onSurfaceVariant,
        fontSize: 12,
        height: 16 / 12,
      ),
    ),
    child: LayoutBuilder(
      builder: (context, constraints) {
        const columns = 2;
        final width = (constraints.maxWidth - 8) / columns;
        const amenities = <(String, String, IconData)>[
          ('wifi', 'WiFi', Icons.wifi_rounded),
          ('own_cr', 'Own CR', Icons.shower_outlined),
          ('kitchen', 'Kitchen', Icons.countertops_outlined),
          ('parking', 'Parking', Icons.local_parking_outlined),
          ('aircon', 'Air Conditioning', Icons.ac_unit_rounded),
          ('laundry', 'Laundry', Icons.local_laundry_service_outlined),
        ];

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: amenities.map((amenity) {
            final (value, label, icon) = amenity;
            return SizedBox(
              width: width,
              child: _AmenityButton(
                label: label,
                icon: icon,
                selected: _viewModel.amenities.contains(value),
                onTap: () => _viewModel.toggleAmenity(value),
              ),
            );
          }).toList(growable: false),
        );
      },
    ),
  );

  Widget _campusFilter() => _FilterGroup(
    title: 'Campus Proximity',
    trailing: Text(
      'Optional',
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: AppTheme.onSurfaceVariant,
        fontSize: 10,
        height: 14 / 10,
        letterSpacing: 0.4,
      ),
    ),
    child: Column(
      children: [
        _CampusButton(
          label: 'Near Alangilan Campus',
          selected: _viewModel.campus == DormCampus.alangilan,
          onTap: () => _viewModel.toggleCampus(DormCampus.alangilan),
        ),
        const SizedBox(height: 8),
        _CampusButton(
          label: 'Near Pablo Borbon Campus',
          selected: _viewModel.campus == DormCampus.pabloBorbon,
          onTap: () => _viewModel.toggleCampus(DormCampus.pabloBorbon),
        ),
        const SizedBox(height: 8),
        _CampusButton(
          label: 'Near LPU',
          selected: _viewModel.campus == DormCampus.lpu,
          onTap: () => _viewModel.toggleCampus(DormCampus.lpu),
        ),
      ],
    ),
  );

  Widget _bottomActions() => SafeArea(
    top: false,
    child: ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            color: AppTheme.surface.withValues(alpha: 0.95),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F000000),
                blurRadius: 20,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                flex: 1,
                child: _BottomButton(
                  label: 'Clear All',
                  background: AppTheme.surfaceContainer,
                  foreground: AppTheme.onSurface,
                  onTap: _clearAll,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: _BottomButton(
                  label: 'Apply Filters',
                  background: AppTheme.primaryDeep,
                  foreground: AppTheme.onPrimary,
                  icon: Icons.arrow_forward_rounded,
                  onTap: _applyFilters,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _FilterGroup extends StatelessWidget {
  const _FilterGroup({
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppTheme.onSurface,
                    fontSize: 14,
                    height: 20 / 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
        ),
        child,
      ],
    ),
  );
}

class _RangeButton<T> extends StatelessWidget {
  const _RangeButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? AppTheme.primaryDeep : AppTheme.surfaceContainer,
    borderRadius: BorderRadius.circular(12),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 36,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: selected ? AppTheme.onPrimary : AppTheme.onSurface,
                  fontSize: 12,
                  height: 16 / 12,
                  letterSpacing: 0.24,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _AmenityButton extends StatelessWidget {
  const _AmenityButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? AppTheme.surfaceContainerLowest : AppTheme.surfaceContainerLow,
    borderRadius: BorderRadius.circular(12),
    elevation: selected ? 1 : 0,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: selected ? AppTheme.primaryDeep : AppTheme.outline,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: selected
                      ? AppTheme.onSurface
                      : AppTheme.onSurfaceVariant,
                  fontSize: 12,
                  height: 16 / 12,
                  letterSpacing: 0.24,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: selected
                    ? AppTheme.primaryDeep
                    : AppTheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(6),
              ),
              child: selected
                  ? const Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: AppTheme.onPrimary,
                    )
                  : null,
            ),
          ],
        ),
      ),
    ),
  );
}

class _CampusButton extends StatelessWidget {
  const _CampusButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? AppTheme.primaryDeep : AppTheme.surfaceContainer,
    borderRadius: BorderRadius.circular(12),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              Icons.school_rounded,
              size: 20,
              color: selected ? AppTheme.onPrimary : AppTheme.outline,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: selected ? AppTheme.onPrimary : AppTheme.onSurface,
                  fontSize: 12,
                  height: 16 / 12,
                  letterSpacing: 0.24,
                ),
              ),
            ),
            if (selected) ...[
              const SizedBox(width: 8),
              const Icon(
                Icons.check_circle_rounded,
                size: 18,
                color: AppTheme.onPrimary,
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

class _BottomButton extends StatelessWidget {
  const _BottomButton({
    required this.label,
    required this.background,
    required this.foreground,
    required this.onTap,
    this.icon,
  });

  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Material(
    color: background,
    borderRadius: BorderRadius.circular(999),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 48,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: foreground,
                fontSize: 14,
                height: 20 / 14,
                letterSpacing: 0.14,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (icon != null) ...[
              const SizedBox(width: 8),
              Icon(icon, size: 18, color: foreground),
            ],
          ],
        ),
      ),
    ),
  );
}
