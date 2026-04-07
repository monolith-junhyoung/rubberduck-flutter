import 'package:flutter/material.dart';

import '../features/controller/presentation/controller_home_page.dart';

class RubberDuckApp extends StatelessWidget {
  const RubberDuckApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '청소난투 콘솔',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4A90E2),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F8FC),
        useMaterial3: true,
      ),
      home: const ControllerHomePage(),
    );
  }
}
