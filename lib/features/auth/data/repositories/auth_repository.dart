import '../../../../core/network/api_client.dart';
import '../../../../core/storage/token_storage.dart';
import '../models/user_model.dart';

class AuthRepository {
  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  AuthRepository({ApiClient? apiClient, TokenStorage? tokenStorage})
      : _apiClient = apiClient ?? ApiClient(),
        _tokenStorage = tokenStorage ?? TokenStorage();

  Future<UserModel> register({
    required String fullName,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    final response = await _apiClient.post(
      '/auth/register',
      body: {
        'full_name': fullName,
        'email': email,
        'password': password,
        'role': role.valueString,
      },
      requiresAuth: false,
    );

    final token = response['access_token'] as String;
    final userJson = response['user'] as Map<String, dynamic>;
    final user = UserModel.fromJson(userJson);

    await _tokenStorage.saveToken(token);
    await _tokenStorage.saveUser(user);

    return user;
  }

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.post(
      '/auth/login',
      body: {
        'email': email,
        'password': password,
      },
      requiresAuth: false,
    );

    final token = response['access_token'] as String;
    final userJson = response['user'] as Map<String, dynamic>;
    final user = UserModel.fromJson(userJson);

    await _tokenStorage.saveToken(token);
    await _tokenStorage.saveUser(user);

    return user;
  }

  Future<UserModel?> getMe() async {
    try {
      final response = await _apiClient.get('/auth/me', requiresAuth: true);
      final user = UserModel.fromJson(response);
      await _tokenStorage.saveUser(user);
      return user;
    } catch (_) {
      return null;
    }
  }

  Future<void> logout() async {
    await _tokenStorage.clearAll();
  }

  Future<UserModel?> getSavedUser() async {
    return await _tokenStorage.getUser();
  }

  Future<String?> getSavedToken() async {
    return await _tokenStorage.getToken();
  }
}
