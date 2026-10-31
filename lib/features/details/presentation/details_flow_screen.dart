import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/network/api_client.dart';
import '../../../core/session/session_service.dart';
import '../../home/presentation/home_screen.dart';
import '../data/profile_repository.dart';

const _primaryBlue = Color(0xFF0075FF);
const _labelColor = Color(0xFF111820);
const _borderColor = Color(0xFFE6E8EB);

enum DetailsStep { personal, email, pan }

class DetailsFlowScreen extends StatefulWidget {
  const DetailsFlowScreen({super.key});

  @override
  State<DetailsFlowScreen> createState() => _DetailsFlowScreenState();
}

class _DetailsFlowScreenState extends State<DetailsFlowScreen> {
  var _loading = true;
  var _step = DetailsStep.personal;
  final _draft = <String, dynamic>{};
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.white,
        systemNavigationBarColor: Colors.white,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F7F8),
        body: SafeArea(
          child: _loading
              ? const _DetailsSkeleton()
              : Column(
                  children: [
                    const _ApplicationProgress(),
                    Expanded(
                      child: ClipRect(
                        child: _AnimatedDetailsSheet(
                          key: ValueKey(_step),
                          child: switch (_step) {
                            DetailsStep.personal => _PersonalDetailsForm(
                              onContinue: (details) => setState(() {
                                _draft.addAll(details);
                                _step = DetailsStep.email;
                              }),
                            ),
                            DetailsStep.email => _EmailVerificationForm(
                              onBack: () =>
                                  setState(() => _step = DetailsStep.personal),
                              onVerified: (email) => setState(() {
                                _draft['email'] = email;
                                _step = DetailsStep.pan;
                              }),
                            ),
                            DetailsStep.pan => _PanVerificationForm(
                              onBack: () =>
                                  setState(() => _step = DetailsStep.email),
                              draft: _draft,
                            ),
                          },
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

class _AnimatedDetailsSheet extends StatefulWidget {
  const _AnimatedDetailsSheet({super.key, required this.child});

  final Widget child;

  @override
  State<_AnimatedDetailsSheet> createState() => _AnimatedDetailsSheetState();
}

class _AnimatedDetailsSheetState extends State<_AnimatedDetailsSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _position;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _position = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(position: _position, child: widget.child);
  }
}

class _ApplicationProgress extends StatelessWidget {
  const _ApplicationProgress();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 26),
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
      child: const Row(
        children: [
          _ProgressItem(number: '1', label: 'Register', active: true),
          Expanded(child: Divider(color: _borderColor, height: 1)),
          _ProgressItem(number: '2', label: 'Offer'),
          Expanded(child: Divider(color: _borderColor, height: 1)),
          _ProgressItem(number: '3', label: 'Approval'),
        ],
      ),
    );
  }
}

class _ProgressItem extends StatelessWidget {
  const _ProgressItem({
    required this.number,
    required this.label,
    this.active = false,
  });

  final String number;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 10,
          backgroundColor: active ? _primaryBlue : const Color(0xFFF0F1F2),
          child: Text(
            number,
            style: TextStyle(
              color: active ? Colors.white : const Color(0xFF8B9299),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: active ? _primaryBlue : const Color(0xFF6E747B),
            fontSize: 11,
            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class _PersonalDetailsForm extends StatefulWidget {
  const _PersonalDetailsForm({required this.onContinue});

  final ValueChanged<Map<String, dynamic>> onContinue;

  @override
  State<_PersonalDetailsForm> createState() => _PersonalDetailsFormState();
}

class _PersonalDetailsFormState extends State<_PersonalDetailsForm> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _monthlyIncome = TextEditingController();
  final _existingEmi = TextEditingController(text: '0');
  DateTime? _birthDate;
  String? _gender;
  String? _maritalStatus;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _monthlyIncome.dispose();
    _existingEmi.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final result = await showDialog<DateTime>(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) => _CompactDatePickerDialog(
        initialDate: _birthDate ?? DateTime(2000, 8, 17),
      ),
    );
    if (result == null) return;
    setState(() {
      _birthDate = result.year == 1900 ? null : result;
    });
  }

  void _continue() {
    if (!(_formKey.currentState?.validate() ?? false) ||
        _gender == null ||
        _birthDate == null ||
        _maritalStatus == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all required details')),
      );
      return;
    }
    widget.onContinue({
      'firstName': _firstName.text.trim(),
      'lastName': _lastName.text.trim(),
      'dateOfBirth': _birthDate!.toIso8601String(),
      'gender': switch (_gender) {
        'Female' => 'female',
        'Male' => 'male',
        _ => 'other',
      },
      'maritalStatus': _maritalStatus == 'Single'
          ? 'single'
          : _maritalStatus == 'Married'
          ? 'married'
          : 'other',
      'monthlyIncome': double.parse(_monthlyIncome.text),
      'existingMonthlyEmi': double.parse(_existingEmi.text),
    });
  }

  @override
  Widget build(BuildContext context) {
    return _DetailsPage(
      title: 'Personal Details',
      onBack: () => Navigator.maybePop(context),
      buttonLabel: 'Continue',
      onButtonPressed: _continue,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: _LabeledField(
                    label: 'First Name*',
                    child: TextFormField(
                      controller: _firstName,
                      decoration: _fieldDecoration('Your first name'),
                      validator: _required,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _LabeledField(
                    label: 'Last Name*',
                    child: TextFormField(
                      controller: _lastName,
                      decoration: _fieldDecoration('Your last name'),
                      validator: _required,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            _LabeledField(
              label: 'Gender*',
              child: DropdownButtonFormField<String>(
                initialValue: _gender,
                decoration: _fieldDecoration('Select your gender'),
                items:
                    const ['Female', 'Male', 'Non-binary', 'Prefer not to say']
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value),
                          ),
                        )
                        .toList(),
                onChanged: (value) => setState(() => _gender = value),
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: _LabeledField(
                    label: 'Monthly Income*',
                    child: TextFormField(
                      controller: _monthlyIncome,
                      keyboardType: TextInputType.number,
                      decoration: _fieldDecoration('e.g., 50000'),
                      validator: _positiveNumber,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _LabeledField(
                    label: 'Existing EMI',
                    child: TextFormField(
                      controller: _existingEmi,
                      keyboardType: TextInputType.number,
                      decoration: _fieldDecoration('0'),
                      validator: _nonNegativeNumber,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            _LabeledField(
              label: 'Date of Birth*',
              child: InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(4),
                child: InputDecorator(
                  decoration: _fieldDecoration('DD - MM - YYYY').copyWith(
                    suffixIcon: const Icon(
                      Icons.calendar_month_outlined,
                      size: 20,
                    ),
                  ),
                  child: Text(
                    _birthDate == null
                        ? 'DD - MM - YYYY'
                        : '${_birthDate!.day.toString().padLeft(2, '0')} - '
                              '${_birthDate!.month.toString().padLeft(2, '0')} - '
                              '${_birthDate!.year}',
                    style: TextStyle(
                      color: _birthDate == null
                          ? const Color(0xFFA1A5AA)
                          : _labelColor,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 22),
            _LabeledField(
              label: 'Your Marital Status *',
              child: DropdownButtonFormField<String>(
                initialValue: _maritalStatus,
                decoration: _fieldDecoration('Select'),
                items: const ['Single', 'Married', 'Divorced', 'Widowed']
                    .map(
                      (value) =>
                          DropdownMenuItem(value: value, child: Text(value)),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _maritalStatus = value),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmailVerificationForm extends StatefulWidget {
  const _EmailVerificationForm({
    required this.onBack,
    required this.onVerified,
  });

  final VoidCallback onBack;
  final ValueChanged<String> onVerified;

  @override
  State<_EmailVerificationForm> createState() => _EmailVerificationFormState();
}

class _EmailVerificationFormState extends State<_EmailVerificationForm> {
  static const stagingOtp = '123456';
  final _email = TextEditingController();
  final _otp = List.generate(6, (_) => TextEditingController());
  final _focusNodes = List.generate(6, (_) => FocusNode());

  @override
  void dispose() {
    _email.dispose();
    for (final controller in _otp) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _verify() {
    final email = _email.text.trim();
    final otp = _otp.map((controller) => controller.text).join();
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email)) {
      _message('Enter a valid email ID');
      return;
    }
    if (otp != stagingOtp) {
      _message('Use staging email OTP $stagingOtp');
      return;
    }
    widget.onVerified(email);
  }

  void _message(String value) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  @override
  Widget build(BuildContext context) {
    return _DetailsPage(
      title: 'Personal Email ID',
      onBack: widget.onBack,
      buttonLabel: 'Verify',
      onButtonPressed: _verify,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 18),
          const _VerificationIllustration(
            icon: Icons.mark_email_read_outlined,
            background: Color(0xFFF3F7FF),
          ),
          const SizedBox(height: 38),
          _LabeledField(
            label: 'Email ID*',
            child: TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: _fieldDecoration('Enter your email ID'),
            ),
          ),
          const SizedBox(height: 22),
          const Text('OTP Verification', style: _labelStyle),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              6,
              (index) => SizedBox(
                width: 45,
                child: TextField(
                  controller: _otp[index],
                  focusNode: _focusNodes[index],
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 1,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: _fieldDecoration('').copyWith(counterText: ''),
                  onChanged: (value) {
                    if (value.isNotEmpty && index < 5) {
                      _focusNodes[index + 1].requestFocus();
                    } else if (value.isEmpty && index > 0) {
                      _focusNodes[index - 1].requestFocus();
                    }
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text("Didn't receive it? ", style: TextStyle(fontSize: 11)),
              TextButton(
                onPressed: () => _message('Staging OTP: $stagingOtp'),
                style: TextButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Resend Code',
                  style: TextStyle(fontSize: 11),
                ),
              ),
              const Spacer(),
              const Text('00:28', style: TextStyle(fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

class _PanVerificationForm extends StatefulWidget {
  const _PanVerificationForm({required this.onBack, required this.draft});

  final VoidCallback onBack;
  final Map<String, dynamic> draft;

  @override
  State<_PanVerificationForm> createState() => _PanVerificationFormState();
}

class _PanVerificationFormState extends State<_PanVerificationForm> {
  final _pan = TextEditingController(text: 'ABCDE1234F');

  @override
  void dispose() {
    _pan.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final valid = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$').hasMatch(_pan.text.trim());
    if (!valid) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter a valid PAN number')));
      return;
    }
    try {
      final repository = ProfileRepository(Get.find<SessionService>());
      await repository.save({...widget.draft, 'pan': _pan.text.trim()});
      Get.offAll(() => const HomeScreen());
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return _DetailsPage(
      title: 'Verify PAN Number',
      onBack: widget.onBack,
      buttonLabel: 'Verify',
      onButtonPressed: _verify,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 22),
          const _VerificationIllustration(
            icon: Icons.credit_card_rounded,
            background: Color(0xFFEFF4FF),
          ),
          const SizedBox(height: 44),
          _LabeledField(
            label: 'Enter Your PAN Number*',
            child: TextField(
              controller: _pan,
              textCapitalization: TextCapitalization.characters,
              maxLength: 10,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
                _UpperCaseTextFormatter(),
              ],
              decoration: _fieldDecoration('e.g., ABCDE1234F')
                  .copyWith(counterText: ''),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailsPage extends StatelessWidget {
  const _DetailsPage({
    required this.title,
    required this.onBack,
    required this.buttonLabel,
    required this.onButtonPressed,
    required this.child,
  });

  final String title;
  final VoidCallback onBack;
  final String buttonLabel;
  final VoidCallback onButtonPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(7, 10, 7, 0),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.13),
              blurRadius: 22,
              spreadRadius: 1,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 22, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        InkWell(
                          onTap: onBack,
                          borderRadius: BorderRadius.circular(20),
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(Icons.arrow_back, size: 20),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Text(
                          title,
                          style: const TextStyle(
                            color: _labelColor,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    child,
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: onButtonPressed,
                  style: FilledButton.styleFrom(
                    backgroundColor: _primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                    elevation: 3,
                  ),
                  child: Text(buttonLabel),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactDatePickerDialog extends StatefulWidget {
  const _CompactDatePickerDialog({required this.initialDate});

  final DateTime initialDate;

  @override
  State<_CompactDatePickerDialog> createState() =>
      _CompactDatePickerDialogState();
}

class _CompactDatePickerDialogState extends State<_CompactDatePickerDialog> {
  late DateTime selectedDate;
  late DateTime visibleMonth;

  static const monthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  @override
  void initState() {
    super.initState();
    selectedDate = widget.initialDate;
    visibleMonth = DateTime(widget.initialDate.year, widget.initialDate.month);
  }

  int get daysInMonth =>
      DateTime(visibleMonth.year, visibleMonth.month + 1, 0).day;

  void _changeMonth(int delta) {
    setState(() {
      visibleMonth = DateTime(visibleMonth.year, visibleMonth.month + delta);
    });
  }

  void _changeYear(int delta) {
    setState(() {
      visibleMonth = DateTime(visibleMonth.year + delta, visibleMonth.month);
    });
  }

  @override
  Widget build(BuildContext context) {
    final leadingEmptyCells = visibleMonth.weekday % 7;
    final cellCount = leadingEmptyCells + daysInMonth;

    return Dialog(
      alignment: const Alignment(0.62, -0.02),
      insetPadding: const EdgeInsets.only(left: 104, right: 22),
      elevation: 12,
      shadowColor: Colors.black.withValues(alpha: 0.22),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 24,
                    height: 24,
                  ),
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _changeMonth(-1),
                  icon: const Icon(Icons.chevron_left, size: 18),
                ),
                Expanded(
                  child: Text(
                    monthNames[visibleMonth.month - 1],
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 24,
                    height: 24,
                  ),
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _changeMonth(1),
                  icon: const Icon(Icons.chevron_right, size: 18),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 24,
                    height: 24,
                  ),
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _changeYear(-1),
                  icon: const Icon(Icons.chevron_left, size: 18),
                ),
                Expanded(
                  child: Text(
                    '${visibleMonth.year}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 24,
                    height: 24,
                  ),
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _changeYear(1),
                  icon: const Icon(Icons.chevron_right, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                for (final day in ['S', 'M', 'T', 'W', 'T', 'F', 'S'])
                  Expanded(
                    child: Text(
                      day,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF5E646B),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisExtent: 32,
              ),
              itemCount: cellCount,
              itemBuilder: (context, index) {
                if (index < leadingEmptyCells) return const SizedBox.shrink();
                final day = index - leadingEmptyCells + 1;
                final isSelected =
                    selectedDate.year == visibleMonth.year &&
                    selectedDate.month == visibleMonth.month &&
                    selectedDate.day == day;
                return InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => setState(() {
                    selectedDate = DateTime(
                      visibleMonth.year,
                      visibleMonth.month,
                      day,
                    );
                  }),
                  child: Center(
                    child: Container(
                      width: 27,
                      height: 27,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected ? _primaryBlue : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$day',
                        style: TextStyle(
                          color: isSelected ? Colors.white : _labelColor,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context, DateTime(1900)),
                  child: const Text('Clear', style: TextStyle(fontSize: 10)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(fontSize: 10)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, selectedDate),
                  child: const Text('OK', style: TextStyle(fontSize: 10)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: _labelStyle),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _VerificationIllustration extends StatelessWidget {
  const _VerificationIllustration({
    required this.icon,
    required this.background,
  });

  final IconData icon;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 128,
        height: 112,
        decoration: BoxDecoration(color: background, shape: BoxShape.circle),
        child: Icon(icon, size: 72, color: const Color(0xFF1268D8)),
      ),
    );
  }
}

class _DetailsSkeleton extends StatelessWidget {
  const _DetailsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 28, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SkeletonBar(height: 16),
          const SizedBox(height: 42),
          const _SkeletonBar(widthFactor: 0.48, height: 16),
          const SizedBox(height: 34),
          Row(
            children: const [
              Expanded(child: _SkeletonBar(height: 16)),
              SizedBox(width: 10),
              Expanded(child: _SkeletonBar(height: 16)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: const [
              Expanded(child: _SkeletonBar(height: 42)),
              SizedBox(width: 10),
              Expanded(child: _SkeletonBar(height: 42)),
            ],
          ),
          const SizedBox(height: 18),
          const _SkeletonBar(height: 16),
          const SizedBox(height: 10),
          const _SkeletonBar(height: 42),
          const SizedBox(height: 18),
          const _SkeletonBar(height: 16),
          const SizedBox(height: 10),
          const _SkeletonBar(height: 42),
          const Spacer(),
          const _SkeletonBar(height: 50),
        ],
      ),
    );
  }
}

class _SkeletonBar extends StatelessWidget {
  const _SkeletonBar({this.widthFactor = 1, required this.height});

  final double widthFactor;
  final double height;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      alignment: Alignment.centerLeft,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFFD9D9D9),
          borderRadius: BorderRadius.circular(5),
        ),
      ),
    );
  }
}

class _UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}

String? _required(String? value) =>
    value == null || value.trim().isEmpty ? 'Required' : null;

String? _positiveNumber(String? value) {
  final number = double.tryParse(value ?? '');
  return number == null || number <= 0 ? 'Enter a valid amount' : null;
}

String? _nonNegativeNumber(String? value) {
  final number = double.tryParse(value ?? '');
  return number == null || number < 0 ? 'Enter a valid amount' : null;
}

const _labelStyle = TextStyle(
  color: _labelColor,
  fontSize: 12,
  fontWeight: FontWeight.w500,
);

InputDecoration _fieldDecoration(String hint) => InputDecoration(
  hintText: hint,
  hintStyle: const TextStyle(color: Color(0xFFA1A5AA), fontSize: 12),
  isDense: true,
  filled: true,
  fillColor: Colors.white,
  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
  enabledBorder: const OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(4)),
    borderSide: BorderSide(color: _borderColor),
  ),
  focusedBorder: const OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(4)),
    borderSide: BorderSide(color: _primaryBlue, width: 1.3),
  ),
  errorBorder: const OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(4)),
    borderSide: BorderSide(color: Colors.redAccent),
  ),
);
