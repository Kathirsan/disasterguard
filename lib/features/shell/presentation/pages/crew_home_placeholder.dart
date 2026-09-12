import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class CrewHomePlaceholder extends StatelessWidget {
  const CrewHomePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.shield_rounded, color: AppColors.primary, size: 22),
            const SizedBox(width: AppSpacing.xs),
            Text('DisasterGuard', style: AppTypography.titleMedium),
            const SizedBox(width: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.roleCrew.withOpacity(0.2),
                borderRadius: AppSpacing.borderRadiusSm,
                border: Border.all(color: AppColors.roleCrew),
              ),
              child: Text(
                'FIELD CREW',
                style: AppTypography.labelSmall.copyWith(color: AppColors.roleCrew),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.textSecondary),
            tooltip: 'Logout',
            onPressed: () => authProvider.logout(),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: AppSpacing.paddingPage,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: AppCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircleAvatar(
                    radius: 32,
                    backgroundColor: AppColors.roleCrew,
                    child: Icon(Icons.engineering_rounded, size: 36, color: AppColors.background),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    user?.fullName ?? 'Field Crew Lead',
                    style: AppTypography.displayMedium.copyWith(fontSize: 22),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    user?.email ?? '',
                    style: AppTypography.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Container(
                    width: double.infinity,
                    padding: AppSpacing.paddingMd,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: AppSpacing.borderRadiusMd,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAlignment.start,
                      children: [
                        Text(
                          '🚐 Field Operations Portal (Phase 1 Ready)',
                          style: AppTypography.titleMedium.copyWith(color: AppColors.roleCrew),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Role-based access granted. Incident assignment response, live navigation, and resolution evidence submission ready for Phase 4 rollout.',
                          style: AppTypography.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AppButton(
                    text: 'Sign Out',
                    variant: AppButtonVariant.secondary,
                    icon: Icons.logout_rounded,
                    onPressed: () => authProvider.logout(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
