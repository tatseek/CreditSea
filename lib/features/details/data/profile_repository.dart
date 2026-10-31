import '../../../core/session/session_service.dart';

class ProfileRepository {
  ProfileRepository(this.session);

  final SessionService session;

  Future<String?> requestEmailOtp(String email) async {
    final response = await session.api.post('/email/request-otp', {
      'email': email,
    });
    return response['developmentOtp'] as String?;
  }

  Future<Map<String, dynamic>> verifyEmailOtp(String email, String otp) async {
    final response = await session.api.post('/email/verify-otp', {
      'email': email,
      'otp': otp,
    });
    final user = response['user'] as Map<String, dynamic>;
    await session.updateUser(user);
    return user;
  }

  Future<Map<String, dynamic>> save(Map<String, dynamic> profile) async {
    final response = await session.api.patch('/profile', profile);
    final user = response['user'] as Map<String, dynamic>;
    await session.updateUser(user);
    return user;
  }
}
