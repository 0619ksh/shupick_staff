import 'package:flutter/material.dart';
import 'package:shupick_staff/dashboard/dashboard_page.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SOLE OPS | 직원 태블릿',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFEDF2F8),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1768E9),
          surface: Colors.white,
        ),
      ),
      home: const DashboardPage(),
    );
  }
}
