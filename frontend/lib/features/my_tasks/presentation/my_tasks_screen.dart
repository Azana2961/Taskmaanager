import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/header.dart';
import '../../../core/widgets/sidebar.dart';
import '../../../core/services/app_state.dart';
import '../../../core/services/api_service.dart';



class MyTasksScreen extends StatefulWidget {
  const MyTasksScreen({
    super.key,
    this.activeItem = 'My Tasks',
    this.selectedProjectId,
    this.onNavTap,
    this.onProjectTap,
  });

  final String activeItem;
  final String? selectedProjectId;
  final void Function(String item)? onNavTap;
  final void Function(String? projectId)? onProjectTap;

  @override
  State<MyTasksScreen> createState() => _MyTasksScreenState();
}

class _MyTasksScreenState extends State<MyTasksScreen> {
  List<ApiTask> _pendingTasks(AppState appState) {
    return appState.tasksForProject(widget.selectedProjectId)
        .where((t) => t.status == 'TO_DO')
        .toList();
  }

  List<ApiTask> _runningTasks(AppState appState) {
    return appState.tasksForProject(widget.selectedProjectId)
        .where((t) => t.status == 'IN_PROGRESS')
        .toList();
  }

  void _startTask(ApiTask task) async {
    await context.read<AppState>().updateTaskStatus(task.id, 'IN_PROGRESS');
    if (mounted) {
      _showSnackbar('Started: "${task.title}" (moved to In Progress)', const Color(0xFF2563EB));
    }
  }

  void _submitTask(ApiTask task) {
    showDialog(
      context: context,
      builder: (ctx) => _SubmitDialog(
        task: task,
        onConfirm: () async {
          await context.read<AppState>().updateTaskStatus(task.id, 'DONE');
          if (mounted) {
            _showSnackbar('Task submitted: "${task.title}" (moved to Done) 🎉', Colors.green);
          }
        },
      ),
    );
  }

  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          Sidebar(
            activeItem: widget.activeItem,
            selectedProjectId: widget.selectedProjectId,
            onNavTap: widget.onNavTap,
            onProjectTap: widget.onProjectTap,
            onProjectAdded: (p) {},
          ),
          Expanded(
            child: Column(
              children: [
                const Header(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Page Header
                        _buildPageHeader(),
                        const SizedBox(height: 24),

                        // Summary chips
                        _buildSummaryRow(appState),
                        const SizedBox(height: 32),

                        // Two Columns
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Pending Tasks Column
                            Expanded(
                              child: _buildPendingColumn(appState),
                            ),
                            const SizedBox(width: 24),
                            // Running Tasks Column
                            Expanded(
                              child: _buildRunningColumn(appState),
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

  Widget _buildPageHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'My Tasks',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Manage and track your assigned tasks.',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
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
      ],
    );
  }

  Widget _buildSummaryRow(AppState appState) {
    return Row(
      children: [
        _buildChip(
          Icons.hourglass_empty_rounded,
          '${_pendingTasks(appState).length} Pending',
          const Color(0xFFFFF7ED),
          const Color(0xFFEA580C),
        ),
        const SizedBox(width: 12),
        _buildChip(
          Icons.bolt_rounded,
          '${_runningTasks(appState).length} In Progress',
          const Color(0xFFEFF6FF),
          const Color(0xFF2563EB),
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

  Widget _buildPendingColumn(AppState appState) {
    final tasks = _pendingTasks(appState);
    return _TaskColumn(
      title: 'Pending Tasks',
      count: tasks.length,
      dotColor: const Color(0xFFEA580C),
      headerBadgeColor: const Color(0xFFFFF7ED),
      headerBadgeTextColor: const Color(0xFFEA580C),
      emptyMessage: 'No pending tasks. Great job! 🎉',
      children: tasks.map((task) {
        return _PendingTaskCard(
          task: task,
          onStart: () => _startTask(task),
        );
      }).toList(),
    );
  }

  Widget _buildRunningColumn(AppState appState) {
    final tasks = _runningTasks(appState);
    return _TaskColumn(
      title: 'Running Tasks',
      count: tasks.length,
      dotColor: const Color(0xFF2563EB),
      headerBadgeColor: const Color(0xFFEFF6FF),
      headerBadgeTextColor: const Color(0xFF2563EB),
      emptyMessage: 'No tasks in progress yet.',
      children: tasks.map((task) {
        return _RunningTaskCard(
          task: task,
          onSubmit: () => _submitTask(task),
        );
      }).toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// Column wrapper
// ---------------------------------------------------------------------------
class _TaskColumn extends StatelessWidget {
  const _TaskColumn({
    required this.title,
    required this.count,
    required this.dotColor,
    required this.headerBadgeColor,
    required this.headerBadgeTextColor,
    required this.children,
    required this.emptyMessage,
  });

  final String title;
  final int count;
  final Color dotColor;
  final Color headerBadgeColor;
  final Color headerBadgeTextColor;
  final List<Widget> children;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Column Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
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
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(
                    color: headerBadgeColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    count.toString(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: headerBadgeTextColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 12),

          if (children.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
              child: Center(
                child: Text(
                  emptyMessage,
                  style: TextStyle(color: Colors.grey[500], fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            ...children,

          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pending Task Card
// ---------------------------------------------------------------------------
class _PendingTaskCard extends StatelessWidget {
  const _PendingTaskCard({required this.task, required this.onStart});

  final ApiTask task;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tag + Priority
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
              _PriorityBadge(priority: task.priority),
            ],
          ),
          const SizedBox(height: 10),

          // Title
          Text(
            task.title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 6),

          // Description
          Text(
            task.description,
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 14),

          // Footer: Due date + Start button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 13, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 4),
                  Text(
                    'Due: ${task.formattedDue}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: onStart,
                icon: const Icon(Icons.play_arrow_rounded, size: 16, color: Colors.white),
                label: const Text(
                  'Start',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
// Running Task Card
// ---------------------------------------------------------------------------
class _RunningTaskCard extends StatelessWidget {
  const _RunningTaskCard({required this.task, required this.onSubmit});

  final ApiTask task;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tag + Priority
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
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.bolt_rounded, size: 12, color: Color(0xFF2563EB)),
                        SizedBox(width: 3),
                        Text(
                          'In Progress',
                          style: TextStyle(
                            color: Color(0xFF2563EB),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              _PriorityBadge(priority: task.priority),
            ],
          ),
          const SizedBox(height: 10),

          // Title
          Text(
            task.title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 6),

          // Description
          Text(
            task.description,
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 14),

          // Progress Bar
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: const LinearProgressIndicator(
                    value: 0.5,
                    backgroundColor: Color(0xFFE2E8F0),
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                '50%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2563EB),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Footer: Due date + Submit button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 13, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 4),
                  Text(
                    'Due: ${task.formattedDue}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: onSubmit,
                icon: const Icon(Icons.check_circle_outline, size: 16, color: Colors.white),
                label: const Text(
                  'Submit',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
// Priority Badge
// ---------------------------------------------------------------------------
class _PriorityBadge extends StatelessWidget {
  const _PriorityBadge({required this.priority});
  final String priority;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        priority,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Submit Confirmation Dialog
// ---------------------------------------------------------------------------
class _SubmitDialog extends StatelessWidget {
  const _SubmitDialog({required this.task, required this.onConfirm});
  final ApiTask task;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'Submit Task',
        style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Are you sure you want to submit this task?',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
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
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    task.title,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            onConfirm();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[600],
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Submit Task', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
