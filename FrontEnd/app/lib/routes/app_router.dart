import 'package:flutter/material.dart';
import '../feature/auth/login/login_screen.dart';
import '../feature/auth/register/register_screen.dart';

class AppRouter {
  static const String initialRoute = '/login';
  static const String login = '/login';
  static const String register = '/register';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case login:
      default:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
    }
  }
}
