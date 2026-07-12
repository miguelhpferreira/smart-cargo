import 'package:flutter/material.dart';

import 'app.dart';
import 'screens/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await LocationDatabase.instance.database;

  runApp(const SmartCargoApp(home: HomePage()));
}
