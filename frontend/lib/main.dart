import 'package:flutter/material.dart';
import 'screens/ai_analysis_screen.dart';

void main() {
  runApp(const DisasterGuardApp());
}

class DisasterGuardApp extends StatelessWidget {
  const DisasterGuardApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DisasterGuard AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF06B6D4),
        scaffoldBackgroundColor: const Color(0xFF070B14),
        brightness: Brightness.dark,
        fontFamily: 'SpaceGrotesk', // Make sure to add the font in real app if required
      ),
      home: const AIAnalysisScreen(),
    );
  }
}
