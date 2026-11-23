/// Normalizes an amenity value to its canonical key: lowercased, stripped
/// of non-alphanumeric characters, with known aliases mapped to the keys
/// used by the amenity option lists (e.g. 'airconditioning' -> 'aircon').
String canonicalAmenity(String value) {
  final normalized = value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  return switch (normalized) {
    'wifi' || 'wififiber' => 'wifi',
    'owncr' || 'bathroom' => 'own_cr',
    'kitchen' || 'kitchenarea' => 'kitchen',
    'parking' || 'vehicleparking' => 'parking',
    'aircon' || 'airconditioning' => 'aircon',
    'laundry' || 'laundryarea' => 'laundry',
    _ => normalized,
  };
}
