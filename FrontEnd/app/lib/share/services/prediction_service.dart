import 'package:dio/dio.dart';

import '../constants/api_config.dart';
import 'auth_api_service.dart';
import 'storage_service.dart';

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

class PredictionData {
  final int predictionId;
  final String imageUrl;
  final String predictedClass;
  final double confidence;
  final int processingTimeMs;
  final int? illnessId;
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
    this.illnessId,
    required this.diseaseName,
    this.symptoms,
    this.causes,
    required this.treatments,
    required this.medicines,
  });

  factory PredictionData.fromJson(Map<String, dynamic> json) {
    final illRaw = json['illnessId'] ?? json['IllnessId'];
    int? illnessId;
    if (illRaw is int) {
      illnessId = illRaw;
    } else if (illRaw != null) {
      illnessId = int.tryParse(illRaw.toString());
    }
    return PredictionData(
      predictionId: json['predictionId'] ?? 0,
      imageUrl: json['imageUrl'] ?? '',
      predictedClass: json['predictedClass'] ?? '',
      confidence: (json['confidence'] ?? 0).toDouble(),
      processingTimeMs: json['processingTimeMs'] ?? 0,
      illnessId: illnessId,
      diseaseName: json['diseaseName'] ?? '',
      symptoms: json['symptoms'],
      causes: json['causes'],
      treatments: json['treatments'] ?? [],
      medicines: json['medicines'] ?? [],
    );
  }
}

class PredictionModelOption {
  const PredictionModelOption({
    required this.modelVersionId,
    required this.modelName,
    required this.version,
    required this.isDefault,
    this.description,
  });

  final int modelVersionId;
  final String modelName;
  final String version;
  final bool isDefault;
  final String? description;

  String get label {
    final v = version.trim();
    if (v.isEmpty) return modelName;
    return '$modelName ($v)';
  }

  factory PredictionModelOption.fromJson(Map<String, dynamic> json) {
    int readInt(Object? a, Object? b) {
      final v = a ?? b;
      if (v == null) return 0;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? 0;
    }

    String readStr(Object? a, Object? b) {
      final v = a ?? b;
      if (v == null) return '';
      final s = v.toString().trim();
      return s;
    }

    final id = readInt(json['modelVersionId'], json['ModelVersionId']);
    var name = readStr(json['modelName'], json['ModelName']);
    final ver = readStr(json['version'], json['Version']);
    if (name.isEmpty && ver.isNotEmpty) name = ver;
    if (name.isEmpty && id > 0) name = 'Model #$id';

    return PredictionModelOption(
      modelVersionId: id,
      modelName: name,
      version: ver,
      isDefault: json['isDefault'] == true || json['IsDefault'] == true,
      description: json['description']?.toString() ?? json['Description']?.toString(),
    );
  }
}

/// Result of [PredictionService.fetchAvailableModels] (list + optional error for UI).
class PredictionModelsFetchResult {
  const PredictionModelsFetchResult({
    required this.models,
    this.errorMessage,
  });

  final List<PredictionModelOption> models;
  final String? errorMessage;
}

class PredictionService {
  final Dio _dio;

  PredictionService({Dio? dio})
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

