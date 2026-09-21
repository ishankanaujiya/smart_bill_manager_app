import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

/// Service that uploads images to Cloudinary using an unsigned upload preset.
///
/// Mirrors the upload flow used elsewhere in the project: the selected image
/// file is POSTed as multipart form data to the Cloudinary upload endpoint,
/// and the returned `secure_url` is handed back to the caller so it can be
/// stored in Firestore.
class CloudinaryService {
  CloudinaryService({String? cloudName, String? uploadPreset})
      : _cloudName = cloudName ?? defaultCloudName,
        _uploadPreset = uploadPreset ?? defaultUploadPreset;

  /// Cloudinary cloud name configured for this app.
  static const String defaultCloudName = 'dbusoogfp';

  /// Unsigned upload preset configured for this app.
  static const String defaultUploadPreset = 'smart_bill_manager_app';

  final String _cloudName;
  final String _uploadPreset;

  /// Uploads [file] to Cloudinary and returns the `secure_url` of the
  /// uploaded asset.
  ///
  /// Returns `null` if the upload fails or the response does not contain
  /// a `secure_url`.
  Future<String?> uploadFile(File file) async {
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$_cloudName/upload',
    );

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = _uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final response = await request.send();
    if (response.statusCode != 200) return null;

    final body = await response.stream.bytesToString();
    final json = jsonDecode(body) as Map<String, dynamic>;
    return json['secure_url'] as String?;
  }
}
