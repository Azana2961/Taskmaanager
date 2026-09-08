import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/app_state.dart';
import '../../../core/services/api_service.dart';
import '../../../core/widgets/sidebar.dart';
import '../../../core/widgets/header.dart';



class TeamScreen extends StatefulWidget {
  const TeamScreen({
    super.key,
    this.activeItem = 'Team',
    this.selectedProjectId,
    this.onNavTap,
    this.onProjectTap,
  });

  final String activeItem;
  final String? selectedProjectId;
  final void Function(String item)? onNavTap;
  final void Function(String? projectId)? onProjectTap;

  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> {
  ApiUser? _selectedMember;

  ApiProject? _currentProject(AppState appState) {
    if (widget.selectedProjectId == null) return null;
    try {
      return appState.projects.firstWhere(
        (p) => p.id == widget.selectedProjectId,
      );
    } catch (_) {
      return null;
    }
  }

  List<ApiUser> _displayedMembers(AppState appState) {
    if (widget.selectedProjectId == null) {
      return appState.users;
    }
    final proj = _currentProject(appState);
    if (proj == null) return [];
    return proj.members;
  }

  void _showSnackbar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
    ));
  }

  void _showAssignTaskDialog(ApiUser member, AppState appState) {
    final effectiveProjectId = widget.selectedProjectId ??
        (appState.projects.isNotEmpty ? appState.projects.first.id : 'p1');
    showDialog(
      context: context,
      builder: (ctx) {
        final unassigned = appState.tasksForProject(effectiveProjectId)
            .where((t) => t.assigneeId == null).toList();
        return _AssignTaskToMemberDialog(
          member: member,
          projectId: effectiveProjectId,
          unassignedTasks: unassigned,
          onAssigned: (msg) {
            // It will update via Provider
            _showSnackbar(msg, const Color(0xFF2563EB));
          },
        );
      },
    );
  }

  void _showAddMemberToProjectDialog(ApiProject project, AppState appState) {
    final existingIds = project.members.map((m) => m.id).toSet();
    final available = appState.users
        .where((m) => !existingIds.contains(m.id))
        .toList();
    if (available.isEmpty) {
      _showSnackbar(
        'All team members are already assigned to this project',
        Colors.orange,
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => _AddMemberDialog(
        project: project,
        availableMembers: available,
        onAdd: (member) async {
          await context.read<AppState>().addMemberToProject(project.id, member.id);
          if (mounted) {
            _showSnackbar(
              '${member.name} added to ${project.name}',
              const Color(0xFF059669),
            );
          }
        },
        onInvite: (email) async {
          try {
            await context.read<AppState>().inviteUserByEmail(project.id, email);
            if (mounted) {
              _showSnackbar('Invitation sent to $email', const Color(0xFF059669));
            }
          } catch (e) {
            if (mounted) {
              _showSnackbar('Failed to invite user: $e', Colors.red[600]!);
            }
          }
        },
      ),
    );
  }

  void _removeMemberFromProject(ApiProject project, ApiUser member) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Remove Member',
          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
        ),
        content: Text(
          'Remove ${member.name} from ${project.name}?',
          style: TextStyle(color: Colors.grey[600]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await context.read<AppState>().removeMemberFromProject(project.id, member.id);
              if (mounted) {
                if (_selectedMember?.id == member.id) {
                  setState(() => _selectedMember = null);
                }
                _showSnackbar(
                  '${member.name} removed from ${project.name}',
                  Colors.red[600]!,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _transferManagerRole(ApiProject project, ApiUser member) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Transfer Manager Role',
          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
        ),
        content: Text(
          'Are you sure you want to transfer the manager role of ${project.name} to ${member.name}? You will become a regular member.',
          style: TextStyle(color: Colors.grey[600]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await context.read<AppState>().transferManagerRole(project.id, member.id);
              if (mounted) {
                _showSnackbar(
                  'Manager role transferred to ${member.name}',
                  const Color(0xFF059669),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Transfer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final members = _displayedMembers(appState);
    final project = _currentProject(appState);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          Sidebar(
            activeItem: widget.activeItem,
            selectedProjectId: widget.selectedProjectId,
            onNavTap: widget.onNavTap,
            onProjectTap: widget.onProjectTap,
            onProjectAdded: (newProject) {
              setState(() {});
            },
          ),
          Expanded(
            child: Column(
              children: [
                Header(selectedProjectId: widget.selectedProjectId),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: _selectedMember != null ? 3 : 5,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildPageHeader(project, appState),
                              const SizedBox(height: 24),
                              _buildSummaryChips(members, project, appState),
                              const SizedBox(height: 28),
                              _buildMembersList(members, project, appState),
                            ],
                          ),
                        ),
                      ),
                      if (_selectedMember != null)
                        SizedBox(
                          width: 360,
                          child: _MemberTaskPanel(
                            member: _selectedMember!,
                            selectedProjectId: widget.selectedProjectId,
                            appState: appState,
                            onClose: () => setState(() => _selectedMember = null),
                            onAssignTask: () =>
                                _showAssignTaskDialog(_selectedMember!, appState),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageHeader(ApiProject? project, AppState appState) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Team',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                if (project != null) ...[
                  const SizedBox(width: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: project.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: project.color.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: project.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          project.name,
                          style: TextStyle(
                            color: project.color,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(
              project != null
                  ? 'Members assigned to "${project.name}"'
                  : 'Manage all your team members and their assigned tasks.',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
        if (project != null)
          OutlinedButton.icon(
            onPressed: () => _showAddMemberToProjectDialog(project, appState),
            icon: const Icon(Icons.person_add_alt_1, size: 16),
            label: const Text('Add Member to Project'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF2563EB),
              side: const BorderSide(color: Color(0xFF2563EB)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildChip(IconData icon, String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: fg),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryChips(List<ApiUser> members, ApiProject? project, AppState appState) {
    final relevantTasks = appState.tasks.where((t) {
      if (project != null && t.projectId != project.id) return false;
      return members.any((m) => m.id == t.assigneeId);
    }).toList();

    final inProgress =
        relevantTasks.where((t) => t.status == 'IN_PROGRESS').length;
    final done = relevantTasks.where((t) => t.status == 'DONE').length;

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        _buildChip(
          Icons.people_outline,
          '${members.length} Members',
          const Color(0xFFEFF6FF),
          const Color(0xFF2563EB),
        ),
        if (project != null)
          _buildChip(
            Icons.folder_outlined,
            project.name,
            project.color.withValues(alpha: 0.1),
            project.color,
          )
        else
          _buildChip(
            Icons.folder_outlined,
            '${appState.projects.length} Projects',
            const Color(0xFFF5F3FF),
            const Color(0xFF7C3AED),
          ),
        _buildChip(
          Icons.task_alt_outlined,
          '${relevantTasks.length} Tasks',
          const Color(0xFFF0FDF4),
          const Color(0xFF059669),
        ),
        _buildChip(
          Icons.bolt_rounded,
          '$inProgress In Progress',
          const Color(0xFFFFF7ED),
          const Color(0xFFEA580C),
        ),
        _buildChip(
          Icons.check_circle_outline,
          '$done Done',
          const Color(0xFFF0FDF4),
          const Color(0xFF16A34A),
        ),
      ],
    );
  }

  Widget _buildMembersList(List<ApiUser> members, ApiProject? project, AppState appState) {
    if (members.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(48),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.people_outline,
                size: 36,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              project != null
                  ? 'No members assigned to "${project.name}" yet.'
                  : 'No team members found.',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Add team members to collaborate and assign tasks.',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
            ),
            if (project != null) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => _showAddMemberToProjectDialog(project, appState),
                icon: const Icon(Icons.person_add, size: 16, color: Colors.white),
                label: const Text(
                  'Add Member to Project',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Column(
      children: members.map((m) {
        return _MemberCard(
          member: m,
          project: project,
          appState: appState,
          isSelected: _selectedMember?.id == m.id,
          onViewTasks: () => setState(() => _selectedMember = m),
          onAssignTask: () => _showAssignTaskDialog(m, appState),
          onRemoveFromProject: project != null
              ? () => _removeMemberFromProject(project, m)
              : null,
          onTransferManagerRole: project != null &&
                  appState.isManagerOfProject(project.id) &&
                  project.ownerId != m.id
              ? () => _transferManagerRole(project, m)
              : null,
        );
      }).toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// Member Card
// ---------------------------------------------------------------------------
class _MemberCard extends StatelessWidget {
  const _MemberCard({
    required this.member,
    required this.isSelected,
    required this.onViewTasks,
    required this.onAssignTask,
    required this.appState,
    this.project,
    this.onRemoveFromProject,
    this.onTransferManagerRole,
  });

  final ApiUser member;
  final ApiProject? project;
  final AppState appState;
  final bool isSelected;
  final VoidCallback onViewTasks, onAssignTask;
  final VoidCallback? onRemoveFromProject;
  final VoidCallback? onTransferManagerRole;

  Widget _badge(String label, int count, Color bg, Color fg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: fg,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: fg,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final memberTasks = appState.tasks.where((t) => t.assigneeId == member.id).toList();
    final relevantTasks = project != null
        ? memberTasks.where((t) => t.projectId == project!.id).toList()
        : memberTasks;

    final a = relevantTasks.where((t) => t.status == 'TO_DO').length;
    final ip =
        relevantTasks.where((t) => t.status == 'IN_PROGRESS').length;
    final d = relevantTasks.where((t) => t.status == 'DONE').length;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected
              ? const Color(0xFF2563EB)
              : const Color(0xFFE2E8F0),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? const Color(0xFF2563EB).withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: member.color.withValues(alpha: 0.15),
                backgroundImage: member.avatarUrl != null ? NetworkImage(member.avatarUrl!) : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  member.role,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
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
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF2563EB),
              side: const BorderSide(color: Color(0xFF2563EB)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: onAssignTask,
            icon: const Icon(Icons.assignment_outlined, size: 15, color: Colors.white),
            label: const Text('Assign Task',
                style: TextStyle(color: Colors.white, fontSize: 13)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
          ),
          if (onTransferManagerRole != null) ...[
            const SizedBox(width: 8),
            IconButton(
              onPressed: onTransferManagerRole,
              tooltip: 'Transfer Manager Role',
              icon: const Icon(Icons.admin_panel_settings_outlined,
                  size: 18, color: Color(0xFF059669)),
            ),
          ],
          if (onRemoveFromProject != null) ...[
            const SizedBox(width: 8),
            IconButton(
              onPressed: onRemoveFromProject,
              tooltip: 'Remove from Project',
              icon: const Icon(Icons.person_remove_outlined,
                  size: 18, color: Color(0xFFDC2626)),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Member Task Side Panel
// ---------------------------------------------------------------------------
class _MemberTaskPanel extends StatelessWidget {
  const _MemberTaskPanel({
    required this.member,
    required this.onClose,
    required this.onAssignTask,
    required this.appState,
    this.selectedProjectId,
  });

  final ApiUser member;
  final AppState appState;
  final String? selectedProjectId;
  final VoidCallback onClose, onAssignTask;

  Widget _section(String title, List<ApiTask> tasks, Color accent, Color bg) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: accent,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  tasks.length.toString(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (tasks.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No $title tasks',
                style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              ),
            )
          else
            ...tasks.map((t) => _PanelTaskCard(task: t)),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final memberTasks = appState.tasks.where((t) => t.assigneeId == member.id).toList();
    final tasks = selectedProjectId != null
        ? memberTasks.where((t) => t.projectId == selectedProjectId).toList()
        : memberTasks;

    final assigned =
        tasks.where((t) => t.status == 'TO_DO').toList();
    final inp =
        tasks.where((t) => t.status == 'IN_PROGRESS').toList();
    final done = tasks.where((t) => t.status == 'DONE').toList();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(left: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundImage: member.avatarUrl != null ? NetworkImage(member.avatarUrl!) : null,
                  backgroundColor: member.color.withValues(alpha: 0.15),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        member.role,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close, color: Color(0xFF64748B), size: 20),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onAssignTask,
                icon: const Icon(Icons.add_task, size: 16, color: Colors.white),
                label: const Text(
                  'Assign New Task',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _section(
                    'Assigned',
                    assigned,
                    const Color(0xFFEA580C),
                    const Color(0xFFFFF7ED),
                  ),
                  const SizedBox(height: 16),
                  _section(
                    'In Progress',
                    inp,
                    const Color(0xFF2563EB),
                    const Color(0xFFEFF6FF),
                  ),
                  const SizedBox(height: 16),
                  _section(
                    'Done',
                    done,
                    const Color(0xFF16A34A),
                    const Color(0xFFF0FDF4),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Panel Task Card
// ---------------------------------------------------------------------------
class _PanelTaskCard extends StatelessWidget {
  const _PanelTaskCard({required this.task});
  final ApiTask task;

  @override
  Widget build(BuildContext context) {

    return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: task.tags.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: tag.parsedColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          tag.name,
                          style: TextStyle(
                            color: tag.parsedColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const Spacer(),
                _MiniPriorityBadge(priority: task.priority),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              task.title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.calendar_today,
                    size: 11, color: Color(0xFF94A3B8)),
                const SizedBox(width: 4),
                Text(
                  'Due: ${task.formattedDue}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
  }
}

// ---------------------------------------------------------------------------
// Add Member to Project Dialog
// ---------------------------------------------------------------------------
class _AddMemberDialog extends StatefulWidget {
  const _AddMemberDialog({
    required this.project,
    required this.availableMembers,
    required this.onAdd,
    required this.onInvite,
  });

  final ApiProject project;
  final List<ApiUser> availableMembers;
  final void Function(ApiUser) onAdd;
  final void Function(String) onInvite;

  @override
  State<_AddMemberDialog> createState() => _AddMemberDialogState();
}

class _AddMemberDialogState extends State<_AddMemberDialog> {
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 420,
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: widget.project.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.person_add_outlined,
                      color: widget.project.color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Add Member',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        Text(
                          'To ${widget.project.name}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Invite by Email section
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        hintText: 'Invite by email...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      if (_emailController.text.trim().isNotEmpty) {
                        widget.onInvite(_emailController.text.trim());
                        Navigator.of(context).pop();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.project.color,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Invite', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: Color(0xFFE2E8F0)),
              const SizedBox(height: 16),
              const Text('Add existing member:', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              const SizedBox(height: 8),
              if (widget.availableMembers.isEmpty)
                const Text('No more existing members available to add.', style: TextStyle(color: Colors.grey)),
              ...widget.availableMembers.map(
                (m) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                        Navigator.of(context).pop();
                        widget.onAdd(m);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          color: const Color(0xFFF8FAFC),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundImage: m.avatarUrl != null ? NetworkImage(m.avatarUrl!) : null,
                              backgroundColor:
                                  m.color.withValues(alpha: 0.15),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    m.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                  Text(
                                    m.role,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.add_circle_outline,
                              color: widget.project.color,
                              size: 22,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
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
      case 'High':
        bg = const Color(0xFFFEF2F2);
        fg = const Color(0xFFDC2626);
        break;
      case 'Medium':
        bg = const Color(0xFFFFFBEB);
        fg = const Color(0xFFD97706);
        break;
      default:
        bg = const Color(0xFFF0FDF4);
        fg = const Color(0xFF16A34A);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        priority,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Assign Task to Member Dialog (Supports assigning unassigned or new tasks)
// ---------------------------------------------------------------------------
class _AssignTaskToMemberDialog extends StatefulWidget {
  const _AssignTaskToMemberDialog({
    required this.member,
    required this.projectId,
    required this.unassignedTasks,
    required this.onAssigned,
  });

  final ApiUser member;
  final String projectId;
  final List<ApiTask> unassignedTasks;
  final void Function(String message) onAssigned;

  @override
  State<_AssignTaskToMemberDialog> createState() =>
      _AssignTaskToMemberDialogState();
}

class _AssignTaskToMemberDialogState extends State<_AssignTaskToMemberDialog> {
  int _tabIndex = 0; // 0: Select Existing Unassigned, 1: Create New Task

  String? _selectedUnassignedTaskId;

  // New task form fields
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String _selectedPriority = 'Medium';
  final List<String> _selectedTagIds = [];
  String _dueDate = 'Sep 15';
  DateTime _dueDateObject = DateTime.now().add(const Duration(days: 3));

  final List<String> _priorities = ['High', 'Medium', 'Low'];

  @override
  void initState() {
    super.initState();
    final unassigned = widget.unassignedTasks;
    if (unassigned.isNotEmpty) {
      _selectedUnassignedTaskId = unassigned.first.id;
      _tabIndex = 0;
    } else {
      _tabIndex = 1;
    }
    _dueDate = _formatDate(_dueDateObject);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDateObject,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _dueDateObject = picked;
        _dueDate = _formatDate(picked);
      });
    }
  }

  void _submitAssignExisting() async {
    if (_selectedUnassignedTaskId == null) return;
    await context.read<AppState>().assignTask(
        _selectedUnassignedTaskId!, widget.member.id);
    if (mounted) {
      Navigator.of(context).pop();
      widget.onAssigned('Task assigned to ${widget.member.name}');
    }
  }

  void _submitCreateAndAssign() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a task title'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await context.read<AppState>().createTask(
      title: title,
      description: _descController.text.trim(),
      tagIds: _selectedTagIds,
      priority: _selectedPriority,
      dueDate: _dueDateObject.toIso8601String(),
      projectId: widget.projectId,
      assigneeId: widget.member.id,
      status: 'TO_DO',
    );

    if (mounted) {
      Navigator.of(context).pop();
      widget.onAssigned('Task "$title" assigned to ${widget.member.name}');
    }
  }

  InputDecoration _inputDec(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
      );

  Color _priorityColor(String p) {
    switch (p) {
      case 'High':
        return const Color(0xFFDC2626);
      case 'Medium':
        return const Color(0xFFD97706);
      default:
        return const Color(0xFF16A34A);
    }
  }

  @override
  Widget build(BuildContext context) {
    final unassigned = widget.unassignedTasks;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      child: Container(
        width: 480,
        constraints: const BoxConstraints(maxHeight: 650),
        padding: const EdgeInsets.all(28),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: widget.member.avatarUrl != null ? NetworkImage(widget.member.avatarUrl!) : null,
                    backgroundColor:
                        widget.member.color.withValues(alpha: 0.15),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Assign Task',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        Text(
                          'To ${widget.member.name} (${widget.member.role})',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Divider(color: Color(0xFFE2E8F0)),
              const SizedBox(height: 14),

              // Segmented Tabs
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _tabIndex = 0),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _tabIndex == 0
                                ? Colors.white
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: _tabIndex == 0
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    )
                                  ]
                                : [],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Unassigned Tasks (${unassigned.length})',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: _tabIndex == 0
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: _tabIndex == 0
                                  ? const Color(0xFF1E293B)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _tabIndex = 1),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _tabIndex == 1
                                ? Colors.white
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: _tabIndex == 1
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    )
                                  ]
                                : [],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'New Task',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: _tabIndex == 1
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: _tabIndex == 1
                                  ? const Color(0xFF1E293B)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Tab 0: Select Existing Unassigned Task
              if (_tabIndex == 0) ...[
                if (unassigned.isEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(24),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.inbox_outlined,
                            size: 32, color: Color(0xFF94A3B8)),
                        const SizedBox(height: 8),
                        const Text(
                          'No unassigned tasks for this project',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF475569)),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () => setState(() => _tabIndex = 1),
                          child: const Text('Create New Task'),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  const Text(
                    'Select an unassigned project task:',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF475569)),
                  ),
                  const SizedBox(height: 10),
                  ...unassigned.map((task) {
                    final isSel = _selectedUnassignedTaskId == task.id;
                    return GestureDetector(
                      onTap: () =>
                          setState(() => _selectedUnassignedTaskId = task.id),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSel
                              ? const Color(0xFFEFF6FF)
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSel
                                ? const Color(0xFF2563EB)
                                : const Color(0xFFE2E8F0),
                            width: isSel ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Radio<String>(
                              value: task.id,
                              groupValue: _selectedUnassignedTaskId,
                              onChanged: (val) => setState(
                                  () => _selectedUnassignedTaskId = val),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    task.title,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1E293B)),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      ...task.tags.map((tag) => Padding(
                                        padding: const EdgeInsets.only(right: 6.0),
                                        child: Text(tag.name,
                                            style: TextStyle(
                                                fontSize: 11,
                                                color: tag.parsedColor,
                                                fontWeight: FontWeight.w600)),
                                      )),
                                      const SizedBox(width: 8),
                                      Text('•',
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey[400])),
                                      const SizedBox(width: 8),
                                      Text('Due: ${task.formattedDue}',
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: Color(0xFF64748B))),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            _MiniPriorityBadge(priority: task.priority),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submitAssignExisting,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Assign Selected Task to ${widget.member.name}',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ],

              // Tab 1: Create New Task for this member
              if (_tabIndex == 1) ...[
                const Text(
                  'Task Title *',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Color(0xFF374151)),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _titleController,
                  autofocus: true,
                  decoration: _inputDec('e.g. Design responsive navbar'),
                ),
                const SizedBox(height: 14),

                const Text(
                  'Description (Optional)',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Color(0xFF374151)),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _descController,
                  maxLines: 2,
                  decoration: _inputDec('Additional task instructions...'),
                ),
                const SizedBox(height: 16),

                // Priority & Deadline
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Priority',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: Color(0xFF374151)),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: _priorities.map((p) {
                              final isSel = _selectedPriority == p;
                              final col = _priorityColor(p);
                              return Expanded(
                                child: GestureDetector(
                                  onTap: () =>
                                      setState(() => _selectedPriority = p),
                                  child: Container(
                                    margin: const EdgeInsets.only(right: 6),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isSel
                                          ? col.withValues(alpha: 0.12)
                                          : const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: isSel
                                            ? col
                                            : const Color(0xFFE2E8F0),
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      p,
                                      style: TextStyle(
                                        color: isSel
                                            ? col
                                            : const Color(0xFF64748B),
                                        fontWeight: isSel
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Deadline',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: Color(0xFF374151)),
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: _pickDate,
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(8),
                                border:
                                    Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_month,
                                      size: 16, color: Color(0xFF2563EB)),
                                  const SizedBox(width: 6),
                                  Text(_dueDate,
                                      style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Tags
                const Text(
                  'Tag',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Color(0xFF374151)),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: context.watch<AppState>().tags.map((t) {
                    final isSel = _selectedTagIds.contains(t.id);
                    final Color color = t.parsedColor;
                    return GestureDetector(
                      onTap: () => setState(() {
                        if (isSel) {
                          _selectedTagIds.remove(t.id);
                        } else {
                          _selectedTagIds.add(t.id);
                        }
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isSel
                              ? color.withValues(alpha: 0.15)
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isSel ? color : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Text(
                          t.name,
                          style: TextStyle(
                            color: isSel ? color : const Color(0xFF64748B),
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _submitCreateAndAssign,
                    icon: const Icon(Icons.check, size: 16, color: Colors.white),
                    label: Text(
                      'Assign to ${widget.member.name}',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
