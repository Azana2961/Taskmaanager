import 'package:flutter/material.dart';

class StatsRow extends StatelessWidget {
  const StatsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard('Total Tasks', '24', '+12% 4 completed today', Icons.check_circle_outline, Colors.green),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard('In Progress', '8', '0% 2 overdue', Icons.schedule, Colors.grey),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard('Team Load', '85%', '+5% Capacity reached', Icons.trending_up, Colors.green),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard('Urgent', '3', '-1 Needs attention', Icons.warning_amber_rounded, Colors.red),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, String subtitle, IconData icon, Color trendColor) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 14, fontWeight: FontWeight.w500),
              ),
              Icon(icon, color: const Color(0xFF94A3B8), size: 18),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(fontSize: 12, color: trendColor, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
