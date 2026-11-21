import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../theme/app_theme.dart';
import '../data/batangas_city_boundary.dart';
import '../data/cloudinary_upload_service.dart';
import '../data/dorm_location_service.dart';
import '../data/dormitory_repository.dart';
import '../domain/dormitory.dart';

class AddDormitoryScreen extends StatefulWidget {
  const AddDormitoryScreen({
    super.key,
    required this.userId,
    this.existingDormitory,
  });

  final String userId;
  final Dormitory? existingDormitory;

  bool get isEditing => existingDormitory != null;

  @override
  State<AddDormitoryScreen> createState() => _AddDormitoryScreenState();
}

class _AddDormitoryScreenState extends State<AddDormitoryScreen> {
  static const int _maxPhotos = 5;
  static const int _maxDescriptionLength = 500;
  static const List<(String, String, IconData)> _amenityOptions = [
    ('wifi', 'Wi-Fi', Icons.wifi_rounded),
    ('own_cr', 'Own CR', Icons.shower_rounded),
    ('kitchen', 'Kitchen', Icons.countertops_rounded),
    ('parking', 'Parking', Icons.local_parking_rounded),
    ('aircon', 'Aircon', Icons.ac_unit_rounded),
    ('laundry', 'Laundry', Icons.local_laundry_service_rounded),
  ];

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _priceController = TextEditingController();
  final _totalSlotsController = TextEditingController();
  final _availableSlotsController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imagePicker = ImagePicker();
  final _uploadService = CloudinaryUploadService();
  final _repository = DormitoryRepository();
  final _locationService = DormLocationService();
  final Set<String> _amenities = {};
  final List<String> _photoUrls = [];
  DormRoomType? _roomType;

  LatLng _location = const LatLng(13.7565, 121.0583);
  bool _isUploadingPhotos = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final dormitory = widget.existingDormitory;
    if (dormitory == null) return;

