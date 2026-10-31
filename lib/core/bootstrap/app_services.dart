import 'package:get/get.dart';

import '../session/session_service.dart';

Future<void> initializeAppServices() async {
  if (!Get.isRegistered<SessionService>()) {
    await Get.putAsync(() => SessionService().init(), permanent: true);
  }
}
