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

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  late final AnimationController _animation;

  @override
  void initState() {
    super.initState();
    _animation = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _animation.forward();
    if (widget.autoNavigate) {
      _timer = Timer(const Duration(milliseconds: 2200), _openAuthentication);
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
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SplashScreen.backgroundColor,
      body: SafeArea(
        top: false,
        bottom: false,
        child: _SplashBrand(animation: _animation),
      ),
    );
  }
}

class _SplashBrand extends StatelessWidget {
  const _SplashBrand({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'CreditSea',
      image: true,
      child: ExcludeSemantics(
        child: Center(
          child: AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              final motion = Curves.easeOutCubic.transform(
                const Interval(.05, .62).transform(animation.value),
              );
              final symbolOpacity = Curves.easeIn.transform(
                const Interval(0, .38).transform(animation.value),
              );
              final brand = Curves.easeOutCubic.transform(
                const Interval(.34, .88).transform(animation.value),
              );
              final width = MediaQuery.sizeOf(context).width;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 142,
                    height: 104,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Opacity(
                          opacity: symbolOpacity,
                          child: Transform.translate(
                            offset: Offset(-(width / 2 + 90) * (1 - motion), 0),
                            child: SvgPicture.asset(
                              'assets/images/credit_sea_circle_layer.svg',
                            ),
                          ),
                        ),
                        Opacity(
                          opacity: symbolOpacity,
                          child: Transform.translate(
                            offset: Offset((width / 2 + 90) * (1 - motion), 0),
                            child: SvgPicture.asset(
                              'assets/images/credit_sea_wedges_layer.svg',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Opacity(
                    opacity: brand,
                    child: Transform.scale(
                      scale: brand,
                      child: const Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'Credit',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            TextSpan(
                              text: 'Sea',
                              style: TextStyle(fontWeight: FontWeight.w300),
                            ),
                          ],
                        ),
                        key: ValueKey('credit-sea-splash-artwork'),
                        style: TextStyle(color: Colors.white, fontSize: 38),
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
}
