import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/network/api_client.dart';
import '../../../core/session/session_service.dart';
import '../../home/presentation/home_screen.dart';
import '../data/auth_repository.dart';
import '../../details/presentation/details_flow_screen.dart';

enum AuthStep { register, otp, createPassword, signIn }

class AuthController extends GetxController {
  // Temporary local credentials. Replace this branch with the OTP API once the
  // backend is connected.
  static const bool stagingAuthEnabled = true;
  static const String stagingMobileNumber = '9999999999';
  static const String stagingOtp = '1234';

  final step = AuthStep.register.obs;
  final carouselIndex = 0.obs;
  final acceptedTerms = true.obs;
  final obscurePassword = true.obs;
  final obscureConfirmation = true.obs;
  final isBusy = false.obs;

  late final AuthRepository _repository = AuthRepository(
    Get.find<SessionService>(),
  );

  final pageController = PageController();
  final mobileController = TextEditingController(
    text: stagingAuthEnabled ? stagingMobileNumber : '',
  );
  final passwordController = TextEditingController();
  final confirmationController = TextEditingController();
  final otpControllers = List.generate(4, (_) => TextEditingController());
  final otpFocusNodes = List.generate(4, (_) => FocusNode());

  String get mobileNumber => mobileController.text.trim();

  void showRegister() => step.value = AuthStep.register;
  void showSignIn() => step.value = AuthStep.signIn;

  Future<void> requestOtp() async {
    if (mobileNumber.length < 10) {
      _message('Enter a valid 10-digit mobile number');
      return;
    }
    if (!acceptedTerms.value) {
      _message('Please accept the terms and privacy policy');
      return;
    }
    await _run(() async {
      await _repository.requestOtp(mobileNumber);
      step.value = AuthStep.otp;
    });
  }

  Future<void> verifyOtp() async {
    final otp = otpControllers.map((controller) => controller.text).join();
    if (otp.length != 4) {
      _message('Enter the complete OTP');
      return;
    }
    await _run(() async {
      await _repository.verifyOtp(mobileNumber, otp);
      step.value = AuthStep.createPassword;
    });
  }

  Future<void> createPassword() async {
    final password = passwordController.text;
    if (password.length < 8 || !RegExp(r'[^A-Za-z0-9]').hasMatch(password)) {
      _message('Use at least 8 characters and one special character');
      return;
    }
    if (password != confirmationController.text) {
      _message('Passwords do not match');
      return;
    }
    await _run(() async {
      await _repository.setPassword(password);
      _message('Account created successfully');
      Get.offAll(() => const DetailsFlowScreen());
    });
  }

  Future<void> signIn() async {
    if (mobileNumber.length < 10 || passwordController.text.isEmpty) {
      _message('Enter your mobile number and password');
      return;
    }
    await _run(() async {
      await _repository.login(mobileNumber, passwordController.text);
      final session = Get.find<SessionService>();
      Get.offAll(
        () => session.isProfileComplete
            ? const HomeScreen()
            : const DetailsFlowScreen(),
      );
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    if (isBusy.value) return;
    isBusy.value = true;
    try {
      await action();
    } on ApiException catch (error) {
      _message(error.message);
    } finally {
      isBusy.value = false;
    }
  }

  void onOtpChanged(int index, String value) {
    if (value.isNotEmpty && index < otpFocusNodes.length - 1) {
      otpFocusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      otpFocusNodes[index - 1].requestFocus();
    }
  }

  void _message(String message) {
    Get.showSnackbar(
      GetSnackBar(message: message, duration: const Duration(seconds: 2)),
    );
  }

  @override
  void onClose() {
    pageController.dispose();
    mobileController.dispose();
    passwordController.dispose();
    confirmationController.dispose();
    for (final controller in otpControllers) {
      controller.dispose();
    }
    for (final node in otpFocusNodes) {
      node.dispose();
    }
    super.onClose();
  }
}
