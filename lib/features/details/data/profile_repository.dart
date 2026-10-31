import '../../../core/session/session_service.dart';

class ProfileRepository {
  ProfileRepository(this.session);

  final SessionService session;

  Future<Map<String, dynamic>> save(Map<String, dynamic> profile) async {
    final response = await session.api.patch('/profile', profile);
    final user = response['user'] as Map<String, dynamic>;
    await session.updateUser(user);
    return user;
  }
}
