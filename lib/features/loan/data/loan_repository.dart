import '../../../core/session/session_service.dart';

class LoanRepository {
  LoanRepository(this.session);

  final SessionService session;

  Future<Map<String, dynamic>> checkEligibility({
    required double amount,
    required int tenureDays,
  }) => session.api.post('/loans/eligibility', {
    'amount': amount,
    'tenureDays': tenureDays,
  });

  Future<Map<String, dynamic>> apply({
    required double amount,
    required int tenureDays,
    required String purpose,
  }) async {
    final response = await session.api.post('/loans', {
      'amount': amount,
      'tenureDays': tenureDays,
      'purpose': purpose,
    });
    return response['loan'] as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> list() async {
    final response = await session.api.get('/loans');
    return (response['loans'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> accept(String id) async {
    final response = await session.api.post('/loans/$id/accept');
    return response['loan'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> cancel(String id) async {
    final response = await session.api.post('/loans/$id/cancel');
    return response['loan'] as Map<String, dynamic>;
  }
}
