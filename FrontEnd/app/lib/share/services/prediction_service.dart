import 'package:dio/dio.dart';
import 'auth_api_service.dart';
import 'storage_service.dart';

/// Model for API prediction response
class PredictionResponse {
  final bool success;
  final String message;
  final PredictionData? data;

  PredictionResponse({required this.success, required this.message, this.data});

  factory PredictionResponse.fromJson(Map<String, dynamic> json) {
    return PredictionResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? PredictionData.fromJson(json['data']) : null,
    );
  }
}

/// Model for prediction data
class PredictionData {
  final int predictionId;
  final String imageUrl;
  final String predictedClass;
  final double confidence;
  final int processingTimeMs;
  final String diseaseName;
  final String? symptoms;
  final String? causes;
  final List<dynamic> treatments;
  final List<dynamic> medicines;

  PredictionData({
    required this.predictionId,
    required this.imageUrl,
    required this.predictedClass,
    required this.confidence,
    required this.processingTimeMs,
    required this.diseaseName,
    this.symptoms,
    this.causes,
    required this.treatments,
    required this.medicines,
  });

  factory PredictionData.fromJson(Map<String, dynamic> json) {
    return PredictionData(
      predictionId: json['predictionId'] ?? 0,
      imageUrl: json['imageUrl'] ?? '',
      predictedClass: json['predictedClass'] ?? '',
      confidence: (json['confidence'] ?? 0).toDouble(),
      processingTimeMs: json['processingTimeMs'] ?? 0,
      diseaseName: json['diseaseName'] ?? '',
      symptoms: json['symptoms'],
      causes: json['causes'],
      treatments: json['treatments'] ?? [],
      medicines: json['medicines'] ?? [],
    );
  }
}

/// Service to handle predictions
class PredictionService {
  final Dio _dio;
  static const String _baseUrl = 'http://10.0.2.2:5299'; // For Android emulator
  // For physical device or web, change to: 'http://your-server-ip:5299'

  PredictionService({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: _baseUrl,
              connectTimeout: const Duration(seconds: 30),
              receiveTimeout: const Duration(seconds: 30),
              sendTimeout: const Duration(seconds: 30),
              headers: {'Accept': 'application/json'},
            ),
          );

  /// Upload image and get prediction
  /// [imageFile] - File path to the image
  Future<PredictionResponse> predict(String imagePath) async {
    return _predictInternal(imagePath, retryOnUnauthorized: true);
  }

  Future<PredictionResponse> _predictInternal(
    String imagePath, {
    required bool retryOnUnauthorized,
  }) async {
    try {
      final accessToken = await StorageService.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        return PredictionResponse(
          success: false,
          message: 'Unauthorized (401): Please login first.',
          data: null,
        );
      }

      final formData = FormData.fromMap({
        'Image': await MultipartFile.fromFile(imagePath),
      });

      final response = await _dio.post(
        '/api/Prediction/predict',
        data: formData,
        options: Options(
          headers: {'Authorization': _formatBearerToken(accessToken)},
        ),
      );

      return PredictionResponse.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 && retryOnUnauthorized) {
        final refreshToken = await StorageService.getRefreshToken();
        if (refreshToken != null && refreshToken.isNotEmpty) {
          final refresh = await AuthApiService.refreshToken(refreshToken);
          if (refresh['success'] == true) {
            return _predictInternal(imagePath, retryOnUnauthorized: false);
          }
        }
        await StorageService.clearAuth();
        AuthApiService.onSessionExpired?.call();
        return PredictionResponse(
          success: false,
          message: 'Unauthorized (401): Token is invalid or expired.',
          data: null,
        );
      }

      return PredictionResponse(
        success: false,
        message: 'Error: ${e.message}',
        data: null,
      );
    } catch (e) {
      return PredictionResponse(
        success: false,
        message: 'Error: $e',
        data: null,
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
}
