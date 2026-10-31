import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import 'auth_controller.dart';

const _blue = Color(0xFF0F559C);
const _buttonBlue = Color(0xFF087BFF);
const _mint = Color(0xFF44D8BF);

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  late final AuthController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(AuthController());
  }

  @override
  void dispose() {
    Get.delete<AuthController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: _blue),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: _blue,
        body: SafeArea(
          bottom: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final designHeight = constraints.maxWidth * (407 / 390);
              final heroHeight = designHeight
                  .clamp(0.0, constraints.maxHeight * 0.56)
                  .toDouble();

              return Column(
                children: [
                  SizedBox(
                    height: heroHeight,
                    child: _AuthHero(controller: controller),
                  ),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(18),
                        ),
                        border: Border(top: BorderSide(color: _mint, width: 4)),
                      ),
                      child: Obx(
                        () => AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          child: _formFor(controller.step.value),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _formFor(AuthStep step) {
    return switch (step) {
      AuthStep.register => _RegisterForm(controller: controller),
      AuthStep.otp => _OtpForm(controller: controller),
      AuthStep.createPassword => _CreatePasswordForm(controller: controller),
      AuthStep.signIn => _SignInForm(controller: controller),
    };
  }
}

class _AuthHero extends StatelessWidget {
  const _AuthHero({required this.controller});

  final AuthController controller;

  static const slides = [
    'assets/images/auth_hero_flexible.svg',
    'assets/images/auth_hero_approval.svg',
    'assets/images/auth_hero_support.svg',
  ];

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: controller.pageController,
      itemCount: slides.length,
      onPageChanged: (index) => controller.carouselIndex.value = index,
      itemBuilder: (context, index) => SvgPicture.asset(
        slides[index],
        width: double.infinity,
        fit: BoxFit.fitWidth,
        alignment: Alignment.topCenter,
      ),
    );
  }
}

class _RegisterForm extends StatelessWidget {
  const _RegisterForm({required this.controller});

  final AuthController controller;

