import 'dart:io';
import 'package:flutter/material.dart';
import '../../data/models/crew_assignment_model.dart';
import '../../data/repositories/crew_repository.dart';

class CrewProvider with ChangeNotifier {
  final CrewRepository _repository;

  CrewDashboardData? _dashboardData;
  List<CrewAssignmentModel> _assignments = [];
  List<CrewAssignmentModel> _completedJobs = [];
  CrewAssignmentModel? _selectedAssignment;
  bool _isLoading = false;
  String? _errorMessage;

  CrewProvider({CrewRepository? repository})
      : _repository = repository ?? CrewRepository();

  CrewDashboardData? get dashboardData => _dashboardData;
  List<CrewAssignmentModel> get assignments => _assignments;
  List<CrewAssignmentModel> get completedJobs => _completedJobs;
  CrewAssignmentModel? get selectedAssignment => _selectedAssignment;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchDashboard() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _dashboardData = await _repository.getDashboard();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAssignments({String? statusFilter}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _assignments = await _repository.getAssignments(statusFilter: statusFilter);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAssignmentDetail(int assignmentId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _selectedAssignment = await _repository.getAssignmentDetail(assignmentId);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> acceptAssignment(int assignmentId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await _repository.acceptAssignment(assignmentId);
      _selectedAssignment = updated;
      await fetchDashboard();
      await fetchAssignments();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> startJob(int assignmentId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await _repository.startJob(assignmentId);
      _selectedAssignment = updated;
      await fetchDashboard();
      await fetchAssignments();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addProgressUpdate(
    int assignmentId, {
    String? note,
    File? imageFile,
    List<int>? imageBytes,
    String? filename,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.addProgressUpdate(
        assignmentId,
        note: note,
        imageFile: imageFile,
        imageBytes: imageBytes,
        filename: filename,
      );
      await fetchAssignmentDetail(assignmentId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> completeJob(
    int assignmentId, {
    required String note,
    File? imageFile,
    List<int>? imageBytes,
    String? filename,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await _repository.completeJob(
        assignmentId,
        note: note,
        imageFile: imageFile,
        imageBytes: imageBytes,
        filename: filename,
      );
      _selectedAssignment = updated;
      await fetchDashboard();
      await fetchAssignments();
      await fetchCompletedJobs();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchCompletedJobs() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _completedJobs = await _repository.getCompletedJobs();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
