import 'package:dio/dio.dart';
import 'auth_api_service.dart';
import 'storage_service.dart';

class HistoryItem {
  final int predictionId;
  final String imageUrl;
  final String diseaseName;
  final double confidence;
  final DateTime createdAt;

  HistoryItem({
    required this.predictionId,
    required this.imageUrl,
    required this.diseaseName,
    required this.confidence,
    required this.createdAt,
  });

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    final rawUrl = (json['imageUrl'] ?? '') as String;
    String imageUrl = rawUrl;
    // If API returned an absolute URL, normalize localhost -> emulator address
    if (rawUrl.startsWith('http')) {
      imageUrl = rawUrl.replaceFirst(
        'http://localhost:5299',
        'http://10.0.2.2:5299',
      );
    } else if (rawUrl.isNotEmpty) {
      // API returned only a filename or a relative path. Ensure we build
      // a full URL pointing to the uploads/images endpoint.
      final base = HistoryService._baseUrl; // http://10.0.2.2:5299
      // If the raw value already contains 'uploads', treat it as a relative path.
      final path = (rawUrl.contains('uploads'))
          ? (rawUrl.startsWith('/') ? rawUrl : '/$rawUrl')
          : '/uploads/images/${rawUrl.startsWith('/') ? rawUrl.substring(1) : rawUrl}';
      imageUrl = '$base$path';
    }
    // Pick disease name from several possible fields returned by backend
    final diseaseName =
        (json['diseaseName'] ??
                json['predictedClass'] ??
                json['illnessName'] ??
                '')
            as String;

    // Support multiple possible confidence fields (backend might send
    // `confidenceScore` as in the example). Be robust to number or string.
    final rawConfidence = json['confidenceScore'] ?? json['confidence'];
    double confidence;
    if (rawConfidence is num) {
      confidence = rawConfidence.toDouble();
    } else if (rawConfidence is String) {
      confidence = double.tryParse(rawConfidence) ?? 0.0;
    } else {
      confidence = 0.0;
    }

    return HistoryItem(
      predictionId: json['predictionId'] ?? 0,
      imageUrl: imageUrl,
      diseaseName: diseaseName,
      confidence: confidence,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
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
  static const String _baseUrl = 'http://10.0.2.2:5299';

  HistoryService({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: _baseUrl,
              connectTimeout: const Duration(seconds: 30),
              receiveTimeout: const Duration(seconds: 30),
              headers: {'Accept': 'application/json'},
            ),
          );

  Future<HistoryListResponse> getHistory() async {
    return _fetch(retryOnUnauthorized: true);
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
        '/api/predictions/history',
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
          ? 'Lỗi máy chủ ($statusCode). Vui lòng thử lại.'
          : 'Không thể kết nối máy chủ. Kiểm tra kết nối mạng.';
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
