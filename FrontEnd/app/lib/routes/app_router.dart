import 'package:flutter/material.dart';
import '../feature/auth/login/login_screen.dart';
import '../feature/auth/register/register_screen.dart';
import '../feature/dashboard/dashboard_screen.dart';
import '../feature/scan/scan_screen.dart';
import '../feature/profile/profile_screen.dart';

class AppRouter {
  static const String initialRoute = '/login';
  static const String login = '/login';
  static const String register = '/register';
  static const String dashboard = '/dashboard';
  static const String scan = '/scan';
  static const String profile = '/profile';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case dashboard:
        return MaterialPageRoute(builder: (_) => const DashboardScreen());
      case scan:
        return MaterialPageRoute(builder: (_) => const ScanScreen());
      case profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      case register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case login:
      default:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
    }
  }
}
