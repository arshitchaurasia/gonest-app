import 'package:digia_ui/digia_ui.dart';
import 'package:flutter/material.dart';
import 'package:gonest/home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Initialize Digia
  final digiaUI = await DigiaUI.initialize(
    DigiaUIOptions(
      accessKey: '6986df360753c105e4e199f6',
      flavor: Flavor.debug(),
    ),
  );

  // ✅ Run app
  runApp(
    DigiaUIApp(
      digiaUI: digiaUI,
      builder: (context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Home(),
      ),
    ),
  );
}