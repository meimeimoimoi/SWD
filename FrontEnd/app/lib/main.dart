import 'package:app/feature/auth/login/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'routes/app_router.dart';
import 'share/services/auth_api_service.dart';
import 'share/theme/app_theme.dart';
import 'share/theme/theme_notifier.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  AuthApiService.onSessionExpired = () {
    final navigator = AppRouter.navigatorKey.currentState;
    if (navigator == null) {
      return;
    }
    navigator.pushNamedAndRemoveUntil(AppRouter.login, (route) => false);
  };
  runApp(MyApp(themeNotifier: ThemeNotifier(prefs: prefs)));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.themeNotifier});

  final ThemeNotifier themeNotifier;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: themeNotifier,
      child: Consumer<ThemeNotifier>(
        builder: (context, notifier, _) {
          return MaterialApp(
            title: 'SWD System',
            debugShowCheckedModeBanner: false,
            navigatorKey: AppRouter.navigatorKey,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: notifier.themeMode,
            initialRoute: AppRouter.initialRoute,
            onGenerateRoute: AppRouter.onGenerateRoute,
            onUnknownRoute: (_) =>
                MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        },
      ),
    );
  }
}
