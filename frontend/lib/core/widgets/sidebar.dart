import 'package:flutter/material.dart';
import '../data/dummy_data.dart';
import 'create_project_dialog.dart';

class Sidebar extends StatelessWidget {
  const Sidebar({
    super.key,
    this.activeItem = 'Dashboard',
    this.selectedProjectId,
    this.onNavTap,
    this.onProjectTap,
    this.onProjectAdded,
  });

  final String activeItem;
  final String? selectedProjectId;
  final void Function(String item)? onNavTap;
  final void Function(String? projectId)? onProjectTap;
  final void Function(Project project)? onProjectAdded;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      color: const Color(0xFF1E1F25), // Dark theme from mockup
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo Area
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'TaskSync',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Navigation Links
          _buildNavItem(Icons.dashboard_outlined, 'Dashboard'),
          _buildNavItem(Icons.check_circle_outline, 'My Tasks'),
          _buildNavItem(Icons.people_outline, 'Team'),
          _buildNavItem(Icons.settings_outlined, 'Settings'),

          const SizedBox(height: 32),

          // Projects Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'PROJECTS',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
                Tooltip(
                  message: 'Add Project',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: () async {
                      final newProject = await CreateProjectDialog.show(
                        context,
                        onProjectCreated: (proj) {
                          onProjectAdded?.call(proj);
                          onProjectTap?.call(proj.id);
                        },
                      );
                      if (newProject != null && onProjectTap != null) {
                        onProjectTap!(newProject.id);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(Icons.add, color: Colors.white70, size: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...DummyData.projects.map((p) => _buildProjectItem(p.color, p.name, p.id)),

          const Spacer(),

          // Bottom Storage/Plan info
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: 0.0),
                  Colors.white.withValues(alpha: 0.05),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pro Plan',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  '4/5 members used',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: 0.8,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String title) {
    final isActive = activeItem == title;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? Colors.white.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(icon, color: isActive ? Colors.white : Colors.white54, size: 20),
        title: Text(
          title,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white54,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            fontSize: 14,
          ),
        ),
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        onTap: onNavTap != null ? () => onNavTap!(title) : null,
      ),
    );
  }

  Widget _buildProjectItem(Color color, String title, String? projectId) {
    final isActive = selectedProjectId == projectId;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: isActive ? Colors.white.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white54,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            fontSize: 14,
          ),
        ),
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        onTap: onProjectTap != null ? () => onProjectTap!(projectId) : null,
      ),
    );
  }
}
