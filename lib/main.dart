import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'pages/auth_page.dart';
import 'pages/main_screen.dart';
import 'services/chat_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EcoTechBin',
      theme: ThemeData.light(),
      home: const AuthRedirector(),
    );
  }
}

class AuthRedirector extends StatelessWidget {
  const AuthRedirector({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    if (authService.isSignedIn) {
      return const MainScreen();
    } else {
      return const AuthPage();
    }
  }
}