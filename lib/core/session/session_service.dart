import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';

import '../network/api_client.dart';

class SessionService extends GetxService {
  SessionService({FlutterSecureStorage? storage, ApiClient? api})
    : storage = storage ?? const FlutterSecureStorage(),
      api = api ?? ApiClient();

  static const _tokenKey = 'creditsea_auth_token';
  final FlutterSecureStorage storage;
  final ApiClient api;
  final user = Rxn<Map<String, dynamic>>();

  bool get isSignedIn => api.token != null;
  bool get isProfileComplete => user.value?['profileCompleted'] == true;

  Future<SessionService> init() async {
    api.token = await storage.read(key: _tokenKey);
    if (api.token != null) {
      try {
        final response = await api.get('/profile');
        user.value = response['user'] as Map<String, dynamic>?;
      } catch (_) {
        await clear();
      }
    }
    return this;
  }

  Future<void> saveSession(
    String token,
    Map<String, dynamic>? currentUser,
  ) async {
    api.token = token;
    user.value = currentUser;
    await storage.write(key: _tokenKey, value: token);
  }

  Future<void> updateUser(Map<String, dynamic> currentUser) async {
    user.value = currentUser;
  }

  Future<void> clear() async {
    api.token = null;
    user.value = null;
    await storage.delete(key: _tokenKey);
  }
}
