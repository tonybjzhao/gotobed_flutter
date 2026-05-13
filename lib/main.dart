import 'package:flutter/material.dart';

import 'app.dart';
import 'services/notification_service.dart';
import 'services/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.instance.initialize();
  await NotificationService.instance.initialize();
  runApp(const SleepNudgerApp());
}
