import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import '../../../core/session/session_service.dart';
import '../../auth/presentation/auth_screen.dart';
import '../../loan/data/loan_repository.dart';
import '../../loan/presentation/loan_collection_screens.dart';
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
        onSubmit: (amount, tenureDays, purpose) async {
          final loan = await loans.apply(
            amount: amount,
            tenureDays: tenureDays,
            purpose: purpose,
          );
          applications = [loan, ...applications];
          Get.off(
            () => OfferScreen(
              loan: loan,
              onAccept: () async {
                final accepted = await loans.accept(loan['_id'] as String);
                Get.off(
                  () => ApplicationStatusScreen(
                    loan: accepted,
                    onContinue: () => Get.offAll(() => const HomeScreen()),
                    onCancel: () async {
                      await loans.cancel(accepted['_id'] as String);
                      Get.offAll(() => const HomeScreen());
                    },
                  ),
                );
              },
              onExtend: () => Get.back(),
            ),
          );
        },
      ),
    );
  }

  void _openOffer() {
    Get.to(() => const LoanOffersScreen());
  }

  void _openStatus() {
    Get.to(() => const LoanApplicationsScreen());
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
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1469B8),
        surfaceTintColor: Colors.white,
        toolbarHeight: 82,
        centerTitle: true,
        elevation: 3,
        shadowColor: Colors.black.withValues(alpha: .16),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 48,
              height: 42,
              child: SvgPicture.asset(
                'assets/images/credit_sea_header_mark.svg',
              ),
            ),
            const SizedBox(width: 5),
            const Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Credit',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(
                    text: 'Sea',
                    style: TextStyle(fontWeight: FontWeight.w300),
                  ),
                ],
              ),
              style: TextStyle(fontSize: 32, color: Color(0xFF1469B8)),
            ),
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
  'cancelled' => 'Cancelled',
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