    _nameController.text = dormitory.name;
    _addressController.text = dormitory.address;
    _priceController.text = dormitory.monthlyPrice.toString();
    _totalSlotsController.text = dormitory.totalSlots.toString();
    _availableSlotsController.text = dormitory.availableSlots.toString();
    _descriptionController.text = dormitory.description;
    _amenities.addAll(dormitory.amenities);
    _roomType = dormitory.roomTypes
        .map(DormRoomType.fromSavedValue)
        .whereType<DormRoomType>()
        .firstOrNull;
    _photoUrls.addAll(dormitory.photoUrls);
    if (dormitory.latitude != null && dormitory.longitude != null) {
      _location = LatLng(dormitory.latitude!, dormitory.longitude!);
    }
  }

  @override
  void dispose() {
    _uploadService.close();
    _locationService.close();
    _nameController.dispose();
    _addressController.dispose();
    _priceController.dispose();
    _totalSlotsController.dispose();
    _availableSlotsController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickPhotos() async {
    if (_isUploadingPhotos || _isSaving) return;
    final remaining = _maxPhotos - _photoUrls.length;
    if (remaining <= 0) {
      _showMessage('You can add up to $_maxPhotos photos.');
      return;
    }

    try {
      final selected = await _imagePicker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 1600,
      );
      if (!mounted || selected.isEmpty) return;

      final files = selected.take(remaining).toList(growable: false);
      if (selected.length > remaining) {
        _showMessage('Only the first $remaining selected photos will be added.');
      }
      setState(() => _isUploadingPhotos = true);

      var failed = 0;
      for (final image in files) {
        try {
          final result = await _uploadService.uploadImage(File(image.path));
          if (!mounted) return;
          setState(() => _photoUrls.add(result.secureUrl));
        } catch (error) {
          failed++;
          if (!mounted) return;
          _showMessage(_uploadErrorMessage(error));
        }
      }
      if (mounted && failed == 0 && files.isNotEmpty) {
        _showMessage('Photos uploaded successfully.');
      }
    } catch (error) {
      if (mounted) _showMessage(_uploadErrorMessage(error));
    } finally {
      if (mounted) setState(() => _isUploadingPhotos = false);
    }
  }

  String _uploadErrorMessage(Object error) => switch (error) {
    CloudinaryUploadException(:final message) => message,
    StateError(:final message) => message,
    _ => 'Could not upload the selected photo. Please try again.',
  };

  void _removePhoto(int index) {
    setState(() => _photoUrls.removeAt(index));
  }

  void _makeCover(int index) {
    if (index == 0) return;
    setState(() {
      final photo = _photoUrls.removeAt(index);
      _photoUrls.insert(0, photo);
    });
  }

  Future<void> _chooseLocation() async {
    var selectedLocation = _location;
    var selectedAddress = _addressController.text.trim();
    var selectionChanged = false;
    if (!_locationService.isWithinBatangasCity(selectedLocation)) {
      selectedLocation = const LatLng(13.7565, 121.0583);
      selectedAddress = '';
      selectionChanged = true;
    }
    if (selectedAddress.isEmpty) selectedAddress = '';
    var isLocating = false;
    var isResolvingAddress = false;
    var isReturningToCity = false;
    var lastValidMapCenter = selectedLocation;
    var lastValidMapZoom = 15.0;
    String? locationMessage;
    final mapController = MapController();

    final result = await showDialog<(LatLng, String?)>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          Future<void> useCurrentLocation() async {
            setDialogState(() => isLocating = true);
            try {
              final location = await _locationService.getCurrentLocation();
              if (!dialogContext.mounted) return;
              if (!_locationService.isWithinBatangasCity(location)) {
                setDialogState(
                  () => locationMessage =
                      'Your current location is outside Batangas City. '
                      'Choose a pin within the outlined area.',
                );
                return;
              }

              lastValidMapCenter = location;
              lastValidMapZoom = 16;
              mapController.move(location, 16);
              setDialogState(() {
                selectedLocation = location;
                selectedAddress = '';
                selectionChanged = true;
                locationMessage = null;
              });

              try {
                final address = await _locationService.reverseGeocode(location);
                if (!dialogContext.mounted) return;
                setDialogState(() => selectedAddress = address ?? '');
                if (address == null && mounted) {
                  _showMessage(
                    'Location found. Enter the street address manually.',
                  );
                }
              } catch (_) {
                if (mounted) {
                  _showMessage(
                    'Location found, but its address could not be looked up. '
                    'Enter it manually.',
                  );
                }
              }
            } on DormLocationException catch (error) {
              if (!dialogContext.mounted) return;
              if (error.issue == DormLocationIssue.servicesDisabled) {
                final openSettings = await showDialog<bool>(
                  context: dialogContext,
                  builder: (promptContext) => AlertDialog(
                    title: const Text('Turn on location'),
                    content: const Text(
                      'Enable your phone location services to use your current position.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(promptContext, false),
                        child: const Text('Not now'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(promptContext, true),
                        child: const Text('Open settings'),
                      ),
                    ],
                  ),
                );
                if (openSettings == true) {
                  await _locationService.openLocationSettings();
                }
              } else if (error.issue ==
                  DormLocationIssue.permissionDeniedForever) {
                final openSettings = await showDialog<bool>(
                  context: dialogContext,
                  builder: (promptContext) => AlertDialog(
                    title: const Text('Location permission needed'),
                    content: const Text(
                      'Allow location access in app settings, or keep placing the pin manually.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(promptContext, false),
                        child: const Text('Not now'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(promptContext, true),
                        child: const Text('Open settings'),
                      ),
                    ],
                  ),
                );
                if (openSettings == true) {
                  await _locationService.openAppSettings();
                }
              } else if (mounted) {
                _showMessage(error.message);
              }
            } catch (_) {
              if (mounted) {
                _showMessage(
                  'Could not get your current location. You can place the pin manually.',
                );
              }
            } finally {
              if (dialogContext.mounted) {
                setDialogState(() => isLocating = false);
              }
            }
          }

          Future<void> confirmLocation() async {
            if (locationMessage != null) return;
            if (!_locationService.isWithinBatangasCity(selectedLocation)) {
              setDialogState(
                () => locationMessage =
                    'Choose a pin within Batangas City to continue.',
              );
              return;
            }
            if (!selectionChanged && selectedAddress.isNotEmpty) {
              Navigator.pop(
                dialogContext,
                (selectedLocation, selectedAddress),
              );
              return;
            }

            setDialogState(() {
              isResolvingAddress = true;
              locationMessage = null;
            });
            String? address;
            try {
              address = await _locationService.reverseGeocode(selectedLocation);
            } catch (_) {
              address = null;
            }
            if (!dialogContext.mounted) return;
            Navigator.pop(
              dialogContext,
              (selectedLocation, address),
            );
            if ((address == null || address.isEmpty) && mounted) {
              _showMessage(
                'Pin saved within Batangas City. Enter the complete address manually.',
              );
            }
          }

          return Dialog(
            insetPadding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Choose dormitory location',
                      style: Theme.of(dialogContext).textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Choose a point inside the Batangas City boundary, or use your current location.',
                      style: Theme.of(dialogContext).textTheme.bodySmall
                          ?.copyWith(color: AppTheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: isLocating || isResolvingAddress
                          ? null
                          : useCurrentLocation,
                      icon: isLocating
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.my_location_rounded),
                      label: Text(
                        isLocating
                            ? 'Finding your location…'
                            : 'Use my current location',
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SizedBox(
                        height: MediaQuery.sizeOf(dialogContext).height * 0.40,
                        child: FlutterMap(
                          mapController: mapController,
                          options: MapOptions(
                            initialCenter: selectedLocation,
                            initialZoom: 15,
                            cameraConstraint: CameraConstraint.contain(
                              bounds: BatangasCityBoundary.mapBounds,
                            ),
                            onPositionChanged: (camera, hasGesture) {
                              if (isReturningToCity) return;
                              if (_locationService.isWithinBatangasCity(
                                camera.center,
                              )) {
                                lastValidMapCenter = camera.center;
                                lastValidMapZoom = camera.zoom;
                                return;
                              }
                              if (!hasGesture) return;
                              isReturningToCity = true;
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (!dialogContext.mounted) return;
                                mapController.move(
                                  lastValidMapCenter,
                                  lastValidMapZoom,
                                );
                                isReturningToCity = false;
                              });
                            },
                            onTap: (tapPosition, point) {
                              if (!_locationService.isWithinBatangasCity(point)) {
                                setDialogState(
                                  () => locationMessage =
                                      'That point is outside Batangas City. '
                                      'Choose a point inside the outlined area.',
                                );
                                return;
                              }
                              setDialogState(() {
                                selectedLocation = point;
                                selectedAddress = '';
                                selectionChanged = true;
                                locationMessage = null;
                              });
                            },
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              tileProvider: NetworkTileProvider(
                                cachingProvider:
                                    const DisabledMapCachingProvider(),
                              ),
                              userAgentPackageName:
                                  'dormtheexplorer.app.dorm_the_explorer',
                              maxNativeZoom: 19,
                            ),
                            PolygonLayer(
                              polygons: [
                                Polygon(
                                  points: BatangasCityBoundary.mapBoundsRing,
                                  holePointsList: BatangasCityBoundary.polygons,
                                  color: AppTheme.onSurface.withValues(
                                    alpha: 0.28,
                                  ),
                                  borderStrokeWidth: 0,
                                  disableHolesBorder: true,
                                ),
                                for (final boundary
                                    in BatangasCityBoundary.polygons)
                                  Polygon(
                                    points: boundary,
                                    color: const Color(0x00000000),
                                    borderColor: AppTheme.primaryContainer,
                                    borderStrokeWidth: 2,
                                  ),
                              ],
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: selectedLocation,
                                  width: 48,
                                  height: 52,
                                  child: const Icon(
                                    Icons.location_on_rounded,
                                    size: 46,
                                    color: AppTheme.primaryContainer,
                                  ),
                                ),
                              ],
                            ),
                            RichAttributionWidget(
                              alignment: AttributionAlignment.bottomRight,
                              attributions: [
                                TextSourceAttribution(
                                  '© OpenStreetMap contributors',
                                  onTap: () => launchUrl(
                                    Uri.parse(
                                      'https://www.openstreetmap.org/copyright',
                                    ),
                                    mode: LaunchMode.externalApplication,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${selectedLocation.latitude.toStringAsFixed(5)}, '
                      '${selectedLocation.longitude.toStringAsFixed(5)}',
                      textAlign: TextAlign.center,
                      style: Theme.of(dialogContext).textTheme.labelMedium,
                    ),
                    if (locationMessage != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        locationMessage!,
                        textAlign: TextAlign.center,
                        style: Theme.of(dialogContext).textTheme.bodySmall
                            ?.copyWith(color: AppTheme.error),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isLocating || isResolvingAddress
                                ? null
                                : () => Navigator.pop(dialogContext),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton(
                            onPressed: isLocating || isResolvingAddress
                                ? null
                                : confirmLocation,
                            child: isResolvingAddress
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppTheme.onPrimary,
                                    ),
                                  )
                                : const Text('Use this location'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
    if (result != null && mounted) {
      setState(() {
        _location = result.$1;
        _addressController.text = result.$2 ?? '';
      });
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    if (_isUploadingPhotos) {
      _showMessage('Wait for photo uploads to finish before saving.');
      return;
    }
    if (_photoUrls.isEmpty) {
      _showMessage('Add at least one dormitory photo.');
      return;
    }

    final price = num.tryParse(_priceController.text.trim());
    final totalSlots = int.tryParse(_totalSlotsController.text.trim());
    final availableSlots = int.tryParse(_availableSlotsController.text.trim());
    if (price == null || price <= 0) {
      _showMessage('Enter a monthly price greater than zero.');
      return;
    }
    if (totalSlots == null || totalSlots <= 0) {
      _showMessage('Enter at least one total slot.');
      return;
    }
    if (availableSlots == null ||
        availableSlots < 0 ||
        availableSlots > totalSlots) {
      _showMessage('Available slots must be between zero and total slots.');
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || currentUser.uid != widget.userId) {
      _showMessage('Your session expired. Please sign in again.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final profile = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();
      final profileData = profile.data() ?? const <String, dynamic>{};
      final landlordName =
          (profileData['fullName'] as String?)?.trim().isNotEmpty == true
          ? (profileData['fullName'] as String).trim()
          : currentUser.displayName ?? currentUser.email?.split('@').first;
      final landlordPhone = (profileData['phone'] as String?)?.trim();

      final dormitory = Dormitory(
        id: '',
        landlordId: widget.userId,
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        monthlyPrice: price,
        availableSlots: availableSlots,
        totalSlots: totalSlots,
        amenities: List.unmodifiable(_amenities),
        description: _descriptionController.text.trim(),
        roomTypes: _roomType == null
            ? const []
            : List.unmodifiable([_roomType!.label]),
        photoUrls: List.unmodifiable(_photoUrls),
        status: widget.existingDormitory?.status ?? 'approved',
        proximityLabel: widget.existingDormitory?.proximityLabel,
        averageRating: widget.existingDormitory?.averageRating,
        latitude: _location.latitude,
        longitude: _location.longitude,
        landlordName: landlordName,
        landlordPhone: landlordPhone == null || landlordPhone.isEmpty
            ? widget.existingDormitory?.landlordPhone
            : landlordPhone,
      );
      final existingDormitory = widget.existingDormitory;
      if (existingDormitory == null) {
        await _repository.addDormitory(dormitory);
      } else {
        await _repository.updateDormitory(
          Dormitory(
            id: existingDormitory.id,
            landlordId: dormitory.landlordId,
            name: dormitory.name,
            address: dormitory.address,
            monthlyPrice: dormitory.monthlyPrice,
            availableSlots: dormitory.availableSlots,
            totalSlots: dormitory.totalSlots,
            amenities: dormitory.amenities,
            description: dormitory.description,
            photoUrls: dormitory.photoUrls,
            status: dormitory.status,
            proximityLabel: dormitory.proximityLabel,
            averageRating: dormitory.averageRating,
            latitude: dormitory.latitude,
            longitude: dormitory.longitude,
            landlordName: dormitory.landlordName,
            landlordPhone: dormitory.landlordPhone,
            roomTypes: dormitory.roomTypes,
            utilitiesIncluded: existingDormitory.utilitiesIncluded,
          ),
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        _showMessage(
          error is FirebaseException
              ? error.message ?? 'Could not save the dormitory.'
              : 'Could not save the dormitory. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String? _requiredText(String? value, String label) {
    if (value == null || value.trim().isEmpty) return '$label is required.';
    return null;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Cancel or go back',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.close_rounded),
        ),
        title: Text(
          widget.isEditing ? 'Edit Dormitory' : 'Add Dormitory',
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppTheme.surface.withValues(alpha: 0.96),
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _section(
                  title: 'Basic Information',
                  child: Column(
                    children: [
                      _textField(
                        controller: _nameController,
                        label: 'Dormitory Name',
                        hint: 'e.g., University Heights Student Residence',
                        icon: Icons.storefront_outlined,
                        validator: (value) =>
                            _requiredText(value, 'Dormitory name'),
                      ),
                      const SizedBox(height: 14),
                      _textField(
                        controller: _addressController,
                        label: 'Complete Address',
                        hint:
                            'e.g., 104 Rizal Avenue, Brgy. Poblacion, Batangas City',
                        icon: Icons.near_me_outlined,
                        validator: (value) =>
                            _requiredText(value, 'Complete address'),
                        helperText:
                            'Pin a location or use your current location to '
                            'fill this address automatically. You can edit it.',
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _isSaving ? null : _chooseLocation,
                        icon: const Icon(Icons.add_location_alt_outlined),
                        label: const Text('Pin location to fill address'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryContainer,
                          minimumSize: const Size.fromHeight(44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _textField(
                        controller: _priceController,
                        label: 'Monthly Rental Price (PHP)',
                        hint: '3,500',
                        icon: Icons.payments_outlined,
                        prefixText: '₱ ',
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          final parsed = num.tryParse(value?.trim() ?? '');
                          return parsed == null || parsed <= 0
                              ? 'Enter a price greater than zero.'
                              : null;
                        },
                        helperText:
                            'Standard rate per resident per month',
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _textField(
                              controller: _totalSlotsController,
                              label: 'Total Slots',
                              hint: '16',
                              icon: Icons.bed_outlined,
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                final parsed =
                                    int.tryParse(value?.trim() ?? '');
                                return parsed == null || parsed <= 0
                                    ? 'Enter at least 1.'
                                    : null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _textField(
                              controller: _availableSlotsController,
                              label: 'Available Slots',
                              hint: '4',
                              icon: Icons.check_circle_outline_rounded,
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                final available =
                                    int.tryParse(value?.trim() ?? '');
                                final total = int.tryParse(
                                  _totalSlotsController.text.trim(),
                                );
                                if (available == null || available < 0) {
                                  return 'Enter 0 or more.';
                                }
                                if (total == null || available > total) {
                                  return 'Cannot exceed total.';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _roomTypesSection(),
                const SizedBox(height: 14),
                _amenitiesSection(),
                const SizedBox(height: 14),
                _descriptionSection(),
                const SizedBox(height: 14),
                _photosSection(),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _bottomActions(),
    );
  }

  Widget _section({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.onSurface.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text.rich(
            TextSpan(
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
              children: [
                TextSpan(text: title),
                if (title == 'Description' ||
                    title == 'Dormitory Photos')
                  const TextSpan(
                    text: ' *',
                    style: TextStyle(color: AppTheme.primaryContainer),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? prefixText,
    String? helperText,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        label: _requiredLabel(label),
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        prefixText: prefixText,
        helperText: helperText,
        filled: true,
        fillColor: AppTheme.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppTheme.primaryContainer,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppTheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppTheme.error, width: 2),
        ),
      ),
    );
  }

  Widget _requiredLabel(String label) => RichText(
    text: TextSpan(
      style: Theme.of(context).textTheme.labelLarge
          ?.copyWith(color: AppTheme.onSurface),
      children: [
        TextSpan(text: label),
        const TextSpan(
          text: ' *',
          style: TextStyle(color: AppTheme.primaryContainer),
        ),
      ],
    ),
  );

  Widget _roomTypesSection() {
    return _section(
      title: 'Room Types',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose one room type.',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: AppTheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: DormRoomType.values
                .map(_roomTypeOption)
                .toList(growable: false),
          ),
        ],
      ),
    );
  }

  Widget _roomTypeOption(DormRoomType roomType) {
    final selected = _roomType == roomType;

    return Material(
      color: selected
          ? AppTheme.primaryContainer
          : AppTheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: _isSaving
            ? null
            : () => setState(() {
                _roomType = selected ? null : roomType;
              }),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: const BoxConstraints(minHeight: 42),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? AppTheme.primaryContainer
                  : AppTheme.outline.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                roomType.label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: selected ? AppTheme.onPrimary : AppTheme.onSurface,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 18,
                color: selected ? AppTheme.onPrimary : AppTheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _amenitiesSection() {
    return _section(
      title: 'Amenities',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Select all available',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: AppTheme.onSurfaceVariant),
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth < 370 ? 1 : 2;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _amenityOptions.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisExtent: 48,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemBuilder: (context, index) {
                  final (key, label, icon) = _amenityOptions[index];
                  final selected = _amenities.contains(key);
                  return InkWell(
                    onTap: () => setState(() {
                      if (selected) {
                        _amenities.remove(key);
                      } else {
                        _amenities.add(key);
                      }
                    }),
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppTheme.primaryContainer
                            : AppTheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            icon,
                            size: 19,
                            color: selected
                                ? AppTheme.onPrimary
                                : AppTheme.onSurface,
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              label,
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(
                                    color: selected
                                        ? AppTheme.onPrimary
                                        : AppTheme.onSurface,
                                  ),
                            ),
                          ),
                          Icon(
                            selected
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked_rounded,
                            size: 18,
                            color: selected
                                ? AppTheme.onPrimary
                                : AppTheme.outline,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _descriptionSection() {
    return _section(
      title: 'Description',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _descriptionController,
            maxLength: _maxDescriptionLength,
            minLines: 4,
            maxLines: 6,
            textCapitalization: TextCapitalization.sentences,
            validator: (value) => _requiredText(value, 'Description'),
            decoration: InputDecoration(
              hintText:
                  'Describe room inclusions, study areas, water/electricity terms, curfew rules, and distance to nearby universities...',
              filled: true,
              fillColor: AppTheme.surfaceContainerLow,
              alignLabelWithHint: true,
              contentPadding: const EdgeInsets.all(14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: AppTheme.primaryContainer,
                  width: 2,
                ),
              ),
              counterStyle: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(color: AppTheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }


  Widget _photosSection() {
    return _section(
      title: 'Dormitory Photos',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${_photoUrls.length} / $_maxPhotos uploaded',
                  textAlign: TextAlign.end,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: AppTheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: _isUploadingPhotos || _isSaving ? null : _pickPhotos,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryContainer.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppTheme.primaryContainer.withValues(alpha: 0.12),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerLowest,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.onSurface.withValues(alpha: 0.08),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.add_a_photo_outlined,
                      color: AppTheme.primaryContainer,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isUploadingPhotos
                        ? 'Uploading photos…'
                        : 'Tap to select photos from gallery',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppTheme.primaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Room, study area and bathroom photos help students compare listings.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: AppTheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'JPG, PNG or WebP · up to 10 MB each · max $_maxPhotos',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelSmall
                        ?.copyWith(color: AppTheme.onSurfaceVariant),
                  ),
                  if (_isUploadingPhotos) ...[
                    const SizedBox(height: 10),
                    const LinearProgressIndicator(minHeight: 2),
                  ],
                ],
              ),
            ),
          ),
          if (_photoUrls.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 116,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _photoUrls.length +
                    (_photoUrls.length < _maxPhotos ? 1 : 0),
                separatorBuilder: (_, index) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  if (index == _photoUrls.length) {
                    return _addMoreTile();
                  }
                  return _photoTile(index);
                },
              ),
            ),
          ] else ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _isUploadingPhotos || _isSaving ? null : _pickPhotos,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add photos'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _photoTile(int index) {
    return SizedBox(
      width: 112,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.network(
              _photoUrls[index],
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: AppTheme.surfaceContainerHigh,
                alignment: Alignment.center,
                child: const Icon(Icons.broken_image_outlined),
              ),
            ),
          ),
          if (index == 0)
            Positioned(
              left: 6,
              bottom: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Cover',
                  style: Theme.of(context).textTheme.labelSmall
                      ?.copyWith(color: AppTheme.onPrimary),
                ),
              ),
            )
          else
            Positioned(
              left: 4,
              bottom: 2,
              child: IconButton(
                tooltip: 'Set as cover photo',
                onPressed: _isSaving ? null : () => _makeCover(index),
                icon: const Icon(Icons.photo_outlined, size: 18),
                color: AppTheme.onPrimary,
              ),
            ),
          Positioned(
            top: 2,
            right: 2,
            child: IconButton.filledTonal(
              tooltip: 'Remove photo',
              onPressed: _isSaving ? null : () => _removePhoto(index),
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.close_rounded, size: 17),
              style: IconButton.styleFrom(
                backgroundColor: AppTheme.onSurface.withValues(alpha: 0.72),
                foregroundColor: AppTheme.onPrimary,
                minimumSize: const Size(30, 30),
                padding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _addMoreTile() {
    return SizedBox(
      width: 92,
      child: OutlinedButton(
        onPressed: _isUploadingPhotos || _isSaving ? null : _pickPhotos,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppTheme.surfaceContainerLow,
          side: BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, color: AppTheme.primaryContainer),
            const SizedBox(height: 3),
            Text(
              'Add More',
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(color: AppTheme.primaryContainer),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bottomActions() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLowest.withValues(alpha: 0.96),
          boxShadow: [
            BoxShadow(
              color: AppTheme.onSurface.withValues(alpha: 0.10),
              blurRadius: 24,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: FilledButton(
                    onPressed: _isSaving || _isUploadingPhotos
                        ? null
                        : () => Navigator.of(context).maybePop(),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.surfaceContainerHigh,
                      foregroundColor: AppTheme.onSurface,
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed:
                        _isSaving || _isUploadingPhotos ? null : _submit,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.onPrimary,
                            ),
                          )
                        : const Icon(Icons.arrow_forward_rounded, size: 20),
                    label: Text(
            _isSaving
                ? 'Saving…'
                : widget.isEditing
                ? 'Save Changes'
                : 'Add Dormitory',
          ),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      backgroundColor: AppTheme.primaryContainer,
                      foregroundColor: AppTheme.onPrimary,
                      elevation: 2,
                      shadowColor:
                          AppTheme.primaryContainer.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
