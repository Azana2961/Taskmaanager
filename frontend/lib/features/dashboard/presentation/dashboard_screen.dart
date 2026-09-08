import 'package:flutter/material.dart';
import '../../../core/widgets/sidebar.dart';
import '../../../core/widgets/header.dart';
import 'widgets/stats_row.dart';
import 'widgets/task_board.dart';
import 'widgets/right_panel.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    this.activeItem = 'Dashboard',
    this.selectedProjectId,
    this.onNavTap,
    this.onProjectTap,
  });

  final String activeItem;
  final String? selectedProjectId;
  final void Function(String item)? onNavTap;
  final void Function(String? projectId)? onProjectTap;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Row(
        children: [
          // Left Sidebar
          Sidebar(
            activeItem: widget.activeItem,
            selectedProjectId: widget.selectedProjectId,
            onNavTap: widget.onNavTap,
            onProjectTap: widget.onProjectTap,
            onProjectAdded: (project) {
              setState(() {});
            },
          ),

          // Main Content Area
          Expanded(
            child: Column(
              children: [
                // Top Navigation/Search Bar
                Header(selectedProjectId: widget.selectedProjectId),

                // Scrollable Body
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Stats Row (Total Tasks, In Progress, etc.)
                        StatsRow(selectedProjectId: widget.selectedProjectId),
                        const SizedBox(height: 32),

                        // Board & Workload section
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Kanban Board takes up more space
                            Expanded(
                              flex: 3,
                              child: TaskBoard(
                                selectedProjectId: widget.selectedProjectId,
                                onTaskAdded: () => setState(() {}),
                              ),
                            ),
                            const SizedBox(width: 24),
                            // Right Insights Panel
                            Expanded(
                              flex: 1,
                              child: RightPanel(selectedProjectId: widget.selectedProjectId),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
