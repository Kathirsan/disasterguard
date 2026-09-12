import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_button.dart';
import '../data/models/incident_model.dart';
import '../providers/incident_provider.dart';
import '../widgets/incident_status_badge.dart';
import 'incident_detail_page.dart';

class MyReportsPage extends StatefulWidget {
  final VoidCallback onNavigateToReport;

  const MyReportsPage({super.key, required this.onNavigateToReport});

  @override
  State<MyReportsPage> createState() => _MyReportsPageState();
}

class _MyReportsPageState extends State<MyReportsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<IncidentProvider>(context, listen: false).fetchMyIncidents();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<IncidentProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('My Disaster Reports', style: AppTypography.titleLarge),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => provider.fetchMyIncidents(),
          ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: () => provider.fetchMyIncidents(),
              color: AppColors.primary,
              child: provider.myIncidents.isEmpty
                  ? Center(
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: AppSpacing.paddingPage,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 400),
                          child: AppCard(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.assignment_turned_in_outlined, size: 54, color: AppColors.textMuted),
                                const SizedBox(height: AppSpacing.md),
                                Text('No Reports Submitted Yet', style: AppTypography.titleLarge),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  'When you report floods, blocked roads, or fallen trees, your reports will appear here for status tracking.',
                                  textAlign: TextAlign.center,
                                  style: AppTypography.bodyMedium,
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                AppButton(
                                  text: 'Report a Disaster',
                                  icon: Icons.add_alert_rounded,
                                  onPressed: widget.onNavigateToReport,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: AppSpacing.paddingPage,
                      itemCount: provider.myIncidents.length,
                      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
                      itemBuilder: (context, index) {
                        final incident = provider.myIncidents[index];
                        return _IncidentListItem(
                          incident: incident,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => IncidentDetailPage(incidentId: incident.id),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
    );
  }
}

class _IncidentListItem extends StatelessWidget {
  final IncidentModel incident;
  final VoidCallback onTap;

  const _IncidentListItem({required this.incident, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AppCard(
        padding: AppSpacing.paddingMd,
        child: Row(
          crossAxisAlignment: CrossAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                borderRadius: AppSpacing.borderRadiusMd,
              ),
              child: Icon(incident.hazardType.icon, color: AppColors.primary, size: 28),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          incident.hazardType.displayLabel,
                          style: AppTypography.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IncidentStatusBadge(status: incident.status),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    incident.description,
                    style: AppTypography.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          incident.addressText ?? '${incident.latitude.toStringAsFixed(3)}, ${incident.longitude.toStringAsFixed(3)}',
                          style: AppTypography.labelSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
