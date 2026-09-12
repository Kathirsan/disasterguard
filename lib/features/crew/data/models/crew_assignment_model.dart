import '../../incidents/data/models/incident_model.dart';

class CrewProgressUpdateModel {
  final int id;
  final int assignmentId;
  final int incidentId;
  final int crewId;
  final String? note;
  final String? evidencePath;
  final String updateType;
  final DateTime createdAt;

  CrewProgressUpdateModel({
    required this.id,
    required this.assignmentId,
    required this.incidentId,
    required this.crewId,
    this.note,
    this.evidencePath,
    required this.updateType,
    required this.createdAt,
  });

  factory CrewProgressUpdateModel.fromJson(Map<String, dynamic> json) {
    return CrewProgressUpdateModel(
      id: json['id'] ?? 0,
      assignmentId: json['assignment_id'] ?? 0,
      incidentId: json['incident_id'] ?? 0,
      crewId: json['crew_id'] ?? 0,
      note: json['note'],
      evidencePath: json['evidence_path'],
      updateType: json['update_type'] ?? 'PROGRESS',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
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
  final DateTime assignedAt;
  final DateTime? acceptedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final IncidentModel? incident;
  final String? reporterName;
  final String? ticketNumber;
  final String? primaryImageUrl;
  final List<CrewProgressUpdateModel> progressUpdates;
  final String? resolutionEvidenceUrl;

  CrewAssignmentModel({
    required this.id,
    required this.incidentId,
    required this.ticketId,
    required this.assignedCrewId,
    required this.assignedById,
    required this.status,
    this.instructions,
    required this.assignedAt,
    this.acceptedAt,
    this.startedAt,
    this.completedAt,
    this.incident,
    this.reporterName,
    this.ticketNumber,
    this.primaryImageUrl,
    this.progressUpdates = const [],
    this.resolutionEvidenceUrl,
  });

  factory CrewAssignmentModel.fromJson(Map<String, dynamic> json) {
    var updatesList = <CrewProgressUpdateModel>[];
    if (json['progress_updates'] != null && json['progress_updates'] is List) {
      updatesList = (json['progress_updates'] as List)
          .map((item) => CrewProgressUpdateModel.fromJson(item))
          .toList();
    }

    return CrewAssignmentModel(
      id: json['id'] ?? 0,
      incidentId: json['incident_id'] ?? 0,
      ticketId: json['ticket_id'] ?? 0,
      assignedCrewId: json['assigned_crew_id'] ?? 0,
      assignedById: json['assigned_by_id'] ?? 0,
      status: json['status'] ?? 'ASSIGNED',
      instructions: json['instructions'],
      assignedAt: json['assigned_at'] != null
          ? DateTime.parse(json['assigned_at'])
          : DateTime.now(),
      acceptedAt: json['accepted_at'] != null
          ? DateTime.parse(json['accepted_at'])
          : null,
      startedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'])
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
      incident: json['incident'] != null
          ? IncidentModel.fromJson(json['incident'])
          : null,
      reporterName: json['reporter_name'],
      ticketNumber: json['ticket_number'],
      primaryImageUrl: json['primary_image_url'],
      progressUpdates: updatesList,
      resolutionEvidenceUrl: json['resolution_evidence_url'],
    );
  }
}

class CrewDashboardData {
  final int totalAssigned;
  final int newAssignmentsCount;
  final int activeInProgressCount;
  final int completedCount;
  final List<CrewAssignmentModel> recentJobs;

  CrewDashboardData({
    required this.totalAssigned,
    required this.newAssignmentsCount,
    required this.activeInProgressCount,
    required this.completedCount,
    required this.recentJobs,
  });

  factory CrewDashboardData.fromJson(Map<String, dynamic> json) {
    var jobs = <CrewAssignmentModel>[];
    if (json['recent_jobs'] != null && json['recent_jobs'] is List) {
      jobs = (json['recent_jobs'] as List)
          .map((item) => CrewAssignmentModel.fromJson(item))
          .toList();
    }

    return CrewDashboardData(
      totalAssigned: json['total_assigned'] ?? 0,
      newAssignmentsCount: json['new_assignments_count'] ?? 0,
      activeInProgressCount: json['active_in_progress_count'] ?? 0,
      completedCount: json['completed_count'] ?? 0,
      recentJobs: jobs,
    );
  }
}
