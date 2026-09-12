import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'crew_dashboard_screen.dart';
import 'assigned_jobs_screen.dart';
import 'completed_jobs_screen.dart';

class CrewHomeScreen extends StatefulWidget {
  const CrewHomeScreen({super.key});

  @override
  State<CrewHomeScreen> createState() => _CrewHomeScreenState();
}

class _CrewHomeScreenState extends State<CrewHomeScreen> {
  int _currentIndex = 0;

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    final List<Widget> tabs = [
      CrewDashboardScreen(onNavigateTab: _onTabSelected),
      const AssignedJobsScreen(),
      const CompletedJobsScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.shield_rounded, color: AppColors.primary, size: 22),
            const SizedBox(width: AppSpacing.xs),
            Text('DisasterGuard', style: AppTypography.titleMedium),
            const SizedBox(width: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.roleCrew.withOpacity(0.2),
                borderRadius: AppSpacing.borderRadiusSm,
                border: Border.all(color: AppColors.roleCrew),
              ),
              child: Text(
                'FIELD CREW',
                style: AppTypography.labelSmall.copyWith(color: AppColors.roleCrew),
              ),
            ),
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
      body: IndexedStack(
        index: _currentIndex,
        children: tabs,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabSelected,
        selectedItemColor: AppColors.roleCrew,
        unselectedItemColor: AppColors.textSecondary,
        backgroundColor: AppColors.surface,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_rounded),
            label: 'Assigned Jobs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_rounded),
            label: 'Completed',
          ),
        ],
      ),
    );
  }
}
