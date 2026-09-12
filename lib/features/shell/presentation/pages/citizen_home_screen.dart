import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../incidents/presentation/providers/incident_provider.dart';
import '../../../incidents/presentation/pages/report_disaster_page.dart';
import '../../../incidents/presentation/pages/my_reports_page.dart';
import '../../../incidents/presentation/pages/incident_detail_page.dart';
import '../../../incidents/presentation/widgets/incident_status_badge.dart';
import '../../../map/presentation/pages/nearby_map_page.dart';
import '../../../alerts/presentation/widgets/citizen_alerts_widget.dart';

class CitizenHomeScreen extends StatefulWidget {
  const CitizenHomeScreen({super.key});

  @override
  State<CitizenHomeScreen> createState() => _CitizenHomeScreenState();
}

class _CitizenHomeScreenState extends State<CitizenHomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<IncidentProvider>(context, listen: false).fetchMyIncidents();
    });
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _CitizenHomeDashboard(
        onReportTap: () => _onTabTapped(2),
        onMapTap: () => _onTabTapped(1),
        onMyReportsTap: () => _onTabTapped(3),
      ),
      const NearbyMapPage(),
      ReportDisasterPage(onReportSubmitted: () => _onTabTapped(3)),
      MyReportsPage(onNavigateToReport: () => _onTabTapped(2)),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map_rounded),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_alert_outlined),
            activeIcon: Icon(Icons.add_alert_rounded),
            label: 'Report',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history_rounded),
            label: 'My Reports',
          ),
        ],
      ),
    );
  }
}

class _CitizenHomeDashboard extends StatelessWidget {
  final VoidCallback onReportTap;
  final VoidCallback onMapTap;
  final VoidCallback onMyReportsTap;

  const _CitizenHomeDashboard({
    required this.onReportTap,
    required this.onMapTap,
    required this.onMyReportsTap,
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final incidentProvider = Provider.of<IncidentProvider>(context);
    final user = authProvider.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.shield_rounded, color: AppColors.primary, size: 24),
            const SizedBox(width: AppSpacing.xs),
            Text('DISASTERGUARD', style: AppTypography.titleLarge.copyWith(letterSpacing: 1.2)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.textSecondary),
            tooltip: 'Sign Out',
            onPressed: () => authProvider.logout(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.paddingPage,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAlignment.start,
              children: [
                // User Greeting Card
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 22,
                      backgroundColor: AppColors.roleCitizen,
                      child: Icon(Icons.person_rounded, color: AppColors.background),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Column(
                      crossAxisAlignment: CrossAlignment.start,
                      children: [
                        Text('Welcome back,', style: AppTypography.bodyMedium),
                        Text(user?.fullName ?? 'Citizen User', style: AppTypography.titleLarge),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // Active Emergency Area Alerts Widget
                const CitizenAlertsWidget(latitude: 6.9271, longitude: 79.8612),

                // Emergency Hero Card
                AppCard(
                  backgroundColor: AppColors.surfaceElevated,
                  border: const BorderSide(color: AppColors.primary, width: 1.5),
                  child: Column(
                    crossAxisAlignment: CrossAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAlignment.start,
                              children: [
                                Text('EMERGENCY HAZARD REPORTING', style: AppTypography.labelSmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
                                Text('Spotted a Flood, Road Blockage or Fallen Tree?', style: AppTypography.titleMedium),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Submit evidence, GPS location & hazard photos directly to city emergency authorities.',
                        style: AppTypography.bodyMedium,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AppButton(
                        text: 'REPORT DISASTER NOW',
                        icon: Icons.add_alert_rounded,
                        onPressed: onReportTap,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Quick Action Cards
                Text('QUICK ACTIONS', style: AppTypography.labelSmall.copyWith(letterSpacing: 1, fontWeight: FontWeight.bold)),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: _QuickActionCard(
                        icon: Icons.map_outlined,
                        title: 'Nearby Map',
                        subtitle: 'View live hazards',
                        color: AppColors.accentCyan,
                        onTap: onMapTap,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _QuickActionCard(
                        icon: Icons.history_rounded,
                        title: 'My Reports',
                        subtitle: 'Track status',
                        color: AppColors.roleCitizen,
                        onTap: onMyReportsTap,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),

                // Recent Reports Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('YOUR RECENT REPORTS', style: AppTypography.labelSmall.copyWith(letterSpacing: 1, fontWeight: FontWeight.bold)),
                    GestureDetector(
                      onTap: onMyReportsTap,
                      child: Text('View All', style: AppTypography.labelSmall.copyWith(color: AppColors.accentCyan, decoration: TextDecoration.underline)),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                if (incidentProvider.myIncidents.isEmpty)
                  AppCard(
                    child: Padding(
                      padding: AppSpacing.paddingMd,
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: AppColors.textMuted),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Text(
                              'No recent disaster reports. Tap "REPORT DISASTER NOW" to submit a hazard.',
                              style: AppTypography.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Column(
                    children: incidentProvider.myIncidents.take(3).map((inc) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: AppCard(
                          padding: AppSpacing.paddingSm,
                          child: ListTile(
                            leading: Icon(inc.hazardType.icon, color: AppColors.primary),
                            title: Text(inc.hazardType.displayLabel, style: AppTypography.titleMedium),
                            subtitle: Text(inc.description, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.bodyMedium),
                            trailing: IncidentStatusBadge(status: inc.status),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => IncidentDetailPage(incidentId: inc.id),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AppCard(
        padding: AppSpacing.paddingMd,
        child: Column(
          crossAxisAlignment: CrossAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: AppSpacing.sm),
            Text(title, style: AppTypography.titleMedium),
            Text(subtitle, style: AppTypography.labelSmall),
          ],
        ),
      ),
    );
  }
}
