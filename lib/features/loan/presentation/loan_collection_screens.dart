import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/network/api_client.dart';
import '../../../core/session/session_service.dart';
import '../data/loan_repository.dart';
import 'loan_flow_screens.dart';

class LoanOffersScreen extends StatefulWidget {
  const LoanOffersScreen({super.key});

  @override
  State<LoanOffersScreen> createState() => _LoanOffersScreenState();
}

class _LoanOffersScreenState extends State<LoanOffersScreen> {
  late final LoanRepository repository;
  List<Map<String, dynamic>> offers = const [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    repository = LoanRepository(Get.find<SessionService>());
    _load();
  }

  Future<void> _load() async {
    try {
      final applications = await repository.list();
      offers = applications
          .where((loan) => loan['status'] == 'submitted')
          .toList();
    } on ApiException catch (error) {
      _message(error.message);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _accept(Map<String, dynamic> loan) async {
    try {
      final accepted = await repository.accept(loan['_id'] as String);
      if (!mounted) return;
      await Get.off(
        () => ApplicationStatusScreen(
          loan: accepted,
          onContinue: () => Get.back(),
          onCancel: () async {
            await repository.cancel(accepted['_id'] as String);
            Get.back();
          },
        ),
      );
      await _load();
    } on ApiException catch (error) {
      _message(error.message);
    }
  }

  void _open(Map<String, dynamic> loan) {
    Get.to(
      () => OfferScreen(
        loan: loan,
        onAccept: () => _accept(loan),
        onExtend: () => Get.back(),
        onOpenStatus: () => Get.to(() => const LoanApplicationsScreen()),
      ),
    );
  }

  void _message(String value) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  @override
  Widget build(BuildContext context) {
    return _CollectionScaffold(
      title: 'Available Offers',
      activeIndex: 1,
      onTabSelected: (index) {
        if (index == 0) Get.back();
        if (index == 2) Get.off(() => const LoanApplicationsScreen());
      },
      child: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: offers.isEmpty
                  ? const _EmptyCollection(
                      icon: Icons.local_offer_outlined,
                      title: 'No active offers available',
                      subtitle:
                          'Submit a loan application to receive an offer.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: offers.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final loan = offers[index];
                        return _LoanCard(
                          loan: loan,
                          actionLabel: 'View Offer',
                          onTap: () => _open(loan),
                        );
                      },
                    ),
            ),
    );
  }
}

class LoanApplicationsScreen extends StatefulWidget {
  const LoanApplicationsScreen({super.key});

  @override
  State<LoanApplicationsScreen> createState() => _LoanApplicationsScreenState();
}

class _LoanApplicationsScreenState extends State<LoanApplicationsScreen> {
  late final LoanRepository repository;
  List<Map<String, dynamic>> applications = const [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    repository = LoanRepository(Get.find<SessionService>());
    _load();
  }

