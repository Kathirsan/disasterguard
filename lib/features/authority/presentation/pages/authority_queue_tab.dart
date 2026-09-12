import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../providers/authority_provider.dart';
import 'authority_incident_detail_screen.dart';

class AuthorityQueueTab extends StatefulWidget {
  const AuthorityQueueTab({super.key});

  @override
  State<AuthorityQueueTab> createState() => _AuthorityQueueTabState();
}

class _AuthorityQueueTabState extends State<AuthorityQueueTab> {
  String _selectedFilter = 'ALL';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AuthorityProvider>(context, listen: false).loadIncidentsList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthorityProvider>(
      builder: (context, provider, child) {
        final incidents = provider.incidentsList.where((item) {
          final verification = item['verification'] as Map<String, dynamic>?;
          final riskLevel = verification?['risk_level'] ?? 'LOW';
          final statusStr = item['status'] ?? '';

          if (_selectedFilter == 'VERIFICATION_REQUIRED' && statusStr != 'VERIFICATION_REQUIRED') {
            return false;
          } else if (_selectedFilter == 'HIGH_RISK' && riskLevel != 'HIGH') {
            return false;
          } else if (_selectedFilter == 'CRITICAL' && riskLevel != 'CRITICAL') {
            return false;
          } else if (_selectedFilter == 'VERIFIED' && statusStr != 'VERIFIED') {
            return false;
          } else if (_selectedFilter == 'DISPATCHED' && statusStr != 'DISPATCHED') {
            return false;
          } else if (_selectedFilter == 'REJECTED' && statusStr != 'REJECTED') {
            return false;
          }

          if (_searchQuery.isNotEmpty) {
            final desc = (item['description'] ?? '').toString().toLowerCase();
            final addr = (item['address_text'] ?? '').toString().toLowerCase();
            final hazard = (item['hazard_type'] ?? '').toString().toLowerCase();
            final query = _searchQuery.toLowerCase();
            return desc.contains(query) || addr.contains(query) || hazard.contains(query);
          }
          return true;
        }).toList();

        return Column(
          children: [
            // Filter Header Controls
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              color: AppColors.surface,
              child: Column(
                children: [
                  // Search Bar
                  TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: AppTypography.bodyMedium,
                    decoration: InputDecoration(
                      hintText: 'Search queue by address, hazard, or description...',
                      hintStyle: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, color: AppColors.textSecondary),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: AppColors.surfaceElevated,
                      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: AppSpacing.borderRadiusMd,
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: AppSpacing.borderRadiusMd,
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: AppSpacing.borderRadiusMd,
                        borderSide: const BorderSide(color: AppColors.roleAuthority),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Horizontal Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('ALL', 'All Queue'),
                        const SizedBox(width: AppSpacing.xs),
                        _buildFilterChip('VERIFICATION_REQUIRED', '⏳ Pending Review'),
                        const SizedBox(width: AppSpacing.xs),
                        _buildFilterChip('CRITICAL', '🔴 Critical Risk'),
                        const SizedBox(width: AppSpacing.xs),
                        _buildFilterChip('HIGH_RISK', '🟠 High Risk'),
                        const SizedBox(width: AppSpacing.xs),
                        _buildFilterChip('VERIFIED', '✅ Verified'),
                        const SizedBox(width: AppSpacing.xs),
                        _buildFilterChip('DISPATCHED', '🚒 Dispatched'),
                        const SizedBox(width: AppSpacing.xs),
                        _buildFilterChip('REJECTED', '❌ Rejected'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Incident List View
            Expanded(
              child: provider.status == AuthorityStatus.loading && incidents.isEmpty
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : RefreshIndicator(
                      onRefresh: () => provider.loadIncidentsList(),
                      color: AppColors.primary,
                      child: incidents.isEmpty
                          ? ListView(
                              padding: AppSpacing.paddingPage,
                              children: [
                                const SizedBox(height: 60),
                                Center(
                                  child: Column(
                                    children: [
                                      const Icon(Icons.search_off_rounded, size: 48, color: AppColors.textMuted),
                                      const SizedBox(height: AppSpacing.md),
                                      Text(
                                        'No incidents match selected filter',
                                        style: AppTypography.titleMedium,
                                      ),
                                      const SizedBox(height: AppSpacing.xs),
                                      Text(
                                        'Try clearing your search or switching filter chips.',
                                        style: AppTypography.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          : ListView.separated(
                              padding: AppSpacing.paddingPage,
                              itemCount: incidents.length,
                              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
                              itemBuilder: (context, index) {
                                final item = incidents[index];
                                final verification = item['verification'] as Map<String, dynamic>?;
                                final hazard = item['hazard_type'] ?? 'FLOOD';
                                final statusStr = item['status'] ?? 'SUBMITTED';
                                final riskLevel = verification?['risk_level'] ?? 'LOW';
                                final riskScore = verification?['risk_score'] ?? 0;
                                final agreement = verification?['hazard_agreement'] ?? 'HIGH';
                                final confidence = (verification?['ai_confidence'] as num?)?.toDouble() ?? 0.0;

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
                                  child: Column(
                                    crossAxisAlignment: CrossAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: badgeColor.withOpacity(0.2),
                                                  borderRadius: AppSpacing.borderRadiusSm,
                                                  border: Border.all(color: badgeColor),
                                                ),
                                                child: Text(
                                                  '$riskLevel RISK ($riskScore/100)',
                                                  style: AppTypography.labelSmall.copyWith(
                                                    color: badgeColor,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: AppSpacing.xs),
                                              if (agreement == 'HIGH')
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.success.withOpacity(0.15),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    'AI AGREE ${(confidence * 100).toInt()}%',
                                                    style: AppTypography.labelSmall.copyWith(
                                                      color: AppColors.success,
                                                      fontSize: 10,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: AppColors.surfaceElevated,
                                              borderRadius: AppSpacing.borderRadiusSm,
                                              border: Border.all(color: AppColors.border),
                                            ),
                                            child: Text(
                                              statusStr.replaceAll('_', ' '),
                                              style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: AppSpacing.md),
                                      Row(
                                        children: [
                                          Icon(
                                            _getHazardIcon(hazard),
                                            color: AppColors.textPrimary,
                                            size: 20,
                                          ),
                                          const SizedBox(width: AppSpacing.xs),
                                          Text(
                                            hazard.replaceAll('_', ' '),
                                            style: AppTypography.titleMedium,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: AppSpacing.xs),
                                      Text(
                                        item['description'] ?? '',
                                        style: AppTypography.bodyMedium,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: AppSpacing.sm),
                                      Row(
                                        children: [
                                          const Icon(Icons.location_on_rounded, size: 14, color: AppColors.textMuted),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              item['address_text'] ?? 'GPS Coordinates',
                                              style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Text(
                                            'Incident #${item['id']}',
                                            style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return ChoiceChip(
      label: Text(
        label,
        style: AppTypography.labelMedium.copyWith(
          color: isSelected ? AppColors.background : AppColors.textPrimary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedFilter = value),
      selectedColor: AppColors.roleAuthority,
      backgroundColor: AppColors.surfaceElevated,
      side: BorderSide(
        color: isSelected ? AppColors.roleAuthority : AppColors.border,
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
