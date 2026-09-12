import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../authority/presentation/providers/authority_provider.dart';

class CitizenAlertsWidget extends StatefulWidget {
  final double latitude;
  final double longitude;

  const CitizenAlertsWidget({
    super.key,
    required this.latitude,
    required this.longitude,
  });

  @override
  State<CitizenAlertsWidget> createState() => _CitizenAlertsWidgetState();
}

class _CitizenAlertsWidgetState extends State<CitizenAlertsWidget> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AuthorityProvider>(context, listen: false)
          .fetchCitizenAlerts(widget.latitude, widget.longitude);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthorityProvider>(
      builder: (context, provider, child) {
        final alerts = provider.activeAlerts;
        if (alerts.isEmpty) return const SizedBox.shrink();

        return Column(
          children: alerts.map((alt) {
            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              padding: AppSpacing.paddingMd,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.15),
                borderRadius: AppSpacing.borderRadiusMd,
                border: Border.all(color: AppColors.primary, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAlignment.start,
                children: [
                  const Container(
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.campaign_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                alt.title,
                                style: AppTypography.titleSmall.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'EMERGENCY AREA ALERT',
                                style: AppTypography.labelSmall.copyWith(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          alt.message,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Issued by Authorities • Radius ${alt.radiusKm} km',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textMuted,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
