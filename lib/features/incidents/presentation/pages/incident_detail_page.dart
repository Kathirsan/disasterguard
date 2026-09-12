import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../data/models/incident_model.dart';
import '../providers/incident_provider.dart';
import '../widgets/incident_status_badge.dart';
import '../widgets/incident_status_timeline.dart';

class IncidentDetailPage extends StatefulWidget {
  final int incidentId;

  const IncidentDetailPage({super.key, required this.incidentId});

  @override
  State<IncidentDetailPage> createState() => _IncidentDetailPageState();
}

class _IncidentDetailPageState extends State<IncidentDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<IncidentProvider>(context, listen: false)
          .fetchIncidentDetails(widget.incidentId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<IncidentProvider>(context);
    final incident = provider.selectedIncident;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Incident #${widget.incidentId}', style: AppTypography.titleLarge),
      ),
      body: provider.isLoading || incident == null
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: AppSpacing.paddingPage,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 580),
                  child: Column(
                    crossAxisAlignment: CrossAlignment.stretch,
                    children: [
                      // Header Summary Card
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(incident.hazardType.icon, color: AppColors.primary, size: 26),
                                    const SizedBox(width: AppSpacing.sm),
                                    Text(incident.hazardType.displayLabel, style: AppTypography.displayMedium.copyWith(fontSize: 20)),
                                  ],
                                ),
                                IncidentStatusBadge(status: incident.status),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              incident.description,
                              style: AppTypography.bodyLarge,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Status Tracking Timeline
                      IncidentStatusTimeline(currentStatus: incident.status),
                      const SizedBox(height: AppSpacing.md),

                      // Evidence Image Container
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAlignment.start,
                          children: [
                            Text('EVIDENCE PHOTOGRAPH', style: AppTypography.labelSmall.copyWith(letterSpacing: 1)),
                            const SizedBox(height: AppSpacing.sm),
                            Container(
                              height: 220,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceElevated,
                                borderRadius: AppSpacing.borderRadiusMd,
                                border: Border.all(color: AppColors.border),
                              ),
                              child: incident.primaryImageUrl != null
                                  ? ClipRRect(
                                      borderRadius: AppSpacing.borderRadiusMd,
                                      child: Image.network(
                                        'http://127.0.0.1:8000${incident.primaryImageUrl}',
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => const Center(
                                          child: Icon(Icons.image_not_supported_outlined, size: 48, color: AppColors.textMuted),
                                        ),
                                      ),
                                    )
                                  : const Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.camera_alt_outlined, size: 42, color: AppColors.textMuted),
                                          SizedBox(height: 8),
                                          Text('Evidence Photo Attached', style: TextStyle(color: AppColors.textSecondary)),
                                        ],
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Location & Metadata Card
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAlignment.start,
                          children: [
                            Text('LOCATION & COORDINATES', style: AppTypography.labelSmall.copyWith(letterSpacing: 1)),
                            const SizedBox(height: AppSpacing.sm),
                            Row(
                              children: [
                                const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 22),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Text(
                                    incident.addressText ?? 'City Sector Center',
                                    style: AppTypography.titleMedium,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'GPS: ${incident.latitude.toStringAsFixed(5)}, ${incident.longitude.toStringAsFixed(5)}',
                              style: AppTypography.bodyMedium,
                            ),
                            const Divider(height: AppSpacing.xl, color: AppColors.border),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Reported Date:', style: AppTypography.labelSmall),
                                Text(incident.createdAt, style: AppTypography.bodyMedium),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
