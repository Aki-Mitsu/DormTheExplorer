/// Image metadata returned after a successful Cloudinary upload.
class CloudinaryUploadResult {
  const CloudinaryUploadResult({
    required this.secureUrl,
    required this.publicId,
    required this.format,
    required this.bytes,
  });

  factory CloudinaryUploadResult.fromJson(Map<String, dynamic> json) {
    final secureUrl = json['secure_url'];
    final publicId = json['public_id'];

    if (secureUrl is! String || publicId is! String) {
      throw const FormatException(
        'Cloudinary response is missing secure_url or public_id.',
      );
    }

    return CloudinaryUploadResult(
      secureUrl: secureUrl,
      publicId: publicId,
      format: json['format'] as String? ?? '',
      bytes: (json['bytes'] as num?)?.toInt() ?? 0,
    );
  }

  /// HTTPS image URL to store in Dormitory.photoUrls.
  final String secureUrl;
  final String publicId;
  final String format;
  final int bytes;
}
