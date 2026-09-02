import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'features/dashboard/presentation/dashboard_screen.dart';

class TaskSyncApp extends StatelessWidget {
  const TaskSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TaskSync',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB), // Sleek blue from mockup
          surface: const Color(0xFFF8FAFC), // Light gray background
        ),
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme),
        useMaterial3: true,
      ),
      home: const DashboardScreen(),
    );
  }
}
