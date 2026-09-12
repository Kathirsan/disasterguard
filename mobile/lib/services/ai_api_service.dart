import 'dart:convert';
import 'package:http/http.dart' as http;

class AIApiService {
  // Using 10.0.2.2 for Android emulator to access localhost
  // Use localhost or 127.0.0.1 for iOS simulator
  static const String baseUrl = 'http://127.0.0.1:8001/api/v1';

  Future<Map<String, dynamic>> analyzeImage(String imageUrl, String incidentId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/image/analyze-image'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'image_url': imageUrl,
        'incident_id': incidentId,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to analyze image');
    }
  }

  Future<Map<String, dynamic>> assessRisk(String hazardType, double confidence) async {
    final response = await http.post(
      Uri.parse('$baseUrl/risk/assess-risk'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'hazard_type': hazardType,
        'confidence': confidence,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to assess risk');
    }
  }
}
