import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../providers/authority_provider.dart';
import 'authority_incident_detail_screen.dart';

class AuthorityMapTab extends StatefulWidget {
  const AuthorityMapTab({super.key});

  @override
  State<AuthorityMapTab> createState() => _AuthorityMapTabState();
}

class _AuthorityMapTabState extends State<AuthorityMapTab> {
  final MapController _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthorityProvider>(
      builder: (context, provider, child) {
        final incidents = provider.incidentsList;

        // Calculate map center
        LatLng center = const LatLng(6.9271, 79.8612); // Default Colombo coordinates
        if (incidents.isNotEmpty) {
          final firstLat = (incidents[0]['latitude'] as num?)?.toDouble() ?? 6.9271;
          final firstLon = (incidents[0]['longitude'] as num?)?.toDouble() ?? 79.8612;
          center = LatLng(firstLat, firstLon);
        }

        final markers = incidents.map((item) {
          final lat = (item['latitude'] as num?)?.toDouble() ?? 0.0;
          final lon = (item['longitude'] as num?)?.toDouble() ?? 0.0;
          final verification = item['verification'] as Map<String, dynamic>?;
          final riskLevel = verification?['risk_level'] ?? 'LOW';
          final hazard = item['hazard_type'] ?? 'FLOOD';

          Color markerColor;
          if (riskLevel == 'CRITICAL' || riskLevel == 'HIGH') {
            markerColor = AppColors.primary;
          } else if (riskLevel == 'MODERATE') {
            markerColor = AppColors.warning;
          } else {
            markerColor = AppColors.accentCyan;
          }

          return Marker(
            point: LatLng(lat, lon),
            width: 44,
            height: 44,
            child: GestureDetector(
              onTap: () => _showIncidentBottomSheet(context, item),
              child: Container(
                decoration: BoxDecoration(
                  color: markerColor.withOpacity(0.9),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: markerColor.withOpacity(0.5),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  _getHazardIcon(hazard),
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          );
        }).toList();

        return Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: center,
                initialZoom: 12.5,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'org.disasterguard.app',
                ),
                MarkerLayer(markers: markers),
              ],
            ),

            // Top Map Overlay Legend & Recenter Controls
            Positioned(
              top: AppSpacing.md,
              left: AppSpacing.md,
              right: AppSpacing.md,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.surface.withOpacity(0.9),
                  borderRadius: AppSpacing.borderRadiusMd,
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.map_rounded, color: AppColors.roleAuthority, size: 20),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          'Live Incident Map (${markers.length})',
                          style: AppTypography.titleSmall,
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        _buildLegendItem('Critical', AppColors.primary),
                        const SizedBox(width: 8),
                        _buildLegendItem('Moderate', AppColors.warning),
                        const SizedBox(width: 8),
                        _buildLegendItem('Low', AppColors.accentCyan),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(fontSize: 10, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  void _showIncidentBottomSheet(BuildContext context, Map<String, dynamic> item) {
    final verification = item['verification'] as Map<String, dynamic>?;
    final hazard = item['hazard_type'] ?? 'FLOOD';
    final riskLevel = verification?['risk_level'] ?? 'LOW';
    final riskScore = verification?['risk_score'] ?? 0;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: AppSpacing.paddingPage,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    hazard.replaceAll('_', ' '),
                    style: AppTypography.displayMedium.copyWith(fontSize: 20),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.2),
                      borderRadius: AppSpacing.borderRadiusSm,
                      border: Border.all(color: AppColors.primary),
                    ),
                    child: Text(
                      '$riskLevel ($riskScore/100)',
                      style: AppTypography.labelSmall.copyWith(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                item['description'] ?? '',
                style: AppTypography.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Location: ${item['address_text'] ?? "GPS Coordinates"}',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                text: 'Inspect Incident & Action',
                icon: Icons.shield_rounded,
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AuthorityIncidentDetailScreen(
                        incidentId: item['id'],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
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
