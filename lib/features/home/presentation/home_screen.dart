import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import '../../../core/session/session_service.dart';
import '../../auth/presentation/auth_screen.dart';
import '../../loan/data/loan_repository.dart';
import '../../loan/presentation/loan_flow_screens.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final SessionService session;
  late final LoanRepository loans;
  List<Map<String, dynamic>> applications = const [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    session = Get.find<SessionService>();
    loans = LoanRepository(session);
    _load();
  }

  Future<void> _load() async {
    try {
      applications = await loans.list();
    } catch (_) {
      applications = const [];
    }
    if (mounted) setState(() => loading = false);
  }

  Map<String, dynamic>? get latest =>
      applications.isEmpty ? null : applications.first;

  void _openApply() {
    Get.to(
      () => LoanCalculatorScreen(
        onApply: () {},
        onSubmit: (amount, tenureMonths, purpose) async {
          final loan = await loans.apply(
            amount: amount,
            tenureMonths: tenureMonths,
            purpose: purpose,
          );
          applications = [loan, ...applications];
          Get.off(
            () => OfferScreen(
              loan: loan,
              onAccept: () => Get.off(
                () => ApplicationStatusScreen(
                  loan: loan,
                  onContinue: () => Get.offAll(() => const HomeScreen()),
                ),
              ),
              onExtend: () => Get.back(),
            ),
          );
        },
      ),
    );
  }

  void _openOffer() {
    if (latest == null) return _message('Apply for a loan first.');
    Get.to(
      () => OfferScreen(
        loan: latest,
        onAccept: () async {
          final accepted = await loans.accept(latest!['_id'] as String);
          applications = [accepted, ...applications.skip(1)];
          Get.off(
            () => ApplicationStatusScreen(
              loan: accepted,
              onContinue: () => Get.offAll(() => const HomeScreen()),
            ),
          );
        },
        onExtend: _openApply,
      ),
    );
  }

  void _openStatus() {
    if (latest == null) return _message('No loan application found.');
    Get.to(
      () => ApplicationStatusScreen(loan: latest, onContinue: () => Get.back()),
    );
  }

  void _message(String value) {
    Get.showSnackbar(
      GetSnackBar(message: value, duration: const Duration(seconds: 2)),
    );
  }

  Future<void> _logout() async {
    await session.clear();
    Get.offAll(() => const AuthScreen());
  }

  @override
  Widget build(BuildContext context) {
    final firstName = session.user.value?['firstName'] as String?;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F4B92),
        foregroundColor: Colors.white,
        title: Row(
          children: [
            SizedBox(
              width: 34,
              height: 34,
              child: SvgPicture.asset('assets/images/credit_sea_mark.svg'),
            ),
            const SizedBox(width: 8),
            const Text('CreditSea'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Log out',
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Welcome${firstName == null ? '' : ', $firstName'}',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              loading
                  ? 'Loading your applications…'
                  : latest == null
                  ? 'Start a new loan application.'
                  : 'Latest application: ${_statusLabel(latest!['status'])}',
              style: const TextStyle(color: Color(0xFF66717D)),
            ),
            const SizedBox(height: 28),
            _HomeAction(
              icon: Icons.calculate_outlined,
              title: 'Apply for Loan',
              subtitle: 'Check eligibility and submit an application',
              onTap: _openApply,
            ),
            const SizedBox(height: 14),
            _HomeAction(
              icon: Icons.local_offer_outlined,
              title: 'Offer',
              subtitle: latest == null
                  ? 'Available after applying'
                  : 'Review your latest loan offer',
              onTap: _openOffer,
            ),
            const SizedBox(height: 14),
            _HomeAction(
              icon: Icons.track_changes_outlined,
              title: 'Application Status',
              subtitle: latest == null
                  ? 'No application submitted yet'
                  : 'Track ${_statusLabel(latest!['status'])}',
              onTap: _openStatus,
            ),
          ],
        ),
      ),
    );
  }
}

String _statusLabel(dynamic value) => switch (value) {
  'under_review' => 'Under Review',
  'approved' => 'Approved',
  'rejected' => 'Rejected',
  'disbursed' => 'Disbursed',
  _ => 'Submitted',
};

class _HomeAction extends StatelessWidget {
  const _HomeAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: ListTile(
        minTileHeight: 86,
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFE7F1FF),
          child: Icon(icon, color: const Color(0xFF0075FF)),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
