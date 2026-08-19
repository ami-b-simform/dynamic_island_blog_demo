import 'package:flutter/material.dart';
import 'home_screen.dart';

void main() {
  runApp(const DynamicIslandApp());
}

class DynamicIslandApp extends StatelessWidget {
  const DynamicIslandApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dynamic Island Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C47FF),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}