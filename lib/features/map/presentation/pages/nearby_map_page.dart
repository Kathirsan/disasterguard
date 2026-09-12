import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../incidents/data/models/incident_model.dart';
import '../../../incidents/presentation/providers/incident_provider.dart';
import '../../../incidents/presentation/widgets/incident_status_badge.dart';
import '../../../incidents/presentation/pages/incident_detail_page.dart';

class NearbyMapPage extends StatefulWidget {
  const NearbyMapPage({super.key});

  @override
  State<NearbyMapPage> createState() => _NearbyMapPageState();
}

class _NearbyMapPageState extends State<NearbyMapPage> {
  final MapController _mapController = MapController();
  final LatLng _userLocation = const LatLng(6.9271, 79.8612); // Default Colombo Center
  IncidentModel? _selectedMarkerIncident;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<IncidentProvider>(context, listen: false).fetchNearbyIncidents(
        latitude: _userLocation.latitude,
        longitude: _userLocation.longitude,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<IncidentProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Nearby Hazards Map', style: AppTypography.titleLarge),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location_rounded),
            onPressed: () {
              _mapController.move(_userLocation, 13.0);
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => provider.fetchNearbyIncidents(
              latitude: _userLocation.latitude,
              longitude: _userLocation.longitude,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // OpenStreetMap Tile Layer
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _userLocation,
              initialZoom: 13.0,
              onTap: (_, __) {
                setState(() {
                  _selectedMarkerIncident = null;
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'org.disasterguard.app',
              ),
              MarkerLayer(
                markers: [
                  // User Current Location Marker
                  Marker(
                    point: _userLocation,
                    width: 44,
                    height: 44,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.accentCyan.withOpacity(0.3),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.accentCyan, width: 2),
                      ),
                      child: const Center(
                        child: Icon(Icons.person_pin_circle_rounded, color: AppColors.accentCyan, size: 28),
                      ),
                    ),
                  ),

                  // Nearby Incident Markers
                  ...provider.nearbyIncidents.map((incident) {
                    final isSelected = _selectedMarkerIncident?.id == incident.id;
                    final isResolved = incident.status == IncidentStatus.RESOLVED || incident.status == IncidentStatus.CLOSED;
                    final markerColor = isResolved ? AppColors.success : AppColors.primary;

                    return Marker(
                      point: LatLng(incident.latitude, incident.longitude),
                      width: 48,
                      height: 48,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedMarkerIncident = incident;
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected ? markerColor : AppColors.surface,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Colors.white : markerColor,
                              width: isSelected ? 2.5 : 1.5,
                            ),
                            boxShadow: const [
                              BoxShadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 3)),
                            ],
                          ),
                          child: Icon(
                            incident.hazardType.icon,
                            size: 24,
                            color: isSelected ? Colors.white : markerColor,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ],
          ),

          // Top Info Banner
          Positioned(
            top: AppSpacing.md,
            left: AppSpacing.md,
            right: AppSpacing.md,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.surface.withOpacity(0.92),
                borderRadius: AppSpacing.borderRadiusMd,
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.sensors_rounded, color: AppColors.primary, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Showing ${provider.nearbyIncidents.length} active hazard reports nearby',
                    style: AppTypography.labelSmall.copyWith(color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Sheet Preview Card when marker tapped
          if (_selectedMarkerIncident != null)
            Positioned(
              bottom: AppSpacing.lg,
              left: AppSpacing.md,
              right: AppSpacing.md,
              child: AppCard(
                padding: AppSpacing.paddingMd,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(_selectedMarkerIncident!.hazardType.icon, color: AppColors.primary, size: 22),
                            const SizedBox(width: AppSpacing.xs),
                            Text(_selectedMarkerIncident!.hazardType.displayLabel, style: AppTypography.titleMedium),
                          ],
                        ),
                        IncidentStatusBadge(status: _selectedMarkerIncident!.status),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(_selectedMarkerIncident!.description, style: AppTypography.bodyMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (_selectedMarkerIncident!.distanceKm != null)
                          Text('${_selectedMarkerIncident!.distanceKm} km away', style: AppTypography.labelSmall.copyWith(color: AppColors.accentCyan)),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                          icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                          label: const Text('View Details'),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => IncidentDetailPage(incidentId: _selectedMarkerIncident!.id),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
