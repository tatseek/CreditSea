import '../../../core/session/session_service.dart';

class LoanRepository {
  LoanRepository(this.session);

  final SessionService session;

  Future<Map<String, dynamic>> checkEligibility({
    required double amount,
    required int tenureMonths,
  }) => session.api.post('/loans/eligibility', {
    'amount': amount,
    'tenureMonths': tenureMonths,
  });

  Future<Map<String, dynamic>> apply({
    required double amount,
    required int tenureMonths,
    required String purpose,
  }) async {
    final response = await session.api.post('/loans', {
      'amount': amount,
      'tenureMonths': tenureMonths,
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
}