  Future<PredictionModelsFetchResult> fetchAvailableModels({
    bool retryOnUnauthorized = true,
  }) async {
    try {
      final accessToken = await StorageService.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        return const PredictionModelsFetchResult(models: []);
      }
      final response = await _dio.get<Map<String, dynamic>>(
        ApiPaths.predictionModels,
        options: Options(
          headers: {'Authorization': _formatBearerToken(accessToken)},
        ),
      );
      return _parseModelsPayload(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 && retryOnUnauthorized) {
        final refreshToken = await StorageService.getRefreshToken();
        if (refreshToken != null && refreshToken.isNotEmpty) {
          final refresh = await AuthApiService.refreshToken(refreshToken);
          if (refresh['success'] == true) {
            return fetchAvailableModels(retryOnUnauthorized: false);
          }
        }
        await StorageService.clearAuth();
        AuthApiService.onSessionExpired?.call();
        return const PredictionModelsFetchResult(
          models: [],
          errorMessage:
              'Session expired. Please sign in again to load AI models.',
        );
      }
      return PredictionModelsFetchResult(
        models: [],
        errorMessage: _modelsLoadErrorMessage(e),
      );
    } catch (e) {
      return PredictionModelsFetchResult(
        models: [],
        errorMessage: 'Could not load models: $e',
      );
    }
  }

  PredictionModelsFetchResult _parseModelsPayload(Map<String, dynamic>? data) {
    if (data == null) {
      return const PredictionModelsFetchResult(
        models: [],
        errorMessage: 'Empty response from server.',
      );
    }
    if (data['success'] != true) {
      final msg = data['message']?.toString();
      return PredictionModelsFetchResult(
        models: [],
        errorMessage: (msg != null && msg.isNotEmpty)
            ? msg
            : 'Could not load models (success=false).',
      );
    }
    final raw = data['data'];
    if (raw is! List) {
      return const PredictionModelsFetchResult(
        models: [],
        errorMessage: 'Invalid models payload (expected a list).',
      );
    }
    final models = raw
        .map(
          (e) => PredictionModelOption.fromJson(
            Map<String, dynamic>.from(e as Map),
          ),
        )
        .where((m) => m.modelVersionId > 0)
        .toList();
    return PredictionModelsFetchResult(models: models);
  }

  String _modelsLoadErrorMessage(DioException e) {
    final body = e.response?.data;
    if (body is Map) {
      final m = body['message']?.toString();
      if (m != null && m.isNotEmpty) return m;
    }
    final code = e.response?.statusCode;
    if (code != null) {
      return 'Could not load models (HTTP $code). ${e.message ?? ''}'.trim();
    }
    return e.message ?? 'Network error loading models.';
  }

  Future<PredictionResponse> predict(
    String imagePath, {
    int? modelVersionId,
  }) async {
    return _predictInternal(
      imagePath,
      modelVersionId: modelVersionId,
      retryOnUnauthorized: true,
    );
  }

  Future<PredictionResponse> _predictInternal(
    String imagePath, {
    int? modelVersionId,
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

      final fields = <String, dynamic>{
        'image': await MultipartFile.fromFile(imagePath),
      };
      if (modelVersionId != null) {
        fields['modelVersionId'] = modelVersionId;
      }
      final formData = FormData.fromMap(fields);

      final response = await _dio.post(
        ApiPaths.predictionPredict,
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
            return _predictInternal(
              imagePath,
              modelVersionId: modelVersionId,
              retryOnUnauthorized: false,
            );
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

  Future<dynamic> getPredictionClasses() async {
    try {
      final response = await _dio.get(ApiPaths.predictionClasses);
      return response.data;
    } catch (e) {
      return null;
    }
  }

  Future<bool> isPredictionServiceHealthy() async {
    try {
      final response = await _dio.get(ApiPaths.predictionHealth);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Global DB aggregates for home dashboard "Common threats".
  Future<List<CommonThreatItem>> fetchCommonThreats({int take = 5}) async {
    try {
      final accessToken = await StorageService.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) return [];
      final response = await _dio.get<Map<String, dynamic>>(
        ApiPaths.predictionCommonThreats(take: take),
        options: Options(
          headers: {'Authorization': _formatBearerToken(accessToken)},
        ),
      );
      final data = response.data;
      if (data == null || data['success'] != true) return [];
      final raw = data['data'];
      if (raw is! List) return [];
      return raw
          .map(
            (e) => CommonThreatItem.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }
}

/// One row from [PredictionService.fetchCommonThreats].
class CommonThreatItem {
  const CommonThreatItem({
    this.illnessId,
    required this.title,
    this.scientificName,
    required this.reportCount,
    this.imageUrl,
  });

  final int? illnessId;
  final String title;
  final String? scientificName;
  final int reportCount;
  final String? imageUrl;

  factory CommonThreatItem.fromJson(Map<String, dynamic> json) {
    final illRaw = json['illnessId'] ?? json['IllnessId'];
    int? illnessId;
    if (illRaw is int) {
      illnessId = illRaw;
    } else if (illRaw != null) {
      illnessId = int.tryParse(illRaw.toString());
    }
    final rc = json['reportCount'] ?? json['ReportCount'];
    final count = rc is int
        ? rc
        : (rc is num ? rc.toInt() : int.tryParse('$rc') ?? 0);
    return CommonThreatItem(
      illnessId: illnessId,
      title: (json['title'] ?? json['Title'] ?? 'Unknown').toString(),
      scientificName: (json['scientificName'] ?? json['ScientificName'])
          ?.toString(),
      reportCount: count,
      imageUrl: (json['imageUrl'] ?? json['ImageUrl'])?.toString(),
    );
  }
}
