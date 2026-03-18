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

  Future<void> fetchAdminData() async {
    _isLoading = true;
    notifyListeners();

    _adminStats = await _service.getAdminStats();
    _adminLogs = await _service.getAdminActivityLogs();

    _isLoading = false;
    notifyListeners();
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
