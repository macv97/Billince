import 'package:flutter/material.dart';
import 'screens/welcome_screen.dart';

void main() {
  runApp(const BillinceApp());
}

class BillinceApp extends StatelessWidget {
  const BillinceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Billince',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F172A), // Midnight Blue / Dark Slate
          primary: const Color(0xFF0F172A), // Dark Slate
          secondary: const Color(0xFF10B981), // Emerald Green
          tertiary: const Color(0xFFF59E0B), // Amber / Lynx Eye
          surface: Colors.grey.shade50,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto', // Modern, clean typography
      ),
      home: const WelcomeScreen(),
    );
  }
}
