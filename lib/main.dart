import 'package:firebase_core/firebase_core.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const DormApp());
}
// ───────────────────────── Theme ─────────────────────────
const ink = Color(0xFF14272B);
const teal = Color(0xFF1F6F78);
const lamp = Color(0xFFF2B134); // window-light accent
const mist = Color(0xFFF3F6F6);

class DormApp extends StatelessWidget {
  const DormApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DormTheExplorer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: teal, primary: teal),
        scaffoldBackgroundColor: mist,
        appBarTheme: const AppBarTheme(
          backgroundColor: mist,
          foregroundColor: ink,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      home: const Shell(),
    );
  }
}

// ───────────────────────── Models ─────────────────────────
enum ListingStatus { pending, approved, rejected }

const allAmenities = ['Wi-Fi', 'Aircon', 'Cooking allowed'];
const roomTypes = ['Solo room', 'Shared room', 'Bedspace'];

IconData amenityIcon(String a) => switch (a) {
  'Wi-Fi' => Icons.wifi,
  'Aircon' => Icons.ac_unit,
  'Cooking allowed' => Icons.soup_kitchen_outlined,
  _ => Icons.check,
};

class Dorm {
  Dorm({
    required this.id,
    required this.name,
    required this.area,
    required this.price,
    required this.capacity,
    required this.roomType,
    required this.amenities,
    required this.utilities,
    required this.rules,
    required this.description,
    required this.ownerName,
    required this.phone,
    required this.email,
    this.status = ListingStatus.approved,
    this.rejectReason,
  });

  final String id, name, area, roomType, utilities, rules, description;
  final String ownerName, phone, email;
  final int price, capacity;
  final Set<String> amenities;
  ListingStatus status;
  String? rejectReason;
}

String peso(int p) =>
    '₱${p.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',')}';

// ───────────────────────── State ─────────────────────────
class AppState extends ChangeNotifier {
  final List<Dorm> dorms = [
    Dorm(
      id: '1',
      name: 'Casa Marilag Boarding House',
      area: 'Alangilan',
      price: 3500,
      capacity: 2,
      roomType: 'Shared room',
      amenities: {'Wi-Fi', 'Cooking allowed'},
      utilities: 'Water included. Electricity split by sub-meter.',
      rules: 'Curfew 10 PM. No overnight guests. Quiet hours after 9 PM.',
      description: 'Two-storey house with a shared kitchen and study area.',
      ownerName: 'Aling Marilag',
      phone: '09171234567',
      email: 'marilag@example.com',
    ),
    Dorm(
      id: '2',
      name: 'Golden Nest Dormitory',
      area: 'Golden Country Homes',
      price: 5200,
      capacity: 1,
      roomType: 'Solo room',
      amenities: {'Wi-Fi', 'Aircon'},
      utilities: 'Electricity and water billed monthly by sub-meter.',
      rules: 'Gate closes at 11 PM. No pets. No cooking inside rooms.',
      description: 'Private rooms with own bed, desk, and cabinet.',
      ownerName: 'Mr. Reyes',
      phone: '09281234567',
      email: 'goldennest@example.com',
    ),
    Dorm(
      id: '3',
      name: 'Bahay Pahingahan Bedspace',
      area: 'Kumintang Ibaba',
      price: 1800,
      capacity: 6,
      roomType: 'Bedspace',
      amenities: {'Wi-Fi', 'Cooking allowed'},
      utilities: 'All utilities included in monthly rate.',
      rules: 'Clean as you go. Visitors in common area only.',
      description: 'Budget bedspace, 6 per room, lockers provided.',
      ownerName: 'Ate Joy',
      phone: '09391234567',
      email: 'joy@example.com',
    ),
    Dorm(
      id: '4',
      name: 'Pallocan Pines Rooms',
      area: 'Pallocan West',
      price: 4200,
      capacity: 2,
      roomType: 'Shared room',
      amenities: {'Aircon'},
      utilities: 'Water included. Aircon electricity billed separately.',
      rules: 'No smoking. Curfew 11 PM.',
      description: 'Newly renovated rooms with tiled floors.',
      ownerName: 'Mr. Dizon',
      phone: '09451234567',
      email: 'pines@example.com',
    ),
    Dorm(
      id: '5',
      name: 'Sunrise Dorm',
      area: 'Alangilan',
      price: 3000,
      capacity: 3,
      roomType: 'Shared room',
      amenities: {'Wi-Fi'},
      utilities: 'Water included.',
      rules: 'Curfew 10 PM.',
      description: 'Waiting for admin review.',
      ownerName: 'Demo Landlord',
      phone: '09501234567',
      email: 'sunrise@example.com',
      status: ListingStatus.pending,
    ),
  ];

