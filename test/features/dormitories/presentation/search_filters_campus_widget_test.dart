import 'package:dorm_the_explorer/features/dormitories/domain/dormitory_search_filters.dart';
import 'package:dorm_the_explorer/features/dormitories/domain/route_destination.dart';
import 'package:dorm_the_explorer/features/dormitories/presentation/search_filters_screen.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('campus filter is a compact dropdown with all campuses and Any Campus', (
    tester,
  ) async {
    await _openFilters(tester);
    final dropdown = find.byType(DropdownButtonFormField<String>).last;
    await tester.ensureVisible(dropdown);

    await tester.tap(dropdown);
    await tester.pumpAndSettle();
    for (final campus in RouteDestination.campuses) {
      expect(find.text(campus.name), findsOneWidget);
    }
    expect(find.text('Any Campus'), findsNWidgets(2));
  });

  testWidgets('selecting a campus applies it to dormitory filters', (
    tester,
  ) async {
    await _openFilters(tester);
    await _chooseCampus(tester, 'Golden Gate Colleges');
    await tester.tap(find.text('Apply Filters'));
    await tester.pumpAndSettle();

    expect(find.text('Golden Gate Colleges'), findsOneWidget);
  });

  testWidgets('Any Campus clears a previously selected campus filter', (
    tester,
  ) async {
    await _openFilters(
      tester,
      initialFilters: DormitorySearchFilters(
        campus: RouteDestination.campuses[3],
      ),
    );
    await _chooseCampus(tester, 'Any Campus');
    await tester.tap(find.text('Apply Filters'));
    await tester.pumpAndSettle();

    expect(find.text('Any Campus'), findsOneWidget);
  });
}

Future<void> _openFilters(
  WidgetTester tester, {
  DormitorySearchFilters? initialFilters,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: _FilterTestHost(initialFilters: initialFilters),
    ),
  );
  await tester.tap(find.text('Open filters'));
  await tester.pumpAndSettle();
}

Future<void> _chooseCampus(WidgetTester tester, String campusName) async {
  final dropdown = find.byType(DropdownButtonFormField<String>).last;
  await tester.ensureVisible(dropdown);
  await tester.tap(dropdown);
  await tester.pumpAndSettle();
  await tester.tap(find.text(campusName).last);
  await tester.pumpAndSettle();
}

class _FilterTestHost extends StatefulWidget {
  const _FilterTestHost({this.initialFilters});

  final DormitorySearchFilters? initialFilters;

  @override
  State<_FilterTestHost> createState() => _FilterTestHostState();
}

class _FilterTestHostState extends State<_FilterTestHost> {
  String _appliedCampus = 'Not applied';

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Column(
      children: [
        Text(_appliedCampus),
        TextButton(
          onPressed: () async {
            final filters = await Navigator.of(context)
                .push<DormitorySearchFilters>(
                  MaterialPageRoute(
                    builder: (_) => SearchFiltersScreen(
                      initialFilters: widget.initialFilters,
                    ),
                  ),
                );
            if (filters != null && mounted) {
              setState(() {
                _appliedCampus = filters.campus?.name ?? 'Any Campus';
              });
            }
          },
          child: const Text('Open filters'),
        ),
      ],
    ),
  );
}
