import 'package:flutter/material.dart';
import '../../data/repositories/authority_repository.dart';
import '../../../incidents/data/models/incident_verification_model.dart';

enum AuthorityStatus { initial, loading, loaded, error }

class AuthorityProvider extends ChangeNotifier {
  final AuthorityRepository _repository;

  AuthorityProvider({AuthorityRepository? repository})
      : _repository = repository ?? AuthorityRepository();

  AuthorityStatus _status = AuthorityStatus.initial;
  AuthorityStatus get status => _status;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Map<String, dynamic>? _dashboardMetrics;
  Map<String, dynamic>? get dashboardMetrics => _dashboardMetrics;

  List<Map<String, dynamic>> _recentIncidents = [];
  List<Map<String, dynamic>> get recentIncidents => _recentIncidents;

  List<Map<String, dynamic>> _incidentsList = [];
  List<Map<String, dynamic>> get incidentsList => _incidentsList;

  Map<String, dynamic>? _selectedIncidentDetail;
  Map<String, dynamic>? get selectedIncidentDetail => _selectedIncidentDetail;

  List<Map<String, dynamic>> _availableCrews = [];
  List<Map<String, dynamic>> get availableCrews => _availableCrews;

  List<AlertModel> _activeAlerts = [];
  List<AlertModel> get activeAlerts => _activeAlerts;

  bool _isActionLoading = false;
  bool get isActionLoading => _isActionLoading;

  Future<void> loadDashboard() async {
    _status = AuthorityStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _repository.getDashboardData();
      _dashboardMetrics = data['metrics'] as Map<String, dynamic>?;
      if (data['recent_incidents'] is List) {
        _recentIncidents = List<Map<String, dynamic>>.from(data['recent_incidents']);
      }
      _status = AuthorityStatus.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      _status = AuthorityStatus.error;
    }
    notifyListeners();
  }

  Future<void> loadIncidentsList({
    String? riskLevel,
    String? statusFilter,
    String? hazardType,
  }) async {
    _status = AuthorityStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _incidentsList = await _repository.getAuthorityIncidents(
        riskLevel: riskLevel,
        statusFilter: statusFilter,
        hazardType: hazardType,
      );
      _status = AuthorityStatus.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      _status = AuthorityStatus.error;
    }
    notifyListeners();
  }

  Future<void> loadIncidentDetail(int incidentId) async {
    _status = AuthorityStatus.loading;
    _errorMessage = null;
    _selectedIncidentDetail = null;
    notifyListeners();

    try {
      _selectedIncidentDetail = await _repository.getIncidentDetail(incidentId);
      _status = AuthorityStatus.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      _status = AuthorityStatus.error;
    }
    notifyListeners();
  }

  Future<bool> confirmIncident(int incidentId) async {
    _isActionLoading = true;
    notifyListeners();

    try {
      await _repository.confirmIncident(incidentId);
      await loadIncidentDetail(incidentId);
      await loadDashboard();
      _isActionLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isActionLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> rejectIncident(int incidentId, String reason) async {
    _isActionLoading = true;
    notifyListeners();

    try {
      await _repository.rejectIncident(incidentId, reason);
      await loadIncidentDetail(incidentId);
      await loadDashboard();
      _isActionLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isActionLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> createAlert({
    required int incidentId,
    required String title,
    required String message,
    double radiusKm = 10.0,
  }) async {
    _isActionLoading = true;
    notifyListeners();

    try {
      await _repository.createAlert(
        incidentId: incidentId,
        title: title,
        message: message,
        radiusKm: radiusKm,
      );
      await loadIncidentDetail(incidentId);
      _isActionLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isActionLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> createCouncilTicket({
    required int incidentId,
    String priority = 'HIGH',
    String? description,
  }) async {
    _isActionLoading = true;
    notifyListeners();

    try {
      await _repository.createCouncilTicket(
        incidentId: incidentId,
        priority: priority,
        description: description,
      );
      await loadIncidentDetail(incidentId);
      _isActionLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isActionLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> loadAvailableCrews() async {
    try {
      _availableCrews = await _repository.fetchAvailableCrews();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
    }
  }

  Future<bool> dispatchCrew({
    required int incidentId,
    required int ticketId,
    required int assignedCrewId,
    String? instructions,
  }) async {
    _isActionLoading = true;
    notifyListeners();

    try {
      await _repository.dispatchCrew(
        incidentId: incidentId,
        ticketId: ticketId,
        assignedCrewId: assignedCrewId,
        instructions: instructions,
      );
      await loadIncidentDetail(incidentId);
      await loadDashboard();
      _isActionLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isActionLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchCitizenAlerts(double latitude, double longitude) async {
    try {
      _activeAlerts = await _repository.fetchCitizenAlerts(
        latitude: latitude,
        longitude: longitude,
      );
      notifyListeners();
    } catch (e) {
      // Ignore silent errors for citizen alert widget
    }
  Future<bool> closeIncident(int incidentId) async {
    _isActionLoading = true;
    notifyListeners();

    try {
      await _repository.closeIncident(incidentId);
      await loadIncidentDetail(incidentId);
      await loadDashboard();
      _isActionLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isActionLoading = false;
      notifyListeners();
      return false;
    }
  }
}
