import 'package:flutter/material.dart';
import '../../../core/widgets/sidebar.dart';
import '../../../core/widgets/header.dart';
import 'widgets/stats_row.dart';
import 'widgets/task_board.dart';
import 'widgets/right_panel.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    this.activeItem = 'Dashboard',
    this.onNavTap,
  });

  final String activeItem;
  final void Function(String item)? onNavTap;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Row(
        children: [
          // Left Sidebar
          Sidebar(activeItem: activeItem, onNavTap: onNavTap),
          
          // Main Content Area
          Expanded(
            child: Column(
              children: [
                // Top Navigation/Search Bar
                const Header(),
                
                // Scrollable Body
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Stats Row (Total Tasks, In Progress, etc.)
                        const StatsRow(),
                        const SizedBox(height: 32),
                        
                        // Board & Workload section
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Kanban Board takes up more space
                            const Expanded(
                              flex: 3,
                              child: TaskBoard(),
                            ),
                            const SizedBox(width: 24),
                            // Right Insights Panel
                            Expanded(
                              flex: 1,
                              child: const RightPanel(),
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
