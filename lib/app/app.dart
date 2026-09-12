import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'theme/app_colors.dart';
import 'theme/app_typography.dart';
import 'theme/app_spacing.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/register_page.dart';
import '../features/auth/data/models/user_model.dart';
import '../features/shell/presentation/pages/citizen_home_screen.dart';
import '../features/authority/presentation/pages/authority_home_screen.dart';
import '../features/crew/presentation/pages/crew_home_screen.dart';

class DisasterGuardApp extends StatefulWidget {
  const DisasterGuardApp({super.key});

  @override
  State<DisasterGuardApp> createState() => _DisasterGuardAppState();
}

class _DisasterGuardAppState extends State<DisasterGuardApp> {
  bool _isRegistering = false;

  void _showRegisterScreen() {
    setState(() {
      _isRegistering = true;
    });
  }

  void _showLoginScreen() {
    setState(() {
      _isRegistering = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DisasterGuard',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          switch (authProvider.status) {
            case AuthStatus.initial:
            case AuthStatus.loading:
              return const SplashScreen();
            case AuthStatus.unauthenticated:
              return _isRegistering
                  ? RegisterPage(onNavigateToLogin: _showLoginScreen)
                  : LoginPage(onNavigateToRegister: _showRegisterScreen);
            case AuthStatus.authenticated:
              final role = authProvider.currentUser?.role;
              switch (role) {
                case UserRole.AUTHORITY:
                  return const AuthorityHomeScreen();
                case UserRole.CREW:
                  return const CrewHomeScreen();
                case UserRole.CITIZEN:
                default:
                  return const CitizenHomeScreen();
              }
          }
        },
      ),
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 2),
              ),
              child: const Icon(
                Icons.shield_rounded,
                size: 64,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'DISASTERGUARD',
              style: AppTypography.displayLarge.copyWith(
                letterSpacing: 2,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Initializing System & Security Verification...',
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.xl),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
