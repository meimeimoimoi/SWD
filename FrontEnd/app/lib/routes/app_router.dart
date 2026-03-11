import 'package:app/feature/admin/feedback/admin_feebackList_sceern.dart';
import 'package:flutter/material.dart';
import '../feature/admin/admin_dashboard_screen.dart';
import '../feature/admin/setting/admin_setting_sceern.dart';
import '../feature/admin/admin_user_screen.dart';
import '../feature/auth/login/login_screen.dart';
import '../feature/auth/register/register_screen.dart';
import '../feature/dashboard/dashboard_screen.dart';
import '../feature/feedback/feedback_sceern.dart';
import '../feature/scan/scan_screen.dart';
import '../feature/profile/profile_screen.dart';
import '../feature/profile/update_profile_screen.dart';
import '../feature/history/hisstory_screen.dart';
import '../feature/prediction/prediction_screen.dart';

class AppRouter {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static const String initialRoute = '/login';
  static const String login = '/login';
  static const String register = '/register';
  static const String dashboard = '/dashboard';
  static const String adminDashboard = '/admin/dashboard';
  static const String adminUsers = '/admin/users';
  static const String adminFeedback = '/admin/feedback';
  static const String adminSettings = '/admin/settings';
  static const String scan = '/scan';
  static const String profile = '/profile';
  static const String updateProfile = '/profile/update';
  static const String prediction = '/prediction';
  static const String feedback = '/feedback';
  static const String history = '/history';
  static const String treatmentHub = '/treatments';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case adminDashboard:
        return MaterialPageRoute(builder: (_) => const AdminDashboardScreen());
      case adminUsers:
        return MaterialPageRoute(builder: (_) => const AdminUserScreen());
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

      case history:
        return MaterialPageRoute(builder: (_) => const HistoryScreen());
      case feedback:
        return MaterialPageRoute(builder: (_) => const FeedbackScreen());
      case login:
      default:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
    }
  }
}
