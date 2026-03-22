import 'package:app/feature/admin/feedback/admin_feebackList_sceern.dart';
import 'package:flutter/material.dart';

import '../share/services/storage_service.dart';
import '../feature/admin/admin_illness_management_screen.dart';
import '../feature/admin/admin_model_management_screen.dart';
import '../feature/admin/admin_model_upload_screen.dart';
import '../feature/admin/admin_server_management_screen.dart';
import '../feature/admin/admin_profile_screen.dart';
import '../feature/admin/admin_dashboard_screen.dart';
import '../feature/admin/admin_user_screen.dart';
import '../feature/admin/setting/admin_setting_sceern.dart';
import '../feature/auth/login/login_screen.dart';
import '../feature/auth/register/register_screen.dart';
import '../feature/dashboard/dashboard_screen.dart';
import '../feature/feedback/feedback_screen.dart';
import '../feature/scan/scan_screen.dart';
import '../feature/profile/profile_screen.dart';
import '../feature/profile/update_profile_screen.dart';
import '../feature/history/hisstory_screen.dart';
import '../feature/prediction/assign_scan_to_tree_screen.dart';
import '../feature/prediction/prediction_screen.dart';
import '../feature/trees/tree_detail_screen.dart';
import '../feature/trees/trees_screen.dart';
import '../feature/trees/user_illness_detail_screen.dart';
import '../feature/trees/user_tree_models.dart';
import '../feature/notifications/notifications_screen.dart';
import '../feature/settings/settings_screen.dart';

class AppRouter {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static const String initialRoute = '/login';
  static const String login = '/login';
  static const String register = '/register';
  static const String dashboard = '/dashboard';
  static const String adminDashboard = '/admin/dashboard';
  static const String adminUsers = '/admin/users';
  static const String adminModels = '/admin/models';
  static const String adminModelUpload = '/admin/models/upload';
  static const String adminServer = '/admin/server';
  static const String adminIllnesses = '/admin/illnesses';
  static const String adminProfile = '/admin/profile';
  static const String adminFeedback = '/admin/feedback';
  static const String adminSettings = '/admin/settings';
  static const String scan = '/scan';
  static const String profile = '/profile';
  static const String updateProfile = '/profile/update';
  static const String prediction = '/prediction';
  static const String predictionAssignTree = '/prediction/assign-tree';
  static const String feedback = '/feedback';
  static const String history = '/history';
  static const String trees = '/trees';
  static const String treeDetail = '/trees/detail';
  static const String userIllnessDetail = '/trees/illness';
  static const String treatmentHub = '/treatments';
  static const String notifications = '/notifications';
  static const String appSettings = '/settings';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case adminDashboard:
        return MaterialPageRoute(builder: (_) => const AdminDashboardScreen());
      case adminUsers:
        return MaterialPageRoute(
          builder: (_) => const _AdminUsersAccessScreen(),
        );
      case adminModels:
        return MaterialPageRoute(
          builder: (_) => const AdminModelManagementScreen(),
        );
      case adminModelUpload:
        return MaterialPageRoute(
          builder: (_) => const AdminModelUploadScreen(),
        );
      case adminServer:
        return MaterialPageRoute(
          builder: (_) => const AdminServerManagementScreen(),
        );
      case adminIllnesses:
        return MaterialPageRoute(
          builder: (_) => const AdminIllnessManagementScreen(),
        );
      case adminProfile:
        return MaterialPageRoute(
          builder: (_) => const AdminProfileScreen(),
        );
      case adminFeedback:
        return MaterialPageRoute(
          builder: (_) => const AdminFeedbackListScreen(),
        );
      case adminSettings:
        return MaterialPageRoute(builder: (_) => const AdminSettingScreen());
      case dashboard:
        return MaterialPageRoute(builder: (_) => const DashboardScreen());
      case scan:
        return MaterialPageRoute(builder: (_) => const ScanScreen());
      case profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      case updateProfile:
        return MaterialPageRoute(builder: (_) => const UpdateProfileScreen());
      case register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case prediction:
        final result = settings.arguments as PredictionResult?;
        return MaterialPageRoute(
          builder: (_) => PredictionScreen(result: result),
        );
      case predictionAssignTree:
        final assignResult = settings.arguments;
        if (assignResult is! PredictionResult) {
          return MaterialPageRoute(
            builder: (_) => const PredictionScreen(),
          );
        }
        return MaterialPageRoute(
          builder: (_) => AssignScanToTreeScreen(result: assignResult),
        );

      case history:
        return MaterialPageRoute(builder: (_) => const HistoryScreen());
      case notifications:
        return MaterialPageRoute(builder: (_) => const NotificationsScreen());
      case appSettings:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      case trees:
        return MaterialPageRoute(builder: (_) => const TreesScreen());
      case treeDetail:
        final summary = settings.arguments;
        if (summary is! UserTreeSummary) {
          return MaterialPageRoute(builder: (_) => const TreesScreen());
        }
        return MaterialPageRoute(
          builder: (_) => TreeDetailScreen(summary: summary),
        );
      case userIllnessDetail:
        final args = settings.arguments;
        if (args is! UserIllnessDetailArgs) {
          return MaterialPageRoute(builder: (_) => const TreesScreen());
        }
        return MaterialPageRoute(
          builder: (_) => UserIllnessDetailScreen(
            item: args.item,
            recommendations: args.recommendations,
          ),
        );
      case feedback:
        final predictionResult = settings.arguments as PredictionResult?;
        return MaterialPageRoute(
          builder: (_) => FeedbackScreen(predictionResult: predictionResult),
        );
      case login:
      default:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
    }
  }
}

class _AdminUsersAccessScreen extends StatefulWidget {
  const _AdminUsersAccessScreen();

  @override
  State<_AdminUsersAccessScreen> createState() => _AdminUsersAccessScreenState();
}

class _AdminUsersAccessScreenState extends State<_AdminUsersAccessScreen> {
  Widget? _child;

  @override
  void initState() {
    super.initState();
    StorageService.canManageUsers().then((ok) {
      if (!mounted) return;
      setState(() {
        _child = ok ? const AdminUserScreen() : const AdminDashboardScreen();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return _child ??
        const Scaffold(
          body: Center(
            child: CircularProgressIndicator(color: Color(0xFF2D7B31)),
          ),
        );
  }
}
