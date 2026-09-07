import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/app_state.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/widgets/add_task_dialog.dart';



class TaskBoard extends StatefulWidget {
  const TaskBoard({
    super.key,
    this.selectedProjectId,
    this.onTaskAdded,
  });

  final String? selectedProjectId;
  final VoidCallback? onTaskAdded;

  @override
  State<TaskBoard> createState() => _TaskBoardState();
}

class _TaskBoardState extends State<TaskBoard> {
  String _filterPriority = 'All'; // 'All', 'High', 'Medium', 'Low'
  String _filterDueDate = 'All'; // 'All', 'Today', 'This Week', 'Overdue'

  void _openAddTask([String initialStatus = 'TO_DO']) async {
    final appState = context.read<AppState>();
    final effectiveProjectId = widget.selectedProjectId ??
        (appState.projects.isNotEmpty ? appState.projects.first.id : 'p1');
    final newTask = await AddTaskDialog.show(
      context,
      projectId: effectiveProjectId,
      initialStatus: initialStatus,
      onTaskAdded: (t) {
        setState(() {});
        widget.onTaskAdded?.call();
      },
    );
    if (newTask != null) {
      setState(() {});
      widget.onTaskAdded?.call();
    }
  }

  void _confirmFinishProject() async {
    final appState = context.read<AppState>();
    final effectiveProjectId = widget.selectedProjectId ??
        (appState.projects.isNotEmpty ? appState.projects.first.id : 'p1');
    final project = appState.projects.firstWhere(
      (p) => p.id == effectiveProjectId,
      orElse: () => appState.projects.first,
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.task_alt, color: Color(0xFF10B981), size: 24),
            ),
            const SizedBox(width: 12),
            const Text(
              'Finish Project',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to finish "${project.name}"?\nAll active and pending tasks in this project will be marked as Done.',
          style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.5),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFE2E8F0)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(ctx).pop(true),
            icon: const Icon(Icons.check, size: 16, color: Colors.white),
            label: const Text('Finish Project', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await appState.finishProject(effectiveProjectId);
      if (!mounted) return;
      widget.onTaskAdded?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Project "${project.name}" completed! All tasks marked Done.'),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  bool _matchesDueDate(ApiTask task, String filter) {
    if (filter == 'All') return true;
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final parts = task.formattedDue.trim().split(' ');
      if (parts.length >= 2) {
        const months = {
          'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
          'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12
        };
        final mStr = parts[0];
        final dStr = parts[1].replaceAll(RegExp(r'[^0-9]'), '');
        final month = months[mStr];
        final day = int.tryParse(dStr);
        if (month != null && day != null) {
          final taskDate = DateTime(now.year, month, day);
          final diffDays = taskDate.difference(today).inDays;
          if (filter == 'Today') {
            return diffDays == 0;
          } else if (filter == 'This Week') {
            return diffDays >= 0 && diffDays <= 7;
          } else if (filter == 'Overdue') {
            return diffDays < 0;
          }
        }
      }
    } catch (_) {}
    return true;
  }

  void _showFilterDialog() async {
    String tempPriority = _filterPriority;
    String tempDueDate = _filterDueDate;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.filter_list, color: Color(0xFF2563EB), size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Filter Tasks',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              if (tempPriority != 'All' || tempDueDate != 'All')
                TextButton(
                  onPressed: () {
                    setDialogState(() {
                      tempPriority = 'All';
                      tempDueDate = 'All';
                    });
                  },
                  child: const Text('Reset', style: TextStyle(fontSize: 12, color: Color(0xFFEF4444))),
                ),
            ],
          ),
          content: SizedBox(
            width: 380,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'By Priority',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ['All', 'High', 'Medium', 'Low'].map((p) {
                    final isSel = tempPriority == p;
                    return ChoiceChip(
                      label: Text(p),
                      selected: isSel,
                      selectedColor: const Color(0xFFEFF6FF),
                      labelStyle: TextStyle(
                        color: isSel ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                        fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                        fontSize: 12,
                      ),
                      side: BorderSide(
                        color: isSel ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                      ),
                      onSelected: (val) {
                        if (val) setDialogState(() => tempPriority = p);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                const Text(
                  'By Due Date',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ['All', 'Today', 'This Week', 'Overdue'].map((d) {
                    final isSel = tempDueDate == d;
                    return ChoiceChip(
                      label: Text(d),
                      selected: isSel,
                      selectedColor: const Color(0xFFEFF6FF),
                      labelStyle: TextStyle(
                        color: isSel ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                        fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                        fontSize: 12,
                      ),
                      side: BorderSide(
                        color: isSel ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                      ),
                      onSelected: (val) {
                        if (val) setDialogState(() => tempDueDate = d);
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFE2E8F0)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _filterPriority = tempPriority;
                  _filterDueDate = tempDueDate;
                });
                Navigator.of(ctx).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Apply Filter', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final allTasks = appState.tasksForProject(widget.selectedProjectId);
    final tasks = allTasks.where((t) {
      final matchesPriority = _filterPriority == 'All' ||
          t.priority.toLowerCase() == _filterPriority.toLowerCase();
      final matchesDue = _matchesDueDate(t, _filterDueDate);
      return matchesPriority && matchesDue;
    }).toList();

    final todo = tasks.where((t) => t.status == 'TO_DO').toList();
    final inProgress =
        tasks.where((t) => t.status == 'IN_PROGRESS').toList();
    final done = tasks.where((t) => t.status == 'DONE').toList();
    final isFiltered = _filterPriority != 'All' || _filterDueDate != 'All';

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
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isFiltered
                      ? 'Filtered by: ${_filterPriority != 'All' ? 'Priority: $_filterPriority ' : ''}${_filterDueDate != 'All' ? 'Due: $_filterDueDate' : ''}'
                      : 'Manage your team\'s tasks, priorities, and workflow.',
                  style: TextStyle(
                    color: isFiltered ? const Color(0xFF2563EB) : Colors.grey[600],
                    fontSize: 14,
                    fontWeight: isFiltered ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                // Filter Button
                OutlinedButton.icon(
                  onPressed: _showFilterDialog,
                  icon: Icon(
                    Icons.filter_list,
                    size: 18,
                    color: isFiltered ? const Color(0xFF2563EB) : const Color(0xFF1E293B),
                  ),
                  label: Text(
                    isFiltered ? 'Filtered' : 'Filter',
                    style: TextStyle(
                      color: isFiltered ? const Color(0xFF2563EB) : const Color(0xFF1E293B),
                      fontWeight: isFiltered ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: isFiltered ? const Color(0xFFEFF6FF) : Colors.transparent,
                    side: BorderSide(
                      color: isFiltered ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                  ),
                ),
                if (isFiltered) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Clear Filter',
                    icon: const Icon(Icons.close, size: 18, color: Color(0xFF94A3B8)),
                    onPressed: () {
                      setState(() {
                        _filterPriority = 'All';
                        _filterDueDate = 'All';
                      });
                    },
                  ),
                ],
                const SizedBox(width: 12),
                // Finish Project Button
                OutlinedButton.icon(
                  onPressed: _confirmFinishProject,
                  icon: const Icon(Icons.check_circle_outline, size: 18, color: Color(0xFF059669)),
                  label: const Text(
                    'Finish Project',
                    style: TextStyle(
                      color: Color(0xFF059669),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: const Color(0xFFECFDF5),
                    side: const BorderSide(color: Color(0xFF10B981)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                  ),
                ),
                const SizedBox(width: 12),
                // New Task Button
                ElevatedButton.icon(
                  onPressed: () => _openAddTask('TO_DO'),
                  icon: const Icon(Icons.add, size: 18, color: Colors.white),
                  label: const Text(
                    'New Task',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
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
                'TO_DO',
                todo.map((t) => _buildTaskCard(t, appState)).toList(),
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: _buildColumn(
                'In Progress',
                inProgress.length,
                const Color(0xFF2563EB),
                'IN_PROGRESS',
                inProgress.map((t) => _buildTaskCard(t, appState)).toList(),
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: _buildColumn(
                'Done',
                done.length,
                Colors.green,
                'DONE',
                done.map((t) => _buildTaskCard(t, appState)).toList(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildColumn(
    String title,
    int count,
    Color dotColor,
    String status,
    List<Widget> taskWidgets,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: dotColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Text(
                        count.toString(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
                Tooltip(
                  message: 'Add to $title',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(4),
                    onTap: () => _openAddTask(status),
                    child: const Padding(
                      padding: EdgeInsets.all(4.0),
                      child: Icon(
                        Icons.add,
                        color: Color(0xFF94A3B8),
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (taskWidgets.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Center(
                child: Text(
                  'No tasks in $title',
                  style:
                      const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                ),
              ),
            )
          else
            ...taskWidgets,
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildTaskCard(ApiTask task, AppState appState) {
    Color priorityColor;
    Color priorityBg;
    switch (task.priority) {
      case 'High':
        priorityColor = const Color(0xFFDC2626);
        priorityBg = const Color(0xFFFEF2F2);
        break;
      case 'Medium':
        priorityColor = const Color(0xFFD97706);
        priorityBg = const Color(0xFFFFFBEB);
        break;
      default:
        priorityColor = const Color(0xFF16A34A);
        priorityBg = const Color(0xFFF0FDF4);
    }

    // Find assigned member if any
    ApiUser? assignee;
    try {
      if (task.assigneeId != null) {
        assignee = appState.users.firstWhere((m) => m.id == task.assigneeId);
      }
    } catch (_) {
      assignee = null;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: task.tags.map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: tag.parsedColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        tag.name,
                        style: TextStyle(
                          color: tag.parsedColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: priorityBg,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  task.priority,
                  style: TextStyle(
                    color: priorityColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            task.title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: Color(0xFF1E293B),
            ),
          ),
          if (task.description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              task.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 13,
                    color: Color(0xFF94A3B8),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    task.formattedDue,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              assignee != null
                  ? Tooltip(
                      message: assignee.name,
                      child: CircleAvatar(
                        radius: 12,
                        backgroundImage: assignee.avatarUrl != null ? NetworkImage(assignee.avatarUrl!) : null,
                        backgroundColor:
                            assignee.color.withValues(alpha: 0.2),
                      ),
                    )
                  : Tooltip(
                      message: 'Unassigned — assign in Team menu',
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.person_outline,
                                size: 12, color: Color(0xFF64748B)),
                            SizedBox(width: 3),
                            Text(
                              'Unassigned',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ],
          ),
        ],
      ),
    );
  }
}
