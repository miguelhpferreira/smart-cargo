import 'package:flutter/material.dart';

class SmartCargoApp extends StatelessWidget {
  final Widget home;

  const SmartCargoApp({super.key, required this.home});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Cargo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.deepPurple, useMaterial3: true),
      home: home,
    );
  }
}
