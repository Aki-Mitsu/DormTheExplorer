import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../config/cloudinary_config.dart';
import '../domain/cloudinary_upload_result.dart';

/// Uploads dormitory photos directly to Cloudinary with an unsigned preset.
///
/// The API secret must never be included in this app. Restrict the upload
/// preset in Cloudinary because unsigned uploads can be called by app users.
class CloudinaryUploadService {
  CloudinaryUploadService({
    this._config = const CloudinaryConfig.fromEnvironment(),
    http.Client? client,
    this.maxUploadBytes = 10 * 1024 * 1024,
  }) : _client = client ?? http.Client(),
       _ownsClient = client == null;

  final CloudinaryConfig _config;
  final http.Client _client;
  final bool _ownsClient;

  /// Client-side guardrail; configure Cloudinary preset restrictions as well.
  final int maxUploadBytes;

  /// Uploads one local image and returns its HTTPS URL and Cloudinary ID.
  ///
  /// Pass the path from an image picker, for example File(pickedFile.path).
  /// Persist CloudinaryUploadResult.secureUrl in the dormitory's photoUrls.
  Future<CloudinaryUploadResult> uploadImage(File imageFile) async {
    if (!_config.isConfigured) {
      throw StateError(
        'Cloudinary is not configured. Provide CLOUDINARY_CLOUD_NAME and '
        'CLOUDINARY_UPLOAD_PRESET using --dart-define.',
      );
    }

    if (!await imageFile.exists()) {
      throw ArgumentError.value(imageFile.path, 'imageFile', 'File not found.');
    }

    final fileLength = await imageFile.length();
    if (fileLength == 0) {
      throw ArgumentError.value(imageFile.path, 'imageFile', 'File is empty.');
    }
    if (fileLength > maxUploadBytes) {
      throw ArgumentError.value(
        fileLength,
        'imageFile',
        'Image exceeds the ${maxUploadBytes ~/ (1024 * 1024)} MB upload limit.',
      );
    }

    final uri = Uri.https(
      'api.cloudinary.com',
      '/v1_1/${_config.cloudName}/image/upload',
    );
    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = _config.unsignedUploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    final response = await _client.send(request);
    final responseText = await response.stream.bytesToString();
    final dynamic decoded;
    try {
      decoded = jsonDecode(responseText);
    } on FormatException {
      throw CloudinaryUploadException(
        'Cloudinary returned an unreadable response (HTTP ${response.statusCode}).',
      );
    }

    if (decoded is! Map<String, dynamic>) {
      throw const CloudinaryUploadException(
        'Cloudinary returned an unexpected response.',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final error = decoded['error'];
      final message = error is Map<String, dynamic>
          ? error['message'] as String?
          : null;
      final cloudinaryDiagnostic = response.headers['x-cld-error'];
      final details = <String>[
        'Cloudinary upload failed (HTTP ${response.statusCode}).',
        if (message != null && message.isNotEmpty) message,
        if (cloudinaryDiagnostic != null &&
            cloudinaryDiagnostic.isNotEmpty &&
            cloudinaryDiagnostic != message)
          'Cloudinary diagnostic: $cloudinaryDiagnostic',
        'Request cloud: ${_config.cloudName}; preset: ${_config.unsignedUploadPreset}.',
      ];
      throw CloudinaryUploadException(details.join(' '));
    }

    try {
      return CloudinaryUploadResult.fromJson(decoded);
    } on FormatException catch (error) {
      throw CloudinaryUploadException(error.message);
    }
  }

  /// Closes the internally-created HTTP client.
  void close() {
    if (_ownsClient) {
      _client.close();
    }
  }
}

/// Error returned for Cloudinary configuration or response failures.
class CloudinaryUploadException implements Exception {
  const CloudinaryUploadException(this.message);

  final String message;

  @override
  String toString() => 'CloudinaryUploadException: $message';
}
