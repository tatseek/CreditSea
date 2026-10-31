import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/network/api_client.dart';

const _blue = Color(0xFF0075FF);
const _dark = Color(0xFF151A20);
const _border = Color(0xFFE3E6EA);
const _green = Color(0xFF00A676);

class LoanFlowPreview extends StatefulWidget {
  const LoanFlowPreview({super.key});

  @override
  State<LoanFlowPreview> createState() => _LoanFlowPreviewState();
}

class _LoanFlowPreviewState extends State<LoanFlowPreview> {
  var index = 0;

  @override
  Widget build(BuildContext context) {
    return switch (index) {
      0 => LoanCalculatorScreen(onApply: () => setState(() => index = 1)),
      1 => OfferScreen(
        onAccept: () => setState(() => index = 2),
        onExtend: () => setState(() => index = 0),
      ),
      _ => ApplicationStatusScreen(onContinue: () {}),
    };
  }
}

class LoanCalculatorScreen extends StatefulWidget {
  const LoanCalculatorScreen({super.key, required this.onApply, this.onSubmit});

  final VoidCallback onApply;
  final Future<void> Function(double amount, int tenureMonths, String purpose)?
  onSubmit;

  @override
  State<LoanCalculatorScreen> createState() => _LoanCalculatorScreenState();
}

class _LoanCalculatorScreenState extends State<LoanCalculatorScreen> {
  double amount = 30000;
  double tenure = 40;
  String? purpose;
  bool submitting = false;

  double get interest => amount * 0.01;
  double get processingFee => amount * 0.10;
  double get total => amount + interest + processingFee;

