import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/data/dummy_data.dart';
import 'features/dashboard/presentation/dashboard_screen.dart';
import 'features/my_tasks/presentation/my_tasks_screen.dart';
import 'features/team/presentation/team_screen.dart';

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
  late String _selectedProjectId;

  @override
  void initState() {
    super.initState();
    _selectedProjectId =
        DummyData.projects.isNotEmpty ? DummyData.projects.first.id : 'p1';
  }

  Widget _buildPage() {
    switch (_activeItem) {
      case 'My Tasks':
        return MyTasksScreen(
          activeItem: _activeItem,
          selectedProjectId: _selectedProjectId,
          onNavTap: _onNavTap,
          onProjectTap: _onProjectTap,
        );
      case 'Team':
        return TeamScreen(
          activeItem: _activeItem,
          selectedProjectId: _selectedProjectId,
          onNavTap: _onNavTap,
          onProjectTap: _onProjectTap,
        );
      default:
        return DashboardScreen(
          activeItem: _activeItem,
          selectedProjectId: _selectedProjectId,
          onNavTap: _onNavTap,
          onProjectTap: _onProjectTap,
        );
    }
  }

  void _onNavTap(String item) {
    setState(() => _activeItem = item);
  }

  void _onProjectTap(String? projectId) {
    if (projectId != null) {
      setState(() => _selectedProjectId = projectId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildPage();
  }
}
