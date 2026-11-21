import 'package:dorm_the_explorer/features/dormitories/domain/route_destination.dart';
import 'package:dorm_the_explorer/features/dormitories/presentation/widgets/campus_selection_bottom_sheet.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('campus dropdown opens below its field and selects a campus', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: _CampusDropdownTestHost()));
    final field = find.byKey(const ValueKey('campus-route-dropdown'));
    final fieldRect = tester.getRect(field);

    await tester.tap(field);
    await tester.pumpAndSettle();

    final menuItems = find.byType(MenuItemButton);
    expect(menuItems, findsNWidgets(RouteDestination.campuses.length));
    for (final campus in RouteDestination.campuses) {
      expect(
        find.text(campus.name),
        campus == RouteDestination.campuses.first
            ? findsNWidgets(2)
            : findsOneWidget,
      );
    }
    expect(tester.getTopLeft(menuItems.first).dy, greaterThanOrEqualTo(fieldRect.bottom));
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);

    await tester.tap(find.text('University of Batangas'));
    await tester.pumpAndSettle();
    expect(find.text('University of Batangas selected'), findsOneWidget);
  });
}

class _CampusDropdownTestHost extends StatefulWidget {
  const _CampusDropdownTestHost();

  @override
  State<_CampusDropdownTestHost> createState() => _CampusDropdownTestHostState();
}

class _CampusDropdownTestHostState extends State<_CampusDropdownTestHost> {
  RouteDestination _selected = RouteDestination.campuses.first;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${_selected.name} selected'),
          CampusRouteDropdown(
            selectedCampus: _selected,
            onChanged: (campus) => setState(() => _selected = campus),
          ),
        ],
      ),
    ),
  );
}
