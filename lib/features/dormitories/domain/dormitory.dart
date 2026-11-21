enum DormRoomType {
  soloRoom('Solo Room'),
  bedspace('Bedspace');

  const DormRoomType(this.label);

  final String label;

  static DormRoomType? fromSavedValue(String value) {
    final normalized = value.toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]'),
      '',
    );
    return switch (normalized) {
      'soloroom' || 'singleroom' => DormRoomType.soloRoom,
      'bedspace' => DormRoomType.bedspace,
      _ => null,
    };
  }

  static List<String> currentLabels(Iterable<String> savedValues) =>
      savedValues
          .map(fromSavedValue)
          .whereType<DormRoomType>()
          .map((roomType) => roomType.label)
          .toSet()
          .toList(growable: false);
}

class Dormitory {
  const Dormitory({
    required this.id,
    required this.landlordId,
    required this.name,
    required this.address,
    required this.monthlyPrice,
    required this.availableSlots,
    required this.totalSlots,
    required this.amenities,
    required this.description,
    required this.photoUrls,
    required this.status,
    this.proximityLabel,
    this.averageRating,
    this.latitude,
    this.longitude,
    this.landlordName,
    this.landlordPhone,
    this.landlordPhotoUrl,
    this.roomTypes = const [],
    this.utilitiesIncluded = false,
  });

  final String id;
  final String landlordId;
  final String name;
  final String address;
  final num monthlyPrice;
  final int availableSlots;
  final int totalSlots;
  final List<String> amenities;
  final String description;
  final List<String> photoUrls;
  final String status;
  final String? proximityLabel;
  final double? averageRating;
  final double? latitude;
  final double? longitude;
  final String? landlordName;
  final String? landlordPhone;
  final String? landlordPhotoUrl;
  final List<String> roomTypes;
  final bool utilitiesIncluded;

  factory Dormitory.fromJson(Map<String, dynamic> json, {required String id}) {
    final rawPhotoUrls = json['photoUrls'];
    final photoUrls = rawPhotoUrls is List
        ? rawPhotoUrls.whereType<String>().toList()
        : <String>[];
    final coverImageUrl = json['coverImageUrl'];
    if (photoUrls.isEmpty &&
        coverImageUrl is String &&
        coverImageUrl.isNotEmpty) {
      photoUrls.add(coverImageUrl);
    }

    final rawAmenities = json['amenities'];
    final amenities = rawAmenities is List
        ? rawAmenities.whereType<String>().toList(growable: false)
        : <String>[];

    return Dormitory(
      id: id,
      landlordId: json['landlordId'] as String? ?? '',
      name: json['name'] as String? ?? 'Untitled dormitory',
      address: json['address'] as String? ?? '',
      monthlyPrice: json['monthlyPrice'] as num? ?? 0,
      availableSlots: (json['availableSlots'] as num?)?.toInt() ?? 0,
      totalSlots: (json['totalSlots'] as num?)?.toInt() ?? 0,
      amenities: List.unmodifiable(amenities),
      description: json['description'] as String? ?? '',
      photoUrls: List.unmodifiable(photoUrls),
      status: json['status'] as String? ?? 'pending',
      proximityLabel: json['proximityLabel'] as String?,
      averageRating: (json['averageRating'] as num?)?.toDouble(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      landlordName: json['landlordName'] as String?,
      landlordPhone: json['landlordPhone'] as String?,
      landlordPhotoUrl: json['landlordPhotoUrl'] as String?,
      roomTypes: json['roomTypes'] is List
          ? List.unmodifiable((json['roomTypes'] as List).whereType<String>())
          : const [],
      utilitiesIncluded: json['utilitiesIncluded'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'landlordId': landlordId,
    'name': name,
    'address': address,
    'monthlyPrice': monthlyPrice,
    'availableSlots': availableSlots,
    'totalSlots': totalSlots,
    'amenities': amenities,
    'description': description,
    'photoUrls': photoUrls,
    'status': status,
    if (proximityLabel != null) 'proximityLabel': proximityLabel,
    if (averageRating != null) 'averageRating': averageRating,
    if (latitude != null) 'latitude': latitude,
    if (longitude != null) 'longitude': longitude,
    if (landlordName != null) 'landlordName': landlordName,
    if (landlordPhone != null) 'landlordPhone': landlordPhone,
    if (landlordPhotoUrl != null) 'landlordPhotoUrl': landlordPhotoUrl,
    'roomTypes': roomTypes,
    'utilitiesIncluded': utilitiesIncluded,
  };
}
