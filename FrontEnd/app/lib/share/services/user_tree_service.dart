import 'package:dio/dio.dart';

import '../constants/api_config.dart';
import 'auth_api_service.dart';
import 'storage_service.dart';

class UserTreeListItem {
  const UserTreeListItem({
    required this.treeId,
    this.treeName,
    this.scientificName,
    this.imagePath,
  });

  final int treeId;
  final String? treeName;
  final String? scientificName;
  final String? imagePath;

  factory UserTreeListItem.fromJson(Map<String, dynamic> json) {
    return UserTreeListItem(
      treeId: json['treeId'] as int,
      treeName: json['treeName'] as String?,
      scientificName: json['scientificName'] as String?,
      imagePath: json['imagePath'] as String?,
    );
  }

  String get displayLabel {
    final n = treeName?.trim();
    if (n != null && n.isNotEmpty) return n;
    return 'Plant #$treeId';
  }
}

class UserTreeService {
  UserTreeService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: ApiConfig.baseUrl,
                connectTimeout: const Duration(seconds: 30),
                receiveTimeout: const Duration(seconds: 30),
                headers: {'Accept': 'application/json'},
              ),
            );

  final Dio _dio;

  Future<({bool success, String message, List<UserTreeListItem> trees})>
      fetchMyTrees() async {
    final r = await _authorizedGet<List<UserTreeListItem>>(
      ApiPaths.userTrees,
      retryOnUnauthorized: true,
      parse: (data) {
        final raw = data['data'];
        if (raw is! List) return <UserTreeListItem>[];
        return raw
            .map((e) => UserTreeListItem.fromJson(e as Map<String, dynamic>))
            .toList();
      },
    );
    return (
      success: r.success,
      message: r.message,
      trees: r.data ?? [],
    );
  }

  Future<({bool success, String message, UserTreeListItem? tree})> createTree({
    required String treeName,
    String? scientificName,
    String? description,
  }) async {
    final r = await _authorizedPost<UserTreeListItem>(
      ApiPaths.userTrees,
      retryOnUnauthorized: true,
      data: {
        'treeName': treeName.trim(),
        if (scientificName != null && scientificName.trim().isNotEmpty)
          'scientificName': scientificName.trim(),
        if (description != null && description.trim().isNotEmpty)
          'description': description.trim(),
      },
      parse: (data) {
        final raw = data['data'];
        if (raw is! Map<String, dynamic>) return null;
        return UserTreeListItem.fromJson(raw);
      },
    );
    return (
      success: r.success,
      message: r.message,
      tree: r.data,
    );
  }

  Future<({bool success, String message})> assignPredictionToTree({
    required int predictionId,
    required int treeId,
  }) async {
    return _authorizedPatch(
      ApiPaths.predictionsHistoryAssignTree(predictionId),
      retryOnUnauthorized: true,
      data: {'treeId': treeId},
    );
  }

  Future<({bool success, String message, T? data})>
      _authorizedGet<T>(
    String path, {
    required bool retryOnUnauthorized,
    required T Function(Map<String, dynamic> body) parse,
  }) async {
    try {
      final accessToken = await StorageService.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        return (
          success: false,
          message: 'Please sign in.',
          data: null,
        );
      }

      final response = await _dio.get<Map<String, dynamic>>(
        path,
        options: Options(
          headers: {'Authorization': _formatBearerToken(accessToken)},
        ),
      );

      final body = response.data;
      if (body == null) {
        return (success: false, message: 'Empty response.', data: null);
      }
      if (body['success'] != true) {
        return (
          success: false,
          message: (body['message'] as String?) ?? 'Request failed.',
          data: null,
        );
      }

      final parsed = parse(body);
      return (success: true, message: '', data: parsed);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 && retryOnUnauthorized) {
        final refreshToken = await StorageService.getRefreshToken();
        if (refreshToken != null && refreshToken.isNotEmpty) {
          final refresh = await AuthApiService.refreshToken(refreshToken);
          if (refresh['success'] == true) {
            return _authorizedGet<T>(
              path,
              retryOnUnauthorized: false,
              parse: parse,
            );
          }
        }
        await StorageService.clearAuth();
        AuthApiService.onSessionExpired?.call();
      }
      final msg = _dioErrorMessage(e);
      return (success: false, message: msg, data: null);
    } catch (e) {
      return (success: false, message: 'Error: $e', data: null);
    }
  }

  Future<({bool success, String message, T? data})>
      _authorizedPost<T>(
    String path, {
    required bool retryOnUnauthorized,
    required Map<String, dynamic> data,
    required T? Function(Map<String, dynamic> body) parse,
  }) async {
    try {
      final accessToken = await StorageService.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        return (
          success: false,
          message: 'Please sign in.',
          data: null,
        );
      }

      final response = await _dio.post<Map<String, dynamic>>(
        path,
        data: data,
        options: Options(
          headers: {
            'Authorization': _formatBearerToken(accessToken),
            'Content-Type': 'application/json',
          },
        ),
      );

      final body = response.data;
      if (body == null) {
        return (success: false, message: 'Empty response.', data: null);
      }
      if (body['success'] != true) {
        return (
          success: false,
          message: (body['message'] as String?) ?? 'Request failed.',
          data: null,
        );
      }

      final parsed = parse(body);
      return (success: true, message: '', data: parsed);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 && retryOnUnauthorized) {
        final refreshToken = await StorageService.getRefreshToken();
        if (refreshToken != null && refreshToken.isNotEmpty) {
          final refresh = await AuthApiService.refreshToken(refreshToken);
          if (refresh['success'] == true) {
            return _authorizedPost<T>(
              path,
              retryOnUnauthorized: false,
              data: data,
              parse: parse,
            );
          }
        }
        await StorageService.clearAuth();
        AuthApiService.onSessionExpired?.call();
      }
      final msg = _dioErrorMessage(e);
      return (success: false, message: msg, data: null);
    } catch (e) {
      return (success: false, message: 'Error: $e', data: null);
    }
  }

  Future<({bool success, String message})> _authorizedPatch(
    String path, {
    required bool retryOnUnauthorized,
    required Map<String, dynamic> data,
  }) async {
    try {
      final accessToken = await StorageService.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        return (success: false, message: 'Please sign in.');
      }

      final response = await _dio.patch<Map<String, dynamic>>(
        path,
        data: data,
        options: Options(
          headers: {
            'Authorization': _formatBearerToken(accessToken),
            'Content-Type': 'application/json',
          },
        ),
      );

      final body = response.data;
      if (body == null) {
        return (success: false, message: 'Empty response.');
      }
      if (body['success'] != true) {
        return (
          success: false,
          message: (body['message'] as String?) ?? 'Request failed.',
        );
      }
      return (
        success: true,
        message: (body['message'] as String?) ?? 'Saved.',
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 && retryOnUnauthorized) {
        final refreshToken = await StorageService.getRefreshToken();
        if (refreshToken != null && refreshToken.isNotEmpty) {
          final refresh = await AuthApiService.refreshToken(refreshToken);
          if (refresh['success'] == true) {
            return _authorizedPatch(
              path,
              retryOnUnauthorized: false,
              data: data,
            );
          }
        }
        await StorageService.clearAuth();
        AuthApiService.onSessionExpired?.call();
      }
      final msg = _dioErrorMessage(e);
      return (success: false, message: msg);
    } catch (e) {
      return (success: false, message: 'Error: $e');
    }
  }

  String _dioErrorMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }
    final code = e.response?.statusCode;
    if (code != null) {
      return 'Server error ($code).';
    }
    return 'Cannot reach the server. Check your network.';
  }

  String _formatBearerToken(String token) {
    final trimmed = token.trim();
    return trimmed.toLowerCase().startsWith('bearer ')
        ? trimmed
        : 'Bearer $trimmed';
  }
}
