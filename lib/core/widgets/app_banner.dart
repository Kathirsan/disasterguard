import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_typography.dart';

enum AppBannerType { error, success, info }

class AppBanner extends StatelessWidget {
  final String message;
  final AppBannerType type;

  const AppBanner({
    super.key,
    required this.message,
    this.type = AppBannerType.error,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color border;
    IconData icon;

    switch (type) {
      case AppBannerType.error:
        bg = AppColors.error.withOpacity(0.12);
        border = AppColors.error;
        icon = Icons.error_outline;
        break;
      case AppBannerType.success:
        bg = AppColors.success.withOpacity(0.12);
        border = AppColors.success;
        icon = Icons.check_circle_outline;
        break;
      case AppBannerType.info:
        bg = AppColors.info.withOpacity(0.12);
        border = AppColors.info;
        icon = Icons.info_outline;
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: border),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
