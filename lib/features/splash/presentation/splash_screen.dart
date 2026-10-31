import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import '../../../core/session/session_service.dart';
import '../../auth/presentation/auth_screen.dart';
import '../../details/presentation/details_flow_screen.dart';
import '../../home/presentation/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.autoNavigate = true});

  final bool autoNavigate;

  static const Color backgroundColor = Color(0xFF0F4B92);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.autoNavigate) {
      _timer = Timer(const Duration(seconds: 2), _openAuthentication);
    }
  }

  void _openAuthentication() {
    if (!mounted) return;
    final session = Get.find<SessionService>();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => session.isSignedIn
            ? session.isProfileComplete
                  ? const HomeScreen()
                  : const DetailsFlowScreen()
            : const AuthScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: SplashScreen.backgroundColor,
      body: SafeArea(top: false, bottom: false, child: _SplashBrand()),
    );
  }
}

class _SplashBrand extends StatelessWidget {
  const _SplashBrand();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'CreditSea',
      image: true,
      child: ExcludeSemantics(
        child: SizedBox.expand(
          child: SvgPicture.asset(
            'assets/images/credit_sea_logo.svg',
            key: const ValueKey('credit-sea-splash-artwork'),
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
        ),
      ),
    );
  }
}
