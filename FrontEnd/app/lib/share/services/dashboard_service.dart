import 'package:dio/dio.dart';

import '../constants/api_config.dart';
import 'storage_service.dart';

class DashboardStats {
  final int totalUsers;
  final int activeUsers;
  final int totalPredictions;
  final int todayPredictions;
  final int totalModels;
  final int activeModels;

  DashboardStats({
    required this.totalUsers,
    required this.activeUsers,
    required this.totalPredictions,
    required this.todayPredictions,
    required this.totalModels,
    required this.activeModels,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    // API returns data wrapped in a 'data' field
    final d = json['data'] ?? json;
    return DashboardStats(
      totalUsers: d['totalUsers'] ?? 0,
      activeUsers: d['activeUsers'] ?? 0,
      totalPredictions: d['totalPredictions'] ?? 0,
      todayPredictions: d['todayPredictions'] ?? 0,
      totalModels: d['totalModels'] ?? 0,
      activeModels: d['activeModels'] ?? 0,
    );
  }
}

class ActivityLogItem {
  final int activityLogId;
  final int? userId;
  final String? username;
  final String action;
  final String entityName;
  final String? entityId;
  final String? description;
  final DateTime createdAt;

  ActivityLogItem({
    required this.activityLogId,
    this.userId,
    this.username,
    required this.action,
    required this.entityName,
    this.entityId,
    this.description,
    required this.createdAt,
  });