  @override
  Widget build(BuildContext context) {
    return _FormScroll(
      key: const ValueKey(AuthStep.register),
      children: [
        const _FormTitle('Welcome to Credit Sea!'),
        const SizedBox(height: 43),
        const _FieldLabel('Mobile Number'),
        const SizedBox(height: 7),
        _MobileField(controller: controller.mobileController),
        const SizedBox(height: 18),
        Obx(
          () => Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 28,
                height: 28,
                child: Checkbox(
                  value: controller.acceptedTerms.value,
                  activeColor: const Color(0xFF00A882),
                  onChanged: (value) =>
                      controller.acceptedTerms.value = value ?? false,
                ),
              ),
              const SizedBox(width: 7),
              const Expanded(
                child: Text.rich(
                  TextSpan(
                    style: TextStyle(
                      color: Color(0xFF6F7379),
                      fontSize: 11,
                      height: 1.5,
                    ),
                    children: [
                      TextSpan(text: 'By continuing, you agree to our '),
                      TextSpan(
                        text: 'privacy policies\nand Terms & Conditions.',
                        style: TextStyle(decoration: TextDecoration.underline),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _PrimaryButton(label: 'Request OTP', onPressed: controller.requestOtp),
        const SizedBox(height: 34),
        _TextAction(
          prefix: 'Existing User? ',
          action: 'Sign in',
          onPressed: controller.showSignIn,
        ),
      ],
    );
  }
}

class _OtpForm extends StatelessWidget {
  const _OtpForm({required this.controller});

  final AuthController controller;

  @override
  Widget build(BuildContext context) {
    return _FormScroll(
      key: const ValueKey(AuthStep.otp),
      children: [
        _BackTitle(title: 'Enter OTP', onBack: controller.showRegister),
        const SizedBox(height: 32),
        Text.rich(
          TextSpan(
            style: const TextStyle(fontSize: 13, color: Color(0xFF17212B)),
            children: [
              const TextSpan(text: 'Verify OTP, Sent on '),
              TextSpan(
                text: '+91 ${controller.mobileNumber}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(
            4,
            (index) => Padding(
              padding: const EdgeInsets.only(right: 20),
              child: SizedBox(
                width: 48,
                child: TextField(
                  key: ValueKey('otp-$index'),
                  controller: controller.otpControllers[index],
                  focusNode: controller.otpFocusNodes[index],
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 1,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: _inputDecoration.copyWith(counterText: ''),
                  onChanged: (value) => controller.onOtpChanged(index, value),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          '00:28',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 22),
        _PrimaryButton(label: 'Verify', onPressed: controller.verifyOtp),
      ],
    );
  }
}

class _CreatePasswordForm extends StatelessWidget {
  const _CreatePasswordForm({required this.controller});

  final AuthController controller;

  @override
  Widget build(BuildContext context) {
    return _FormScroll(
      key: const ValueKey(AuthStep.createPassword),
      children: [
        _BackTitle(
          title: 'Create a password',
          onBack: () => controller.step.value = AuthStep.otp,
        ),
        const SizedBox(height: 43),
        const _FieldLabel('Enter password'),
        const SizedBox(height: 7),
        Obx(
          () => _PasswordField(
            controller: controller.passwordController,
            hint: 'Enter password',
            obscure: controller.obscurePassword.value,
            onToggle: () => controller.obscurePassword.toggle(),
          ),
        ),
        const SizedBox(height: 16),
        const _FieldLabel('Re enter password'),
        const SizedBox(height: 7),
        Obx(
          () => _PasswordField(
            controller: controller.confirmationController,
            hint: 'Re enter password',
            obscure: controller.obscureConfirmation.value,
            onToggle: () => controller.obscureConfirmation.toggle(),
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          '*your password must include at least 8 characters,\ninclusive of at least 1 special character',
          style: TextStyle(
            color: Color(0xFFACACAC),
            fontSize: 12,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 22),
        _PrimaryButton(label: 'Proceed', onPressed: controller.createPassword),
      ],
    );
  }
}

class _SignInForm extends StatelessWidget {
  const _SignInForm({required this.controller});

  final AuthController controller;

  @override
  Widget build(BuildContext context) {
    return _FormScroll(
      key: const ValueKey(AuthStep.signIn),
      children: [
        const _FormTitle('Please enter your credentials'),
        const SizedBox(height: 43),
        const _FieldLabel('Mobile Number'),
        const SizedBox(height: 7),
        _MobileField(controller: controller.mobileController),
        const SizedBox(height: 16),
        const _FieldLabel('Enter password'),
        const SizedBox(height: 7),
        Obx(
          () => _PasswordField(
            controller: controller.passwordController,
            hint: 'Enter password',
            obscure: controller.obscurePassword.value,
            onToggle: () => controller.obscurePassword.toggle(),
          ),
        ),
        const SizedBox(height: 5),
        const Align(
          alignment: Alignment.centerRight,
          child: Text(
            'Enter password',
            style: TextStyle(color: _buttonBlue, fontSize: 11),
          ),
        ),
        const SizedBox(height: 18),
        _PrimaryButton(label: 'Sign In', onPressed: controller.signIn),
        const SizedBox(height: 24),
        _TextAction(
          prefix: 'New to CreditSea? ',
          action: 'Create an account',
          onPressed: controller.showRegister,
        ),
      ],
    );
  }
}

class _FormScroll extends StatelessWidget {
  const _FormScroll({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

class _FormTitle extends StatelessWidget {
  const _FormTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
    );
  }
}

class _BackTitle extends StatelessWidget {
  const _BackTitle({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back, color: Color(0xFF929DAC)),
          ),
        ),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 13, color: Color(0xFF17212B)),
    );
  }
}

class _MobileField extends StatelessWidget {
  const _MobileField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFD1D4D8)),
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(6),
            ),
          ),
          child: const Row(
            children: [
              Text('🇮🇳', style: TextStyle(fontSize: 19)),
              SizedBox(width: 8),
              Text('+91', style: TextStyle(color: Color(0xFF45515D))),
            ],
          ),
        ),
        Expanded(
          child: SizedBox(
            height: 50,
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: _inputDecoration.copyWith(
                hintText: 'Please enter your mobile no.',
                counterText: '',
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.horizontal(
                    right: Radius.circular(6),
                  ),
                  borderSide: BorderSide(color: Color(0xFFD1D4D8)),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.hint,
    required this.obscure,
    required this.onToggle,
  });

  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: _inputDecoration.copyWith(
        hintText: hint,
        suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(
            obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          ),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: _buttonBlue,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
          elevation: 4,
          shadowColor: _buttonBlue.withValues(alpha: 0.45),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _TextAction extends StatelessWidget {
  const _TextAction({
    required this.prefix,
    required this.action,
    required this.onPressed,
  });

  final String prefix;
  final String action;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      child: Text.rich(
        TextSpan(
          text: prefix,
          children: [
            TextSpan(
              text: action,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        style: const TextStyle(color: Color(0xFF004593), fontSize: 13),
      ),
    );
  }
}

const _inputDecoration = InputDecoration(
  isDense: true,
  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 15),
  hintStyle: TextStyle(color: Color(0xFFB0B0B0), fontSize: 14),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(6)),
    borderSide: BorderSide(color: Color(0xFFD1D4D8)),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(6)),
    borderSide: BorderSide(color: _buttonBlue, width: 1.5),
  ),
);