  // Filters
  String query = '';
  RangeValues priceRange = const RangeValues(0, 10000);
  final Set<String> amenityFilter = {};
  String? roomTypeFilter;
  String? areaFilter;

  // Landlord session
  String? landlordName;
  String? landlordPhone;

  List<String> get areas =>
      dorms.map((d) => d.area).toSet().toList()..sort();

  List<Dorm> get visible => dorms.where((d) {
    if (d.status != ListingStatus.approved) return false;
    if (query.isNotEmpty &&
        !('${d.name} ${d.area}'.toLowerCase())
            .contains(query.toLowerCase())) {
      return false;
    }
    if (d.price < priceRange.start || d.price > priceRange.end) return false;
    if (!amenityFilter.every(d.amenities.contains)) return false;
    if (roomTypeFilter != null && d.roomType != roomTypeFilter) return false;
    if (areaFilter != null && d.area != areaFilter) return false;
    return true;
  }).toList();

  List<Dorm> get pending =>
      dorms.where((d) => d.status == ListingStatus.pending).toList();

  List<Dorm> get mine =>
      dorms.where((d) => d.ownerName == landlordName).toList();

  bool get hasActiveFilters =>
      priceRange != const RangeValues(0, 10000) ||
          roomTypeFilter != null ||
          areaFilter != null;

  void setQuery(String q) {
    query = q;
    notifyListeners();
  }

  void toggleAmenity(String a) {
    amenityFilter.contains(a) ? amenityFilter.remove(a) : amenityFilter.add(a);
    notifyListeners();
  }

  void applyFilters(RangeValues r, String? type, String? area) {
    priceRange = r;
    roomTypeFilter = type;
    areaFilter = area;
    notifyListeners();
  }

  void clearFilters() {
    priceRange = const RangeValues(0, 10000);
    roomTypeFilter = null;
    areaFilter = null;
    amenityFilter.clear();
    notifyListeners();
  }

  void signIn(String name, String phone) {
    landlordName = name;
    landlordPhone = phone;
    notifyListeners();
  }

  void signOut() {
    landlordName = null;
    landlordPhone = null;
    notifyListeners();
  }

  void submitListing(Dorm d) {
    d.status = ListingStatus.pending;
    dorms.add(d);
    notifyListeners();
  }

  void approve(Dorm d) {
    d.status = ListingStatus.approved;
    d.rejectReason = null;
    notifyListeners();
  }

  void reject(Dorm d, String reason) {
    d.status = ListingStatus.rejected;
    d.rejectReason = reason;
    notifyListeners();
  }
}

final appState = AppState();

// ───────────────────────── Shell ─────────────────────────
class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int tab = 0;
  static const pages = [BrowsePage(), LandlordPage(), AdminPage()];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final n = appState.pending.length;
        return Scaffold(
          body: SafeArea(child: pages[tab]),
          bottomNavigationBar: NavigationBar(
            selectedIndex: tab,
            onDestinationSelected: (i) => setState(() => tab = i),
            destinations: [
              const NavigationDestination(
                  icon: Icon(Icons.search), label: 'Browse'),
              const NavigationDestination(
                  icon: Icon(Icons.home_work_outlined), label: 'My listings'),
              NavigationDestination(
                icon: Badge(
                  label: Text('$n'),
                  isLabelVisible: n > 0,
                  child: const Icon(Icons.fact_check_outlined),
                ),
                label: 'Review',
              ),
            ],
          ),
        );
      },
    );
  }
}

