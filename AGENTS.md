# Refactoring Rules and Steps: Dorm the Explorer (Flutter)

You are a careful senior Flutter engineer. Your job is to refactor an existing Flutter app so the code is cleaner, with IDENTICAL behavior. Users must not notice any change. A safe small change is always better than an impressive risky one.

## 1. Project context

- App: Dorm the Explorer, a dorm finder for Batangas City. Two roles: 'seeker' and 'landlord'.
- Dart SDK ^3.14. Packages: material_ui, flutter_map, latlong2, firebase_core, firebase_auth, cloud_firestore, image_picker, geolocator, http, url_launcher. There is NO state-management package. Screens use simple view models with listeners (ListenableBuilder).
- Backend: Firebase Auth and Cloud Firestore. Photos are uploaded to Cloudinary with plain HTTP. Maps use flutter_map with OpenStreetMap, limited to Batangas City.
- Layout: lib/main.dart (auth gate), lib/features/auth/presentation, lib/features/dormitories/{data,domain,presentation,presentation/widgets}, lib/services/auth_service.dart, lib/theme/app_theme.dart, lib/config/cloudinary_config.dart, lib/app_notice.dart.
- Biggest files (about lines): add_dormitory_screen.dart 1480, dorm_dashboard_screen.dart 1470, landlord_dormitory_details_screen.dart 1100, profile_dashboard_screen.dart 925, create_account_screen.dart 755, search_filters_screen.dart 700. The method _chooseLocation() in add_dormitory_screen.dart is about 390 lines.
- Source files use Windows (CRLF) line endings.

## 2. Hard rules (never break these)

1. Behavior must not change: no new features, no UI or visual changes, no text or label changes, no navigation changes.
2. Do NOT edit: pubspec.yaml, pubspec.lock, analysis_options.yaml, firebase.json, firestore.rules, lib/firebase_options.dart, lib/config/cloudinary_config.dart, CLOUDINARY_SETUP.md, anything under android/ or ios/, lib/features/dormitories/data/batangas_city_boundary.dart, or any test file.
3. Do NOT rename or move the Terms and Conditions .md file in lib/features/auth/presentation (its exact path is an asset in pubspec.yaml) or assets/images/Dorm_the_Explorer_Logo.png.
4. Do NOT add, remove or upgrade packages. Keep every import of package:material_ui/material_ui.dart as it is. Keep the dependency_overrides entry in pubspec.
5. Do NOT change public class names, constructor parameters or file paths that other files import, unless I ask. If you move code, update every import. New files and folders are allowed ONLY under the rules in section 3b.
6. Keep the existing CRLF line endings and code style. Do not reformat whole files. Only format files you changed.
7. Keep every 'if (!mounted) return' and 'context.mounted' check, every dispose() of controllers and listeners, every GlobalKey and ValueKey, and the same async order.
8. Never silence warnings with ignore comments. Never delete code that looks unused unless analysis proves it unused AND I approve.
9. If you are not sure a change is safe, DO NOT make it. Put it under 'Skipped / needs human review'.

Firestore rules are the real contract. Code that compiles can still fail with permission-denied. So:
- Updating a dormitory may ONLY change these keys: name, address, monthlyPrice, availableSlots, totalSlots, amenities, description, photoUrls, proximityLabel, latitude, longitude, landlordName, landlordPhone, landlordPhotoUrl, roomTypes, utilitiesIncluded, updatedAt. Never add, remove or rename a written field. Never write landlordId or status on update.
- Rating updates may change ONLY averageRating (a number from 0 to 5).
- Creating a dormitory requires: landlordId equal to the signed-in uid, name and address strings, monthlyPrice a number, totalSlots and availableSlots ints with 0 <= availableSlots <= totalSlots, status equal to 'approved', and landlordPhotoUrl absent, null, or an https string up to 2048 characters.
- Keep all Firestore where clauses exactly as they are (status == 'approved' for seekers, landlordId == uid for landlords).
- Reviews: document id equals the author's uid; fields authorUid, authorName, comment, rating (int 1 to 5). Reports: exactly the keys reporterId, reason, details, createdAt (server timestamp), reason from the existing six values, details at most 1000 characters. Users: role never changes.
- Do not change Dormitory.toJson or Dormitory.fromJson keys, collection names ('users', 'dormitories', 'reviews', 'reports'), the status 'approved', or the roles.

