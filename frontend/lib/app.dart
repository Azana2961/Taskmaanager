import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'features/dashboard/presentation/dashboard_screen.dart';
import 'features/my_tasks/presentation/my_tasks_screen.dart';

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
      home: const _AppShell(),
    );
  }
}

class _AppShell extends StatefulWidget {
  const _AppShell();

  @override
  State<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<_AppShell> {
  String _activeItem = 'Dashboard';

  Widget _buildPage() {
    switch (_activeItem) {
      case 'My Tasks':
        return MyTasksScreen(
          activeItem: _activeItem,
          onNavTap: _onNavTap,
        );
      default:
        return DashboardScreen(
          activeItem: _activeItem,
          onNavTap: _onNavTap,
        );
    }
  }

  void _onNavTap(String item) {
    setState(() => _activeItem = item);
  }

  @override
  Widget build(BuildContext context) {
    return _buildPage();
  }
}
