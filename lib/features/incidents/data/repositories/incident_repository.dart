import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/token_storage.dart';
import '../models/incident_model.dart';

class IncidentRepository {
  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  IncidentRepository({ApiClient? apiClient, TokenStorage? tokenStorage})
      : _apiClient = apiClient ?? ApiClient(),
        _tokenStorage = tokenStorage ?? TokenStorage();

  Future<IncidentModel> createIncident({
    required HazardType hazardType,
    required String description,
    required double latitude,
    required double longitude,
    String? addressText,
    File? imageFile,
    List<int>? imageBytes,
    String? filename,
  }) async {
    final token = await _tokenStorage.getToken();
    final url = Uri.parse('${_apiClient.baseUrl}/incidents');

    final request = http.MultipartRequest('POST', url);
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.fields['hazard_type'] = hazardType.valueString;
    request.fields['description'] = description;
    request.fields['latitude'] = latitude.toString();
    request.fields['longitude'] = longitude.toString();
    if (addressText != null && addressText.isNotEmpty) {
      request.fields['address_text'] = addressText;
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
      return IncidentModel.fromJson(jsonBody);
    } else {
      String err = 'Failed to submit report (${response.statusCode})';
      try {
        final jsonBody = jsonDecode(response.body);
        if (jsonBody is Map && jsonBody.containsKey('detail')) {
          err = jsonBody['detail'].toString();
        }
      } catch (_) {}
      throw ApiException(err, statusCode: response.statusCode);
    }
  }

  Future<List<IncidentModel>> getMyIncidents() async {
    final response = await _apiClient.get('/incidents/my', requiresAuth: true);
    if (response is List) {
      return response.map((item) => IncidentModel.fromJson(item)).toList();
    }
    return [];
  }

  Future<List<IncidentModel>> getNearbyIncidents({
    required double latitude,
    required double longitude,
    double radiusKm = 50.0,
  }) async {
    final response = await _apiClient.get(
      '/incidents/nearby?latitude=$latitude&longitude=$longitude&radius_km=$radiusKm',
      requiresAuth: true,
    );
    if (response is List) {
      return response.map((item) => IncidentModel.fromJson(item)).toList();
    }
    return [];
  }

  Future<IncidentModel> getIncidentDetails(int incidentId) async {
    final response = await _apiClient.get('/incidents/$incidentId', requiresAuth: true);
    return IncidentModel.fromJson(response);
  }
}
