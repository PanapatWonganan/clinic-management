import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'constants/app_config.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'services/auth_service.dart';
import 'services/delivery_service.dart';

// Global navigator key — used by ApiService to push the user back to the
// login screen when the server invalidates their token, so they don't get
// stuck on a screen that loops 401s on every interaction.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('th_TH', null);

  // โหลด token จาก storage
  await AuthService.instance.loadTokenFromStorage();

  // Dev-only: probe the delivery API so we catch config regressions early.
  // Production boot should not block on an auxiliary network call.
  if (AppConfig.isDevelopment) {
    DeliveryService.testApiConnection().catchError((_) {});
  }

  runApp(const ClinicApp());
}

class ClinicApp extends StatelessWidget {
  const ClinicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Exquiller Member',
      debugShowCheckedModeBanner: false,
      navigatorKey: appNavigatorKey,
      theme: ThemeData(
        fontFamily: 'Prompt',
        primarySwatch: Colors.purple,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          systemOverlayStyle: SystemUiOverlayStyle.light,
        ),
      ),
      home: AuthService.instance.isLoggedIn
          ? const HomeScreen()
          : const LoginScreen(),
    );
  }
}
