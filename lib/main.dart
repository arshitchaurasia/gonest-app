import 'package:digia_ui/digia_ui.dart';
import 'package:flutter/material.dart';
import 'package:gonest/home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final digiaUI = await DigiaUI.initialize(
    DigiaUIOptions(
      accessKey: '6986df360753c105e4e199f6',
      flavor: Flavor.debug(),
      // Use a Strategy of your choice.
      // NetworkFirstStrategy() or CacheFirstStrategy()
    ),
  );

  runApp(
    DigiaUIApp(
      digiaUI: digiaUI,
      builder: (context) => MaterialApp(
        home: Home(),
      ),
    ),
  );
}