// ───────────────────────── Shared widgets ─────────────────────────
class PhotoPlaceholder extends StatelessWidget {
  const PhotoPlaceholder({super.key, required this.seed, this.height = 150});
  final String seed;
  final double height;

  @override
  Widget build(BuildContext context) {
    final h = (seed.hashCode % 60).abs() + 170.0;
    final base = HSLColor.fromAHSL(1, h, 0.35, 0.32).toColor();
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [base, HSLColor.fromColor(base).withLightness(0.2).toColor()],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          const Center(
              child: Icon(Icons.apartment, size: 54, color: Colors.white54)),
          Positioned(
            right: 18,
            top: 16,
            child: Container(
              width: 14,
              height: 18,
              decoration: BoxDecoration(
                color: lamp,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key});
  final ListingStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      ListingStatus.pending => ('Pending review', const Color(0xFFB7791F)),
      ListingStatus.approved => ('Approved', const Color(0xFF2F855A)),
      ListingStatus.rejected => ('Rejected', const Color(0xFFC53030)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

class DormCard extends StatelessWidget {
  const DormCard(this.dorm, {super.key, this.onTap, this.footer});
  final Dorm dorm;
  final VoidCallback? onTap;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PhotoPlaceholder(seed: dorm.id),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(dorm.name,
                            style: const TextStyle(
                                fontSize: 17, fontWeight: FontWeight.w700)),
                      ),
                      Text('${peso(dorm.price)}/mo',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, color: teal)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('${dorm.area} • ${dorm.roomType} • ${dorm.capacity} pax',
                      style: TextStyle(color: ink.withValues(alpha: 0.65))),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      for (final a in dorm.amenities)
                        Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Icon(amenityIcon(a), size: 20, color: teal),
                        ),
                      const Spacer(),
                      ?footer,
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

// ───────────────────────── Browse ─────────────────────────
class BrowsePage extends StatelessWidget {
  const BrowsePage({super.key});

  void _openFilters(BuildContext context) {
    var range = appState.priceRange;
    var type = appState.roomTypeFilter;
    var area = appState.areaFilter;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => StatefulBuilder(
        builder: (context, setSheet) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Filters',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              Text(
                  'Monthly price: ${peso(range.start.round())} – ${peso(range.end.round())}'),
              RangeSlider(
                values: range,
                min: 0,
                max: 10000,
                divisions: 40,
                onChanged: (v) => setSheet(() => range = v),
              ),
              const Text('Room type'),
              Wrap(
                spacing: 8,
                children: [
                  for (final t in roomTypes)
                    ChoiceChip(
                      label: Text(t),
                      selected: type == t,
                      onSelected: (s) => setSheet(() => type = s ? t : null),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              const Text('Area'),
              Wrap(
                spacing: 8,
                children: [
                  for (final a in appState.areas)
                    ChoiceChip(
                      label: Text(a),
                      selected: area == a,
                      onSelected: (s) => setSheet(() => area = s ? a : null),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  TextButton(
                    onPressed: () {
                      appState.clearFilters();
                      Navigator.pop(context);
                    },
                    child: const Text('Reset'),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: () {
                      appState.applyFilters(range, type, area);
                      Navigator.pop(context);
                    },
                    child: const Text('Show results'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final list = appState.visible;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Find your dorm',
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: ink)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          onChanged: appState.setQuery,
                          decoration: const InputDecoration(
                            hintText: 'Search by name or area',
                            prefixIcon: Icon(Icons.search),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: () => _openFilters(context),
                        icon: Badge(
                          isLabelVisible: appState.hasActiveFilters,
                          smallSize: 8,
                          child: const Icon(Icons.tune),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final a in allAmenities)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              avatar: Icon(amenityIcon(a), size: 18),
                              label: Text(a),
                              selected: appState.amenityFilter.contains(a),
                              onSelected: (_) => appState.toggleAmenity(a),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: list.isEmpty
                  ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('No dorms match these filters.'),
                    TextButton(
                      onPressed: appState.clearFilters,
                      child: const Text('Clear filters'),
                    ),
                  ],
                ),
              )
                  : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                separatorBuilder: (context, index) =>
                const SizedBox(height: 14),
                itemBuilder: (context, i) => DormCard(
                  list[i],
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => DetailPage(list[i])),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ───────────────────────── Detail ─────────────────────────
class DetailPage extends StatelessWidget {
  const DetailPage(this.dorm, {super.key});
  final Dorm dorm;

  Widget _section(String title, String body) => Padding(
    padding: const EdgeInsets.only(top: 18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style:
            const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(body,
            style: TextStyle(
                color: ink.withValues(alpha: 0.8), height: 1.4)),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(dorm.name)),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          PhotoPlaceholder(seed: dorm.id, height: 220),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${peso(dorm.price)} per month',
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: teal)),
                const SizedBox(height: 4),
                Text(
                    '${dorm.area} • ${dorm.roomType} • fits ${dorm.capacity}',
                    style: TextStyle(color: ink.withValues(alpha: 0.65))),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final a in dorm.amenities)
                      Chip(
                          avatar: Icon(amenityIcon(a), size: 18),
                          label: Text(a)),
                  ],
                ),
                _section('About', dorm.description),
                _section('Utilities', dorm.utilities),
                _section('House rules', dorm.rules),
                _section('Landlord',
                    '${dorm.ownerName}\n${dorm.phone}\n${dorm.email}'),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: FilledButton.icon(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          icon: const Icon(Icons.send),
          label: const Text('Send inquiry'),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => InquiryPage(dorm)),
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── Inquiry ─────────────────────────
class InquiryPage extends StatefulWidget {
  const InquiryPage(this.dorm, {super.key});
  final Dorm dorm;
  @override
  State<InquiryPage> createState() => _InquiryPageState();
}

class _InquiryPageState extends State<InquiryPage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _budget = TextEditingController();
  final _note = TextEditingController();
  DateTime? _moveIn;
  bool _viaSms = true;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _budget.dispose();
    _note.dispose();
    super.dispose();
  }

  String? _validatePhone(String? v) {
    final p = (v ?? '').replaceAll(RegExp(r'[\s-]'), '');
    if (p.isEmpty) return 'Enter your mobile number';
    if (!RegExp(r'^(09\d{9}|\+639\d{9})$').hasMatch(p)) {
      return 'Use 09XXXXXXXXX or +639XXXXXXXXX';
    }
    return null;
  }

  String? _validateBudget(String? v) {
    final n = int.tryParse((v ?? '').trim());
    if (n == null) return 'Enter a whole number';
    if (n <= 0) return 'Budget must be greater than 0';
    return null;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _moveIn ?? now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (d != null) setState(() => _moveIn = d);
  }

  Future<void> _send() async {
    if (!_form.currentState!.validate()) return;
    final d = widget.dorm;
    final m = _moveIn!;
    final body = 'Hi ${d.ownerName}, I am interested in "${d.name}".\n'
        'Name: ${_name.text.trim()}\n'
        'Contact: ${_phone.text.trim()}\n'
        'Budget: ${peso(int.parse(_budget.text.trim()))}/mo\n'
        'Move-in: ${m.year}-${m.month.toString().padLeft(2, '0')}-${m.day.toString().padLeft(2, '0')}\n'
        '${_note.text.trim().isEmpty ? '' : 'Note: ${_note.text.trim()}'}';

    final uri = _viaSms
        ? Uri.parse('sms:${d.phone}?body=${Uri.encodeComponent(body)}')
        : Uri.parse(
        'mailto:${d.email}?subject=${Uri.encodeComponent('Inquiry: ${d.name}')}&body=${Uri.encodeComponent(body)}');

    final ok = await launchUrl(uri);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No app found to send this message.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inquiry')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Message ${widget.dorm.ownerName}',
                style:
                const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Your name'),
              validator: (v) =>
              (v ?? '').trim().length < 2 ? 'Enter your name' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                  labelText: 'Your mobile number', hintText: '09171234567'),
              validator: _validatePhone,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _budget,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Monthly budget', prefixText: '₱ '),
              validator: _validateBudget,
            ),
            const SizedBox(height: 12),
            FormField<DateTime>(
              validator: (_) =>
              _moveIn == null ? 'Pick a move-in date' : null,
              builder: (field) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () async {
                      await _pickDate();
                      field.validate();
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Move-in date',
                        errorText: field.errorText,
                        suffixIcon: const Icon(Icons.event),
                      ),
                      child: Text(_moveIn == null
                          ? 'Select a date'
                          : '${_moveIn!.day}/${_moveIn!.month}/${_moveIn!.year}'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _note,
              maxLines: 3,
              decoration: const InputDecoration(
                  labelText: 'Note (optional)',
                  hintText: 'Ask about viewing schedule, deposit, etc.'),
            ),
            const SizedBox(height: 16),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                    value: true,
                    icon: Icon(Icons.sms_outlined),
                    label: Text('SMS')),
                ButtonSegment(
                    value: false,
                    icon: Icon(Icons.email_outlined),
                    label: Text('Email')),
              ],
              selected: {_viaSms},
              onSelectionChanged: (s) => setState(() => _viaSms = s.first),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52)),
              icon: const Icon(Icons.send),
              label: Text(_viaSms ? 'Open SMS' : 'Open email'),
              onPressed: _send,
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────── Landlord ─────────────────────────
class LandlordPage extends StatelessWidget {
  const LandlordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        if (appState.landlordName == null) return const _LandlordSignIn();
        final mine = appState.mine;
        return Scaffold(
          backgroundColor: Colors.transparent,
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddListingPage()),
            ),
            icon: const Icon(Icons.add),
            label: const Text('New listing'),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('Hi, ${appState.landlordName}',
                        style: const TextStyle(
                            fontSize: 26, fontWeight: FontWeight.w800)),
                  ),
                  TextButton(
                      onPressed: appState.signOut,
                      child: const Text('Sign out')),
                ],
              ),
              const SizedBox(height: 12),
              if (mine.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 60),
                  child: Center(
                    child: Text(
                        'No listings yet. Add one and an admin will review it.'),
                  ),
                ),
              for (final d in mine) ...[
                DormCard(d, footer: StatusChip(d.status)),
                if (d.status == ListingStatus.rejected)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                    child: Text('Reason: ${d.rejectReason}',
                        style: const TextStyle(color: Color(0xFFC53030))),
                  ),
                const SizedBox(height: 14),
              ],
              const SizedBox(height: 70),
            ],
          ),
        );
      },
    );
  }
}

