import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_banner.dart';
import '../providers/auth_provider.dart';

class LoginPage extends StatefulWidget {
  final VoidCallback onNavigateToRegister;

  const LoginPage({super.key, required this.onNavigateToRegister});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    FocusScope.of(context).unfocus();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    authProvider.clearError();

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in both email and password.')),
      );
      return;
    }

    await authProvider.login(email, password);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isLoading = authProvider.status == AuthStatus.loading;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: AppSpacing.paddingPage,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAlignment.stretch,
              children: [
                // Header Logo & Branding
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary.withOpacity(0.4), width: 1.5),
                    ),
                    child: const Icon(
                      Icons.shield_rounded,
                      size: 44,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'DISASTERGUARD',
                  textAlign: TextAlign.center,
                  style: AppTypography.displayLarge.copyWith(
                    letterSpacing: 1.5,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'AI-Powered Emergency Response Platform',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.xl),

                // Form Card
                AppCard(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAlignment.start,
                      children: [
                        Text(
                          'Sign In',
                          style: AppTypography.displayMedium.copyWith(fontSize: 22),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Enter your account details to access the system.',
                          style: AppTypography.bodyMedium,
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        if (authProvider.errorMessage != null) ...[
                          AppBanner(
                            message: authProvider.errorMessage!,
                            type: AppBannerType.error,
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],

                        AppTextField(
                          label: 'Email Address',
                          hint: 'citizen@disasterguard.org',
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: Icons.email_outlined,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppTextField(
                          label: 'Password',
                          hint: '••••••••',
                          controller: _passwordController,
                          isPassword: true,
                          prefixIcon: Icons.lock_outline,
                        ),
                        const SizedBox(height: AppSpacing.xl),

                        AppButton(
                          text: 'Sign In',
                          isLoading: isLoading,
                          icon: Icons.login_rounded,
                          onPressed: _handleLogin,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Register Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: AppTypography.bodyMedium,
                    ),
                    GestureDetector(
                      onTap: widget.onNavigateToRegister,
                      child: Text(
                        'Register Now',
                        style: AppTypography.labelLarge.copyWith(
                          color: AppColors.accentCyan,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.accentCyan,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
