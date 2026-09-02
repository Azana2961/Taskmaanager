import 'package:flutter/material.dart';

class TaskBoard extends StatelessWidget {
  const TaskBoard({super.key});

  @override
  Widget build(BuildContext context) {
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
                3, 
                Colors.grey, 
                [
                  _buildTaskCard('Strategy', 'Research competitor analysis', 'Tomorrow', Colors.purple[50]!, Colors.purple, ['https://i.pravatar.cc/150?img=1']),
                  _buildTaskCard('Docs', 'Update client documentation', 'Dec 15', Colors.blue[50]!, Colors.blue, ['https://i.pravatar.cc/150?img=2']),
                  _buildTaskCard('Bug', 'Fix navigation bug on mobile', 'Dec 18', Colors.orange[50]!, Colors.orange, ['https://i.pravatar.cc/150?img=3']),
                ],
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: _buildColumn(
                'In Progress', 
                2, 
                const Color(0xFF2563EB), 
                [
                  _buildTaskCard('Design', 'Design new landing page hero', 'Today', Colors.blue[50]!, Colors.blue, ['https://i.pravatar.cc/150?img=4', 'https://i.pravatar.cc/150?img=5']),
                  _buildTaskCard('Dev', 'Implement authentication flow', 'Today', Colors.green[50]!, Colors.green, ['https://i.pravatar.cc/150?img=6']),
                ],
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: _buildColumn(
                'Done', 
                2, 
                Colors.green, 
                [
                  _buildTaskCard('Meeting', 'Weekly team sync meeting', 'Yesterday', Colors.blue[50]!, Colors.blue, ['https://i.pravatar.cc/150?img=7']),
                  _buildTaskCard('Marketing', 'Q4 Marketing Plan Review', 'Dec 10', Colors.purple[50]!, Colors.purple, ['https://i.pravatar.cc/150?img=8', 'https://i.pravatar.cc/150?img=9']),
                ],
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
