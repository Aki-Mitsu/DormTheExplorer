/// Formats [price] as a peso amount: rounded to whole pesos with
/// thousands separators, prefixed by the peso sign (e.g. '₱12,500').
String formatPeso(num price) {
  final roundedPrice = price.round().toString();
  final groupedPrice = roundedPrice.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  return '₱$groupedPrice';
}
