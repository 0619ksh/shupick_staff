import 'package:flutter/material.dart';
import 'package:shupick_staff/dashboard/dashboard_page.dart';
import 'package:shupick_staff/view/login.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  StaffRole? selectedRole;
  String selectedBranch = '강남구';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SHOEPICK | 직원 태블릿',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFEDF2F8),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1768E9),
          surface: Colors.white,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
      home: selectedRole == null
          ? Login(
              onSelect: (role, branch) => setState(() {
                selectedRole = role;
                selectedBranch = branch;
              }),
            )
          : DashboardPage(
              initialRole: selectedRole!,
              branch: selectedBranch,
              onChangeRole: () => setState(() => selectedRole = null),
            ),
    );
  }
}
