import '../../../core/session/session_service.dart';

class AuthRepository {
  AuthRepository(this.session);

  final SessionService session;

  Future<void> requestOtp(String mobile) async {
    await session.api.post('/auth/request-otp', {'mobile': mobile});
  }

  Future<void> verifyOtp(String mobile, String otp) async {
    final response = await session.api.post('/auth/verify-otp', {
      'mobile': mobile,
      'otp': otp,
    });
    await session.saveSession(
      response['token'] as String,
      response['user'] as Map<String, dynamic>?,
    );
  }

  Future<void> setPassword(String password) async {
    final response = await session.api.post('/auth/set-password', {
      'token': session.api.token,
      'password': password,
    });
    await session.saveSession(
      response['token'] as String,
      response['user'] as Map<String, dynamic>?,
    );
  }

  Future<void> login(String mobile, String password) async {
    final response = await session.api.post('/auth/login', {
      'mobile': mobile,
      'password': password,
    });
    await session.saveSession(
      response['token'] as String,
      response['user'] as Map<String, dynamic>?,
    );
  }
}
