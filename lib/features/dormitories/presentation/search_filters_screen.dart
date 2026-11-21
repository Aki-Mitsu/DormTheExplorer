import 'dart:ui' show ImageFilter;

import 'package:material_ui/material_ui.dart';

import '../../../theme/app_theme.dart';
import '../domain/dormitory.dart';
import '../domain/dormitory_search_filters.dart';
import '../domain/route_destination.dart';
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

  void _resetAndApply() {
    _clearAll();
    _applyFilters();
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
                            _roomTypeFilter(),
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
              blurRadius: 6,
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
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.primaryContainer,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    'Search & Filters',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            Tooltip(
              message: 'Clear all filters and return to results',
              child: TextButton(
                onPressed: _resetAndApply,
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primaryContainer,
                  minimumSize: const Size(0, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Reset',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.primaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _searchField() => Padding(
    padding: const EdgeInsets.only(top: 4, bottom: 8),
    child: Container(
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _viewModel.updateQuery,
        textInputAction: TextInputAction.search,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppTheme.onSurface,
          fontSize: 16,
          height: 22 / 16,
        ),
        decoration: InputDecoration(
          hintText: 'Search by name or address...',
          hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.outline,
            fontSize: 16,
            height: 22 / 16,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppTheme.primaryDeep,
            size: 24,
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 52,
            minHeight: 52,
          ),
          filled: true,
          fillColor: AppTheme.surfaceContainerLowest,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 15,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: AppTheme.outline.withValues(alpha: 0.3),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: AppTheme.outline.withValues(alpha: 0.3),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: AppTheme.primaryDeep,
              width: 1.5,
            ),
          ),
        ),
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
            onTap: () =>
                _viewModel.selectPriceRange(DormPriceRange.budget),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _RangeButton<DormPriceRange>(
            label: '₱3,000–₱5,000',
            selected: _viewModel.priceRange == DormPriceRange.midRange,
            onTap: () =>
                _viewModel.selectPriceRange(DormPriceRange.midRange),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _RangeButton<DormPriceRange>(
            label: '₱5,000+',
            selected: _viewModel.priceRange == DormPriceRange.premium,
            onTap: () =>
                _viewModel.selectPriceRange(DormPriceRange.premium),
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
            onTap: () =>
                _viewModel.selectSlotRange(DormSlotRange.oneToTwo),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _RangeButton<DormSlotRange>(
            label: '3–4',
            selected: _viewModel.slotRange == DormSlotRange.threeToFour,
            onTap: () =>
                _viewModel.selectSlotRange(DormSlotRange.threeToFour),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _RangeButton<DormSlotRange>(
            label: '5+',
            selected: _viewModel.slotRange == DormSlotRange.fiveOrMore,
            onTap: () =>
                _viewModel.selectSlotRange(DormSlotRange.fiveOrMore),
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
        final columns = constraints.maxWidth < 360 ? 1 : 2;
        final width = columns == 1
            ? constraints.maxWidth
            : (constraints.maxWidth - 8) / columns;
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

  Widget _roomTypeFilter() => _FilterGroup(
    title: 'Room Type',
    trailing: Text(
      'Optional',
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: AppTheme.onSurfaceVariant,
        fontSize: 10,
        height: 14 / 10,
        letterSpacing: 0.4,
      ),
    ),
    child: DropdownButtonFormField<String>(
      key: ValueKey('room-type-${_viewModel.roomType?.name ?? 'any'}'),
      initialValue: _viewModel.roomType?.name ?? '',
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Room type',
        prefixIcon: Icon(Icons.bed_outlined),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      items: [
        const DropdownMenuItem(value: '', child: Text('Any Room Type')),
        ...DormRoomType.values.map(
          (roomType) => DropdownMenuItem(
            value: roomType.name,
            child: Text(roomType.label),
          ),
        ),
      ],
      onChanged: (value) {
        if (value == null || value.isEmpty) {
          _viewModel.selectRoomType(null);
          return;
        }
        final roomType = DormRoomType.values.firstWhere(
          (type) => type.name == value,
        );
        _viewModel.selectRoomType(roomType);
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
    child: DropdownButtonFormField<String>(
      key: ValueKey(_viewModel.campus?.name ?? 'any-campus'),
      initialValue: _viewModel.campus?.name ?? '',
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Campus',
        prefixIcon: Icon(Icons.school_outlined),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      items: [
        const DropdownMenuItem(value: '', child: Text('Any Campus')),
        ...RouteDestination.campuses.map(
          (campus) => DropdownMenuItem(
            value: campus.name,
            child: Text(campus.name, overflow: TextOverflow.ellipsis),
          ),
        ),
      ],
      onChanged: (value) {
        if (value == null || value.isEmpty) {
          _viewModel.selectCampus(null);
          return;
        }
        final campus = RouteDestination.campuses.firstWhere(
          (destination) => destination.name == value,
        );
        _viewModel.selectCampus(campus);
      },
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
                blurRadius: 12,
                offset: Offset(0, -3),
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
                  background: AppTheme.primaryContainer,
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
