import 'package:dio/dio.dart';

import 'auth_api_service.dart';
import 'storage_service.dart';

class TreatmentRecommendationItem {
  TreatmentRecommendationItem({
    required this.solutionId,
    this.solutionName,
    this.solutionType,
    this.description,
    this.treeStageName,
    this.illnessName,
  });

  final int solutionId;
  final String? solutionName;
  final String? solutionType;
  final String? description;
  final String? treeStageName;
  final String? illnessName;

  factory TreatmentRecommendationItem.fromJson(Map<String, dynamic> json) {
    return TreatmentRecommendationItem(
      solutionId: (json['solutionId'] as num?)?.toInt() ?? 0,
      solutionName: json['solutionName'] as String?,
      solutionType: json['solutionType'] as String?,
      description: json['description'] as String?,
      treeStageName: json['treeStageName'] as String?,
      illnessName: json['illnessName'] as String?,
    );
  }
}

class TreatmentApiService {
  TreatmentApiService({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: AuthApiService.baseUrl,
              connectTimeout: const Duration(seconds: 30),
              receiveTimeout: const Duration(seconds: 30),
              headers: {'Accept': 'application/json'},
            ),
          );

  final Dio _dio;

  String _bearer(String token) {
    final t = token.trim();
    return t.toLowerCase().startsWith('bearer ') ? t : 'Bearer $t';
  }

  /// GET /api/treatments/recommendations?illnessId=
  Future<List<TreatmentRecommendationItem>> getRecommendationsForIllness(
    int illnessId,
  ) async {
    try {
      final token = await StorageService.getAccessToken();
      final headers = <String, dynamic>{};
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = _bearer(token);
      }
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/treatments/recommendations',
        queryParameters: {'illnessId': illnessId},
        options: Options(headers: headers),
      );
      final data = response.data;
      if (data == null || data['success'] != true) return [];
      final raw = data['data'];
      if (raw is! List) return [];
      return raw
          .map(
            (e) => TreatmentRecommendationItem.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }
}
