/// Public client configuration for unsigned Cloudinary uploads.
///
/// Defaults to this project's Cloudinary account and unsigned upload preset.
/// These client values are public by design; never include the API secret.
class CloudinaryConfig {
  const CloudinaryConfig({
    required this.cloudName,
    required this.unsignedUploadPreset,
  });

  const CloudinaryConfig.fromEnvironment()
    : cloudName = const String.fromEnvironment(
        'CLOUDINARY_CLOUD_NAME',
        defaultValue: 'qnvu74gu',
      ),
      unsignedUploadPreset = const String.fromEnvironment(
        'CLOUDINARY_UPLOAD_PRESET',
        defaultValue: 'Dorm the Explorer',
      );

  final String cloudName;
  final String unsignedUploadPreset;

  bool get isConfigured =>
      cloudName.trim().isNotEmpty && unsignedUploadPreset.trim().isNotEmpty;
}
