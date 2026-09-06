import 'package:flutter/material.dart';
import '../../../core/widgets/sidebar.dart';
import '../../../core/widgets/header.dart';

enum TaskStatus { assigned, inProgress, done }

class _TeamTask {
  final String id;
  final String title;
  final String tag;
  final Color tagColor;
  final String priority;
  final String dueDate;
  TaskStatus status;
  _TeamTask({required this.id, required this.title, required this.tag, required this.tagColor, required this.priority, required this.dueDate, this.status = TaskStatus.assigned});
}

class _TeamMember {
  final String id;
  final String name;
  final String role;
  final String avatarUrl;
  final Color avatarColor;
  List<_TeamTask> tasks;
  _TeamMember({required this.id, required this.name, required this.role, required this.avatarUrl, required this.avatarColor, required this.tasks});
}

class _Project {
  final String id;
  final String name;
  final Color color;
  List<String> memberIds;
  _Project({required this.id, required this.name, required this.color, required this.memberIds});
}

class TeamScreen extends StatefulWidget {
  const TeamScreen({super.key, this.activeItem = 'Team', this.onNavTap});
  final String activeItem;
  final void Function(String item)? onNavTap;
  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  _TeamMember? _selectedMember;

  late final List<_TeamMember> _members = [
    _TeamMember(id: 'm1', name: 'Alex Johnson', role: 'Frontend Developer', avatarUrl: 'https://i.pravatar.cc/150?img=3', avatarColor: const Color(0xFF2563EB), tasks: [
      _TeamTask(id: 't1', title: 'Build dashboard components', tag: 'Dev', tagColor: Colors.blue, priority: 'High', dueDate: 'Sep 10', status: TaskStatus.inProgress),
      _TeamTask(id: 't2', title: 'Fix mobile responsive layout', tag: 'Bug', tagColor: Colors.orange, priority: 'Medium', dueDate: 'Sep 12', status: TaskStatus.assigned),
      _TeamTask(id: 't3', title: 'Implement dark mode toggle', tag: 'Design', tagColor: Colors.purple, priority: 'Low', dueDate: 'Sep 8', status: TaskStatus.done),
    ]),
    _TeamMember(id: 'm2', name: 'Sarah Miller', role: 'UX Designer', avatarUrl: 'https://i.pravatar.cc/150?img=5', avatarColor: const Color(0xFF7C3AED), tasks: [
      _TeamTask(id: 't4', title: 'Create onboarding wireframes', tag: 'Design', tagColor: Colors.purple, priority: 'High', dueDate: 'Sep 9', status: TaskStatus.inProgress),
      _TeamTask(id: 't5', title: 'Design new landing page hero', tag: 'Design', tagColor: Colors.purple, priority: 'Medium', dueDate: 'Sep 14', status: TaskStatus.assigned),
    ]),
    _TeamMember(id: 'm3', name: 'James Carter', role: 'Backend Developer', avatarUrl: 'https://i.pravatar.cc/150?img=12', avatarColor: const Color(0xFF059669), tasks: [
      _TeamTask(id: 't6', title: 'Set up CI/CD pipeline', tag: 'Dev', tagColor: Colors.blue, priority: 'High', dueDate: 'Sep 11', status: TaskStatus.done),
      _TeamTask(id: 't7', title: 'Write API documentation', tag: 'Docs', tagColor: Colors.teal, priority: 'Low', dueDate: 'Sep 18', status: TaskStatus.assigned),
      _TeamTask(id: 't8', title: 'Implement authentication flow', tag: 'Dev', tagColor: Colors.blue, priority: 'High', dueDate: 'Sep 7', status: TaskStatus.inProgress),
    ]),
    _TeamMember(id: 'm4', name: 'Priya Nair', role: 'QA Engineer', avatarUrl: 'https://i.pravatar.cc/150?img=16', avatarColor: const Color(0xFFDB2777), tasks: [
      _TeamTask(id: 't9', title: 'Write end-to-end test cases', tag: 'QA', tagColor: Colors.pink, priority: 'Medium', dueDate: 'Sep 13', status: TaskStatus.assigned),
    ]),
  ];

