import 'package:digia_ui/digia_ui.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:gonest/core/analytics/app_analytics.dart';
import 'package:gonest/firebase_options.dart';
import 'package:gonest/home.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final digiaUI = await DigiaUI.initialize(
    DigiaUIOptions(
      accessKey: '6986df360753c105e4e199f6',
      flavor: Flavor.debug(),
    ),
  );

  runApp(
    DigiaUIApp(
      digiaUI: digiaUI,
      builder: (context) =>
          MaterialApp(debugShowCheckedModeBanner: false, home: Home()),
      analytics: MyAppAnalytics(),
    ),
  );
}
