import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_typography.dart';
import '../../features/auth/data/models/user_model.dart';

class AppRoleChip extends StatelessWidget {
  final UserRole role;
  final bool isSelected;
  final VoidCallback onTap;

  const AppRoleChip({
    super.key,
    required this.role,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color activeColor;

    switch (role) {
      case UserRole.CITIZEN:
        icon = Icons.person_outline;
        activeColor = AppColors.roleCitizen;
        break;
      case UserRole.AUTHORITY:
        icon = Icons.shield_outlined;
        activeColor = AppColors.roleAuthority;
        break;
      case UserRole.CREW:
        icon = Icons.engineering_outlined;
        activeColor = AppColors.roleCrew;
        break;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: AppSpacing.borderRadiusMd,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withOpacity(0.15) : AppColors.surfaceElevated,
          borderRadius: AppSpacing.borderRadiusMd,
          border: Border.all(
            color: isSelected ? activeColor : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? activeColor : AppColors.textMuted,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              role.nameString,
              style: AppTypography.labelSmall.copyWith(
                color: isSelected ? activeColor : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