  late final List<_Project> _projects = [
    _Project(id: 'p1', name: 'Website Redesign', color: Colors.blue, memberIds: ['m1', 'm2']),
    _Project(id: 'p2', name: 'Q4 Marketing', color: Colors.purple, memberIds: ['m2', 'm4']),
    _Project(id: 'p3', name: 'Mobile App', color: Colors.green, memberIds: ['m1', 'm3', 'm4']),
  ];

  @override
  void initState() { super.initState(); _tabController = TabController(length: 2, vsync: this); }
  @override
  void dispose() { _tabController.dispose(); super.dispose(); }

  void _showSnackbar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor: color, behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: const EdgeInsets.all(16), duration: const Duration(seconds: 2),
    ));
  }

  void _showAssignTaskDialog(_TeamMember member) {
    showDialog(context: context, builder: (ctx) => _AssignTaskDialog(
      member: member, onAssign: (task) { setState(() => member.tasks.add(task)); _showSnackbar('Task assigned to ', const Color(0xFF2563EB)); },
    ));
  }

  void _showAddMemberToProjectDialog(_Project project) {
    final available = _members.where((m) => !project.memberIds.contains(m.id)).toList();
    if (available.isEmpty) { _showSnackbar('All members are already in this project', Colors.orange); return; }
    showDialog(context: context, builder: (ctx) => _AddMemberDialog(
      project: project, availableMembers: available, onAdd: (member) {
        setState(() => project.memberIds.add(member.id));
        _showSnackbar(' added to ', const Color(0xFF059669));
      },
    ));
  }

  void _kickMemberFromProject(_Project project, _TeamMember member) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Remove Member', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
      content: Text('Remove  from ?', style: TextStyle(color: Colors.grey[600])),
      actions: [
        TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text('Cancel', style: TextStyle(color: Colors.grey[600]))),
        ElevatedButton(
          onPressed: () { setState(() => project.memberIds.remove(member.id)); Navigator.of(ctx).pop(); _showSnackbar(' removed from ', Colors.red[600]!); },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red[600], elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          child: const Text('Remove', style: TextStyle(color: Colors.white)),
        ),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(children: [
        Sidebar(activeItem: widget.activeItem, onNavTap: widget.onNavTap),
        Expanded(child: Column(children: [
          const Header(),
          Expanded(child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              flex: _selectedMember != null ? 3 : 5,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _buildPageHeader(), const SizedBox(height: 24),
                  _buildSummaryChips(), const SizedBox(height: 28),
                  _buildTabBar(), const SizedBox(height: 20),
                  AnimatedBuilder(animation: _tabController, builder: (ctx, _) {
                    return _tabController.index == 0 ? _buildMembersTab() : _buildProjectsTab();
                  }),
                ]),
              ),
            ),
            if (_selectedMember != null)
              SizedBox(width: 360, child: _MemberTaskPanel(
                member: _selectedMember!, onClose: () => setState(() => _selectedMember = null),
                onAssignTask: () => _showAssignTaskDialog(_selectedMember!),
              )),
          ])),
        ])),
      ]),
    );
  }

  Widget _buildPageHeader() {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Team', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        const SizedBox(height: 4),
        Text('Manage your team members, projects and tasks.', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
      ]),
      ElevatedButton.icon(
        onPressed: () => _showSnackbar('Invite Member coming soon!', const Color(0xFF2563EB)),
        icon: const Icon(Icons.person_add_outlined, size: 18, color: Colors.white),
        label: const Text('Invite Member', style: TextStyle(color: Colors.white)),
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
      ),
    ]);
  }

  Widget _buildChip(IconData icon, String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 15, color: fg), const SizedBox(width: 6),
        Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 13)),
      ]),
    );
  }

  Widget _buildSummaryChips() {
    return Wrap(spacing: 12, runSpacing: 8, children: [
      _buildChip(Icons.people_outline, '${_members.length} Members', const Color(0xFFEFF6FF), const Color(0xFF2563EB)),
      _buildChip(Icons.folder_outlined, '${_projects.length} Projects', const Color(0xFFF5F3FF), const Color(0xFF7C3AED)),
      _buildChip(Icons.task_alt_outlined, '${_members.fold(0, (s, m) => s + m.tasks.length)} Total Tasks', const Color(0xFFF0FDF4), const Color(0xFF059669)),
      _buildChip(Icons.bolt_rounded, '${_members.fold(0, (s, m) => s + m.tasks.where((t) => t.status == TaskStatus.inProgress).length)} In Progress', const Color(0xFFFFF7ED), const Color(0xFFEA580C)),
      _buildChip(Icons.check_circle_outline, '${_members.fold(0, (s, m) => s + m.tasks.where((t) => t.status == TaskStatus.done).length)} Done', const Color(0xFFF0FDF4), const Color(0xFF16A34A)),
    ]);
  }

  Widget _buildTab(int index, IconData icon, String label) {
    final isActive = _tabController.index == index;
    return GestureDetector(
      onTap: () => setState(() => _tabController.index = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF2563EB) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isActive ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0)),
          boxShadow: isActive ? [BoxShadow(color: const Color(0xFF2563EB).withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 3))] : [],
        ),
        child: Row(children: [
          Icon(icon, size: 16, color: isActive ? Colors.white : const Color(0xFF64748B)),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: isActive ? Colors.white : const Color(0xFF64748B), fontWeight: FontWeight.w600, fontSize: 14)),
        ]),
      ),
    );
  }

  Widget _buildTabBar() {
    return AnimatedBuilder(animation: _tabController, builder: (ctx, _) {
      return Row(children: [_buildTab(0, Icons.people_outline, 'Members'), const SizedBox(width: 8), _buildTab(1, Icons.folder_outlined, 'Projects')]);
    });
  }

  Widget _buildMembersTab() {
    return Column(children: _members.map((m) => _MemberCard(
      member: m, isSelected: _selectedMember?.id == m.id,
      onViewTasks: () => setState(() => _selectedMember = m),
      onAssignTask: () => _showAssignTaskDialog(m),
    )).toList());
  }

  Widget _buildProjectsTab() {
    return Column(children: _projects.map((p) {
      final pm = _members.where((m) => p.memberIds.contains(m.id)).toList();
      return _ProjectCard(project: p, members: pm,
        onAddMember: () => _showAddMemberToProjectDialog(p),
        onKickMember: (m) => _kickMemberFromProject(p, m),
        onAssignTask: (m) => _showAssignTaskDialog(m));
    }).toList());
  }
}

