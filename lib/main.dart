import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/time_tracking_provider.dart';
import 'theme/bundesbank_theme.dart';
import 'screens/main_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => TimeTrackingProvider()..initialize(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gleitzeitrechner',
      theme: BundesbankTheme.lightTheme,
      home: const MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

