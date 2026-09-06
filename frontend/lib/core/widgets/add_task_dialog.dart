import 'package:flutter/material.dart';
import '../data/dummy_data.dart';

class AddTaskDialog extends StatefulWidget {
  const AddTaskDialog({
    super.key,
    required this.projectId,
    this.initialStatus = TaskStatus.assigned,
    this.onTaskAdded,
  });

  final String projectId;
  final TaskStatus initialStatus;
  final void Function(Task task)? onTaskAdded;

  static Future<Task?> show(
    BuildContext context, {
    required String projectId,
    TaskStatus initialStatus = TaskStatus.assigned,
    void Function(Task task)? onTaskAdded,
  }) {
    return showDialog<Task>(
      context: context,
      builder: (ctx) => AddTaskDialog(
        projectId: projectId,
        initialStatus: initialStatus,
        onTaskAdded: onTaskAdded,
      ),
    );
  }

  @override
  State<AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  late TaskStatus _selectedStatus;
  String _selectedPriority = 'Medium';
  String _selectedTag = 'Dev';
  Color _selectedTagColor = Colors.blue;
  String _dueDate = 'Sep 15';
  DateTime _dueDateObject = DateTime.now().add(const Duration(days: 3));

  final List<Map<String, dynamic>> _tags = [
    {'label': 'Dev', 'color': const Color(0xFF2563EB)},
    {'label': 'Design', 'color': const Color(0xFF7C3AED)},
    {'label': 'Bug', 'color': const Color(0xFFEA580C)},
    {'label': 'Marketing', 'color': const Color(0xFF4F46E5)},
    {'label': 'QA', 'color': const Color(0xFFDB2777)},
    {'label': 'Docs', 'color': const Color(0xFF0D9488)},
  ];

  final List<String> _priorities = ['High', 'Medium', 'Low'];

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.initialStatus;
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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2563EB),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1E293B),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dueDateObject = picked;
        _dueDate = _formatDate(picked);
      });
    }
  }

  void _submit() {
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

    final newTask = Task(
      id: 't_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      description: _descController.text.trim(),
      tag: _selectedTag,
      tagColor: _selectedTagColor,
      priority: _selectedPriority,
      dueDate: _dueDate,
      projectId: widget.projectId,
      status: _selectedStatus,
      progress: _selectedStatus == TaskStatus.inProgress
          ? 0.3
          : (_selectedStatus == TaskStatus.done ? 1.0 : 0.0),
    );

    DummyData.addTask(newTask);

    widget.onTaskAdded?.call(newTask);
    Navigator.of(context).pop(newTask);
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
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.add_task_rounded,
                      color: Color(0xFF2563EB),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Create New Task',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Set title, priority, deadline, and tags',
                          style: TextStyle(
                              fontSize: 13, color: Color(0xFF64748B)),
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
              const SizedBox(height: 20),
              const Divider(color: Color(0xFFE2E8F0)),
              const SizedBox(height: 18),

              // Title
              const Text(
                'Task Title *',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Color(0xFF374151),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _titleController,
                autofocus: true,
                decoration: _inputDec('e.g. Design onboarding screen'),
              ),
              const SizedBox(height: 16),

              // Description
              const Text(
                'Description (Optional)',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Color(0xFF374151),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _descController,
                maxLines: 2,
                decoration:
                    _inputDec('Add any additional details or requirements...'),
              ),
              const SizedBox(height: 18),

              // Priority & Deadline Row
              Row(
                children: [
                  // Priority
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Priority *',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: Color(0xFF374151),
                          ),
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
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  margin: const EdgeInsets.only(right: 6),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isSel
                                        ? col.withValues(alpha: 0.12)
                                        : const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color:
                                          isSel ? col : const Color(0xFFE2E8F0),
                                      width: isSel ? 1.5 : 1,
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
                                          : FontWeight.w500,
                                      fontSize: 12,
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
                  const SizedBox(width: 16),

                  // Deadline / Due Date
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Deadline *',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: Color(0xFF374151),
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: _pickDate,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 11),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border:
                                  Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.calendar_month_outlined,
                                  color: Color(0xFF2563EB),
                                  size: 18,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _dueDate,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                ),
                                const Text(
                                  'Change',
                                  style: TextStyle(
                                    color: Color(0xFF2563EB),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
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
              const SizedBox(height: 18),

              // Status & Tag Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Status',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: Color(0xFF374151),
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<TaskStatus>(
                          initialValue: _selectedStatus,
                          decoration: _inputDec('Status'),
                          items: const [
                            DropdownMenuItem(
                              value: TaskStatus.assigned,
                              child:
                                  Text('To Do', style: TextStyle(fontSize: 13)),
                            ),
                            DropdownMenuItem(
                              value: TaskStatus.inProgress,
                              child: Text('In Progress',
                                  style: TextStyle(fontSize: 13)),
                            ),
                            DropdownMenuItem(
                              value: TaskStatus.done,
                              child:
                                  Text('Done', style: TextStyle(fontSize: 13)),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedStatus = val);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Tag
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tag',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: Color(0xFF374151),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: _tags.map((t) {
                            final isSel = _selectedTag == t['label'];
                            final Color color = t['color'] as Color;
                            return GestureDetector(
                              onTap: () => setState(() {
                                _selectedTag = t['label'] as String;
                                _selectedTagColor = color;
                              }),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 9, vertical: 5),
                                decoration: BoxDecoration(
                                  color: isSel
                                      ? color.withValues(alpha: 0.15)
                                      : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: isSel
                                        ? color
                                        : const Color(0xFFE2E8F0),
                                    width: isSel ? 1.5 : 1,
                                  ),
                                ),
                                child: Text(
                                  t['label'] as String,
                                  style: TextStyle(
                                    color: isSel
                                        ? color
                                        : const Color(0xFF64748B),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _submit,
                      icon: const Icon(Icons.add, size: 18, color: Colors.white),
                      label: const Text(
                        'Add Task',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