  factory ActivityLogItem.fromJson(Map<String, dynamic> json) {
    return ActivityLogItem(
      activityLogId: json['activityLogId'] ?? 0,
      userId: json['userId'],
      username: json['user']?['username'],
      action: json['action'] ?? '',
      entityName: json['entityName'] ?? '',
      entityId: json['entityId']?.toString(),
      description: json['description'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class NotificationItem {
  final int notificationId;
  final String title;
  final String message;
  final String? type;
  final bool isRead;
  final DateTime createdAt;

  NotificationItem({
    required this.notificationId,
    required this.title,
    required this.message,
    this.type,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      notificationId: json['notificationId'] ?? 0,
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: json['type'],
      isRead: json['isRead'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class DashboardService {
  final Dio _dio;

  DashboardService({Dio? dio})
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

  Future<DashboardStats?> getAdminStats() async {
    try {
      final response = await _authorizedGet(ApiPaths.adminStats);
      if (response.data['success'] == true) {
        return DashboardStats.fromJson(response.data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<ActivityLogItem>> getAdminActivityLogs({int count = 50}) async {
    try {
      final response = await _authorizedGet('/api/admin/activity-logs?count=$count');
      if (response.data['success'] == true) {
        final List raw = response.data['data'] ?? [];
        return raw.map((e) => ActivityLogItem.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<NotificationItem>> getUserNotifications() async {
    try {
      final response = await _authorizedGet(ApiPaths.userNotifications);
      if (response.data['success'] == true) {
        final List raw = response.data['data'] ?? [];
        return raw.map((e) => NotificationItem.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<ActivityLogItem>> getUserActivities() async {
    try {
      final response = await _authorizedGet(ApiPaths.userActivities);
      if (response.data['success'] == true) {
        final List raw = response.data['data'] ?? [];
        return raw.map((e) => ActivityLogItem.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<dynamic>> getFeedbackList() async {
    try {
      final response = await _authorizedGet(ApiPaths.ratingAll);
      if (response.data['success'] == true) {
        return response.data['data'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<dynamic>> getAdminUsers({
    String? search,
    String? role,
    String sortBy = 'email',
    String sortOrder = 'asc',
  }) async {
    try {
      final path = ApiPaths.adminUsersList(
        search: search,
        role: role,
        sortBy: sortBy,
        sortOrder: sortOrder,
      );
      final response = await _authorizedGet(path);
      if (response.data['success'] == true) {
        return response.data['data'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> getAdminUserById(int userId) async {
    try {
      final response = await _authorizedGet(ApiPaths.adminUser(userId));
      if (response.data['success'] == true) {
        final d = response.data['data'];
        if (d is Map) {
          return Map<String, dynamic>.from(d);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> deleteAdminUser(int userId) async {
    try {
      final response = await _authorizedDelete(ApiPaths.adminUser(userId));
      return response.data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> createAdminStaff(
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await _authorizedPost(ApiPaths.adminUsersStaff, body);
      if (response.data['success'] == true) {
        final d = response.data['data'];
        if (d is Map) {
          return Map<String, dynamic>.from(d);
        }
        return {};
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> updateAdminUser(int userId, Map<String, dynamic> body) async {
    try {
      final response = await _authorizedPut(ApiPaths.adminUser(userId), body);
      return response.data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  Future<List<dynamic>> getAdminPredictions() async {
    try {
      final response = await _authorizedGet(ApiPaths.adminPredictions);
      if (response.data['success'] == true) {
        return response.data['data'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> getAdminPredictionStats({int days = 7}) async {
    try {
      final response =
          await _authorizedGet(ApiPaths.adminPredictionStats(days: days));
      if (response.data['success'] == true) {
        final d = response.data['data'];
        if (d is Map) {
          return Map<String, dynamic>.from(d);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getAdminRatingsPaged({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _authorizedGet(
        ApiPaths.adminRatings(page: page, pageSize: pageSize),
      );
      if (response.data['success'] == true) {
        return Map<String, dynamic>.from(response.data as Map);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> createUser(String email, String password, String role) async {
    try {
      final response = await _authorizedPost(ApiPaths.adminUsersRoot, {
        'email': email,
        'password': password,
        'role': role,
      });
      return response.data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateUserStatus(int userId, String status) async {
    try {
      final response =
          await _authorizedPatch('${ApiPaths.adminUser(userId)}/status', {
        'status': status,
      });
      return response.data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateUserRole(int userId, String role) async {
    try {
      final response = await _authorizedPut('/api/Admin/users/$userId', {
        'role': role,
      });
      return response.data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  /// Per-model predictions, confidence, and positive rating rate (admin).
  Future<List<Map<String, dynamic>>> getModelAccuracy() async {
    try {
      final response = await _authorizedGet(ApiPaths.adminModelsAccuracy);
      if (response.data['success'] == true) {
        final List raw = response.data['data'] ?? [];
        return raw
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getAdminModelsList() async {
    try {
      final response = await _authorizedGet(ApiPaths.adminModels);
      if (response.data['success'] == true) {
        final List raw = response.data['data'] ?? [];
        return raw
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> activateAdminModel(int id) async {
    try {
      final response =
          await _authorizedPatch(ApiPaths.adminModelActive(id), {});
      return response.data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> uploadAdminModel({
    required String modelName,
    required String version,
    required String filePath,
    String? description,
    String modelType = 'mobilenetv3',
  }) async {
    try {
      final accessToken = await StorageService.getAccessToken();
      final fileName = filePath.split(RegExp(r'[\\/]')).last;
      final formData = FormData.fromMap({
        'ModelName': modelName,
        'Version': version,
        'ModelType': modelType,
        if (description != null && description.isNotEmpty) 'Description': description,
        'ModelFile': await MultipartFile.fromFile(filePath, filename: fileName),
      });
      final response = await _dio.post(
        ApiPaths.adminModels,
        data: formData,
        options: Options(
          headers: {'Authorization': 'Bearer $accessToken'},
        ),
      );
      return response.data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  /// Public health endpoints (no JWT).
  Future<Map<String, dynamic>> getHealthChecks() async {
    final out = <String, dynamic>{};
    try {
      final live = await _dio.get('/health/live');
      out['live'] = live.data;
      out['liveCode'] = live.statusCode;
    } catch (e) {
      out['liveError'] = e.toString();
    }
    try {
      final ready = await _dio.get('/health/ready');
      out['ready'] = ready.data;
      out['readyCode'] = ready.statusCode;
    } catch (e) {
      out['readyError'] = e.toString();
    }
    try {
      final root = await _dio.get('/health');
      out['root'] = root.data;
      out['rootCode'] = root.statusCode;
    } catch (e) {
      out['rootError'] = e.toString();
    }
    return out;
  }

  Future<List<Map<String, dynamic>>> getIllnesses() async {
    try {
      final response = await _authorizedGet('/api/technician/illnesses');
      if (response.data['success'] == true) {
        final List raw = response.data['data'] ?? [];
        return raw
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> getIllnessById(int id) async {
    try {
      final response = await _authorizedGet(ApiPaths.technicianIllness(id));
      if (response.data['success'] == true) {
        final d = response.data['data'];
        if (d is Map) {
          return Map<String, dynamic>.from(d);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> createIllness(Map<String, dynamic> body) async {
    try {
      final response = await _authorizedPost(ApiPaths.technicianIllnesses, body);
      return response.data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateIllness(int id, Map<String, dynamic> body) async {
    try {
      final response =
          await _authorizedPut(ApiPaths.technicianIllness(id), body);
      return response.data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteIllness(int id) async {
    try {
      final accessToken = await StorageService.getAccessToken();
      final response = await _dio.delete(
        ApiPaths.technicianIllness(id),
        options: Options(
          headers: {'Authorization': 'Bearer $accessToken'},
        ),
      );
      return response.data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> assignIllnessToTree(int illnessId, int treeId) async {
    try {
      final response = await _authorizedPost(
        ApiPaths.technicianIllnessAssignTree(illnessId),
        {'treeId': treeId},
      );
      return response.data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getTechnicianStages() async {
    try {
      final response = await _authorizedGet(ApiPaths.technicianStages);
      if (response.data['success'] == true) {
        final List raw = response.data['data'] ?? [];
        return raw
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> getTechnicianStageById(int id) async {
    try {
      final response = await _authorizedGet(ApiPaths.technicianStage(id));
      if (response.data['success'] == true) {
        final d = response.data['data'];
        if (d is Map) {
          return Map<String, dynamic>.from(d);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> createTechnicianStage(Map<String, dynamic> body) async {
    try {
      final response = await _authorizedPost(ApiPaths.technicianStages, body);
      return response.data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateTechnicianStage(int id, Map<String, dynamic> body) async {
    try {
      final response = await _authorizedPut(ApiPaths.technicianStage(id), body);
      return response.data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getAdminDataStages() async {
    try {
      final response = await _authorizedGet(ApiPaths.adminDataStages);
      if (response.data['success'] == true) {
        final List raw = response.data['data'] ?? [];
        return raw
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> getAdminDataStageById(int id) async {
    try {
      final response = await _authorizedGet(ApiPaths.adminDataStage(id));
      if (response.data['success'] == true) {
        final d = response.data['data'];
        if (d is Map) {
          return Map<String, dynamic>.from(d);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> createAdminDataStage(Map<String, dynamic> body) async {
    try {
      final response = await _authorizedPost(ApiPaths.adminDataStages, body);
      return response.data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateAdminDataStage(int id, Map<String, dynamic> body) async {
    try {
      final response = await _authorizedPut(ApiPaths.adminDataStage(id), body);
      return response.data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteAdminDataStage(int id) async {
    try {
      final response = await _authorizedDelete(ApiPaths.adminDataStage(id));
      return response.data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getAdminDataRelationships({
    int? treeId,
    int? illnessId,
  }) async {
    try {
      final response = await _authorizedGet(
        ApiPaths.adminDataRelationships(treeId: treeId, illnessId: illnessId),
      );
      if (response.data['success'] == true) {
        final List raw = response.data['data'] ?? [];
        return raw
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> createAdminDataRelationship(
    Map<String, dynamic> body,
  ) async {
    try {
      final response =
          await _authorizedPost(ApiPaths.adminDataRelationships(), body);
      if (response.data['success'] == true) {
        final d = response.data['data'];
        if (d is Map) {
          return Map<String, dynamic>.from(d);
        }
        return {};
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> deleteAdminDataRelationship(int id) async {
    try {
      final response =
          await _authorizedDelete(ApiPaths.adminDataRelationship(id));
      return response.data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getReviewTreatments() async {
    try {
      final response = await _authorizedGet(ApiPaths.reviewTreatments);
      if (response.data['success'] == true) {
        final List raw = response.data['data'] ?? [];
        return raw
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> getReviewTreatmentById(int id) async {
    try {
      final response = await _authorizedGet(ApiPaths.reviewTreatment(id));
      if (response.data['success'] == true) {
        final d = response.data['data'];
        if (d is Map) {
          return Map<String, dynamic>.from(d);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> updateReviewTreatment(int id, Map<String, dynamic> body) async {
    try {
      final response = await _authorizedPut(ApiPaths.reviewTreatment(id), body);
      return response.data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteReviewTreatment(int id) async {
    try {
      final response = await _authorizedDelete(ApiPaths.reviewTreatment(id));
      return response.data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getReviewModels() async {
    try {
      final response = await _authorizedGet(ApiPaths.reviewModels);
      if (response.data['success'] == true) {
        final List raw = response.data['data'] ?? [];
        return raw
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> reviewActivateModel(int id) async {
    try {
      final response =
          await _authorizedPatch(ApiPaths.reviewModelActivate(id), {});
      return response.data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> reviewDeactivateModel(int id) async {
    try {
      final response =
          await _authorizedPatch(ApiPaths.reviewModelDeactivate(id), {});
      return response.data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  Future<List<dynamic>> getAdminSettings() async {
    try {
      final response = await _authorizedGet(ApiPaths.adminSettings);
      if (response.data['success'] == true) {
        final d = response.data['data'];
        if (d is List) return d;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> updateAdminSetting(String key, String? value) async {
    try {
      final response = await _authorizedPut(
        ApiPaths.adminSettingKey(key),
        {'value': value},
      );
      return response.data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getTreatmentManagementList() async {
    try {
      final response = await _authorizedGet(ApiPaths.treatments);
      if (response.data['success'] == true) {
        final List raw = response.data['data'] ?? [];
        return raw
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> createTreatmentManagement(
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await _authorizedPost(ApiPaths.treatments, body);
      if (response.data['success'] == true) {
        final d = response.data['data'];
        if (d is Map) {
          return Map<String, dynamic>.from(d);
        }
        return {};
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> assignTreatmentToIllness(int treatmentId, int illnessId) async {
    try {
      final response = await _authorizedPost(
        ApiPaths.treatmentAssign(treatmentId),
        {'illnessId': illnessId},
      );
      return response.data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  Future<Response> _authorizedGet(String path) async {
    final accessToken = await StorageService.getAccessToken();
    return await _dio.get(
      path,
      options: Options(
        headers: {'Authorization': 'Bearer $accessToken'},
      ),
    );
  }

  Future<Response> _authorizedPost(String path, dynamic data) async {
    final accessToken = await StorageService.getAccessToken();
    return await _dio.post(
      path,
      data: data,
      options: Options(
        headers: {'Authorization': 'Bearer $accessToken'},
      ),
    );
  }

  Future<Response> _authorizedPatch(String path, dynamic data) async {
    final accessToken = await StorageService.getAccessToken();
    return await _dio.patch(
      path,
      data: data,
      options: Options(
        headers: {'Authorization': 'Bearer $accessToken'},
      ),
    );
  }

  Future<Response> _authorizedPut(String path, dynamic data) async {
    final accessToken = await StorageService.getAccessToken();
    return await _dio.put(
      path,
      data: data,
      options: Options(
        headers: {'Authorization': 'Bearer $accessToken'},
      ),
    );
  }

  Future<Response> _authorizedDelete(String path) async {
    final accessToken = await StorageService.getAccessToken();
    return await _dio.delete(
      path,
      options: Options(
        headers: {'Authorization': 'Bearer $accessToken'},
      ),
    );
  }
}
