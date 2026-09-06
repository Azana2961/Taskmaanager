import 'package:flutter/material.dart';
import '../../../../core/data/dummy_data.dart';

class TaskBoard extends StatelessWidget {
  const TaskBoard({super.key, this.selectedProjectId});
  final String? selectedProjectId;

  @override
  Widget build(BuildContext context) {
    final tasks = DummyData.getTasksForProject(selectedProjectId);
    final todo = tasks.where((t) => t.status == TaskStatus.assigned).toList();
    final inProgress = tasks.where((t) => t.status == TaskStatus.inProgress).toList();
    final done = tasks.where((t) => t.status == TaskStatus.done).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Board Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Task Board',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 4),
                Text(
                  'Manage your team\'s tasks and workflow.',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.filter_list, size: 18),
                  label: const Text('Filter', style: TextStyle(color: Color(0xFF1E293B))),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add, size: 18, color: Colors.white),
                  label: const Text('New Task', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),
        
        // Kanban Columns
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildColumn(
                'To Do', 
                todo.length, 
                Colors.grey, 
                todo.map((t) => _buildTaskCard(t.tag, t.title, t.dueDate, t.tagColor.withValues(alpha: 0.1), t.tagColor, ['https://i.pravatar.cc/150?img=1'])).toList(),
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: _buildColumn(
                'In Progress', 
                inProgress.length, 
                const Color(0xFF2563EB), 
                inProgress.map((t) => _buildTaskCard(t.tag, t.title, t.dueDate, t.tagColor.withValues(alpha: 0.1), t.tagColor, ['https://i.pravatar.cc/150?img=4'])).toList(),
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: _buildColumn(
                'Done', 
                done.length, 
                Colors.green, 
                done.map((t) => _buildTaskCard(t.tag, t.title, t.dueDate, t.tagColor.withValues(alpha: 0.1), t.tagColor, ['https://i.pravatar.cc/150?img=7'])).toList(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildColumn(String title, int count, Color dotColor, List<Widget> tasks) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Text(
                        count.toString(),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                      ),
                    ),
                  ],
                ),
                const Icon(Icons.add, color: Color(0xFF94A3B8), size: 20),
              ],
            ),
          ),
          ...tasks,
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildTaskCard(String tag, String title, String date, Color tagBg, Color tagText, List<String> avatars) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: tagBg,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              tag,
              style: TextStyle(color: tagText, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 14, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 4),
                  Text(
                    date,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                  ),
                ],
              ),
              Row(
                children: avatars.map((url) => Padding(
                  padding: const EdgeInsets.only(left: 2.0),
                  child: CircleAvatar(
                    radius: 12,
                    backgroundImage: NetworkImage(url),
                  ),
                )).toList(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
