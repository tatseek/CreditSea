import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../features/splash/presentation/splash_screen.dart';
import '../features/details/presentation/details_flow_screen.dart';
import '../features/loan/presentation/loan_flow_screens.dart';

class CreditSeaApp extends StatelessWidget {
  const CreditSeaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'CreditSea',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F4B92)),
        scaffoldBackgroundColor: const Color(0xFF0F4B92),
        useMaterial3: true,
      ),
      home: const bool.fromEnvironment('SHOW_LOAN_FLOW')
          ? const LoanFlowPreview()
          : const bool.fromEnvironment('SHOW_DETAILS')
          ? const DetailsFlowScreen()
          : const SplashScreen(),
    );
  }
}
