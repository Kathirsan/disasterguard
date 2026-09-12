import '../../../../core/network/api_client.dart';
import '../../../incidents/data/models/incident_verification_model.dart';

class AuthorityRepository {
  final ApiClient _apiClient;

  AuthorityRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Future<Map<String, dynamic>> getDashboardData() async {
    final response = await _apiClient.get('/authority/dashboard', requiresAuth: true);
    return response as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getAuthorityIncidents({
    String? riskLevel,
    String? statusFilter,
    String? hazardType,
  }) async {
    String query = '?limit=100';
    if (riskLevel != null && riskLevel.isNotEmpty) query += '&risk_level=$riskLevel';
    if (statusFilter != null && statusFilter.isNotEmpty) query += '&status_filter=$statusFilter';
    if (hazardType != null && hazardType.isNotEmpty) query += '&hazard_type=$hazardType';

    final response = await _apiClient.get('/authority/incidents$query', requiresAuth: true);
    if (response is List) {
      return List<Map<String, dynamic>>.from(response);
    }
    return [];
  }

  Future<Map<String, dynamic>> getIncidentDetail(int incidentId) async {
    final response = await _apiClient.get('/authority/incidents/$incidentId', requiresAuth: true);
    return response as Map<String, dynamic>;
  }

  Future<void> confirmIncident(int incidentId) async {
    await _apiClient.post('/authority/incidents/$incidentId/confirm', body: {}, requiresAuth: true);
  }

  Future<void> rejectIncident(int incidentId, String reason) async {
    await _apiClient.post('/authority/incidents/$incidentId/reject', body: {'reason': reason}, requiresAuth: true);
  }

  Future<AlertModel> createAlert({
    required int incidentId,
    required String title,
    required String message,
    double radiusKm = 10.0,
  }) async {
    final response = await _apiClient.post(
      '/authority/alerts',
      body: {
        'incident_id': incidentId,
        'title': title,
        'message': message,
        'radius_km': radiusKm,
      },
      requiresAuth: true,
    );
    return AlertModel.fromJson(response);
  }

  Future<List<AlertModel>> fetchCitizenAlerts({
    required double latitude,
    required double longitude,
  }) async {
    final response = await _apiClient.get(
      '/alerts/relevant?latitude=$latitude&longitude=$longitude',
      requiresAuth: true,
    );
    if (response is List) {
      return response.map((item) => AlertModel.fromJson(item)).toList();
    }
    return [];
  }

  Future<CouncilTicketModel> createCouncilTicket({
    required int incidentId,
    String priority = 'HIGH',
    String? description,
  }) async {
    final response = await _apiClient.post(
      '/authority/tickets',
      body: {
        'incident_id': incidentId,
        'priority': priority,
        'description': description,
      },
      requiresAuth: true,
    );
    return CouncilTicketModel.fromJson(response);
  }

  Future<List<Map<String, dynamic>>> fetchAvailableCrews() async {
    final response = await _apiClient.get('/authority/crews', requiresAuth: true);
    if (response is List) {
      return List<Map<String, dynamic>>.from(response);
    }
    return [];
  }

  Future<CrewAssignmentModel> dispatchCrew({
    required int incidentId,
    required int ticketId,
    required int assignedCrewId,
    String? instructions,
  }) async {
    final response = await _apiClient.post(
      '/authority/dispatch',
      body: {
        'incident_id': incidentId,
        'ticket_id': ticketId,
        'assigned_crew_id': assignedCrewId,
        'instructions': instructions,
      },
      requiresAuth: true,
    );
    return CrewAssignmentModel.fromJson(response);
  Future<void> closeIncident(int incidentId) async {
    await _apiClient.post('/authority/incidents/$incidentId/close', body: {}, requiresAuth: true);
  }
}
