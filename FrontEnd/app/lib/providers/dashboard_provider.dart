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

  /// Last filters for GET /api/Admin/users (search, role, sort).
  String? _adminUsersSearch;
  String? _adminUsersRole;
  String _adminUsersSortBy = 'email';
  String _adminUsersSortOrder = 'asc';

  List<dynamic> _feedbackList = [];
  List<dynamic> get feedbackList => _feedbackList;

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

  /// Updates user list filters and refetches (OpenAPI query params).
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
