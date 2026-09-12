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
import 'in_progress_job_screen.dart';

class AssignedJobsScreen extends StatefulWidget {
  const AssignedJobsScreen({super.key});

  @override
  State<AssignedJobsScreen> createState() => _AssignedJobsScreenState();
}

class _AssignedJobsScreenState extends State<AssignedJobsScreen> {
  String _selectedFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CrewProvider>(context, listen: false).fetchAssignments();
    });
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.roleCrew,
      backgroundColor: AppColors.surfaceElevated,
      labelStyle: AppTypography.labelSmall.copyWith(
        color: isSelected ? AppColors.background : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedFilter = value;
          });
        }
      },
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
        List<CrewAssignmentModel> jobs = provider.assignments;
        if (_selectedFilter != 'ALL') {
          jobs = jobs.where((j) => j.status == _selectedFilter).toList();
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Padding(
            padding: AppSpacing.paddingPage,
            child: Column(
              crossAxisAlignment: CrossAlignment.start,
              children: [
                Text('Assigned Emergency Jobs', style: AppTypography.displayMedium.copyWith(fontSize: 20)),
                const SizedBox(height: AppSpacing.xs),
                Text('Manage field assignments dispatches.', style: AppTypography.bodyMedium),
                const SizedBox(height: AppSpacing.md),

                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All Jobs', 'ALL'),
                      const SizedBox(width: AppSpacing.xs),
                      _buildFilterChip('New Assigned', 'ASSIGNED'),
                      const SizedBox(width: AppSpacing.xs),
                      _buildFilterChip('Accepted', 'ACCEPTED'),
                      const SizedBox(width: AppSpacing.xs),
                      _buildFilterChip('In Progress', 'IN_PROGRESS'),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                Expanded(
                  child: provider.isLoading && provider.assignments.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : jobs.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.assignment_turned_in_rounded, size: 48, color: AppColors.textTertiary),
                                  const SizedBox(height: AppSpacing.sm),
                                  Text('No Jobs Found', style: AppTypography.titleMedium),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text('No active assignments match the selected filter.', style: AppTypography.bodySmall),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: () => provider.fetchAssignments(),
                              child: ListView.separated(
                                itemCount: jobs.length,
                                separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                                itemBuilder: (context, index) {
                                  final job = jobs[index];
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
                                                  Text(
                                                    inc?.hazardType.replaceAll('_', ' ') ?? 'HAZARD',
                                                    style: AppTypography.titleMedium,
                                                  ),
                                                  const SizedBox(width: AppSpacing.xs),
                                                  Text(
                                                    '#${job.id}',
                                                    style: AppTypography.labelSmall.copyWith(color: AppColors.primary),
                                                  ),
                                                ],
                                              ),
                                              _buildStatusChip(job.status),
                                            ],
                                          ),
                                          const SizedBox(height: AppSpacing.xs),
                                          Text(
                                            inc?.description ?? 'Emergency Report',
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
                                          const SizedBox(height: AppSpacing.sm),

                                          // Quick action buttons
                                          if (job.status == 'ASSIGNED') ...[
                                            AppButton(
                                              text: 'ACCEPT JOB',
                                              icon: Icons.check_circle_outline_rounded,
                                              onPressed: () async {
                                                await provider.acceptAssignment(job.id);
                                              },
                                            ),
                                          ] else if (job.status == 'ACCEPTED') ...[
                                            AppButton(
                                              text: 'START WORK',
                                              icon: Icons.play_arrow_rounded,
                                              onPressed: () async {
                                                final ok = await provider.startJob(job.id);
                                                if (ok && context.mounted) {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (_) => InProgressJobScreen(assignmentId: job.id),
                                                    ),
                                                  );
                                                }
                                              },
                                            ),
                                          ] else if (job.status == 'IN_PROGRESS') ...[
                                            AppButton(
                                              text: 'CONTINUE WORKFLOW',
                                              icon: Icons.engineering_rounded,
                                              variant: AppButtonVariant.secondary,
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) => InProgressJobScreen(assignmentId: job.id),
                                                  ),
                                                );
                                              },
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
