import 'package:flutter/material.dart';
import '../feature/auth/login/login_screen.dart';
import '../feature/auth/register/register_screen.dart';
import '../feature/dashboard/dashboard_screen.dart';
import '../feature/scan/scan_screen.dart';
import '../feature/profile/profile_screen.dart';
import '../feature/profile/update_profile_screen.dart';
import '../feature/prediction/prediction_screen.dart';

class AppRouter {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static const String initialRoute = '/login';
  static const String login = '/login';
  static const String register = '/register';
  static const String dashboard = '/dashboard';
  static const String scan = '/scan';
  static const String profile = '/profile';
  static const String updateProfile = '/profile/update';
  static const String prediction = '/prediction';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
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
      case login:
      default:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
    }
  }
}
