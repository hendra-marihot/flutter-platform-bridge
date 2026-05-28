import 'package:flutter/material.dart';
import 'home_screen.dart';

class PlatformBridgeApp extends StatelessWidget {
  const PlatformBridgeApp({super.key});

  static const _seedColor = Color(0xFF6750A4);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Platform Bridge',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: _seedColor),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: _seedColor,
        brightness: Brightness.dark,
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
