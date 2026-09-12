import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_button.dart';
import '../providers/crew_provider.dart';
import '../models/crew_assignment_model.dart';
import 'job_details_screen.dart';

class CrewDashboardScreen extends StatefulWidget {
  final Function(int) onNavigateTab;

  const CrewDashboardScreen({super.key, required this.onNavigateTab});

  @override
  State<CrewDashboardScreen> createState() => _CrewDashboardScreenState();
}

class _CrewDashboardScreenState extends State<CrewDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CrewProvider>(context, listen: false).fetchDashboard();
    });
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: AppCard(
        padding: AppSpacing.paddingMd,
        child: Column(
          crossAxisAlignment: CrossAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 22),
                Text(
                  value,
                  style: AppTypography.displayMedium.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              title,
              style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: AppSpacing.borderRadiusSm,
        border: Border.all(color: color),
      ),
      child: Text(
        status.replaceAll('_', ' '),
        style: AppTypography.labelSmall.copyWith(color: color, fontSize: 10),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CrewProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.dashboardData == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = provider.dashboardData;

        return RefreshIndicator(
          onRefresh: () => provider.fetchDashboard(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: AppSpacing.paddingPage,
            child: Column(
              crossAxisAlignment: CrossAlignment.start,
              children: [
                Text(
                  'Field Operational Overview',
                  style: AppTypography.displayMedium.copyWith(fontSize: 20),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Active assignments & emergency dispatch queue.',
                  style: AppTypography.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.lg),

                // Stat Cards Row
                Row(
                  children: [
                    _buildStatCard('Total Jobs', '${data?.totalAssigned ?? 0}', Icons.assignment_rounded, AppColors.textPrimary),
                    const SizedBox(width: AppSpacing.sm),
                    _buildStatCard('New Assigned', '${data?.newAssignmentsCount ?? 0}', Icons.new_releases_rounded, AppColors.roleCrew),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    _buildStatCard('In Progress', '${data?.activeInProgressCount ?? 0}', Icons.engineering_rounded, AppColors.warning),
                    const SizedBox(width: AppSpacing.sm),
                    _buildStatCard('Completed', '${data?.completedCount ?? 0}', Icons.check_circle_rounded, AppColors.success),
                  ],
                ),

                const SizedBox(height: AppSpacing.xl),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Emergency Assignments',
                      style: AppTypography.titleLarge,
                    ),
                    TextButton(
                      onPressed: () => widget.onNavigateTab(1),
                      child: Text('View All', style: AppTypography.labelMedium.copyWith(color: AppColors.primary)),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),

                if (data == null || data.recentJobs.isEmpty)
                  AppCard(
                    child: Padding(
                      padding: AppSpacing.paddingLg,
                      child: Column(
                        children: [
                          const Icon(Icons.task_alt_rounded, size: 48, color: AppColors.success),
                          const SizedBox(height: AppSpacing.sm),
                          Text('No Active Assignments', style: AppTypography.titleMedium),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'You currently have no pending emergency assignments from authorities.',
                            style: AppTypography.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: data.recentJobs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final job = data.recentJobs[index];
                      final inc = job.incident;

                      return AppCard(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => JobDetailsScreen(assignmentId: job.id),
                            ),
                          );
                        },
                        child: Padding(
                          padding: AppSpacing.paddingMd,
                          child: Column(
                            crossAxisAlignment: CrossAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: AppColors.roleCrew.withOpacity(0.15),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.warning_amber_rounded, color: AppColors.roleCrew, size: 20),
                                      ),
                                      const SizedBox(width: AppSpacing.sm),
                                      Column(
                                        crossAxisAlignment: CrossAlignment.start,
                                        children: [
                                          Text(
                                            inc?.hazardType.replaceAll('_', ' ') ?? 'HAZARD',
                                            style: AppTypography.titleMedium,
                                          ),
                                          Text(
                                            'Ticket: ${job.ticketNumber ?? "N/A"}',
                                            style: AppTypography.labelSmall.copyWith(color: AppColors.textTertiary),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  _buildStatusChip(job.status),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                inc?.description ?? 'Emergency hazard report',
                                style: AppTypography.bodyMedium,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Row(
                                children: [
                                  const Icon(Icons.location_on_rounded, size: 14, color: AppColors.textSecondary),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      inc?.addressText ?? '${inc?.latitude}, ${inc?.longitude}',
                                      style: AppTypography.bodySmall,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
