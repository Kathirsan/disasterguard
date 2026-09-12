import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';

enum HazardType {
  FLOOD,
  BLOCKED_ROAD,
  FALLEN_TREE,
  OTHER,
}

extension HazardTypeExtension on HazardType {
  String get displayLabel {
    switch (this) {
      case HazardType.FLOOD:
        return 'Severe Flood';
      case HazardType.BLOCKED_ROAD:
        return 'Blocked Road / Landslide';
      case HazardType.FALLEN_TREE:
        return 'Fallen Tree / Debris';
      case HazardType.OTHER:
        return 'Other Hazard';
    }
  }

  IconData get icon {
    switch (this) {
      case HazardType.FLOOD:
        return Icons.water_drop_outlined;
      case HazardType.BLOCKED_ROAD:
        return Icons.warning_amber_rounded;
      case HazardType.FALLEN_TREE:
        return Icons.nature_outlined;
      case HazardType.OTHER:
        return Icons.report_problem_outlined;
    }
  }

  String get valueString {
    switch (this) {
      case HazardType.FLOOD:
        return 'FLOOD';
      case HazardType.BLOCKED_ROAD:
        return 'BLOCKED_ROAD';
      case HazardType.FALLEN_TREE:
        return 'FALLEN_TREE';
      case HazardType.OTHER:
        return 'OTHER';
    }
  }
}

enum IncidentStatus {
  SUBMITTED,
  SYSTEM_CHECKING,
  VERIFICATION_REQUIRED,
  VERIFIED,
  REJECTED,
  DISPATCHED,
  IN_PROGRESS,
  RESOLVED,
  CLOSED,
}

extension IncidentStatusExtension on IncidentStatus {
  String get displayLabel {
    switch (this) {
      case IncidentStatus.SUBMITTED:
        return 'Submitted';
      case IncidentStatus.SYSTEM_CHECKING:
        return 'System Checking';
      case IncidentStatus.VERIFICATION_REQUIRED:
        return 'Pending Verification';
      case IncidentStatus.VERIFIED:
        return 'Verified';
      case IncidentStatus.REJECTED:
        return 'Rejected';
      case IncidentStatus.DISPATCHED:
        return 'Crew Dispatched';
      case IncidentStatus.IN_PROGRESS:
        return 'In Progress';
      case IncidentStatus.RESOLVED:
        return 'Resolved';
      case IncidentStatus.CLOSED:
        return 'Closed';
    }
  }

  Color get color {
    switch (this) {
      case IncidentStatus.SUBMITTED:
      case IncidentStatus.SYSTEM_CHECKING:
        return AppColors.accentCyan;
      case IncidentStatus.VERIFICATION_REQUIRED:
        return AppColors.warning;
      case IncidentStatus.VERIFIED:
        return AppColors.success;
      case IncidentStatus.REJECTED:
        return AppColors.error;
      case IncidentStatus.DISPATCHED:
      case IncidentStatus.IN_PROGRESS:
        return AppColors.info;
      case IncidentStatus.RESOLVED:
      case IncidentStatus.CLOSED:
        return AppColors.roleCrew;
    }
  }
}

class IncidentMediaModel {
  final int id;
  final String filePath;
  final String mediaType;
  final String createdAt;

  IncidentMediaModel({
    required this.id,
    required this.filePath,
    required this.mediaType,
    required this.createdAt,
  });

  factory IncidentMediaModel.fromJson(Map<String, dynamic> json) {
    return IncidentMediaModel(
      id: json['id'] ?? 0,
      filePath: json['file_path'] ?? '',
      mediaType: json['media_type'] ?? 'image/jpeg',
      createdAt: json['created_at'] ?? '',
    );
  }
}

class IncidentModel {
  final int id;
  final int reporterId;
  final HazardType hazardType;
  final String description;
  final double latitude;
  final double longitude;
  final String? addressText;
  final IncidentStatus status;
  final String createdAt;
  final String updatedAt;
  final List<IncidentMediaModel> media;
  final double? distanceKm;
  final String? primaryImageUrl;

  IncidentModel({
    required this.id,
    required this.reporterId,
    required this.hazardType,
    required this.description,
    required this.latitude,
    required this.longitude,
    this.addressText,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.media = const [],
    this.distanceKm,
    this.primaryImageUrl,
  });

  factory IncidentModel.fromJson(Map<String, dynamic> json) {
    HazardType ht = HazardType.OTHER;
    final hStr = json['hazard_type']?.toString().toUpperCase();
    if (hStr == 'FLOOD') ht = HazardType.FLOOD;
    else if (hStr == 'BLOCKED_ROAD') ht = HazardType.BLOCKED_ROAD;
    else if (hStr == 'FALLEN_TREE') ht = HazardType.FALLEN_TREE;

    IncidentStatus st = IncidentStatus.SUBMITTED;
    final sStr = json['status']?.toString().toUpperCase();
    for (var val in IncidentStatus.values) {
      if (val.name == sStr) {
        st = val;
        break;
      }
    }

    List<IncidentMediaModel> parsedMedia = [];
    if (json['media'] is List) {
      parsedMedia = (json['media'] as List)
          .map((m) => IncidentMediaModel.fromJson(m))
          .toList();
    }

    String? mainImg = json['primary_image_url'];
    if (mainImg == null && parsedMedia.isNotEmpty) {
      mainImg = parsedMedia.first.filePath;
    }

    return IncidentModel(
      id: json['id'] ?? 0,
      reporterId: json['reporter_id'] ?? 0,
      hazardType: ht,
      description: json['description'] ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      addressText: json['address_text'],
      status: st,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      media: parsedMedia,
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      primaryImageUrl: mainImg,
    );
  }
}
