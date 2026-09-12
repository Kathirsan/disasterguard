class WeatherObservationModel {
  final int id;
  final int incidentId;
  final String condition;
  final double rainfallMm;
  final double windSpeedKmh;
  final double temperatureC;
  final String provider;
  final String weatherSupport;
  final String observedAt;

  WeatherObservationModel({
    required this.id,
    required this.incidentId,
    required this.condition,
    required this.rainfallMm,
    required this.windSpeedKmh,
    required this.temperatureC,
    required this.provider,
    required this.weatherSupport,
    required this.observedAt,
  });

  factory WeatherObservationModel.fromJson(Map<String, dynamic> json) {
    return WeatherObservationModel(
      id: json['id'] ?? 0,
      incidentId: json['incident_id'] ?? 0,
      condition: json['condition'] ?? 'Unknown',
      rainfallMm: (json['rainfall_mm'] ?? 0.0).toDouble(),
      windSpeedKmh: (json['wind_speed_kmh'] ?? 0.0).toDouble(),
      temperatureC: (json['temperature_c'] ?? 0.0).toDouble(),
      provider: json['provider'] ?? '',
      weatherSupport: json['weather_support'] ?? 'UNKNOWN',
      observedAt: json['observed_at'] ?? '',
    );
  }
}

class AIAssessmentModel {
  final int id;
  final int incidentId;
  final String detectedHazard;
  final double confidence;
  final String severityEstimate;
  final String visibleEvidence;
  final String reasoningSummary;
  final String hazardAgreement;

  AIAssessmentModel({
    required this.id,
    required this.incidentId,
    required this.detectedHazard,
    required this.confidence,
    required this.severityEstimate,
    required this.visibleEvidence,
    required this.reasoningSummary,
    required this.hazardAgreement,
  });

  factory AIAssessmentModel.fromJson(Map<String, dynamic> json) {
    return AIAssessmentModel(
      id: json['id'] ?? 0,
      incidentId: json['incident_id'] ?? 0,
      detectedHazard: json['detected_hazard'] ?? 'OTHER',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      severityEstimate: json['severity_estimate'] ?? 'MODERATE',
      visibleEvidence: json['visible_evidence'] ?? '',
      reasoningSummary: json['reasoning_summary'] ?? '',
      hazardAgreement: json['hazard_agreement'] ?? 'HIGH',
    );
  }
}

class IncidentVerificationModel {
  final int id;
  final int incidentId;
  final bool gpsValid;
  final String weatherSupport;
  final String? weatherSummary;
  final int nearbyReportCount;
  final bool isPossibleDuplicate;
  final int? duplicateOfId;
  final String? clusterId;
  final String? aiDetectedHazard;
  final double? aiConfidence;
  final String? aiSeverity;
  final String? hazardAgreement;
  final String? aiVisibleEvidence;
  final String? aiReasoning;
  final int riskScore;
  final String riskLevel;
  final String? evidenceSummary;

  IncidentVerificationModel({
    required this.id,
    required this.incidentId,
    required this.gpsValid,
    required this.weatherSupport,
    this.weatherSummary,
    required this.nearbyReportCount,
    required this.isPossibleDuplicate,
    this.duplicateOfId,
    this.clusterId,
    this.aiDetectedHazard,
    this.aiConfidence,
    this.aiSeverity,
    this.hazardAgreement,
    this.aiVisibleEvidence,
    this.aiReasoning,
    required this.riskScore,
    required this.riskLevel,
    this.evidenceSummary,
  });

  factory IncidentVerificationModel.fromJson(Map<String, dynamic> json) {
    return IncidentVerificationModel(
      id: json['id'] ?? 0,
      incidentId: json['incident_id'] ?? 0,
      gpsValid: json['gps_valid'] ?? true,
      weatherSupport: json['weather_support'] ?? 'UNKNOWN',
      weatherSummary: json['weather_summary'],
      nearbyReportCount: json['nearby_report_count'] ?? 0,
      isPossibleDuplicate: json['is_possible_duplicate'] ?? false,
      duplicateOfId: json['duplicate_of_id'],
      clusterId: json['cluster_id'],
      aiDetectedHazard: json['ai_detected_hazard'],
      aiConfidence: (json['ai_confidence'] as num?)?.toDouble(),
      aiSeverity: json['ai_severity'],
      hazardAgreement: json['hazard_agreement'],
      aiVisibleEvidence: json['ai_visible_evidence'],
      aiReasoning: json['ai_reasoning'],
      riskScore: json['risk_score'] ?? 0,
      riskLevel: json['risk_level'] ?? 'LOW',
      evidenceSummary: json['evidence_summary'],
    );
  }
}

