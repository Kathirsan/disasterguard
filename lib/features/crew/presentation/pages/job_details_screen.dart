import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_button.dart';
import '../providers/crew_provider.dart';
import 'in_progress_job_screen.dart';

class JobDetailsScreen extends StatefulWidget {
  final int assignmentId;

  const JobDetailsScreen({super.key, required this.assignmentId});

  @override
  State<JobDetailsScreen> createState() => _JobDetailsScreenState();
}

class _JobDetailsScreenState extends State<JobDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CrewProvider>(context, listen: false)
          .fetchAssignmentDetail(widget.assignmentId);
    });
  }

  Future<void> _openExternalNavigation(double lat, double lng) async {
    final googleMapsUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch external maps application')),
        );
      }
    }
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'COMPLETED':
        color = AppColors.success;
        break;
      case 'IN_PROGRESS':
        color = AppColors.warning;
        break;
      case 'ACCEPTED':
        color = AppColors.info;
        break;
      case 'ASSIGNED':
      default:
        color = AppColors.roleCrew;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: AppSpacing.borderRadiusSm,
        border: Border.all(color: color),
      ),
      child: Text(
        status.replaceAll('_', ' '),
        style: AppTypography.labelMedium.copyWith(color: color),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Assignment #${widget.assignmentId}', style: AppTypography.titleLarge),
      ),
      body: Consumer<CrewProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.selectedAssignment == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final job = provider.selectedAssignment;
          if (job == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
                  const SizedBox(height: AppSpacing.md),
                  Text('Assignment Not Found', style: AppTypography.titleMedium),
                  const SizedBox(height: AppSpacing.sm),
                  AppButton(
                    text: 'Go Back',
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            );
          }

          final inc = job.incident;

          return SingleChildScrollView(
            padding: AppSpacing.paddingPage,
            child: Column(
              crossAxisAlignment: CrossAlignment.start,
              children: [
                // Top Status Header Card
                AppCard(
                  child: Padding(
                    padding: AppSpacing.paddingMd,
                    child: Column(
                      crossAxisAlignment: CrossAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              inc?.hazardType.replaceAll('_', ' ') ?? 'HAZARD',
                              style: AppTypography.displayMedium.copyWith(fontSize: 22),
                            ),
                            _buildStatusChip(job.status),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Council Ticket: ${job.ticketNumber ?? "N/A"}',
                          style: AppTypography.titleSmall.copyWith(color: AppColors.primary),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Assigned: ${job.assignedAt.toLocal().toString().substring(0, 16)}',
                          style: AppTypography.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Authority Dispatch Instructions
                if (job.instructions != null && job.instructions!.isNotEmpty) ...[
                  AppCard(
                    child: Padding(
                      padding: AppSpacing.paddingMd,
                      child: Column(
                        crossAxisAlignment: CrossAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.admin_panel_settings_rounded, color: AppColors.roleAuthority, size: 20),
                              const SizedBox(width: AppSpacing.xs),
                              Text('Authority Dispatch Instructions', style: AppTypography.titleMedium.copyWith(color: AppColors.roleAuthority)),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(job.instructions!, style: AppTypography.bodyMedium),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],

                // Incident Details Card
                AppCard(
                  child: Padding(
                    padding: AppSpacing.paddingMd,
                    child: Column(
                      crossAxisAlignment: CrossAlignment.start,
                      children: [
                        Text('Operational Details', style: AppTypography.titleMedium),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          inc?.description ?? 'No description provided.',
                          style: AppTypography.bodyMedium,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        const Divider(color: AppColors.border),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: [
                            const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 20),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: Text(
                                inc?.addressText ?? 'Coordinates: ${inc?.latitude}, ${inc?.longitude}',
                                style: AppTypography.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Citizen Report Photo Evidence
                if (job.primaryImageUrl != null) ...[
                  AppCard(
                    child: Padding(
                      padding: AppSpacing.paddingMd,
                      child: Column(
                        crossAxisAlignment: CrossAlignment.start,
                        children: [
                          Text('Citizen Field Photo Evidence', style: AppTypography.titleMedium),
                          const SizedBox(height: AppSpacing.sm),
                          ClipRRect(
                            borderRadius: AppSpacing.borderRadiusMd,
                            child: Image.network(
                              job.primaryImageUrl!.startsWith('http')
                                  ? job.primaryImageUrl!
                                  : 'http://localhost:8000${job.primaryImageUrl}',
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                height: 160,
                                color: AppColors.surfaceElevated,
                                child: const Center(
                                  child: Icon(Icons.broken_image_rounded, size: 48, color: AppColors.textTertiary),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],

                // Action Buttons according to Job Status
                if (job.status == 'ASSIGNED') ...[
                  AppButton(
                    text: 'ACCEPT ASSIGNMENT',
                    icon: Icons.check_circle_outline_rounded,
                    isLoading: provider.isLoading,
                    onPressed: () async {
                      final success = await provider.acceptAssignment(job.id);
                      if (success && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Job Accepted! You can now start work.')),
                        );
                      }
                    },
                  ),
                ] else if (job.status == 'ACCEPTED') ...[
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          text: 'START WORK',
                          icon: Icons.play_arrow_rounded,
                          isLoading: provider.isLoading,
                          onPressed: () async {
                            final success = await provider.startJob(job.id);
                            if (success && mounted) {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => InProgressJobScreen(assignmentId: job.id),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: AppButton(
                          text: 'NAVIGATE',
                          variant: AppButtonVariant.secondary,
                          icon: Icons.navigation_rounded,
                          onPressed: () {
                            if (inc != null) {
                              _openExternalNavigation(inc.latitude, inc.longitude);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ] else if (job.status == 'IN_PROGRESS') ...[
                  AppButton(
                    text: 'OPEN IN-PROGRESS WORKFLOW',
                    icon: Icons.engineering_rounded,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => InProgressJobScreen(assignmentId: job.id),
                        ),
                      );
                    },
                  ),
                ] else if (job.status == 'COMPLETED') ...[
                  AppCard(
                    child: Padding(
                      padding: AppSpacing.paddingMd,
                      child: Column(
                        crossAxisAlignment: CrossAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.verified_rounded, color: AppColors.success, size: 24),
                              const SizedBox(width: AppSpacing.xs),
                              Text('Job Completed & Incident Resolved', style: AppTypography.titleMedium.copyWith(color: AppColors.success)),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Completed At: ${job.completedAt?.toLocal().toString().substring(0, 16) ?? "N/A"}',
                            style: AppTypography.bodySmall,
                          ),
                          if (job.resolutionEvidenceUrl != null) ...[
                            const SizedBox(height: AppSpacing.sm),
                            ClipRRect(
                              borderRadius: AppSpacing.borderRadiusMd,
                              child: Image.network(
                                job.resolutionEvidenceUrl!.startsWith('http')
                                    ? job.resolutionEvidenceUrl!
                                    : 'http://localhost:8000${job.resolutionEvidenceUrl}',
                                height: 180,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
