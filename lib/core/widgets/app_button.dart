import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_typography.dart';

enum AppButtonVariant { primary, secondary, danger, outline }

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final AppButtonVariant variant;
  final double? width;
  final double height;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.variant = AppButtonVariant.primary,
    this.width,
    this.height = 50,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color fgColor;
    BorderSide border = BorderSide.none;

    switch (variant) {
      case AppButtonVariant.primary:
        bgColor = AppColors.primary;
        fgColor = Colors.white;
        break;
      case AppButtonVariant.secondary:
        bgColor = AppColors.surfaceElevated;
        fgColor = AppColors.textPrimary;
        border = const BorderSide(color: AppColors.border, width: 1);
        break;
      case AppButtonVariant.danger:
        bgColor = AppColors.error;
        fgColor = Colors.white;
        break;
      case AppButtonVariant.outline:
        bgColor = Colors.transparent;
        fgColor = AppColors.primary;
        border = const BorderSide(color: AppColors.primary, width: 1.5);
        break;
    }

    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: fgColor,
          side: border,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.borderRadiusMd,
          ),
        ),
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18, color: fgColor),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Text(
                    text,
                    style: AppTypography.labelLarge.copyWith(
                      color: fgColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
