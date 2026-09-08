import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/app_state.dart';
import 'dart:math';

class RightPanel extends StatelessWidget {
  final String? selectedProjectId;
  const RightPanel({super.key, this.selectedProjectId});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final tasks = appState.tasksForProject(selectedProjectId);
    
    // Calculate team workload
    final Map<String, int> workload = {};
    for (var task in tasks) {
      if (task.assigneeId != null) {
        workload[task.assigneeId!] = (workload[task.assigneeId!] ?? 0) + 1;
      }
    }
    
    final maxTasks = workload.isEmpty ? 1 : workload.values.reduce(max);
    
    // Build bars
    final members = appState.membersForProject(selectedProjectId);
    final bars = members.take(4).map((member) {
      final count = workload[member.id] ?? 0;
      final height = (count / maxTasks) * 120.0;
      return _buildBar(member.name.split(' ').first, height == 0 ? 4.0 : height, member.color);
    }).toList();

    if (bars.isEmpty) {
      bars.add(_buildBar('No team', 4.0, Colors.grey[300]!));
    }

    // Recent activity (using recently added tasks)
    final recentTasks = tasks.reversed.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Team Workload
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Team Workload',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            Text(
              'View All',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFF1F5F9)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: bars,
          ),
        ),
        
        const SizedBox(height: 32),
        
        // Activity Feed
        const Text(
          '• Activity Feed',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
        ),
        const SizedBox(height: 16),
        if (recentTasks.isEmpty)
          const Text('No recent activity', style: TextStyle(color: Colors.grey)),
        ...recentTasks.map((t) {
          final user = appState.userById(t.assigneeId);
          return _buildActivityItem(
            user?.name ?? 'System',
            'created task "${t.title}"',
            'recently',
            user?.avatarUrl ?? 'https://i.pravatar.cc/150?u=${t.id}',
            user?.color ?? Colors.blue,
          );
        }),
      ],
    );
  }

  Widget _buildBar(String name, double height, Color color) {
    return Column(
      children: [
        Container(
          width: 24,
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          name,
          style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildActivityItem(String name, String action, String time, String avatarUrl, Color avatarColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: avatarColor.withOpacity(0.2),
            child: avatarUrl.startsWith('http')
                ? ClipOval(child: Image.network(avatarUrl, width: 32, height: 32, fit: BoxFit.cover, errorBuilder: (_,__,___) => Icon(Icons.person, color: avatarColor, size: 20)))
                : Icon(Icons.person, color: avatarColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B)),
                    children: [
                      TextSpan(text: '$name ', style: const TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(text: action),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