  Future<void> _load() async {
    try {
      applications = await repository.list();
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _cancel(Map<String, dynamic> loan) async {
    try {
      await repository.cancel(loan['_id'] as String);
      if (!mounted) return;
      Get.back();
      await _load();
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  void _open(Map<String, dynamic> loan) {
    if (loan['status'] == 'submitted') {
      Get.to(
        () => OfferScreen(
          loan: loan,
          onAccept: () async {
            final accepted = await repository.accept(loan['_id'] as String);
            Get.off(
              () => ApplicationStatusScreen(
                loan: accepted,
                onContinue: () => Get.back(),
                onCancel: () => _cancel(accepted),
              ),
            );
          },
          onExtend: () => Get.back(),
        ),
      );
      return;
    }
    Get.to(
      () => ApplicationStatusScreen(
        loan: loan,
        onContinue: () => Get.back(),
        onCancel: () => _cancel(loan),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _CollectionScaffold(
      title: 'Applications',
      activeIndex: 2,
      onTabSelected: (index) {
        if (index == 0) Get.back();
        if (index == 1) Get.off(() => const LoanOffersScreen());
      },
      child: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: applications.isEmpty
                  ? const _EmptyCollection(
                      icon: Icons.track_changes_outlined,
                      title: 'No applications yet',
                      subtitle: 'Your submitted loans will appear here.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: applications.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) => _LoanCard(
                        loan: applications[index],
                        actionLabel:
                            applications[index]['status'] == 'submitted'
                            ? 'View Offer'
                            : 'View Status',
                        onTap: () => _open(applications[index]),
                      ),
                    ),
            ),
    );
  }
}

class _CollectionScaffold extends StatelessWidget {
  const _CollectionScaffold({
    required this.title,
    required this.activeIndex,
    required this.onTabSelected,
    required this.child,
  });

  final String title;
  final int activeIndex;
  final ValueChanged<int> onTabSelected;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Text(title),
      ),
      body: Column(
        children: [
          _CollectionProgress(
            activeIndex: activeIndex,
            onSelected: onTabSelected,
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _CollectionProgress extends StatelessWidget {
  const _CollectionProgress({
    required this.activeIndex,
    required this.onSelected,
  });

  final int activeIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    const labels = ['Register', 'Offer', 'Approval'];
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (var index = 0; index < labels.length; index++) ...[
            InkWell(
              onTap: () => onSelected(index),
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 10,
                      backgroundColor: index == activeIndex
                          ? const Color(0xFF0075FF)
                          : const Color(0xFFF0F1F2),
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: index == activeIndex
                              ? Colors.white
                              : const Color(0xFF8B9299),
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      labels[index],
                      style: TextStyle(
                        color: index == activeIndex
                            ? const Color(0xFF0075FF)
                            : const Color(0xFF727980),
                        fontSize: 11,
                        fontWeight: index == activeIndex
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LoanCard extends StatelessWidget {
  const _LoanCard({
    required this.loan,
    required this.actionLabel,
    required this.onTap,
  });

  final Map<String, dynamic> loan;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = _statusLabel(loan['status']);
    return Card(
      color: Colors.white,
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _money((loan['amount'] as num?)?.toDouble() ?? 0),
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  _StatusChip(label: status, status: loan['status']),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${loan['purpose'] ?? 'Personal loan'} · ${loan['tenureDays'] ?? '-'} days',
                style: const TextStyle(color: Color(0xFF626A73)),
              ),
              const SizedBox(height: 5),
              Text(
                'Total payable ${_money((loan['totalPayable'] as num?)?.toDouble() ?? 0)}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF626A73)),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '$actionLabel  →',
                  style: const TextStyle(
                    color: Color(0xFF0075FF),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.status});

  final String label;
  final dynamic status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'approved' || 'disbursed' => const Color(0xFF008B63),
      'rejected' || 'cancelled' => const Color(0xFFD64242),
      _ => const Color(0xFF1268D8),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 11)),
    );
  }
}

class _EmptyCollection extends StatelessWidget {
  const _EmptyCollection({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 150),
        Icon(icon, size: 58, color: const Color(0xFF8BA2BB)),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF6E7781)),
        ),
      ],
    );
  }
}

String _statusLabel(dynamic value) => switch (value) {
  'under_review' => 'Under Review',
  'approved' => 'Approved',
  'rejected' => 'Rejected',
  'cancelled' => 'Cancelled',
  'disbursed' => 'Disbursed',
  _ => 'Offer Available',
};

String _money(double value) {
  final digits = value.round().toString();
  if (digits.length <= 3) return '₹$digits';
  final last = digits.substring(digits.length - 3);
  var remaining = digits.substring(0, digits.length - 3);
  final parts = <String>[];
  while (remaining.length > 2) {
    parts.insert(0, remaining.substring(remaining.length - 2));
    remaining = remaining.substring(0, remaining.length - 2);
  }
  if (remaining.isNotEmpty) parts.insert(0, remaining);
  return '₹${parts.join(',')},$last';
}
