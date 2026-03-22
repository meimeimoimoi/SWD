import 'package:flutter/foundation.dart';
import '../share/services/dashboard_service.dart';

class DashboardProvider with ChangeNotifier {
  final DashboardService _service = DashboardService();

  DashboardStats? _adminStats;
  List<ActivityLogItem> _adminLogs = [];
  List<NotificationItem> _userNotifications = [];
  List<ActivityLogItem> _userActivities = [];
  bool _isLoading = false;

  DashboardStats? get adminStats => _adminStats;
  List<ActivityLogItem> get adminLogs => _adminLogs;
  List<NotificationItem> get userNotifications => _userNotifications;
  List<ActivityLogItem> get userActivities => _userActivities;
  bool get isLoading => _isLoading;

  List<dynamic> _adminUsers = [];
  List<dynamic> get adminUsers => _adminUsers;

  String? _adminUsersSearch;
  String? _adminUsersRole;
  String _adminUsersSortBy = 'email';
  String _adminUsersSortOrder = 'asc';

  List<dynamic> _feedbackList = [];
  List<dynamic> get feedbackList => _feedbackList;

  Map<String, dynamic>? _adminPredictionStats;
  List<Map<String, dynamic>> _adminModelAccuracy = [];
  int _criticalFeedbackCount = 0;

  Map<String, dynamic>? get adminPredictionStats => _adminPredictionStats;
  List<Map<String, dynamic>> get adminModelAccuracy => _adminModelAccuracy;
  int get criticalFeedbackCount => _criticalFeedbackCount;

  Future<void> fetchAdminDashboard() async {
    _isLoading = true;
    notifyListeners();

    _adminStats = await _service.getAdminStats();
    _adminPredictionStats = await _service.getAdminPredictionStats(days: 7);
    _adminModelAccuracy = await _service.getModelAccuracy();
    _adminLogs = await _service.getAdminActivityLogs(count: 25);
    final feedback = await _service.getFeedbackList();
    _criticalFeedbackCount = feedback.where((e) {
      if (e is! Map) return false;
      final m = Map<String, dynamic>.from(e);
      final s = m['score'];
      final n = s is int
          ? s
          : (s is num ? s.round() : int.tryParse('$s') ?? 99);
      return n <= 2;
    }).length;

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchFeedbackList() async {
    _isLoading = true;
    notifyListeners();
    _feedbackList = await _service.getFeedbackList();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchAdminData() async {
    _isLoading = true;
    notifyListeners();

    _adminStats = await _service.getAdminStats();
    _adminLogs = await _service.getAdminActivityLogs();
    _adminUsersSearch = null;
    _adminUsersRole = null;
    _adminUsers = await _service.getAdminUsers(
      sortBy: _adminUsersSortBy,
      sortOrder: _adminUsersSortOrder,
    );
    _feedbackList = await _service.getFeedbackList();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchAdminUsers() async {
    _isLoading = true;
    notifyListeners();
    _adminUsers = await _service.getAdminUsers(
      search: _adminUsersSearch,
      role: _adminUsersRole,
      sortBy: _adminUsersSortBy,
      sortOrder: _adminUsersSortOrder,
    );
    _isLoading = false;
    notifyListeners();
  }

  Future<void> setAdminUsersFilters({
    String? search,
    String? role,
    String? sortBy,
    String? sortOrder,
  }) async {
    if (search != null) {
      _adminUsersSearch = search.trim().isEmpty ? null : search.trim();
    }
    if (role != null) {
      _adminUsersRole = role.trim().isEmpty ? null : role.trim();
    }
    if (sortBy != null && sortBy.isNotEmpty) {
      _adminUsersSortBy = sortBy;
    }
    if (sortOrder != null && sortOrder.isNotEmpty) {
      _adminUsersSortOrder = sortOrder;
    }
    await fetchAdminUsers();
  }

  Future<bool> createUser(String email, String password, String role) async {
    _isLoading = true;
    notifyListeners();
    final success = await _service.createUser(email, password, role);
    if (success) {
      _adminUsers = await _service.getAdminUsers(
        search: _adminUsersSearch,
        role: _adminUsersRole,
        sortBy: _adminUsersSortBy,
        sortOrder: _adminUsersSortOrder,
      );
    }
    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<bool> updateUserStatus(int userId, String status) async {
    _isLoading = true;
    notifyListeners();
    final success = await _service.updateUserStatus(userId, status);
    // Always reload so UI matches server (PATCH may succeed even if client misread response).
    _adminUsers = await _service.getAdminUsers(
      search: _adminUsersSearch,
      role: _adminUsersRole,
      sortBy: _adminUsersSortBy,
      sortOrder: _adminUsersSortOrder,
    );
    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<bool> updateUserRole(int userId, String role) async {
    _isLoading = true;
    notifyListeners();
    final success = await _service.updateUserRole(userId, role);
    if (success) {
      _adminUsers = await _service.getAdminUsers(
        search: _adminUsersSearch,
        role: _adminUsersRole,
        sortBy: _adminUsersSortBy,
        sortOrder: _adminUsersSortOrder,
      );
    }
    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<void> fetchUserData() async {
    _isLoading = true;
    notifyListeners();

    _userNotifications = await _service.getUserNotifications();
    _userActivities = await _service.getUserActivities();

    _isLoading = false;
    notifyListeners();
  }
}
