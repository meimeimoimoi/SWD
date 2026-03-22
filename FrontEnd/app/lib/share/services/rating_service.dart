import 'package:dio/dio.dart';

import '../constants/api_config.dart';
import 'auth_api_service.dart';
import 'storage_service.dart';

class RatingService {
  final Dio _dio;

  RatingService({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: ApiConfig.baseUrl,
              connectTimeout: const Duration(seconds: 30),
              receiveTimeout: const Duration(seconds: 30),
              sendTimeout: const Duration(seconds: 30),
              headers: {'Accept': 'application/json'},
            ),
          );

  /// Post rating and comment for a prediction
  Future<Map<String, dynamic>> submitRating({
    required int predictionId,
    required int score,
    required String comment,
  }) async {
    return _submitRatingInternal(
      predictionId,
      score,
      comment,
      retryOnUnauthorized: true,
    );
  }

  Future<Map<String, dynamic>> _submitRatingInternal(
    int predictionId,
    int score,
    String comment, {
    required bool retryOnUnauthorized,
  }) async {
    try {
      final accessToken = await StorageService.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        return {'success': false, 'message': 'Unauthorized: Please login first.'};
      }

      final response = await _dio.post(
        ApiPaths.ratingPrediction(predictionId),
        data: {'score': score, 'comment': comment},
        options: Options(
          headers: {'Authorization': _formatBearerToken(accessToken)},
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'message': 'Feedback sent successfully'};
      }

      return {
        'success': false,
        'message': response.data['message'] ?? 'Failed to send feedback',
      };
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 && retryOnUnauthorized) {
        final refreshToken = await StorageService.getRefreshToken();
        if (refreshToken != null && refreshToken.isNotEmpty) {
          final refresh = await AuthApiService.refreshToken(refreshToken);
          if (refresh['success'] == true) {
            return _submitRatingInternal(
              predictionId,
              score,
              comment,
              retryOnUnauthorized: false,
            );
          }
        }
        await StorageService.clearAuth();
        AuthApiService.onSessionExpired?.call();
        return {
          'success': false,
          'message': 'Unauthorized: Session expired.',
        };
      }

      return {
        'success': false,
        'message': 'Error: ${e.message}',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  String _formatBearerToken(String token) {
    final trimmed = token.trim();
    if (trimmed.toLowerCase().startsWith('bearer ')) {
      return trimmed;
    }
    return 'Bearer $trimmed';
  }

  /// GET /api/rating/prediction/{predictionId}
  Future<Map<String, dynamic>?> getRatingForPrediction(int predictionId) async {
    try {
      final accessToken = await StorageService.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) return null;
      final response = await _dio.get<Map<String, dynamic>>(
        ApiPaths.ratingPrediction(predictionId),
        options: Options(
          headers: {'Authorization': _formatBearerToken(accessToken)},
        ),
      );
      final d = response.data;
      if (d != null && d['success'] == true) {
        return Map<String, dynamic>.from(d);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// GET /api/rating/all
  Future<List<dynamic>> getAllRatings() async {
    try {
      final accessToken = await StorageService.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) return [];
      final response = await _dio.get<Map<String, dynamic>>(
        ApiPaths.ratingAll,
        options: Options(
          headers: {'Authorization': _formatBearerToken(accessToken)},
        ),
      );
      final d = response.data;
      if (d != null && d['success'] == true && d['data'] is List) {
        return List<dynamic>.from(d['data'] as List);
      }
      return [];
    } catch (_) {
      return [];
    }
  }
}
