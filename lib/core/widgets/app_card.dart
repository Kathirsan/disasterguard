import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final BorderSide? border;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.backgroundColor,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? AppSpacing.paddingLg,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surface,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.fromBorderSide(
          border ?? const BorderSide(color: AppColors.border, width: 1),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}
