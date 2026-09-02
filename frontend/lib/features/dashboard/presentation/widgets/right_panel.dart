import 'package:flutter/material.dart';

class RightPanel extends StatelessWidget {
  const RightPanel({super.key});

  @override
  Widget build(BuildContext context) {
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
            children: [
              _buildBar('Sarah', 60, Colors.grey[300]!),
              _buildBar('Mike', 120, const Color(0xFF2563EB)),
              _buildBar('Elena', 50, Colors.grey[300]!),
              _buildBar('Alex', 80, Colors.grey[300]!),
            ],
          ),
        ),
        
        const SizedBox(height: 32),
        
        // Activity Feed
        const Text(
          '• Activity Feed',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
        ),
        const SizedBox(height: 16),
        _buildActivityItem('Elena K.', 'completed Q4 Marketing Plan', '2 hours ago', 'https://i.pravatar.cc/150?img=10'),
        _buildActivityItem('Mike R.', 'moved Auth Flow to In Progress', '4 hours ago', 'https://i.pravatar.cc/150?img=11'),
        _buildActivityItem('Sarah J.', 'commented on Landing Page Design', '5 hours ago', 'https://i.pravatar.cc/150?img=12'),
        _buildActivityItem('Alex T.', 'added tag Mobile Bug', 'Yesterday', 'https://i.pravatar.cc/150?img=13'),
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

  Widget _buildActivityItem(String name, String action, String time, String avatarUrl) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundImage: NetworkImage(avatarUrl),
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
