import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../providers/crew_provider.dart';
import 'job_details_screen.dart';

class CompletedJobsScreen extends StatefulWidget {
  const CompletedJobsScreen({super.key});

  @override
  State<CompletedJobsScreen> createState() => _CompletedJobsScreenState();
}

class _CompletedJobsScreenState extends State<CompletedJobsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CrewProvider>(context, listen: false).fetchCompletedJobs();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CrewProvider>(
      builder: (context, provider, child) {
        final jobs = provider.completedJobs;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Padding(
            padding: AppSpacing.paddingPage,
            child: Column(
              crossAxisAlignment: CrossAlignment.start,
              children: [
                Text('Completed Jobs History', style: AppTypography.displayMedium.copyWith(fontSize: 20)),
                const SizedBox(height: AppSpacing.xs),
                Text('Archive of resolved hazard assignments.', style: AppTypography.bodyMedium),
                const SizedBox(height: AppSpacing.md),

                Expanded(
                  child: provider.isLoading && jobs.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : jobs.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.history_rounded, size: 48, color: AppColors.textTertiary),
                                  const SizedBox(height: AppSpacing.sm),
                                  Text('No Completed Jobs', style: AppTypography.titleMedium),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text('Finished assignments will appear here.', style: AppTypography.bodySmall),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: () => provider.fetchCompletedJobs(),
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
                                                  const Icon(Icons.verified_rounded, color: AppColors.success, size: 20),
                                                  const SizedBox(width: AppSpacing.xs),
                                                  Text(
                                                    inc?.hazardType.replaceAll('_', ' ') ?? 'HAZARD',
                                                    style: AppTypography.titleMedium,
                                                  ),
                                                ],
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: AppColors.success.withOpacity(0.15),
                                                  borderRadius: AppSpacing.borderRadiusSm,
                                                  border: Border.all(color: AppColors.success),
                                                ),
                                                child: Text(
                                                  'RESOLVED',
                                                  style: AppTypography.labelSmall.copyWith(color: AppColors.success, fontSize: 10),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: AppSpacing.xs),
                                          Text(
                                            'Completed: ${job.completedAt?.toLocal().toString().substring(0, 16) ?? "N/A"}',
                                            style: AppTypography.bodySmall,
                                          ),
                                          const SizedBox(height: AppSpacing.xs),
                                          Text(
                                            inc?.description ?? '',
                                            style: AppTypography.bodyMedium,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (job.resolutionEvidenceUrl != null) ...[
                                            const SizedBox(height: AppSpacing.sm),
                                            ClipRRect(
                                              borderRadius: AppSpacing.borderRadiusSm,
                                              child: Image.network(
                                                job.resolutionEvidenceUrl!.startsWith('http')
                                                    ? job.resolutionEvidenceUrl!
                                                    : 'http://localhost:8000${job.resolutionEvidenceUrl}',
                                                height: 120,
                                                width: double.infinity,
                                                fit: BoxFit.cover,
                                              ),
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
