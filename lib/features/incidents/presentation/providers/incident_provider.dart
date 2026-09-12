import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../data/models/incident_model.dart';
import '../../data/repositories/incident_repository.dart';

class IncidentProvider extends ChangeNotifier {
  final IncidentRepository _repository;

  
  List<IncidentModel> _myIncidents = [];
  List<IncidentModel> _nearbyIncidents = [];
  IncidentModel? _selectedIncident;
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  IncidentProvider({IncidentRepository? repository})
      : _repository = repository ?? IncidentRepository();

  List<IncidentModel> get myIncidents => _myIncidents;
  List<IncidentModel> get nearbyIncidents => _nearbyIncidents;
  IncidentModel? get selectedIncident => _selectedIncident;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

  Future<void> fetchMyIncidents() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _myIncidents = await _repository.getMyIncidents();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchNearbyIncidents({required double latitude, required double longitude}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _nearbyIncidents = await _repository.getNearbyIncidents(
        latitude: latitude,
        longitude: longitude,
      );
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchIncidentDetails(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _selectedIncident = await _repository.getIncidentDetails(id);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> submitReport({
    required HazardType hazardType,
    required String description,
    required double latitude,
    required double longitude,
    String? addressText,
    File? imageFile,
    List<int>? imageBytes,
    String? filename,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newIncident = await _repository.createIncident(
        hazardType: hazardType,
        description: description,
        latitude: latitude,
        longitude: longitude,
        addressText: addressText,
        imageFile: imageFile,
        imageBytes: imageBytes,
        filename: filename,
      );
      _myIncidents.insert(0, newIncident);
      _isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
