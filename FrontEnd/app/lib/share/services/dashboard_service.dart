import 'package:dio/dio.dart';
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
  static const String _baseUrl = 'http://10.0.2.2:5299';

  DashboardService({Dio? dio})
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

  Future<DashboardStats?> getAdminStats() async {
    try {
      final response = await _authorizedGet('/api/admin/stats');
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
      final response = await _authorizedGet('/api/User/notifications');
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
      final response = await _authorizedGet('/api/User/activities');
      if (response.data['success'] == true) {
        final List raw = response.data['data'] ?? [];
        return raw.map((e) => ActivityLogItem.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<dynamic>> getAdminUsers() async {
    try {
      final response = await _authorizedGet('/api/Admin/users');
      if (response.data['success'] == true) {
        return response.data['data'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> createUser(String email, String password, String role) async {
    try {
      final response = await _authorizedPost('/api/Admin/users', {
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
      final response = await _authorizedPatch('/api/Admin/users/$userId/status', {
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
}
