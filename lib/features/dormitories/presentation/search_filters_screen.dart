import 'package:material_ui/material_ui.dart';
import '../../../theme/app_theme.dart';
import '../data/dormitory_repository.dart';
import '../domain/dormitory.dart';
import '../domain/route_destination.dart';
import 'dorm_details_screen.dart';
import 'search_filters_view_model.dart';

class SearchFiltersScreen extends StatefulWidget {
  const SearchFiltersScreen({super.key, required this.repository, this.initialQuery = ''});
  final DormitoryRepository repository;
  final String initialQuery;
  @override
  State<SearchFiltersScreen> createState() => _SearchFiltersScreenState();
}

class _SearchFiltersScreenState extends State<SearchFiltersScreen> {
  late final SearchFiltersViewModel vm;
  late final TextEditingController queryController;
  final ScrollController _scrollController = ScrollController();
  @override
  void initState() {
    super.initState();
    queryController = TextEditingController(text: widget.initialQuery);
    vm = SearchFiltersViewModel(repository: widget.repository, initialQuery: widget.initialQuery)
      ..addListener(_changed);
  }
  void _changed() { if (mounted) setState(() {}); }
  @override
  void dispose() {
    vm..removeListener(_changed)..dispose();
    queryController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  void _clear() { queryController.clear(); vm.clear(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTheme.surface,
    body: SafeArea(child: Column(children: [
      _header(),
      Expanded(child: LayoutBuilder(builder: (context, constraints) {
        final width = constraints.maxWidth > 1000 ? 920.0 : constraints.maxWidth - 32;
        return Align(alignment: Alignment.topCenter, child: SizedBox(width: width,
          child: SingleChildScrollView(controller: _scrollController, padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text('Find your next dorm', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 3),
              Text('Browse student accommodations across Batangas City', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.onSurfaceVariant)),
              const SizedBox(height: 18),
              _search(),
              const SizedBox(height: 22),
              _choiceSection<PriceBand>('Price Range', null, const [
                ('₱1,000–₱3,000', PriceBand.budget), ('₱3,000–₱5,000', PriceBand.midRange), ('₱5,000+', PriceBand.premium)
              ], vm.price, vm.setPrice),
              const SizedBox(height: 20),
              _choiceSection<SlotBand>('Available Slots', 'Full listings remain visible unless filtered', const [
                ('1–2', SlotBand.oneToTwo), ('3–4', SlotBand.threeToFour), ('5+', SlotBand.fiveOrMore)
              ], vm.slots, vm.setSlots),
              const SizedBox(height: 20),
              _amenities(),
              const SizedBox(height: 20),
              _dropdownSection<int?>('Campus Proximity', 'Optional', vm.campusIndex,
                [const DropdownMenuItem<int?>(value: null, child: Text('Any location')),
                 for (var i = 0; i < RouteDestination.campuses.length; i++)
                   DropdownMenuItem<int?>(value: i, child: Text(switch(i) { 0 => 'Near Alangilan Campus', 1 => 'Near Pablo Borbon Campus', _ => 'Near LPU' }))],
                vm.setCampus),
              const SizedBox(height: 20),
              _dropdownSection<double>('Minimum Rating', 'Based on student reviews', vm.rating, const [
                DropdownMenuItem(value: 0, child: Text('Any rating')),
                DropdownMenuItem(value: 4, child: Text('4 stars & up')),
                DropdownMenuItem(value: 4.5, child: Text('4.5 stars & up')),
              ], (v) { if (v != null) vm.setRating(v); }),
              const SizedBox(height: 24),
              _resultsHeader(),
              const SizedBox(height: 12),
              _results(constraints.maxWidth),
            ]),
          ),
        ));
      })),
    ])),
    bottomNavigationBar: SafeArea(top: false, child: Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: const BoxDecoration(color: AppTheme.surfaceContainerLowest,
        border: Border(top: BorderSide(color: AppTheme.surfaceContainer))),
      child: Row(children: [
        Expanded(child: OutlinedButton(onPressed: _clear, child: const Text('Clear All'))),
        const SizedBox(width: 10),
        Expanded(flex: 2, child: FilledButton.icon(
          onPressed: () {
            FocusScope.of(context).unfocus();
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          },
          iconAlignment: IconAlignment.end, icon: const Icon(Icons.arrow_forward_rounded),
          label: Text('View ${vm.results.length} results'))),
      ]),
    )),
  );

  Widget _header() => Container(
    padding: const EdgeInsets.fromLTRB(8, 6, 12, 6),
    color: AppTheme.surfaceContainerLowest,
    child: Row(children: [
      IconButton(tooltip: 'Back to dorm listings', onPressed: () => Navigator.maybePop(context), icon: const Icon(Icons.arrow_back_rounded)),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('DormTheExplorer', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTheme.onSurfaceVariant)),
        Text('Search & Filters', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
      ])),
      TextButton(onPressed: _clear, child: const Text('Reset')),
    ]),
  );

  Widget _search() => SizedBox(height: 50, child: TextField(
    controller: queryController, onChanged: vm.updateQuery, textInputAction: TextInputAction.search,
    decoration: InputDecoration(
      hintText: 'Search by dorm name, location, or keyword',
      hintStyle: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.outline),
      prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.outline),
      suffixIcon: vm.query.isEmpty ? null : IconButton(onPressed: () {
        queryController.clear(); vm.updateQuery('');
      }, icon: const Icon(Icons.close_rounded)),
      filled: true, fillColor: AppTheme.surfaceContainerLowest,
      contentPadding: const EdgeInsets.symmetric(vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.surfaceContainer)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.surfaceContainer)),
    ),
  ));

  Widget _choiceSection<T>(String title, String? note, List<(String,T)> choices,
      T? selected, ValueChanged<T?> changed) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    _sectionTitle(title, note), const SizedBox(height: 10),
    Row(children: [for (var i = 0; i < choices.length; i++) ...[
      if (i > 0) const SizedBox(width: 8),
      Expanded(child: OutlinedButton(
        onPressed: () => changed(selected == choices[i].$2 ? null : choices[i].$2),
        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(46),
          padding: const EdgeInsets.symmetric(horizontal: 5),
          foregroundColor: selected == choices[i].$2 ? AppTheme.onPrimary : AppTheme.onSurface,
          backgroundColor: selected == choices[i].$2 ? AppTheme.primary : AppTheme.surfaceContainerLowest,
          side: BorderSide(color: selected == choices[i].$2 ? AppTheme.primary : AppTheme.surfaceContainer),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        child: FittedBox(child: Text(choices[i].$1)),
      )),
    ]]),
  ]);

  Widget _amenities() {
    const items = <(String,String,IconData)>[
      ('wifi','WiFi',Icons.wifi_rounded), ('own_cr','Own CR',Icons.shower_outlined),
      ('kitchen','Kitchen',Icons.countertops_outlined), ('parking','Parking',Icons.local_parking_outlined),
      ('aircon','Aircon',Icons.ac_unit_rounded), ('laundry','Laundry',Icons.local_laundry_service_outlined),
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionTitle('Amenities', 'Select all that apply'), const SizedBox(height: 10),
      LayoutBuilder(builder: (context, box) {
        final columns = box.maxWidth >= 540 ? 3 : 2;
        final itemWidth = (box.maxWidth - (columns - 1) * 8) / columns;
        return Wrap(spacing: 8, runSpacing: 8, children: items.map((item) {
          final selected = vm.amenities.contains(item.$1);
          return SizedBox(width: itemWidth, child: Material(
            color: selected ? AppTheme.accentBackground : AppTheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(onTap: () => vm.toggleAmenity(item.$1), borderRadius: BorderRadius.circular(12),
              child: Container(height: 48, padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: selected ? AppTheme.primaryFixedDim : AppTheme.surfaceContainer)),
                child: Row(children: [
                  Icon(item.$3, size: 18, color: AppTheme.primaryDeep), const SizedBox(width: 7),
                  Expanded(child: Text(item.$2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall)),
                  Icon(selected ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                    size: 18, color: selected ? AppTheme.primary : AppTheme.outline),
                ]),
              ),
            ),
          ));
        }).toList());
      }),
    ]);
  }

  Widget _dropdownSection<T>(String title, String note, T value, List<DropdownMenuItem<T>> items,
      ValueChanged<T?> changed) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    _sectionTitle(title, note), const SizedBox(height: 10),
    DropdownButtonFormField<T>(initialValue: value, isExpanded: true, items: items, onChanged: changed,
      decoration: InputDecoration(filled: true, fillColor: AppTheme.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppTheme.surfaceContainer))),
    ),
  ]);

  Widget _sectionTitle(String title, String? note) => Row(children: [
    Expanded(child: Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700))),
    if (note != null) Text(note, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTheme.onSurfaceVariant)),
  ]);

  Widget _resultsHeader() => Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Dormitories in Batangas City', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
      const SizedBox(height: 2),
      Text('Showing ${vm.results.length}${vm.results.length == 1 ? ' verified dorm available for rent' : ' verified dorms available for rent'}',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.onSurfaceVariant)),
    ])),
    DropdownButtonHideUnderline(child: DropdownButton<DormSort>(value: vm.sort, isDense: true,
      items: const [
        DropdownMenuItem(value: DormSort.recommended, child: Text('Recommended')),
        DropdownMenuItem(value: DormSort.priceLow, child: Text('Price: Low to high')),
        DropdownMenuItem(value: DormSort.priceHigh, child: Text('Price: High to low')),
        DropdownMenuItem(value: DormSort.rating, child: Text('Top rated')),
      ], onChanged: (v) { if (v != null) vm.setSort(v); })),
  ]);

  Widget _results(double width) {
    if (vm.loading) {
      return const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()));
    }
    if (vm.error != null) {
      return _message(Icons.cloud_off_outlined, 'Could not load dormitories',
          'Check your connection and Firestore access, then try again.', 'Try again', vm.retry);
    }
    final items = vm.results;
    if (items.isEmpty) {
      return _message(Icons.search_off_rounded, 'No dorms found',
          'Try changing your search or clearing one or more filters.');
    }
    return GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: width >= 760 ? 3 : 2, mainAxisExtent: 236, crossAxisSpacing: 12, mainAxisSpacing: 12),
      itemBuilder: (context, index) => _DormCard(dorm: items[index], onTap: () =>
        Navigator.push(context, MaterialPageRoute<void>(builder: (_) => DormDetailsScreen(
          dormitory: items[index], canEditLocation: false, canReview: true)))),
    );
  }

  Widget _message(IconData icon, String title, String subtitle, [String? action, VoidCallback? onPressed]) =>
    Padding(padding: const EdgeInsets.symmetric(vertical: 34), child: Center(child: Column(children: [
      Icon(icon, size: 38, color: AppTheme.outline), const SizedBox(height: 10),
      Text(title, style: Theme.of(context).textTheme.titleMedium), const SizedBox(height: 4),
      Text(subtitle, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.onSurfaceVariant)),
      if (action != null) TextButton(onPressed: onPressed, child: Text(action)),
    ])));
}