Existing tests (do not edit them; keep these working):
- ValueKey('campus-route-dropdown') in the campus selection bottom sheet
- search_filters_screen.dart keeps a DropdownButtonFormField<String> for the campus filter and the texts 'Apply Filters', 'Any Campus' and the 'Open filters' flow
- The domain classes Dormitory, DormitorySearchFilters, RouteDestination, DormRoute and their public methods
- test/widget_test.dart is probably already failing (it starts the app without Firebase and expects old text). Do not "fix" it. Just report which tests fail before and after.

## 3. How you must work

- If you can run commands: before editing, run flutter analyze and flutter test and report the baseline. If you cannot run commands, say so and tell me exactly which commands to run and what to paste back.
- If you cannot read my files (chat only), ask me to paste only the files needed for the current step. Return COMPLETE replacement files for those files only. Never return partial snippets with '...' or 'rest of the code unchanged'.
- Work on ONE step at a time. For each step: (1) show a short PLAN listing the files you will touch and what moves where, (2) make the change, (3) give the report below, (4) STOP and wait for me to type CONTINUE. Never start the next step on your own.
- Touch as few files as possible. If a change needs more than the step allows, stop and tell me instead.
- Copy moved code exactly. Extracted widgets receive the same data and callbacks through constructors. All state, controllers, listeners and action methods stay where they are unless the step says otherwise.

Report format after every step:
- Files changed (one line of reasoning each)
- What was moved or extracted
- Analyze and test results compared with the baseline (or the commands I should run)
- New files and folders created (path, what is inside, which file imports it)
- Line counts: before -> after for every file touched or created
- Skipped items and why
- A short manual test checklist for this step

## 3b. Structure, naming, file size and new folders

### The target structure (best fit for this app: feature-first, one folder per screen, grouped files)

Do NOT create one file per tiny widget. Group related widgets in one file. Do NOT create deep or generic folders. Use this layout and nothing more complicated:

lib/
  core/
    formatters.dart                                  (Step 1)
  features/
    dormitories/
      data/                                          (existing, do not touch)
      domain/
        amenity_utils.dart                           (Step 2)
      presentation/
        widgets/
          dashboard/                                 (Step 3)
            dashboard_header.dart                    DashboardHeader, DashboardMessage
            dormitory_card.dart                      DormitoryCard, DormitoryPhotoPlaceholder, DormitoryBadge, LandlordStatusChip
            dashboard_navigation_bars.dart           SeekerNavigationBar, LandlordNavigationBar, DashboardNavigationBarShell
          landlord_details/                          (Step 4)
            landlord_photo_gallery.dart              LandlordPhotoGallery
            landlord_detail_cards.dart               availability, overview, description, amenities, location cards
            landlord_detail_parts.dart               section card, section title, metric tile, amenity tile
          add_dormitory/                             (Step 5)
            location_picker_dialog.dart              LocationPickerDialog (5a)
            room_types_section.dart                  room types section and option (5b)
            amenities_description_sections.dart      amenities section, description section (5b)
            photos_section.dart                      photos section, photo tile, add-more tile (5b)
            add_dormitory_bottom_actions.dart        bottom actions (5b)

That is about 14 new files in total. Do not exceed it. Files that already exist stay where they are.

### Naming rules