// ---------------------------------------------------------------------------
// Member Card
// ---------------------------------------------------------------------------
class _MemberCard extends StatelessWidget {
  const _MemberCard({required this.member, required this.isSelected, required this.onViewTasks, required this.onAssignTask});
  final _TeamMember member;
  final bool isSelected;
  final VoidCallback onViewTasks, onAssignTask;

  Widget _badge(String label, int count, Color bg, Color fg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
    child: Column(children: [
      Text(count.toString(), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: fg)),
      Text(label, style: TextStyle(fontSize: 10, color: fg, fontWeight: FontWeight.w500)),
    ]),
  );

  @override
  Widget build(BuildContext context) {
    final a = member.tasks.where((t) => t.status == TaskStatus.assigned).length;
    final ip = member.tasks.where((t) => t.status == TaskStatus.inProgress).length;
    final d = member.tasks.where((t) => t.status == TaskStatus.done).length;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0), width: isSelected ? 2 : 1),
        boxShadow: [BoxShadow(color: isSelected ? const Color(0xFF2563EB).withOpacity(0.08) : Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Row(children: [
        Stack(children: [
          CircleAvatar(radius: 26, backgroundColor: member.avatarColor.withOpacity(0.15), backgroundImage: NetworkImage(member.avatarUrl)),
          Positioned(bottom: 0, right: 0, child: Container(width: 12, height: 12, decoration: BoxDecoration(color: const Color(0xFF22C55E), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)))),
        ]),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(member.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B))),
          const SizedBox(height: 3),
          Text(member.role, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
        ])),
        _badge('Assigned', a, const Color(0xFFFFF7ED), const Color(0xFFEA580C)),
        const SizedBox(width: 8),
        _badge('In Progress', ip, const Color(0xFFEFF6FF), const Color(0xFF2563EB)),
        const SizedBox(width: 8),
        _badge('Done', d, const Color(0xFFF0FDF4), const Color(0xFF16A34A)),
        const SizedBox(width: 20),
        OutlinedButton.icon(
          onPressed: onViewTasks,
          icon: const Icon(Icons.visibility_outlined, size: 15),
          label: const Text('View Tasks', style: TextStyle(fontSize: 13)),
          style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF2563EB), side: const BorderSide(color: Color(0xFF2563EB)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: onAssignTask,
          icon: const Icon(Icons.assignment_outlined, size: 15, color: Colors.white),
          label: const Text('Assign Task', style: TextStyle(color: Colors.white, fontSize: 13)),
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
        ),
      ]),
    );
  }
}