  Future<void> _apply() async {
    if (purpose == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a purpose for the loan.')),
      );
      return;
    }
    if (widget.onSubmit == null) {
      widget.onApply();
      return;
    }
    setState(() => submitting = true);
    try {
      await widget.onSubmit!(amount, (tenure / 30).ceil(), purpose!);
    } on ApiException catch (error) {
      if (!mounted) return;
      final reasons = error.data?['eligibility']?['reasons'];
      final detail = reasons is List && reasons.isNotEmpty
          ? reasons.join('\n')
          : error.message;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(detail)));
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _LoanScaffold(
      child: Column(
        children: [
          const _CreditSeaHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _BackHeading(title: 'Apply for loan'),
                  const Text(
                    "We've calculated your loan eligibility. Select your preferred loan amount and tenure.",
                    style: TextStyle(fontSize: 11, color: Color(0xFF565D65)),
                  ),
                  const SizedBox(height: 18),
                  const Row(
                    children: [
                      Expanded(
                        child: _RateCard(
                          label: 'Interest Per Day',
                          value: '1%',
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: _RateCard(label: 'Processing Fee', value: '10%'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  const Text('Purpose of Loan*', style: _fieldLabel),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: purpose,
                    decoration: _inputDecoration('Select purpose of loan'),
                    items:
                        const [
                              'Personal expenses',
                              'Medical expenses',
                              'Education',
                              'Home improvement',
                              'Business',
                            ]
                            .map(
                              (item) => DropdownMenuItem(
                                value: item,
                                child: Text(item),
                              ),
                            )
                            .toList(),
                    onChanged: (value) => setState(() => purpose = value),
                  ),
                  const SizedBox(height: 26),
                  _SliderTitle(
                    label: 'Principal Amount',
                    value: _money(amount),
                  ),
                  SliderTheme(
                    data: _sliderTheme(context),
                    child: Slider(
                      value: amount,
                      min: 10000,
                      max: 100000,
                      divisions: 18,
                      onChanged: (value) => setState(() => amount = value),
                    ),
                  ),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('₹10,000', style: _rangeLabel),
                      Text('₹1,00,000', style: _rangeLabel),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _SliderTitle(
                    label: 'Tenure',
                    value: '${tenure.round()} Days',
                  ),
                  SliderTheme(
                    data: _sliderTheme(context),
                    child: Slider(
                      value: tenure,
                      min: 20,
                      max: 45,
                      divisions: 25,
                      onChanged: (value) => setState(() => tenure = value),
                    ),
                  ),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('20 Days', style: _rangeLabel),
                      Text('45 Days', style: _rangeLabel),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFF37BFD1),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Column(
                      children: [
                        _SummaryRow(
                          label: 'Principle Amount',
                          value: _money(amount),
                        ),
                        const SizedBox(height: 12),
                        const _SummaryRow(label: 'Interest', value: '1%'),
                        const SizedBox(height: 12),
                        _SummaryRow(
                          label: 'Total Payable',
                          value: _money(total),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Thank you for choosing CreditSea. Please accept to proceed with the loan details.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF318CB4), fontSize: 11),
                  ),
                  const SizedBox(height: 18),
                  _PrimaryButton(
                    label: submitting ? 'Submitting…' : 'Apply',
                    onPressed: submitting ? null : _apply,
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: () => Navigator.maybePop(context),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      side: const BorderSide(color: _blue),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OfferScreen extends StatelessWidget {
  const OfferScreen({
    super.key,
    required this.onAccept,
    required this.onExtend,
    this.loan,
  });

  final VoidCallback onAccept;
  final VoidCallback onExtend;
  final Map<String, dynamic>? loan;

  @override
  Widget build(BuildContext context) {
    return _LoanScaffold(
      child: Column(
        children: [
          _LoanProgress(
            activeIndex: 1,
            onSelected: (index) {
              if (index == 0) Navigator.maybePop(context);
              if (index == 2) onAccept();
            },
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 72, 16, 18),
              child: Column(
                children: [
                  const Text(
                    'Our Offerings',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 44),
                  Container(
                    width: 82,
                    height: 82,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFD600),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.currency_rupee_rounded,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 52),
                  Text.rich(
                    TextSpan(
                      style: const TextStyle(
                        color: Color(0xFF4A5057),
                        fontSize: 13,
                        height: 1.55,
                      ),
                      children: [
                        const TextSpan(
                          text: 'Congratulations! ',
                          style: TextStyle(
                            color: _green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextSpan(
                          text:
                              'We can offer you ${_money((loan?['amount'] as num?)?.toDouble() ?? 10000)} within 30 minutes, with an estimated EMI of ${_money((loan?['estimatedEmi'] as num?)?.toDouble() ?? 10600)}. Just a few more steps remain.',
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Proceed further to',
                    style: TextStyle(fontSize: 12),
                  ),
                  const Spacer(),
                  _PrimaryButton(label: 'Accept Offer', onPressed: onAccept),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: onExtend,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      side: const BorderSide(color: _blue),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    child: const Text('Extend Offer'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ApplicationStatusScreen extends StatelessWidget {
  const ApplicationStatusScreen({
    super.key,
    required this.onContinue,
    this.loan,
  });

  final VoidCallback onContinue;
  final Map<String, dynamic>? loan;

  static const statuses = [
    ('Application Submitted', _green),
    ('Application under Review', _blue),
    ('E-KYC', Color(0xFF848B92)),
    ('E-Nach', Color(0xFF848B92)),
    ('E-Sign', Color(0xFF848B92)),
    ('Disbursement', Color(0xFF848B92)),
  ];

  @override
  Widget build(BuildContext context) {
    return _LoanScaffold(
      child: Column(
        children: [
          _LoanProgress(
            activeIndex: 2,
            onSelected: (index) {
              if (index < 2) Navigator.maybePop(context);
            },
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _BackHeading(title: 'Application Status'),
                  Text(
                    'Loan application no. #${_shortId(loan?['_id'])}',
                    style: TextStyle(fontSize: 11, color: Color(0xFF565D65)),
                  ),
                  const SizedBox(height: 18),
                  for (final status in statuses) ...[
                    _StatusTile(label: status.$1, color: status.$2),
                    const SizedBox(height: 10),
                  ],
                  const Spacer(),
                  const Icon(
                    Icons.directions_car_filled_outlined,
                    color: _blue,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _statusTitle(loan?['status']),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "We're carefully reviewing your application to ensure everything is in order. Thank you for your patience.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF5E646B),
                      height: 1.4,
                    ),
                  ),
                  const Spacer(),
                  _PrimaryButton(label: 'Continue', onPressed: onContinue),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoanScaffold extends StatelessWidget {
  const _LoanScaffold({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.white,
        systemNavigationBarColor: Colors.white,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(child: child),
      ),
    );
  }
}

class _LoanProgress extends StatelessWidget {
  const _LoanProgress({required this.activeIndex, this.onSelected});

  final int activeIndex;
  final ValueChanged<int>? onSelected;

  @override
  Widget build(BuildContext context) {
    const labels = ['Register', 'Offer', 'Approval'];
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          for (var index = 0; index < labels.length; index++) ...[
            InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: onSelected == null ? null : () => onSelected!(index),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 10,
                      backgroundColor: index == activeIndex
                          ? _blue
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
                            ? _blue
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
            if (index < labels.length - 1)
              const Expanded(child: Divider(color: _border, height: 1)),
          ],
        ],
      ),
    );
  }
}

class _CreditSeaHeader extends StatelessWidget {
  const _CreditSeaHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 92,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: SvgPicture.asset('assets/images/credit_sea_mark.svg'),
          ),
          const SizedBox(width: 8),
          const Text(
            'CreditSea',
            style: TextStyle(
              color: Color(0xFF1469B8),
              fontSize: 28,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _BackHeading extends StatelessWidget {
  const _BackHeading({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkWell(
          onTap: () => Navigator.maybePop(context),
          child: const Padding(
            padding: EdgeInsets.fromLTRB(0, 4, 12, 4),
            child: Icon(Icons.arrow_back, size: 20),
          ),
        ),
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _RateCard extends StatelessWidget {
  const _RateCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(border: Border.all(color: _border)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 10)),
          Text(
            value,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _SliderTitle extends StatelessWidget {
  const _SliderTitle({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: _fieldLabel),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F8F9),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(value, style: const TextStyle(fontSize: 12)),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12)),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF0069C8),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _StatusTile extends StatelessWidget {
  const _StatusTile({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Icon(Icons.description_outlined, color: color, size: 18),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(color: color, fontSize: 12),
            ),
          ),
          const SizedBox(width: 32),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: _blue,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
          elevation: 3,
        ),
        child: Text(label),
      ),
    );
  }
}

SliderThemeData _sliderTheme(BuildContext context) =>
    SliderTheme.of(context).copyWith(
      activeTrackColor: _blue,
      inactiveTrackColor: const Color(0xFFE4E7EA),
      thumbColor: _blue,
      overlayColor: _blue.withValues(alpha: 0.12),
      trackHeight: 8,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
    );

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

String _shortId(dynamic value) {
  final id = value?.toString() ?? 'CS12323';
  return id.length <= 8
      ? id.toUpperCase()
      : id.substring(id.length - 8).toUpperCase();
}

String _statusTitle(dynamic value) => switch (value) {
  'approved' => 'Application Approved',
  'rejected' => 'Application Rejected',
  'disbursed' => 'Loan Disbursed',
  'submitted' => 'Application Submitted',
  _ => 'Application Under Review',
};

const _fieldLabel = TextStyle(
  color: _dark,
  fontSize: 12,
  fontWeight: FontWeight.w500,
);
const _rangeLabel = TextStyle(color: Color(0xFF7C838A), fontSize: 9);

InputDecoration _inputDecoration(String hint) => InputDecoration(
  hintText: hint,
  hintStyle: const TextStyle(color: Color(0xFFA1A6AB), fontSize: 12),
  isDense: true,
  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
  enabledBorder: const OutlineInputBorder(
    borderSide: BorderSide(color: _border),
    borderRadius: BorderRadius.all(Radius.circular(4)),
  ),
  focusedBorder: const OutlineInputBorder(
    borderSide: BorderSide(color: _blue),
    borderRadius: BorderRadius.all(Radius.circular(4)),
  ),
);