- Files and folders: snake_case, lowercase, English words, no spaces, no numbers.
- Folder name = the screen name without the "_screen" suffix (dorm_dashboard_screen.dart -> dashboard/, landlord_dormitory_details_screen.dart -> landlord_details/, add_dormitory_screen.dart -> add_dormitory/).
- File name describes its group or its main class: DormitoryCard -> dormitory_card.dart. A grouped file is named after its group (dashboard_navigation_bars.dart), not after one of its classes.
- Class names: when a private class moves, only drop the leading underscore (_DormitoryCard -> DormitoryCard). Do not rename anything else.
- When a builder METHOD becomes a widget class (Step 4), use PascalCase with a clear prefix so it cannot collide with the seeker widgets: _photoGallery -> LandlordPhotoGallery, _availabilityCard -> LandlordAvailabilityCard, _overviewCard -> LandlordOverviewCard, _descriptionCard -> LandlordDescriptionCard, _amenitiesCard -> LandlordAmenitiesCard, _locationCard -> LandlordLocationCard, _sectionCard -> DetailSectionCard, _sectionTitle -> DetailSectionTitle, _metricTile -> DetailMetricTile, _amenityTile -> DetailAmenityTile.
- Before naming any new public class, search all of lib/ for the same name. If it already exists, stop and ask me.
- Forbidden file names: utils.dart, helpers.dart, common.dart, misc.dart, widgets.dart, index.dart, and any barrel file that only re-exports other files.

### Creating new folders (allowed, but only when ALL of these are true)

1. The folder is inside lib/ and is listed in the target structure above, or is a sub-folder of lib/features/<feature>/presentation/widgets/ named after a screen as described in the naming rules.
2. Every file in it is imported by at least one existing file (no orphan files, no empty folders).
3. Creating it moves no existing file, changes no existing path that other files import, and changes no behavior.
4. It is not under android/, ios/, test/, assets/, or any forbidden file or folder from section 2, and it does not touch any asset path in pubspec.yaml.
5. It does not need a new package, a pubspec change or an analysis_options change.
6. It holds at least 2 files, unless it is a folder listed in the target structure.

If any of these is false, or you want a folder that is not in the target structure (for example a new top-level folder under lib/ other than core/), STOP and ask me. Name every new folder and the reason in the report.

### Grouping and line limits (targets, not reasons to break a hard rule)

- Group closely related widgets in one file. Small widgets under about 80 lines must never get their own file, except the files listed in the target structure.
- Grouped widget file: aim for 100 to 300 lines, hard maximum 400. If a group would exceed 400, split it into two files, not more, and tell me.
- Single widget file (for example LocationPickerDialog): hard maximum 450 lines. If it is bigger, stop and tell me instead of splitting it.
- Helper, formatter or utility file: under 150 lines.
- Repository or data file: hard maximum 400 lines.
- Screen files: after extraction, aim for under 600 lines. Some screens will stay bigger because controllers, listeners, validation and action methods must stay in the State (hard rule 7). That is expected. Do NOT move State logic out just to reduce lines. Report the final line count.
- One public widget group per file. Private helper widgets used only inside one file may stay in that file.
- Extracted widgets hold no state that was in the screen's State. Pass data and callbacks through constructors.
- Every new file uses the same line endings and code style as the file it was copied from, and uses the project's existing import style (do not mix package: and relative imports in one file).
- Remove an import from the old screen only when flutter analyze reports it unused. Never add ignore comments.

## 4. Steps (in order; start a step only when I type START STEP followed by its number)

STEP 1: Shared price formatter. _formatPrice(num) exists three times (dorm_details_screen.dart, landlord_dormitory_details_screen.dart as a private method, dorm_dashboard_screen.dart as a top-level function). Compare them. If they produce identical output (peso sign, rounded, thousands separators), create lib/core/formatters.dart with one function formatPeso(num price) using the same logic and replace the three copies. If they differ at all, stop and show me the difference.

STEP 2: Shared amenity normalizer. _canonicalAmenity exists only in landlord_dormitory_details_screen.dart. Search all of lib/ for other amenity normalizing or comparing. Move the function unchanged into a small shared file (for example lib/features/dormitories/domain/amenity_utils.dart) and use it from the landlord screen. Do NOT merge or rename the amenity label lists: labels differ on screen ('WiFi' vs 'Wi-Fi') and UI text must not change. Report every place where amenity matching looks inconsistent, but do not fix it.

