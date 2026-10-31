import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/bootstrap/app_services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeAppServices();
  runApp(const CreditSeaApp());
}
