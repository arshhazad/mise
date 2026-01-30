import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme/app_theme.dart';
import 'screens/auth_screen.dart';
import 'screens/dashboard_screen.dart';
import 'package:provider/provider.dart';
import 'services/auth_provider.dart';
import 'services/menu_provider.dart';
import 'screens/onboarding_screen.dart';
import 'screens/profile_setup_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://jpqlbwmhzpmexcrzrueb.supabase.co',
    anonKey: 'sb_publishable_puHLOw4stwgo__UEE3U3DQ_7CUVfU0J',
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => MenuProvider()),
      ],
      child: const MiseApp(),
    ),
  );
}

class MiseApp extends StatelessWidget {
  const MiseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mise',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (!auth.isAuthenticated) return const OnboardingScreen();
          if (auth.currentUser != null && !auth.currentUser!.onboardingCompleted) {
            return const ProfileSetupScreen();
          }
          return const DashboardScreen();
        },
      ),
    );
  }
}