STEP 3: Leaf widgets from dorm_dashboard_screen.dart. Move ONLY these stateless private widgets into the grouped files listed in section 3b under lib/features/dormitories/presentation/widgets/dashboard/: _DashboardHeader, _DormitoryCard, _DormitoryPhotoPlaceholder, _DormitoryBadge, _DashboardMessage, _SeekerNavigationBar, _LandlordNavigationBar, _DashboardNavigationBarShell, _LandlordStatusChip. Make them public only as needed, keep const constructors. Do NOT touch _DormDashboardScreenState, _LandlordListingCard or the view-model wiring. Do 2 or 3 widgets per round and run analysis between rounds.

STEP 4: landlord_dormitory_details_screen.dart. Convert these builder methods into separate widget classes, grouped into the files listed in section 3b under lib/features/dormitories/presentation/widgets/landlord_details/: _photoGallery, _availabilityCard, _overviewCard, _descriptionCard, _amenitiesCard, _locationCard, _sectionCard, _sectionTitle, _metricTile, _amenityTile. Keep ALL state, listener setup in initState and dispose, and every action method (_toggleAvailability, _saveAvailableSlots, _deleteListing, _openEditForm) in the screen's State. Do NOT replace them with the existing seeker widgets in widgets/ unless the rendered output is provably identical. One widget at a time (several widgets may end up in the same grouped file).

STEP 5: add_dormitory_screen.dart, in two parts. Do 5a, then STOP and wait for me to test.
5a. Extract the inline map picker in _chooseLocation() (showDialog with StatefulBuilder, MapController, current-location lookup, Batangas City boundary check, address lookup) into its own widget, for example LocationPickerDialog, in lib/features/dormitories/presentation/widgets/add_dormitory/location_picker_dialog.dart. It must return the exact same type, (LatLng, String?), keep the same defaults (Batangas City center, zoom 15) and the same user-facing messages. _chooseLocation() becomes a short call to it.
5b. Only after I confirm 5a works: extract _roomTypesSection, _roomTypeOption, _amenitiesSection, _descriptionSection, _photosSection, _photoTile, _addMoreTile and _bottomActions into widgets, grouped into the files listed in section 3b under lib/features/dormitories/presentation/widgets/add_dormitory/. Controllers, the form key, the GlobalKeys used by _scrollToFirstInvalidField, _pickPhotos, _submit and all validation STAY in the screen's State, untouched. Do not change Cloudinary upload or how the listing is saved.

STEP 6 (DO NOT DO unless I type START STEP 6): move the direct Firebase calls out of profile_dashboard_screen.dart and add_dormitory_screen.dart into a new UserProfileRepository modeled on DormitoryRepository. Put it in a data/ folder in the same feature as profile_dashboard_screen.dart and show me the exact path in the PLAN before creating it. This is the riskiest change: identical queries, identical batch logic, identical error handling, keep the uid ownership check. Show old and new code side by side before editing.

STEP 7: Final safety review. Review the full diff as a strict code reviewer. For every changed file, report any: changed user-visible strings, labels or colors; changed constants or default values; changed null handling or async order; removed or altered mounted checks, dispose calls, controllers, listeners or keys; changed Firestore collection names, field names, queries, status or role values; changed imports; any edit to a forbidden file; any widget that lost its const, key or callback. List anything risky with file and line. Also report: any new file over its hard maximum, any orphan file or empty folder, any file or folder outside section 3b, any file name that does not match section 3b naming, any new public class name that already existed elsewhere, and any file that ended up with mixed line endings. Do not fix it yet.

## 5. Things to flag but NOT fix

- Amenity labels that differ between screens ('WiFi' vs 'Wi-Fi')
- The rules require status 'approved' on create, so new listings go live without admin review
- test/widget_test.dart is stale
- CLOUDINARY_SETUP.md says the Add Dormitory screen is "future" even though it exists

## 6. Your first reply

If my first message does NOT contain a START STEP command, do not edit or output any code. Reply with exactly:
1. The hard rules, summarized in 6 bullets or fewer
2. Whether you can run commands and read my files (yes or no)
3. The baseline commands I should run
4. Your PLAN for Step 1

Then wait for me to type START STEP 1.

If my first message DOES contain a START STEP command (for example "START STEP 3"), skip the summary and begin with that step's PLAN.
