import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/auth/data/models/user_model.dart';

class TokenStorage {
  static const String _tokenKey = 'disasterguard_jwt_token';
  static const String _userKey = 'disasterguard_user_data';

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> saveUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  Future<UserModel?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    if (userJson != null) {
      try {
        return UserModel.fromJson(jsonDecode(userJson));
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }
}