class AlertModel {
  final int id;
  final int incidentId;
  final String title;
  final String hazardType;
  final String riskLevel;
  final String message;
  final double latitude;
  final double longitude;
  final double radiusKm;
  final int issuingAuthorityId;
  final String createdAt;

  AlertModel({
    required this.id,
    required this.incidentId,
    required this.title,
    required this.hazardType,
    required this.riskLevel,
    required this.message,
    required this.latitude,
    required this.longitude,
    required this.radiusKm,
    required this.issuingAuthorityId,
    required this.createdAt,
  });

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    return AlertModel(
      id: json['id'] ?? 0,
      incidentId: json['incident_id'] ?? 0,
      title: json['title'] ?? '',
      hazardType: json['hazard_type'] ?? 'FLOOD',
      riskLevel: json['risk_level'] ?? 'HIGH',
      message: json['message'] ?? '',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      radiusKm: (json['radius_km'] ?? 10.0).toDouble(),
      issuingAuthorityId: json['issuing_authority_id'] ?? 0,
      createdAt: json['created_at'] ?? '',
    );
  }
}

class CouncilTicketModel {
  final int id;
  final String ticketNumber;
  final int incidentId;
  final String status;
  final String priority;
  final String? description;
  final int createdById;
  final int? assignedCrewId;
  final String createdAt;

  CouncilTicketModel({
    required this.id,
    required this.ticketNumber,
    required this.incidentId,
    required this.status,
    required this.priority,
    this.description,
    required this.createdById,
    this.assignedCrewId,
    required this.createdAt,
  });

  factory CouncilTicketModel.fromJson(Map<String, dynamic> json) {
    return CouncilTicketModel(
      id: json['id'] ?? 0,
      ticketNumber: json['ticket_number'] ?? '',
      incidentId: json['incident_id'] ?? 0,
      status: json['status'] ?? 'OPEN',
      priority: json['priority'] ?? 'HIGH',
      description: json['description'],
      createdById: json['created_by_id'] ?? 0,
      assignedCrewId: json['assigned_crew_id'],
      createdAt: json['created_at'] ?? '',
    );
  }
}

class CrewAssignmentModel {
  final int id;
  final int incidentId;
  final int ticketId;
  final int assignedCrewId;
  final int assignedById;
  final String status;
  final String? instructions;
  final String assignedAt;

  CrewAssignmentModel({
    required this.id,
    required this.incidentId,
    required this.ticketId,
    required this.assignedCrewId,
    required this.assignedById,
    required this.status,
    this.instructions,
    required this.assignedAt,
  });

  factory CrewAssignmentModel.fromJson(Map<String, dynamic> json) {
    return CrewAssignmentModel(
      id: json['id'] ?? 0,
      incidentId: json['incident_id'] ?? 0,
      ticketId: json['ticket_id'] ?? 0,
      assignedCrewId: json['assigned_crew_id'] ?? 0,
      assignedById: json['assigned_by_id'] ?? 0,
      status: json['status'] ?? 'ASSIGNED',
      instructions: json['instructions'],
      assignedAt: json['assigned_at'] ?? '',
    );
  }
}

class IncidentStatusHistoryModel {
  final int id;
  final int incidentId;
  final String prevStatus;
  final String newStatus;
  final int? actorId;
  final String actorRole;
  final String? reason;
  final String createdAt;

  IncidentStatusHistoryModel({
    required this.id,
    required this.incidentId,
    required this.prevStatus,
    required this.newStatus,
    this.actorId,
    required this.actorRole,
    this.reason,
    required this.createdAt,
  });

  factory IncidentStatusHistoryModel.fromJson(Map<String, dynamic> json) {
    return IncidentStatusHistoryModel(
      id: json['id'] ?? 0,
      incidentId: json['incident_id'] ?? 0,
      prevStatus: json['prev_status'] ?? '',
      newStatus: json['new_status'] ?? '',
      actorId: json['actor_id'],
      actorRole: json['actor_role'] ?? 'SYSTEM',
      reason: json['reason'],
      createdAt: json['created_at'] ?? '',
    );
  }
}
