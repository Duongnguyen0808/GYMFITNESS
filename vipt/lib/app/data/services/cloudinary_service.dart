import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CloudinaryService {
  CloudinaryService._privateConstructor();
  static final CloudinaryService instance =
      CloudinaryService._privateConstructor();

  String get cloudName => dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? 'daouokjft';

  String get apiKey => dotenv.env['CLOUDINARY_API_KEY'] ?? '484939797711948';

  String get apiSecret =>
      dotenv.env['CLOUDINARY_API_SECRET'] ?? 'c9jQOQvOpF6oNyt6VVBCp_okquQ';

  String get uploadPreset =>
      dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ?? 'Fitness_uploads';

  String get baseUrl => 'https://api.cloudinary.com/v1_1/$cloudName';
  String get imageUrl => 'https://res.cloudinary.com/$cloudName/image/upload';
  String get videoUrl => 'https://res.cloudinary.com/$cloudName/video/upload';

  String _generateSignature(Map<String, dynamic> params) {
    final sortedParams = Map.fromEntries(
        params.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));

    final queryString =
        sortedParams.entries.map((e) => '${e.key}=${e.value}').join('&');

    final signatureString = '$queryString$apiSecret';

    final bytes = utf8.encode(signatureString);
    final hash = sha1.convert(bytes);

    return hash.toString();
  }

  /// Upload image from File and return Cloudinary URL
  Future<String> uploadImage(File file, String folder) async {
    try {
      final bytes = await file.readAsBytes();
      return await uploadImageBytes(bytes, folder, file.path.split('.').last);
    } catch (e) {
      rethrow;
    }
  }

  /// Upload video from File and return Cloudinary URL
  Future<String> uploadVideo(File file, String folder) async {
    try {
      final bytes = await file.readAsBytes();
      return await uploadVideoBytes(bytes, folder, file.path.split('.').last);
    } catch (e) {
      rethrow;
    }
  }

  /// Upload image from bytes (for web) and return Cloudinary URL
  Future<String> uploadImageBytes(Uint8List bytes, String folder,
      [String? format]) async {
    try {
      final params = <String, dynamic>{};

      if (uploadPreset.isNotEmpty) {
        params['upload_preset'] = uploadPreset;
        if (folder.isNotEmpty) {
          params['folder'] = folder;
        }
      } else {
        final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
        params['timestamp'] = timestamp;
        params['api_key'] = apiKey;
        if (folder.isNotEmpty) {
          params['folder'] = folder;
        }
        final signature = _generateSignature(params);
        params['signature'] = signature;
      }

      final uri = Uri.parse('$baseUrl/image/upload');
      final request = http.MultipartRequest('POST', uri);

      params.forEach((key, value) {
        request.fields[key] = value.toString();
      });

      final fileName =
          'image_${DateTime.now().millisecondsSinceEpoch}.${format ?? 'jpg'}';
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: fileName,
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final secureUrl = jsonResponse['secure_url'] as String?;
        final publicId = jsonResponse['public_id'] as String?;

        if (secureUrl != null) {
          return secureUrl;
        } else if (publicId != null) {
          return '$imageUrl/$publicId';
        } else {
          throw Exception('No URL returned from Cloudinary');
        }
      } else {
        throw Exception(
            'Upload failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Upload video from bytes (for web) and return Cloudinary URL
  Future<String> uploadVideoBytes(Uint8List bytes, String folder,
      [String? format]) async {
    try {
      final params = <String, dynamic>{};

      if (uploadPreset.isNotEmpty) {
        params['upload_preset'] = uploadPreset;
        if (folder.isNotEmpty) {
          params['folder'] = folder;
        }
      } else {
        final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
        params['timestamp'] = timestamp;
        params['api_key'] = apiKey;
        if (folder.isNotEmpty) {
          params['folder'] = folder;
        }
        final signature = _generateSignature(params);
        params['signature'] = signature;
      }

      final uri = Uri.parse('$baseUrl/video/upload');
      final request = http.MultipartRequest('POST', uri);

      params.forEach((key, value) {
        request.fields[key] = value.toString();
      });

      final fileName =
          'video_${DateTime.now().millisecondsSinceEpoch}.${format ?? 'mp4'}';
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: fileName,
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final secureUrl = jsonResponse['secure_url'] as String?;
        final publicId = jsonResponse['public_id'] as String?;

        if (secureUrl != null) {
          return secureUrl;
        } else if (publicId != null) {
          return '$videoUrl/$publicId';
        } else {
          throw Exception('No URL returned from Cloudinary');
        }
      } else {
        throw Exception(
            'Upload failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Delete file from Cloudinary
  Future<void> deleteFile(String publicId) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();

      final params = <String, dynamic>{
        'public_id': publicId,
        'timestamp': timestamp,
        'api_key': apiKey,
      };

      final signature = _generateSignature(params);
      params['signature'] = signature;

      final uri = Uri.parse('$baseUrl/image/destroy').replace(queryParameters: {
        'public_id': publicId,
        'timestamp': timestamp,
        'api_key': apiKey,
        'signature': signature,
      });

      final response = await http.post(uri);

      if (response.statusCode != 200) {
        throw Exception(
            'Delete failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  String getOptimizedUrl(
    String publicIdOrUrl, {
    int? width,
    int? height,
    String? format,
    String? quality,
  }) {
    if (publicIdOrUrl.startsWith('http')) {
      if (width == null &&
          height == null &&
          format == null &&
          quality == null) {
        return publicIdOrUrl;
      }
      final uri = Uri.parse(publicIdOrUrl);
      final pathParts = uri.pathSegments;
      if (pathParts.length >= 3 &&
          pathParts[0] == 'image' &&
          pathParts[1] == 'upload') {
        final publicId = pathParts.sublist(2).join('/');
        return getOptimizedUrl(publicId,
            width: width, height: height, format: format, quality: quality);
      }
      return publicIdOrUrl;
    }
    final transformations = <String>[];
    if (width != null || height != null) {
      transformations.add('w_${width ?? 'auto'},h_${height ?? 'auto'}');
    }
    if (format != null) {
      transformations.add('f_$format');
    }
    if (quality != null) {
      transformations.add('q_$quality');
    }

    final transformString =
        transformations.isNotEmpty ? '${transformations.join('/')}/' : '';

    return '$imageUrl/$transformString$publicIdOrUrl';
  }
}