class _DormCard extends StatelessWidget {
  const _DormCard({required this.dorm, required this.onTap});
  final Dormitory dorm;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final photo = dorm.photoUrls.isNotEmpty && dorm.photoUrls.first.isNotEmpty;
    return Material(color: AppTheme.surfaceContainerLowest, borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias, child: InkWell(onTap: onTap, child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SizedBox(height: 118, child: Stack(fit: StackFit.expand, children: [
            if (photo) Image.network(dorm.photoUrls.first, fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _placeholder())
            else _placeholder(),
            if (dorm.availableSlots == 0) Positioned(top: 8, left: 8,
              child: Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(20)),
                child: const Text('FULL', style: TextStyle(color: AppTheme.onPrimary, fontSize: 10, fontWeight: FontWeight.w700)))),
          ])),
          Expanded(child: Padding(padding: const EdgeInsets.fromLTRB(10, 8, 10, 9),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(dorm.name.isEmpty ? 'Dorm name coming soon' : dorm.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 3),
              Text(dorm.address, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTheme.onSurfaceVariant)),
              const Spacer(),
              Row(children: [
                Expanded(child: Text('₱${dorm.monthlyPrice.toStringAsFixed(0)}/mo', maxLines: 1,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppTheme.primary, fontWeight: FontWeight.w700))),
                const Icon(Icons.star_rounded, size: 15, color: AppTheme.tertiaryAccent),
                Text(dorm.averageRating?.toStringAsFixed(1) ?? 'New', style: Theme.of(context).textTheme.labelSmall),
              ]),
            ]),
          )),
        ],
      )));
  }
  Widget _placeholder() => const ColoredBox(color: AppTheme.surfaceContainerHigh,
    child: Center(child: Icon(Icons.apartment_rounded, size: 36, color: AppTheme.outline)));
}
