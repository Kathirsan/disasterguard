import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/authority_provider.dart';
import 'authority_dashboard_tab.dart';
import 'authority_queue_tab.dart';
import 'authority_map_tab.dart';

class AuthorityHomeScreen extends StatefulWidget {
  const AuthorityHomeScreen({super.key});

  @override
  State<AuthorityHomeScreen> createState() => _AuthorityHomeScreenState();
}

class _AuthorityHomeScreenState extends State<AuthorityHomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authorityProvider = Provider.of<AuthorityProvider>(context, listen: false);
      authorityProvider.loadDashboard();
      authorityProvider.loadIncidentsList();
    });
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    final List<Widget> tabs = [
      AuthorityDashboardTab(
        onNavigateToQueue: () => _onTabTapped(1),
        onNavigateToMap: () => _onTabTapped(2),
      ),
      const AuthorityQueueTab(),
      const AuthorityMapTab(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.shield_rounded, color: AppColors.roleAuthority, size: 22),
            const SizedBox(width: AppSpacing.xs),
            Text('DisasterGuard', style: AppTypography.titleMedium),
            const SizedBox(width: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.roleAuthority.withOpacity(0.2),
                borderRadius: AppSpacing.borderRadiusSm,
                border: Border.all(color: AppColors.roleAuthority),
              ),
              child: Text(
                'AUTHORITY',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.roleAuthority,
                  fontWeight: FontWeight.bold,
                ),
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
        onTap: _onTabTapped,
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.roleAuthority,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.format_list_bulleted_rounded),
            label: 'Queue',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_rounded),
            label: 'Live Map',
          ),
        ],
      ),
    );
  }
}