// ---------------------------------------------------------------------------
// Member Task Side Panel
// ---------------------------------------------------------------------------
class _MemberTaskPanel extends StatelessWidget {
  const _MemberTaskPanel({required this.member, required this.onClose, required this.onAssignTask});
  final _TeamMember member;
  final VoidCallback onClose, onAssignTask;

  Widget _section(String title, List<_TeamTask> tasks, Color accent, Color bg) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(color: accent, shape: BoxShape.circle)),
      const SizedBox(width: 8),
      Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: accent)),
      const SizedBox(width: 6),
      Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2), decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
        child: Text(tasks.length.toString(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: accent))),
    ]),
    const SizedBox(height: 8),
    ...tasks.map((t) => _PanelTaskCard(task: t)),
  ]);

  @override
  Widget build(BuildContext context) {
    final assigned = member.tasks.where((t) => t.status == TaskStatus.assigned).toList();
    final inp = member.tasks.where((t) => t.status == TaskStatus.inProgress).toList();
    final done = member.tasks.where((t) => t.status == TaskStatus.done).toList();
    return Container(
      decoration: const BoxDecoration(color: Colors.white, border: Border(left: BorderSide(color: Color(0xFFE2E8F0)))),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0)))),
          child: Row(children: [
            CircleAvatar(radius: 22, backgroundImage: NetworkImage(member.avatarUrl)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(member.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B))),
              Text(member.role, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            ])),
            IconButton(onPressed: onClose, icon: const Icon(Icons.close, color: Color(0xFF64748B), size: 20)),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: SizedBox(width: double.infinity, child: ElevatedButton.icon(
            onPressed: onAssignTask,
            icon: const Icon(Icons.add_task, size: 16, color: Colors.white),
            label: const Text('Assign New Task', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), elevation: 0, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          )),
        ),
        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (inp.isNotEmpty) ...[_section('In Progress', inp, const Color(0xFF2563EB), const Color(0xFFEFF6FF)), const SizedBox(height: 16)],
            if (assigned.isNotEmpty) ...[_section('Assigned', assigned, const Color(0xFFEA580C), const Color(0xFFFFF7ED)), const SizedBox(height: 16)],
            if (done.isNotEmpty) _section('Done', done, const Color(0xFF16A34A), const Color(0xFFF0FDF4)),
            if (member.tasks.isEmpty) Center(child: Padding(padding: const EdgeInsets.all(32), child: Text('No tasks assigned yet.', style: TextStyle(color: Colors.grey[400], fontSize: 14)))),
          ]),
        )),
      ]),
    );
  }
}

class _PanelTaskCard extends StatelessWidget {
  const _PanelTaskCard({required this.task});
  final _TeamTask task;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3), decoration: BoxDecoration(color: task.tagColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
          child: Text(task.tag, style: TextStyle(color: task.tagColor, fontSize: 11, fontWeight: FontWeight.w600))),
        const Spacer(),
        _MiniPriorityBadge(priority: task.priority),
      ]),
      const SizedBox(height: 8),
      Text(task.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
      const SizedBox(height: 6),
      Row(children: [
        const Icon(Icons.calendar_today, size: 11, color: Color(0xFF94A3B8)), const SizedBox(width: 4),
        Text('Due: ', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
      ]),
    ]),
  );
}

