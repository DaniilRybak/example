import 'package:flutter/material.dart';
import 'pages/main_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EcoTechBin',
      theme: ThemeData.light(), // Светлая тема по умолчанию
      darkTheme: ThemeData.dark(), // Темная тема
      home: const MainScreen(),
    );
  }
}