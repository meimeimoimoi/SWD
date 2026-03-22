import 'package:dio/dio.dart';

import '../constants/api_config.dart';
import 'auth_api_service.dart';
import 'storage_service.dart';

class HistoryItem {
  final int predictionId;
  final String imageUrl;
  final String diseaseName;
  final double confidence;
  final DateTime createdAt;
  final int? treeId;
  final int? illnessId;
  final String? illnessSeverity;
  final String? scientificName;
  final String? illnessDescription;
  final String? symptoms;
  final String? causes;
  final String? treeName;
  final String? treeScientificName;
  final String? treeDescription;
  final String? treeImageUrl;

  HistoryItem({
    required this.predictionId,
    required this.imageUrl,
    required this.diseaseName,
    required this.confidence,
    required this.createdAt,
    this.treeId,
    this.illnessId,
    this.illnessSeverity,
    this.scientificName,
    this.illnessDescription,
    this.symptoms,
    this.causes,
    this.treeName,
    this.treeScientificName,
    this.treeDescription,
    this.treeImageUrl,
  });

  static String resolveImageUrl(String rawUrl) => ApiConfig.resolveMediaUrl(rawUrl);

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    final rawUrl = (json['imageUrl'] ?? '') as String;
    final imageUrl = rawUrl.isEmpty ? '' : HistoryItem.resolveImageUrl(rawUrl);
    final diseaseName =
        (json['diseaseName'] ??
                json['predictedClass'] ??
                json['illnessName'] ??
                '')
            as String;

    final rawConfidence = json['confidenceScore'] ?? json['confidence'];
    double confidence;
    if (rawConfidence is num) {
      confidence = rawConfidence.toDouble();
    } else if (rawConfidence is String) {
      confidence = double.tryParse(rawConfidence) ?? 0.0;
    } else {
      confidence = 0.0;
    }

    final treePath = json['treeImagePath'] as String?;
    final treeImageUrl = (treePath == null || treePath.isEmpty)
        ? null
        : HistoryItem.resolveImageUrl(treePath);

    return HistoryItem(
      predictionId: json['predictionId'] ?? 0,
      imageUrl: imageUrl,
      diseaseName: diseaseName,
      confidence: confidence,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      treeId: (json['treeId'] as num?)?.toInt(),
      illnessId: (json['illnessId'] as num?)?.toInt(),
      illnessSeverity: json['illnessSeverity'] as String?,
      scientificName: json['scientificName'] as String?,
      illnessDescription: json['illnessDescription'] as String?,
      symptoms: json['symptoms'] as String?,
      causes: json['causes'] as String?,
      treeName: json['treeName'] as String?,
      treeScientificName: json['treeScientificName'] as String?,
      treeDescription: json['treeDescription'] as String?,
      treeImageUrl: treeImageUrl,
    );
  }
}

class HistoryListResponse {
  final bool success;
  final String message;
  final List<HistoryItem> data;

  HistoryListResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory HistoryListResponse.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    List<HistoryItem> items = [];
    if (rawData is List) {
      items = rawData
          .map((e) => HistoryItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return HistoryListResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: items,
    );
  }
}

class HistoryService {
  final Dio _dio;

  HistoryService({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: ApiConfig.baseUrl,
              connectTimeout: const Duration(seconds: 30),
              receiveTimeout: const Duration(seconds: 30),
              headers: {'Accept': 'application/json'},
            ),
          );

  Future<HistoryListResponse> getHistory() async {
    return _fetch(retryOnUnauthorized: true);
  }

  Future<Map<String, dynamic>?> getPredictionById(int id) async {
    return _fetchDetail(id, retryOnUnauthorized: true);
  }

  Future<Map<String, dynamic>?> _fetchDetail(
    int id, {
    required bool retryOnUnauthorized,
  }) async {
    try {
      final accessToken = await StorageService.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        return null;
      }

      final response = await _dio.get<Map<String, dynamic>>(
        ApiPaths.predictionsHistoryItem(id),
        options: Options(
          headers: {'Authorization': _formatBearerToken(accessToken)},
        ),
      );

      final body = response.data;
      if (body != null &&
          body['success'] == true &&
          body['data'] is Map<String, dynamic>) {
        return Map<String, dynamic>.from(body['data'] as Map);
      }
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 && retryOnUnauthorized) {
        final refreshToken = await StorageService.getRefreshToken();
        if (refreshToken != null && refreshToken.isNotEmpty) {
          final refresh = await AuthApiService.refreshToken(refreshToken);
          if (refresh['success'] == true) {
            return _fetchDetail(id, retryOnUnauthorized: false);
          }
        }
        await StorageService.clearAuth();
        AuthApiService.onSessionExpired?.call();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<HistoryListResponse> _fetch({
    required bool retryOnUnauthorized,
  }) async {
    try {
      final accessToken = await StorageService.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        return HistoryListResponse(
          success: false,
          message: 'Unauthorized: Please login first.',
          data: [],
        );
      }

      final response = await _dio.get(
        ApiPaths.predictionsHistory,
        options: Options(
          headers: {'Authorization': _formatBearerToken(accessToken)},
        ),
      );

      return HistoryListResponse.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 && retryOnUnauthorized) {
        final refreshToken = await StorageService.getRefreshToken();
        if (refreshToken != null && refreshToken.isNotEmpty) {
          final refresh = await AuthApiService.refreshToken(refreshToken);
          if (refresh['success'] == true) {
            return _fetch(retryOnUnauthorized: false);
          }
        }
        await StorageService.clearAuth();
        AuthApiService.onSessionExpired?.call();
        return HistoryListResponse(
          success: false,
          message: 'Unauthorized: Token expired.',
          data: [],
        );
      }
      final statusCode = e.response?.statusCode;
      final msg = statusCode != null
          ? 'Server error ($statusCode). Please try again.'
          : 'Cannot reach the server. Check your network connection.';
      return HistoryListResponse(success: false, message: msg, data: []);
    } catch (e) {
      return HistoryListResponse(
        success: false,
        message: 'Error: $e',
        data: [],
      );
    }
  }

  String _formatBearerToken(String token) {
    final trimmed = token.trim();
    return trimmed.toLowerCase().startsWith('bearer ')
        ? trimmed
        : 'Bearer $trimmed';
  }
}