// ---------------------------------------------------------------------------
// Project Card
// ---------------------------------------------------------------------------
class _ProjectCard extends StatelessWidget {
  const _ProjectCard({required this.project, required this.members, required this.onAddMember, required this.onKickMember, required this.onAssignTask});
  final _Project project;
  final List<_TeamMember> members;
  final VoidCallback onAddMember;
  final void Function(_TeamMember) onKickMember, onAssignTask;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 20),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0)),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 3))]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: project.color.withOpacity(0.05), borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          border: Border(bottom: BorderSide(color: project.color.withOpacity(0.2)), left: BorderSide(color: project.color, width: 4)),
        ),
        child: Row(children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: project.color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
            child: Icon(Icons.folder_outlined, color: project.color, size: 20)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(project.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B))),
            Text(' members', style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
          ])),
          ElevatedButton.icon(
            onPressed: onAddMember,
            icon: const Icon(Icons.person_add_outlined, size: 15, color: Colors.white),
            label: const Text('Add Member', style: TextStyle(color: Colors.white, fontSize: 13)),
            style: ElevatedButton.styleFrom(backgroundColor: project.color, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
          ),
        ]),
      ),
      if (members.isEmpty)
        const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('No members in this project yet.', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14))))
      else
        Padding(padding: const EdgeInsets.all(16), child: Column(children: members.map((m) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
          child: Row(children: [
            CircleAvatar(radius: 18, backgroundImage: NetworkImage(m.avatarUrl), backgroundColor: m.avatarColor.withOpacity(0.15)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(m.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF1E293B))),
              Text(m.role, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            ])),
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(12)),
              child: Text(' tasks', style: const TextStyle(fontSize: 12, color: Color(0xFF2563EB), fontWeight: FontWeight.w600))),
            const SizedBox(width: 10),
            OutlinedButton.icon(
              onPressed: () => onAssignTask(m),
              icon: const Icon(Icons.assignment_outlined, size: 14),
              label: const Text('Assign Task', style: TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF2563EB), side: const BorderSide(color: Color(0xFF2563EB)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: () => onKickMember(m),
              icon: const Icon(Icons.person_remove_outlined, size: 14),
              label: const Text('Remove', style: TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.red[600], side: BorderSide(color: Colors.red[300]!), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
            ),
          ]),
        )).toList())),
    ]),
  );
}

// ---------------------------------------------------------------------------
// Assign Task Dialog
// ---------------------------------------------------------------------------
class _AssignTaskDialog extends StatefulWidget {
  const _AssignTaskDialog({required this.member, required this.onAssign});
  final _TeamMember member;
  final void Function(_TeamTask) onAssign;
  @override
  State<_AssignTaskDialog> createState() => _AssignTaskDialogState();
}
class _AssignTaskDialogState extends State<_AssignTaskDialog> {
  final _tc = TextEditingController();
  String _tag = 'Dev'; Color _tagColor = Colors.blue;
  String _priority = 'Medium'; String _dueDate = 'Sep 20';
  final _tags = [{'label': 'Dev', 'color': Colors.blue}, {'label': 'Design', 'color': Colors.purple}, {'label': 'Bug', 'color': Colors.orange}, {'label': 'Docs', 'color': Colors.teal}, {'label': 'QA', 'color': Colors.pink}, {'label': 'Marketing', 'color': Colors.indigo}];
  final _priorities = ['High', 'Medium', 'Low'];
  final _dueDates = ['Today', 'Sep 10', 'Sep 12', 'Sep 15', 'Sep 18', 'Sep 20', 'Sep 25'];

  InputDecoration _dec([String? hint]) => InputDecoration(
    hintText: hint, hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    filled: true, fillColor: const Color(0xFFF8FAFC),
  );

