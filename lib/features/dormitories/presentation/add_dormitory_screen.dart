import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app_notice.dart';
import '../../../theme/app_theme.dart';
import '../data/cloudinary_upload_service.dart';
import '../data/dorm_location_service.dart';
import '../data/dormitory_repository.dart';
import '../data/user_profile_repository.dart';
import '../domain/dormitory.dart';
import 'widgets/add_dormitory/add_dormitory_bottom_actions.dart';
import 'widgets/add_dormitory/amenities_description_sections.dart';
import 'widgets/add_dormitory/location_picker_dialog.dart';
import 'widgets/add_dormitory/photos_section.dart';
import 'widgets/add_dormitory/room_types_section.dart';

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
  static const int _maxMonthlyPrice = 99999;
  static const int _maxSlots = 99;
  static const List<(String, String, IconData)> _amenityOptions = [
    ('wifi', 'Wi-Fi', Icons.wifi_rounded),
    ('own_cr', 'Own CR', Icons.shower_rounded),
    ('kitchen', 'Kitchen', Icons.countertops_rounded),
    ('parking', 'Parking', Icons.local_parking_rounded),
    ('aircon', 'Aircon', Icons.ac_unit_rounded),
    ('laundry', 'Laundry', Icons.local_laundry_service_rounded),
  ];

  final _formKey = GlobalKey<FormState>();
  final _nameFieldKey = GlobalKey<FormFieldState<String>>();
  final _addressFieldKey = GlobalKey<FormFieldState<String>>();
  final _priceFieldKey = GlobalKey<FormFieldState<String>>();
  final _totalSlotsFieldKey = GlobalKey<FormFieldState<String>>();
  final _availableSlotsFieldKey = GlobalKey<FormFieldState<String>>();
  final _descriptionFieldKey = GlobalKey<FormFieldState<String>>();
  final _photosSectionKey = GlobalKey();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _priceController = TextEditingController();
  final _totalSlotsController = TextEditingController();
  final _availableSlotsController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imagePicker = ImagePicker();
  final _uploadService = CloudinaryUploadService();
  final _repository = DormitoryRepository();
  final _userProfileRepository = UserProfileRepository();
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
    _priceController.text = _formatIntegerWithCommas(
      dormitory.monthlyPrice.round().toString(),
    );
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
    final result = await showDialog<(LatLng, String?)>(
      context: context,
      builder: (dialogContext) => LocationPickerDialog(
        initialLocation: _location,
        initialAddress: _addressController.text.trim(),
        locationService: _locationService,
        onMessage: _showMessage,
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
    if (!_formKey.currentState!.validate()) {
      await _scrollToFirstInvalidField();
      return;
    }
    if (_isUploadingPhotos) {
      _showMessage('Wait for photo uploads to finish before saving.');
      return;
    }
    if (_photoUrls.isEmpty) {
      await _scrollTo(_photosSectionKey);
      _showMessage('Add at least one dormitory photo.');
      return;
    }

    final price = _parseIntegerInput(_priceController.text);
    final totalSlots = _parseIntegerInput(_totalSlotsController.text);
    final availableSlots = _parseIntegerInput(_availableSlotsController.text);
    if (price == null || price <= 0 || price > _maxMonthlyPrice) {
      _showMessage('Monthly rental price must be between ₱1 and ₱99,999.');
      return;
    }
    if (totalSlots == null || totalSlots <= 0 || totalSlots > _maxSlots) {
      _showMessage('Total slots must be between 1 and 99.');
      return;
    }
    if (availableSlots == null ||
        availableSlots < 0 ||
        availableSlots > _maxSlots ||
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
      final profileData = await _userProfileRepository.fetchUserProfile(
        widget.userId,
      );
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
        landlordPhotoUrl:
            currentUser.photoURL ?? widget.existingDormitory?.landlordPhotoUrl,
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
            landlordPhotoUrl: dormitory.landlordPhotoUrl,
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

  Future<void> _scrollToFirstInvalidField() async {
    final fieldKeys = [
      _nameFieldKey,
      _addressFieldKey,
      _priceFieldKey,
      _totalSlotsFieldKey,
      _availableSlotsFieldKey,
      _descriptionFieldKey,
    ];

    for (final key in fieldKeys) {
      if (key.currentState?.hasError != true) continue;
      await _scrollTo(key);
      return;
    }
  }

  Future<void> _scrollTo(GlobalKey key) async {
    final targetContext = key.currentContext;
    if (targetContext == null) return;
    await Scrollable.ensureVisible(
      targetContext,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      alignment: 0.2,
    );
  }

  String? _requiredText(String? value, String label) {
    if (value == null || value.trim().isEmpty) return '$label is required.';
    return null;
  }

  void _showMessage(String message) => AppNotice.show(context, message);

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
                        fieldKey: _nameFieldKey,
                        controller: _nameController,
                        label: 'Dormitory Name',
                        hint: 'e.g., University Heights Student Residence',
                        icon: Icons.storefront_outlined,
                        validator: (value) =>
                            _requiredText(value, 'Dormitory name'),
                      ),
                      const SizedBox(height: 14),
                      _textField(
                        fieldKey: _addressFieldKey,
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
                        fieldKey: _priceFieldKey,
                        controller: _priceController,
                        label: 'Monthly Rental Price (PHP)',
                        hint: '3,500',
                        icon: Icons.payments_outlined,
                        prefixText: '₱ ',
                        keyboardType: TextInputType.number,
                        inputFormatters: const [
                          _IntegerInputFormatter(
                            maxDigits: 5,
                            maxValue: _maxMonthlyPrice,
                            groupThousands: true,
                          ),
                        ],
                        validator: (value) {
                          final parsed = _parseIntegerInput(value);
                          if (parsed == null || parsed <= 0) {
                            return 'Enter a price greater than zero.';
                          }
                          return parsed > _maxMonthlyPrice
                              ? 'Maximum monthly price is ₱99,999.'
                              : null;
                        },
                        helperText:
                            'Standard rate per resident per month · Max ₱99,999',
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _textField(
                              fieldKey: _totalSlotsFieldKey,
                              controller: _totalSlotsController,
                              label: 'Total Slots',
                              hint: '16',
                              icon: Icons.bed_outlined,
                              keyboardType: TextInputType.number,
                              inputFormatters: const [
                                _IntegerInputFormatter(
                                  maxDigits: 2,
                                  maxValue: _maxSlots,
                                ),
                              ],
                              validator: (value) {
                                final parsed = _parseIntegerInput(value);
                                if (parsed == null || parsed <= 0) {
                                  return 'Enter at least 1.';
                                }
                                return parsed > _maxSlots
                                    ? 'Maximum is 99.'
                                    : null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _textField(
                              fieldKey: _availableSlotsFieldKey,
                              controller: _availableSlotsController,
                              label: 'Available Slots',
                              hint: '4',
                              icon: Icons.check_circle_outline_rounded,
                              keyboardType: TextInputType.number,
                              inputFormatters: const [
                                _IntegerInputFormatter(
                                  maxDigits: 2,
                                  maxValue: _maxSlots,
                                ),
                              ],
                              validator: (value) {
                                final available = _parseIntegerInput(value);
                                final total = _parseIntegerInput(
                                  _totalSlotsController.text,
                                );
                                if (available == null || available < 0) {
                                  return 'Enter 0 or more.';
                                }
                                if (available > _maxSlots) {
                                  return 'Maximum is 99.';
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

  Widget _section({
    Key? key,
    required String title,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      key: key,
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text.rich(
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
              ),
               ?trailing,
            ],
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
    Key? fieldKey,
    String? prefixText,
    String? helperText,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      key: fieldKey,
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      decoration: InputDecoration(
        label: _requiredLabel(label),
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 36,
          minHeight: 48,
        ),
        prefixText: prefixText,
        helperText: helperText,
        filled: true,
        fillColor: AppTheme.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
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
      child: RoomTypesSection(
        selectedRoomType: _roomType,
        isSaving: _isSaving,
        onSelect: (roomType) => setState(() {
          _roomType = _roomType == roomType ? null : roomType;
        }),
      ),
    );
  }

  Widget _amenitiesSection() {
    return _section(
      title: 'Amenities',
      child: AmenitiesSection(
        amenities: _amenities,
        options: _amenityOptions,
        onToggle: (key) => setState(() {
          if (_amenities.contains(key)) {
            _amenities.remove(key);
          } else {
            _amenities.add(key);
          }
        }),
      ),
    );
  }

  Widget _descriptionSection() {
    return _section(
      title: 'Description',
      child: DescriptionSection(
        controller: _descriptionController,
        fieldKey: _descriptionFieldKey,
        maxLength: _maxDescriptionLength,
        validator: (value) => _requiredText(value, 'Description'),
      ),
    );
  }

  Widget _photosSection() {
    return _section(
      key: _photosSectionKey,
      title: 'Dormitory Photos',
      trailing: Text(
        '${_photoUrls.length} / $_maxPhotos uploaded',
        style: Theme.of(context).textTheme.bodySmall
            ?.copyWith(color: AppTheme.onSurfaceVariant),
      ),
      child: PhotosSection(
        photoUrls: _photoUrls,
        maxPhotos: _maxPhotos,
        isUploading: _isUploadingPhotos,
        isSaving: _isSaving,
        onPickPhotos: _pickPhotos,
        onMakeCover: _makeCover,
        onRemovePhoto: _removePhoto,
      ),
    );
  }

  Widget _bottomActions() {
    return AddDormitoryBottomActions(
      isSaving: _isSaving,
      isUploadingPhotos: _isUploadingPhotos,
      isEditing: widget.isEditing,
      onCancel: () => Navigator.of(context).maybePop(),
      onSubmit: _submit,
    );
  }
}

int? _parseIntegerInput(String? value) =>
    int.tryParse(value?.replaceAll(',', '').trim() ?? '');

String _formatIntegerWithCommas(String value) {
  final digits = value.replaceAll(RegExp(r'\D'), '');
  return digits.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
}

class _IntegerInputFormatter extends TextInputFormatter {
  const _IntegerInputFormatter({
    required this.maxDigits,
    required this.maxValue,
    this.groupThousands = false,
  });

  final int maxDigits;
  final int maxValue;
  final bool groupThousands;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final cursorOffset = newValue.selection.extentOffset
        .clamp(0, newValue.text.length)
        .toInt();
    final digitsBeforeCursor = newValue.text
        .substring(0, cursorOffset)
        .replaceAll(RegExp(r'\D'), '')
        .length;
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final parsed = int.tryParse(digits);
    if (digits.length > maxDigits || (parsed != null && parsed > maxValue)) {
      return oldValue;
    }
    final formatted = groupThousands
        ? _formatIntegerWithCommas(digits)
        : digits;

    var formattedCursorOffset = 0;
    var countedDigits = 0;
    final targetDigitCount = digitsBeforeCursor
        .clamp(0, digits.length)
        .toInt();
    while (formattedCursorOffset < formatted.length &&
        countedDigits < targetDigitCount) {
      if (formatted.codeUnitAt(formattedCursorOffset) != 44) {
        countedDigits++;
      }
      formattedCursorOffset++;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formattedCursorOffset),
      composing: TextRange.empty,
    );
  }
}
