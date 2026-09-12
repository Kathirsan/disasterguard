import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/token_storage.dart';
import '../models/crew_assignment_model.dart';

class CrewRepository {
  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  CrewRepository({ApiClient? apiClient, TokenStorage? tokenStorage})
      : _apiClient = apiClient ?? ApiClient(),
        _tokenStorage = tokenStorage ?? TokenStorage();

  Future<CrewDashboardData> getDashboard() async {
    final response = await _apiClient.get('/crew/dashboard', requiresAuth: true);
    return CrewDashboardData.fromJson(response);
  }

  Future<List<CrewAssignmentModel>> getAssignments({String? statusFilter}) async {
    String endpoint = '/crew/assignments';
    if (statusFilter != null && statusFilter.isNotEmpty) {
      endpoint += '?status_filter=$statusFilter';
    }
    final response = await _apiClient.get(endpoint, requiresAuth: true);
    if (response is List) {
      return response.map((item) => CrewAssignmentModel.fromJson(item)).toList();
    }
    return [];
  }

  Future<CrewAssignmentModel> getAssignmentDetail(int assignmentId) async {
    final response = await _apiClient.get('/crew/assignments/$assignmentId', requiresAuth: true);
    return CrewAssignmentModel.fromJson(response);
  }

  Future<CrewAssignmentModel> acceptAssignment(int assignmentId) async {
    final response = await _apiClient.post('/crew/assignments/$assignmentId/accept', requiresAuth: true);
    return CrewAssignmentModel.fromJson(response);
  }

  Future<CrewAssignmentModel> startJob(int assignmentId) async {
    final response = await _apiClient.post('/crew/assignments/$assignmentId/start', requiresAuth: true);
    return CrewAssignmentModel.fromJson(response);
  }

  Future<CrewProgressUpdateModel> addProgressUpdate(
    int assignmentId, {
    String? note,
    File? imageFile,
    List<int>? imageBytes,
    String? filename,
  }) async {
    final token = await _tokenStorage.getToken();
    final url = Uri.parse('${_apiClient.baseUrl}/crew/assignments/$assignmentId/progress');

    final request = http.MultipartRequest('POST', url);
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    if (note != null && note.isNotEmpty) {
      request.fields['note'] = note;
    }

    if (imageFile != null) {
      request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));
    } else if (imageBytes != null && filename != null) {
      request.files.add(http.MultipartFile.fromBytes('file', imageBytes, filename: filename));
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final jsonBody = jsonDecode(response.body);
      return CrewProgressUpdateModel.fromJson(jsonBody);
    } else {
      String err = 'Failed to upload progress (${response.statusCode})';
      try {
        final jsonBody = jsonDecode(response.body);
        if (jsonBody is Map && jsonBody.containsKey('detail')) {
          err = jsonBody['detail'].toString();
        }
      } catch (_) {}
      throw ApiException(err, statusCode: response.statusCode);
    }
  }

  Future<CrewAssignmentModel> completeJob(
    int assignmentId, {
    required String note,
    File? imageFile,
    List<int>? imageBytes,
    String? filename,
  }) async {
    final token = await _tokenStorage.getToken();
    final url = Uri.parse('${_apiClient.baseUrl}/crew/assignments/$assignmentId/complete');

    final request = http.MultipartRequest('POST', url);
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.fields['note'] = note;

    if (imageFile != null) {
      request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));
    } else if (imageBytes != null && filename != null) {
      request.files.add(http.MultipartFile.fromBytes('file', imageBytes, filename: filename));
    } else {
      throw ApiException('Resolution photo evidence is required to complete job');
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final jsonBody = jsonDecode(response.body);
      return CrewAssignmentModel.fromJson(jsonBody);
    } else {
      String err = 'Failed to complete job (${response.statusCode})';
      try {
        final jsonBody = jsonDecode(response.body);
        if (jsonBody is Map && jsonBody.containsKey('detail')) {
          err = jsonBody['detail'].toString();
        }
      } catch (_) {}
      throw ApiException(err, statusCode: response.statusCode);
    }
  }

  Future<List<CrewAssignmentModel>> getCompletedJobs() async {
    final response = await _apiClient.get('/crew/completed-jobs', requiresAuth: true);
    if (response is List) {
      return response.map((item) => CrewAssignmentModel.fromJson(item)).toList();
    }
    return [];
  }
}
