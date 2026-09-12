import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_role_chip.dart';
import '../../../../core/widgets/app_banner.dart';
import '../../data/models/user_model.dart';
import '../providers/auth_provider.dart';

class RegisterPage extends StatefulWidget {
  final VoidCallback onNavigateToLogin;

  const RegisterPage({super.key, required this.onNavigateToLogin});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  UserRole _selectedRole = UserRole.CITIZEN;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleRegister() async {
    FocusScope.of(context).unfocus();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    authProvider.clearError();

    final fullName = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (fullName.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields.')),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters long.')),
      );
      return;
    }

    await authProvider.register(
      fullName: fullName,
      email: email,
      password: password,
      role: _selectedRole,
    );
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
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAlignment.stretch,
              children: [
                // Header Branding
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.shield_rounded, size: 28, color: AppColors.primary),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'DISASTERGUARD',
                        style: AppTypography.titleLarge.copyWith(letterSpacing: 1.2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Register Card
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAlignment.start,
                    children: [
                      Text(
                        'Create Account',
                        style: AppTypography.displayMedium.copyWith(fontSize: 22),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Select your role and register to access DisasterGuard.',
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

                      // Role Selector
                      Text(
                        'SELECT YOUR ROLE',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: UserRole.values.map((role) {
                          return AppRoleChip(
                            role: role,
                            isSelected: _selectedRole == role,
                            onTap: () {
                              setState(() {
                                _selectedRole = role;
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      AppTextField(
                        label: 'Full Name',
                        hint: 'John Doe',
                        controller: _fullNameController,
                        prefixIcon: Icons.person_outline,
                      ),
                      const SizedBox(height: AppSpacing.md),
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
                        hint: 'At least 6 characters',
                        controller: _passwordController,
                        isPassword: true,
                        prefixIcon: Icons.lock_outline,
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      AppButton(
                        text: 'Register Account',
                        isLoading: isLoading,
                        icon: Icons.person_add_outlined,
                        onPressed: _handleRegister,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Back to Sign In
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: AppTypography.bodyMedium,
                    ),
                    GestureDetector(
                      onTap: widget.onNavigateToLogin,
                      child: Text(
                        'Sign In',
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
