import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

import 'auth_api_service.dart';
import 'storage_service.dart';

class ImageUploadResult {
  const ImageUploadResult({
    required this.success,
    required this.message,
    this.data,
  });

  final bool success;
  final String message;
  final Map<String, dynamic>? data;
}

class ImageUploadService {
  static const String baseUrl = 'http://10.0.2.2:5299';
  static const String uploadEndpoint = '/api/ImageUpload/upload';
  static const Duration timeout = Duration(seconds: 120);
  static const int maxFileBytes = 10 * 1024 * 1024;

  static const List<String> allowedExtensions = ['png', 'jpg', 'jpeg'];

  Future<ImageUploadResult> uploadImage({required XFile imageFile}) async {
    return _uploadImageInternal(
      imageFile: imageFile,
      retryOnUnauthorized: true,
    );
  }

  Future<ImageUploadResult> _uploadImageInternal({
    required XFile imageFile,
    required bool retryOnUnauthorized,
  }) async {
    final extension = _fileExtension(imageFile.path);
    if (extension == null || !allowedExtensions.contains(extension)) {
      return const ImageUploadResult(
        success: false,
        message: 'Invalid file type. Use PNG, JPG, or JPEG.',
      );
    }

    final length = await imageFile.length();
    if (length > maxFileBytes) {
      return const ImageUploadResult(
        success: false,
        message: 'File too large. Max size is 10MB.',
      );
    }

    try {
      final accessToken = await StorageService.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        return const ImageUploadResult(
          success: false,
          message: 'Unauthorized (401): Please login first.',
        );
      }

      final uri = Uri.parse('$baseUrl$uploadEndpoint');
      final request = http.MultipartRequest('POST', uri);
      request.headers['Accept'] = 'application/json';
      request.headers['Authorization'] = _formatBearerToken(accessToken);
      final contentType = _contentTypeForExtension(extension);
      request.files.add(
        await http.MultipartFile.fromPath(
          'Image',
          imageFile.path,
          filename: imageFile.name,
          contentType: contentType,
        ),
      );

      final streamedResponse = await request.send().timeout(timeout);
      final response = await http.Response.fromStream(streamedResponse);

      final Map<String, dynamic> payload = _tryParseJson(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ImageUploadResult(
          success: true,
          message:
              payload['message']?.toString() ?? 'Image uploaded successfully',
          data: payload['data'] is Map<String, dynamic>
              ? payload['data'] as Map<String, dynamic>
              : null,
        );
      }

      if (response.statusCode == 400) {
        return ImageUploadResult(
          success: false,
          message: payload['message']?.toString() ?? 'Validation error',
        );
      }

      if (response.statusCode == 413) {
        return const ImageUploadResult(
          success: false,
          message: 'File too large. Max size is 10MB.',
        );
      }

      if (response.statusCode == 401) {
        if (retryOnUnauthorized) {
          final refreshToken = await StorageService.getRefreshToken();
          if (refreshToken != null && refreshToken.isNotEmpty) {
            final refresh = await AuthApiService.refreshToken(refreshToken);
            if (refresh['success'] == true) {
              return _uploadImageInternal(
                imageFile: imageFile,
                retryOnUnauthorized: false,
              );
            }
          }

          await StorageService.clearAuth();
          AuthApiService.onSessionExpired?.call();
        }

        return ImageUploadResult(
          success: false,
          message:
              payload['message']?.toString() ??
              'Unauthorized (401): Token is invalid or expired.',
        );
      }

      return ImageUploadResult(
        success: false,
        message: 'Server error (${response.statusCode})',
      );
    } on SocketException catch (e) {
      return ImageUploadResult(
        success: false,
        message: 'Network error: ${e.message}',
      );
    } on TimeoutException {
      return ImageUploadResult(
        success: false,
        message: 'Request timeout (${timeout.inSeconds}s). Please try again.',
      );
    } catch (e) {
      return ImageUploadResult(
        success: false,
        message: 'Error: ${e.toString()}',
      );
    }
  }

  String _formatBearerToken(String token) {
    final trimmed = token.trim();
    if (trimmed.toLowerCase().startsWith('bearer ')) {
      return trimmed;
    }
    return 'Bearer $trimmed';
  }

  String? _fileExtension(String path) {
    final dotIndex = path.lastIndexOf('.');
    if (dotIndex < 0 || dotIndex == path.length - 1) {
      return null;
    }
    return path.substring(dotIndex + 1).toLowerCase();
  }

  MediaType _contentTypeForExtension(String extension) {
    switch (extension) {
      case 'png':
        return MediaType('image', 'png');
      case 'jpg':
      case 'jpeg':
        return MediaType('image', 'jpeg');
      default:
        return MediaType('application', 'octet-stream');
    }
  }

  Map<String, dynamic> _tryParseJson(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {}
    return {'message': body};
  }
}
