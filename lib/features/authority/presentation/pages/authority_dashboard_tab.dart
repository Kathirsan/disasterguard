import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../providers/authority_provider.dart';
import 'authority_incident_detail_screen.dart';

class AuthorityDashboardTab extends StatelessWidget {
  final VoidCallback onNavigateToQueue;
  final VoidCallback onNavigateToMap;

  const AuthorityDashboardTab({
    super.key,
    required this.onNavigateToQueue,
    required this.onNavigateToMap,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthorityProvider>(
      builder: (context, provider, child) {
        if (provider.status == AuthorityStatus.loading && provider.dashboardMetrics == null) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        final metrics = provider.dashboardMetrics ?? {
          'pending_verification': 0,
          'high_risk_incidents': 0,
          'critical_incidents': 0,
          'verified_incidents': 0,
          'dispatched_incidents': 0,
          'total_incidents': 0,
        };

        final recent = provider.recentIncidents;

        return RefreshIndicator(
          onRefresh: () => provider.loadDashboard(),
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: AppSpacing.paddingPage,
            child: Column(
              crossAxisAlignment: CrossAlignment.start,
              children: [
                // Top Header Welcome & Security Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAlignment.start,
                      children: [
                        Text(
                          'COMMAND & CONTROL ROOM',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.roleAuthority,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Incident Verification Center',
                          style: AppTypography.displaySmall.copyWith(fontSize: 22),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
                      onPressed: () => provider.loadDashboard(),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // Metrics Overview Grid (2x2)
                GridView.count(
                  crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
                  crossAxisSpacing: AppSpacing.md,
                  mainAxisSpacing: AppSpacing.md,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.4,
                  children: [
                    _buildMetricCard(
                      title: 'VERIFICATION QUEUE',
                      value: '${metrics['pending_verification'] ?? 0}',
                      subtitle: 'Pending Review',
                      icon: Icons.hourglass_top_rounded,
                      color: AppColors.roleAuthority,
                      onTap: onNavigateToQueue,
                    ),
                    _buildMetricCard(
                      title: 'HIGH / CRITICAL RISK',
                      value: '${(metrics['high_risk_incidents'] ?? 0) + (metrics['critical_incidents'] ?? 0)}',
                      subtitle: 'Requires Immediate Action',
                      icon: Icons.warning_amber_rounded,
                      color: AppColors.primary,
                      onTap: onNavigateToQueue,
                    ),
                    _buildMetricCard(
                      title: 'VERIFIED INCIDENTS',
                      value: '${metrics['verified_incidents'] ?? 0}',
                      subtitle: 'Confirmed Real Disasters',
                      icon: Icons.verified_user_rounded,
                      color: AppColors.accentCyan,
                      onTap: onNavigateToQueue,
                    ),
                    _buildMetricCard(
                      title: 'DISPATCHED CREWS',
                      value: '${metrics['dispatched_incidents'] ?? 0}',
                      subtitle: 'Active Field Responders',
                      icon: Icons.local_fire_department_rounded,
                      color: AppColors.roleCrew,
                      onTap: onNavigateToQueue,
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.xl),

                // Section Title: Quick Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.bolt_rounded, color: AppColors.roleAuthority, size: 20),
                        const SizedBox(width: AppSpacing.xs),
                        Text('Recent High-Priority Reports', style: AppTypography.titleMedium),
                      ],
                    ),
                    TextButton(
                      onPressed: onNavigateToQueue,
                      child: Text(
                        'View All Queue →',
                        style: AppTypography.labelMedium.copyWith(color: AppColors.roleAuthority),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),

                if (recent.isEmpty)
                  AppCard(
                    child: Padding(
                      padding: AppSpacing.paddingLg,
                      child: Center(
                        child: Text(
                          'No recent incidents reported.',
                          style: AppTypography.bodyMedium,
                        ),
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: recent.length,
                    separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final item = recent[index];
                      final riskScore = item['risk_score'] ?? 0;
                      final riskLevel = item['risk_level'] ?? 'LOW';
                      final hazard = item['hazard_type'] ?? 'FLOOD';
                      final statusStr = item['status'] ?? 'SUBMITTED';

                      Color badgeColor;
                      if (riskLevel == 'CRITICAL' || riskLevel == 'HIGH') {
                        badgeColor = AppColors.primary;
                      } else if (riskLevel == 'MODERATE') {
                        badgeColor = AppColors.warning;
                      } else {
                        badgeColor = AppColors.accentCyan;
                      }

                      return AppCard(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AuthorityIncidentDetailScreen(
                                incidentId: item['id'],
                              ),
                            ),
                          );
                        },
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.sm),
                              decoration: BoxDecoration(
                                color: badgeColor.withOpacity(0.15),
                                borderRadius: AppSpacing.borderRadiusSm,
                                border: Border.all(color: badgeColor),
                              ),
                              child: Icon(
                                _getHazardIcon(hazard),
                                color: badgeColor,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        hazard.replaceAll('_', ' '),
                                        style: AppTypography.titleSmall.copyWith(fontSize: 15),
                                      ),
                                      const SizedBox(width: AppSpacing.xs),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: badgeColor.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          '$riskLevel ($riskScore)',
                                          style: AppTypography.labelSmall.copyWith(
                                            color: badgeColor,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    item['description'] ?? '',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.bodySmall,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Location: ${item['address_text'] ?? "GPS Coordinates"}',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.textMuted,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Column(
                              crossAxisAlignment: CrossAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceElevated,
                                    borderRadius: AppSpacing.borderRadiusSm,
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Text(
                                    statusStr.replaceAll('_', ' '),
                                    style: AppTypography.labelSmall.copyWith(fontSize: 10),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textSecondary),
                              ],
                            ),
                          ],
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

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: AppSpacing.paddingMd,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppSpacing.borderRadiusMd,
          border: Border.all(color: color.withOpacity(0.5), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: AppTypography.labelSmall.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(icon, color: color, size: 20),
              ],
            ),
            Text(
              value,
              style: AppTypography.displayMedium.copyWith(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              subtitle,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textMuted,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getHazardIcon(String hazard) {
    switch (hazard) {
      case 'FLOOD':
        return Icons.water_drop_rounded;
      case 'FALLEN_TREE':
        return Icons.nature_rounded;
      case 'BLOCKED_ROAD':
        return Icons.warning_rounded;
      default:
        return Icons.report_problem_rounded;
    }
  }
}