  @override
  Widget build(BuildContext context) => Dialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    child: Container(width: 480, padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.assignment_outlined, color: Color(0xFF2563EB), size: 20)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Assign Task', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1E293B))),
          Text('To ', style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
        ])),
        IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close, color: Color(0xFF64748B))),
      ]),
      const SizedBox(height: 24), const Divider(color: Color(0xFFE2E8F0)), const SizedBox(height: 20),
      const Text('Task Title', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF374151))),
      const SizedBox(height: 8),
      TextField(controller: _tc, decoration: _dec('Enter task title...')),
      const SizedBox(height: 18),
      const Text('Tag', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF374151))),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 8, children: _tags.map((t) {
        final sel = _tag == t['label'];
        return GestureDetector(
          onTap: () => setState(() { _tag = t['label'] as String; _tagColor = t['color'] as Color; }),
          child: AnimatedContainer(duration: const Duration(milliseconds: 150), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: sel ? (t['color'] as Color).withOpacity(0.15) : const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8), border: Border.all(color: sel ? t['color'] as Color : const Color(0xFFE2E8F0), width: sel ? 2 : 1)),
            child: Text(t['label'] as String, style: TextStyle(color: sel ? t['color'] as Color : const Color(0xFF64748B), fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        );
      }).toList()),
      const SizedBox(height: 18),
      Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Priority', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF374151))), const SizedBox(height: 8),
          DropdownButtonFormField<String>(initialValue: _priority, decoration: _dec(), items: _priorities.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(), onChanged: (v) => setState(() => _priority = v!)),
        ])),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Due Date', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF374151))), const SizedBox(height: 8),
          DropdownButtonFormField<String>(initialValue: _dueDate, decoration: _dec(), items: _dueDates.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(), onChanged: (v) => setState(() => _dueDate = v!)),
        ])),
      ]),
      const SizedBox(height: 28),
      Row(children: [
        Expanded(child: OutlinedButton(onPressed: () => Navigator.of(context).pop(), style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFFE2E8F0)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(vertical: 14)),
          child: Text('Cancel', style: TextStyle(color: Colors.grey[600])))),
        const SizedBox(width: 12),
        Expanded(flex: 2, child: ElevatedButton.icon(
          onPressed: () {
            if (_tc.text.trim().isEmpty) return;
            final t = _TeamTask(id: DateTime.now().millisecondsSinceEpoch.toString(), title: _tc.text.trim(), tag: _tag, tagColor: _tagColor, priority: _priority, dueDate: _dueDate, status: TaskStatus.assigned);
            Navigator.of(context).pop(); widget.onAssign(t);
          },
          icon: const Icon(Icons.check_rounded, size: 18, color: Colors.white),
          label: const Text('Assign Task', style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), elevation: 0, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
        )),
      ]),
    ])),
  );
}

// ---------------------------------------------------------------------------
// Add Member to Project Dialog
// ---------------------------------------------------------------------------
class _AddMemberDialog extends StatelessWidget {
  const _AddMemberDialog({required this.project, required this.availableMembers, required this.onAdd});
  final _Project project;
  final List<_TeamMember> availableMembers;
  final void Function(_TeamMember) onAdd;

  @override
  Widget build(BuildContext context) => Dialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    child: Container(width: 400, padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: project.color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)), child: Icon(Icons.person_add_outlined, color: project.color, size: 20)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Add Member', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1E293B))),
          Text('To ', style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
        ])),
        IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close, color: Color(0xFF64748B))),
      ]),
      const SizedBox(height: 20), const Divider(color: Color(0xFFE2E8F0)), const SizedBox(height: 16),
      ...availableMembers.map((m) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        child: Material(color: Colors.transparent, child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () { Navigator.of(context).pop(); onAdd(m); },
          child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0)), color: const Color(0xFFF8FAFC)),
            child: Row(children: [
              CircleAvatar(radius: 18, backgroundImage: NetworkImage(m.avatarUrl), backgroundColor: m.avatarColor.withOpacity(0.15)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(m.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF1E293B))),
                Text(m.role, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              ])),
              Icon(Icons.add_circle_outline, color: project.color, size: 22),
            ]),
          ),
        )),
      )),
    ])),
  );
}

// ---------------------------------------------------------------------------
// Mini Priority Badge
// ---------------------------------------------------------------------------
class _MiniPriorityBadge extends StatelessWidget {
  const _MiniPriorityBadge({required this.priority});
  final String priority;
  @override
  Widget build(BuildContext context) {
    Color bg, fg;
    switch (priority) {
      case 'High': bg = const Color(0xFFFEF2F2); fg = const Color(0xFFDC2626); break;
      case 'Medium': bg = const Color(0xFFFFFBEB); fg = const Color(0xFFD97706); break;
      default: bg = const Color(0xFFF0FDF4); fg = const Color(0xFF16A34A);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(priority, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: fg)),
    );
  }
}
