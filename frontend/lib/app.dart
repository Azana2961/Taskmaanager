import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'core/services/app_state.dart';
import 'features/dashboard/presentation/dashboard_screen.dart';
import 'features/my_tasks/presentation/my_tasks_screen.dart';
import 'features/team/presentation/team_screen.dart';
import 'features/settings/presentation/settings_screen.dart';

class TaskSyncApp extends StatelessWidget {
  const TaskSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TaskSync',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
          surface: const Color(0xFFF8FAFC),
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
  String? _selectedProjectId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Set first project once data loads
    final appState = context.read<AppState>();
    if (_selectedProjectId == null && appState.projects.isNotEmpty) {
      _selectedProjectId = appState.projects.first.id;
    }
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
      case 'Settings':
        return SettingsScreen(
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

  void _onNavTap(String item) => setState(() => _activeItem = item);

  void _onProjectTap(String? projectId) {
    if (projectId != null) setState(() => _selectedProjectId = projectId);
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    // Auto-select first project when data arrives
    if (_selectedProjectId == null && appState.projects.isNotEmpty) {
      _selectedProjectId = appState.projects.first.id;
    }

    if (appState.loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Color(0xFF2563EB)),
              SizedBox(height: 16),
              Text(
                'Loading TaskSync...',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    if (appState.error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 48, color: Color(0xFFDC2626)),
              const SizedBox(height: 16),
              const Text(
                'Cannot connect to backend',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 8),
              Text(
                'Make sure the server is running on localhost:5000',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => context.read<AppState>().loadAll(),
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: const Text('Retry', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return _buildPage();
  }
}
