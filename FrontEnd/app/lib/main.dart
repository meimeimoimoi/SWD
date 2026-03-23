import 'package:app/feature/auth/login/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'routes/app_router.dart';
import 'share/services/auth_api_service.dart';
import 'share/constants/app_brand.dart';
import 'share/theme/app_theme.dart';
import 'providers/dashboard_provider.dart';
import 'providers/theme_mode_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AuthApiService.onSessionExpired = () {
    final navigator = AppRouter.navigatorKey.currentState;
    if (navigator == null) {
      return;
    }
    navigator.pushNamedAndRemoveUntil(AppRouter.login, (route) => false);
  };
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => ThemeModeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeModeProvider>(
      builder: (context, theme, _) {
        return MaterialApp(
          title: AppBrand.appTitle,
          debugShowCheckedModeBanner: false,
          navigatorKey: AppRouter.navigatorKey,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: theme.themeMode,
          initialRoute: AppRouter.initialRoute,
          onGenerateRoute: AppRouter.onGenerateRoute,
          onUnknownRoute: (_) =>
              MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      },
    );
  }
}