class _LandlordSignIn extends StatefulWidget {
  const _LandlordSignIn();
  @override
  State<_LandlordSignIn> createState() => _LandlordSignInState();
}

class _LandlordSignInState extends State<_LandlordSignIn> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _form,
          child: Column(
            children: [
              const Icon(Icons.home_work, size: 56, color: teal),
              const SizedBox(height: 12),
              const Text('List your dorm',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              const Text('Every listing is reviewed before it goes public.',
                  textAlign: TextAlign.center),
              const SizedBox(height: 24),
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Full name'),
                validator: (v) =>
                (v ?? '').trim().length < 2 ? 'Enter your name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Mobile number'),
                validator: (v) => RegExp(r'^(09\d{9}|\+639\d{9})$')
                    .hasMatch((v ?? '').replaceAll(RegExp(r'[\s-]'), ''))
                    ? null
                    : 'Use 09XXXXXXXXX',
              ),
              const SizedBox(height: 20),
              FilledButton(
                style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52)),
                onPressed: () {
                  if (_form.currentState!.validate()) {
                    appState.signIn(_name.text.trim(), _phone.text.trim());
                  }
                },
                child: const Text('Continue as landlord'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── Add Listing ─────────────────────────
class AddListingPage extends StatefulWidget {
  const AddListingPage({super.key});
  @override
  State<AddListingPage> createState() => _AddListingPageState();
}

class _AddListingPageState extends State<AddListingPage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _area = TextEditingController();
  final _price = TextEditingController();
  final _capacity = TextEditingController(text: '1');
  String _roomType = roomTypes.first;
  final Set<String> _amenities = {};
  final _utilities = TextEditingController();
  final _rules = TextEditingController();
  final _description = TextEditingController();
  final _email = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _area.dispose();
    _price.dispose();
    _capacity.dispose();
    _utilities.dispose();
    _rules.dispose();
    _description.dispose();
    _email.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;
    final dorm = Dorm(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _name.text.trim(),
      area: _area.text.trim(),
      price: int.parse(_price.text.trim()),
      capacity: int.parse(_capacity.text.trim()),
      roomType: _roomType,
      amenities: _amenities,
      utilities: _utilities.text.trim(),
      rules: _rules.text.trim(),
      description: _description.text.trim(),
      ownerName: appState.landlordName ?? 'Landlord',
      phone: appState.landlordPhone ?? '',
      email: _email.text.trim(),
      status: ListingStatus.pending,
    );
    appState.submitListing(dorm);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Listing submitted for review!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Dorm Listing')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Dorm or House Name'),
              validator: (v) => (v ?? '').trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _area,
              decoration: const InputDecoration(
                  labelText: 'Barangay or Area (e.g. Alangilan)'),
              validator: (v) => (v ?? '').trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _price,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Monthly Price', prefixText: '₱ '),
                    validator: (v) => int.tryParse(v ?? '') == null
                        ? 'Enter valid amount'
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _capacity,
                    keyboardType: TextInputType.number,
                    decoration:
                    const InputDecoration(labelText: 'Max Capacity (pax)'),
                    validator: (v) => int.tryParse(v ?? '') == null
                        ? 'Enter valid number'
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _roomType,
              decoration: const InputDecoration(labelText: 'Room Type'),
              items: roomTypes
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) => setState(() => _roomType = v!),
            ),
            const SizedBox(height: 16),
            const Text('Amenities',
                style: TextStyle(fontWeight: FontWeight.w700)),
            Wrap(
              spacing: 8,
              children: [
                for (final a in allAmenities)
                  FilterChip(
                    label: Text(a),
                    selected: _amenities.contains(a),
                    onSelected: (selected) {
                      setState(() {
                        selected ? _amenities.add(a) : _amenities.remove(a);
                      });
                    },
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _utilities,
              decoration: const InputDecoration(
                  labelText: 'Utilities (e.g. Water included, Sub-metered elec)'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _rules,
              decoration: const InputDecoration(
                  labelText: 'House Rules (e.g. Curfew 10 PM)'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _description,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Contact Email'),
              validator: (v) =>
              (v ?? '').contains('@') ? null : 'Enter valid email',
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52)),
              onPressed: _submit,
              icon: const Icon(Icons.check),
              label: const Text('Submit for Review'),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────── Admin ─────────────────────────
class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  void _promptReject(BuildContext context, Dorm dorm) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Listing'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
              hintText: 'Enter reason (e.g. Incomplete details)'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              appState.reject(dorm, reasonController.text.trim());
              Navigator.pop(context);
            },
            child: const Text('Confirm Reject'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final pending = appState.pending;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Admin Review Queue',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(
                'Review new property submissions before they appear in browse.',
                style: TextStyle(color: ink.withValues(alpha: 0.65))),
            const SizedBox(height: 16),
            if (pending.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(
                  child: Text('No pending listings to review. All caught up!'),
                ),
              ),
            for (final d in pending) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(d.name,
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold)),
                          ),
                          Text(peso(d.price),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, color: teal)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('Owner: ${d.ownerName} (${d.phone})'),
                      Text('Area: ${d.area} • Type: ${d.roomType}'),
                      const SizedBox(height: 10),
                      Text(d.description),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _promptReject(context, d),
                            style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red),
                            icon: const Icon(Icons.close),
                            label: const Text('Reject'),
                          ),
                          const SizedBox(width: 12),
                          FilledButton.icon(
                            onPressed: () => appState.approve(d),
                            icon: const Icon(Icons.check),
                            label: const Text('Approve'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ],
        );
      },
    );
  }
}