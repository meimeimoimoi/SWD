import 'package:dio/dio.dart';

import '../constants/api_config.dart';
import 'auth_api_service.dart';
import 'storage_service.dart';

class AiSuggestResult {
  AiSuggestResult({
    required this.source,
    required this.summary,
    required this.actionSteps,
    required this.disclaimer,
  });

  final String source;
  final String summary;
  final List<String> actionSteps;
  final String disclaimer;

  factory AiSuggestResult.fromJson(Map<String, dynamic> json) {
    final steps = json['actionSteps'];
    return AiSuggestResult(
      source: (json['source'] ?? 'heuristic').toString(),
      summary: (json['summary'] ?? '').toString(),
      actionSteps: steps is List
          ? steps.map((e) => e.toString()).toList()
          : const [],
      disclaimer: (json['disclaimer'] ?? '').toString(),
    );
  }
}

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

  Future<List<TreatmentRecommendationItem>> getRecommendations({
    int? illnessId,
    int? illnessStageId,
    int? treeStageId,
  }) async {
    try {
      final token = await StorageService.getAccessToken();
      final headers = <String, dynamic>{};
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = _bearer(token);
      }
      final qp = <String, dynamic>{};
      if (illnessId != null) qp['illnessId'] = illnessId;
      if (illnessStageId != null) qp['illnessStageId'] = illnessStageId;
      if (treeStageId != null) qp['treeStageId'] = treeStageId;
      final response = await _dio.get<Map<String, dynamic>>(
        ApiPaths.treatmentsRecommendationsPath,
        queryParameters: qp.isEmpty ? null : qp,
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

  Future<List<TreatmentRecommendationItem>> getRecommendationsForIllness(
    int illnessId,
  ) {
    return getRecommendations(illnessId: illnessId);
  }

  Future<Map<String, dynamic>?> getDiseaseDetail(int id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiPaths.diseaseDetail(id),
      );
      final data = response.data;
      if (data != null && data['success'] == true && data['data'] is Map) {
        return Map<String, dynamic>.from(data['data'] as Map);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<AiSuggestResult?> requestAiSolutionSuggestion({
    int? illnessId,
    required String diseaseName,
    required double confidence,
    int? predictionId,
  }) async {
    try {
      final token = await StorageService.getAccessToken();
      if (token == null || token.isEmpty) return null;
      final body = <String, dynamic>{
        'diseaseName': diseaseName,
        'confidence': confidence,
      };
      if (illnessId != null) body['illnessId'] = illnessId;
      if (predictionId != null && predictionId > 0) {
        body['predictionId'] = predictionId;
      }
      final response = await _dio.post<Map<String, dynamic>>(
        ApiPaths.treatmentsAiSuggest,
        data: body,
        options: Options(headers: {'Authorization': _bearer(token)}),
      );
      final data = response.data;
      if (data == null || data['success'] != true || data['data'] is! Map) {
        return null;
      }
      return AiSuggestResult.fromJson(
        Map<String, dynamic>.from(data['data'] as Map),
      );
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getSolutionDetail(int solutionId) async {
    try {
      final token = await StorageService.getAccessToken();
      final headers = <String, dynamic>{};
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = _bearer(token);
      }
      final response = await _dio.get<Map<String, dynamic>>(
        ApiPaths.treatmentSolution(solutionId),
        options: Options(headers: headers),
      );
      final data = response.data;
      if (data != null && data['success'] == true && data['data'] is Map) {
        return Map<String, dynamic>.from(data['data'] as Map);
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
