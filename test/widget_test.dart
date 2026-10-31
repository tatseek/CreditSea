import 'package:credit_sea/features/auth/presentation/auth_controller.dart';
import 'package:credit_sea/features/auth/presentation/auth_screen.dart';
import 'package:credit_sea/features/details/presentation/details_flow_screen.dart';
import 'package:credit_sea/features/loan/presentation/loan_flow_screens.dart';
import 'package:credit_sea/features/splash/presentation/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  test('exposes the configured staging credentials', () {
    expect(AuthController.stagingMobileNumber, '9999999999');
    expect(AuthController.stagingOtp, '1234');
  });

  testWidgets('shows the CreditSea splash screen', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: SplashScreen(autoNavigate: false)),
    );

    expect(find.byType(SplashScreen), findsOneWidget);
    expect(
      find.byKey(const ValueKey('credit-sea-splash-artwork')),
      findsOneWidget,
    );

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, SplashScreen.backgroundColor);
  });

  testWidgets('switches between registration and sign in', (tester) async {
    await tester.pumpWidget(const GetMaterialApp(home: AuthScreen()));

    expect(find.text('Welcome to Credit Sea!'), findsOneWidget);
    expect(find.byType(PageView), findsOneWidget);

    final signInLink = find.text('Existing User? Sign in');
    await tester.ensureVisible(signInLink);
    await tester.tap(signInLink);
    await tester.pumpAndSettle();

    expect(find.text('Please enter your credentials'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });

  testWidgets('loads the personal details form after the skeleton', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: DetailsFlowScreen()));

    expect(find.text('Personal Details'), findsNothing);
    await tester.pump(const Duration(milliseconds: 950));
    await tester.pumpAndSettle();

    expect(find.text('Personal Details'), findsOneWidget);
    expect(find.text('First Name*'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);

    await tester.tap(find.text('DD - MM - YYYY').first);
    await tester.pumpAndSettle();
    expect(find.text('Clear'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('OK'), findsOneWidget);
  });

  testWidgets('renders the standalone loan calculator', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: LoanCalculatorScreen(onApply: _noop)),
    );

    expect(find.text('Apply for loan'), findsOneWidget);
    expect(find.text('Purpose of Loan*'), findsOneWidget);
    expect(find.byType(Slider), findsNWidgets(2));
  });
}

void _noop() {}
