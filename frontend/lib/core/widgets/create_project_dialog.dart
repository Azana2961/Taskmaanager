import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../services/api_service.dart';

class CreateProjectDialog extends StatefulWidget {
  const CreateProjectDialog({
    super.key,
    this.onProjectCreated,
  });

  final void Function(ApiProject project)? onProjectCreated;

  static Future<ApiProject?> show(
    BuildContext context, {
    void Function(ApiProject project)? onProjectCreated,
  }) {
    return showDialog<ApiProject>(
      context: context,
      builder: (ctx) => CreateProjectDialog(onProjectCreated: onProjectCreated),
    );
  }

  @override
  State<CreateProjectDialog> createState() => _CreateProjectDialogState();
}

class _CreateProjectDialogState extends State<CreateProjectDialog> {
  final _nameController = TextEditingController();

  final List<Color> _colors = const [
    Color(0xFF2563EB), // Blue
    Color(0xFF7C3AED), // Purple
    Color(0xFF059669), // Emerald
    Color(0xFFEA580C), // Orange
    Color(0xFFDB2777), // Pink
    Color(0xFF0891B2), // Cyan
    Color(0xFFD97706), // Amber
    Color(0xFF4F46E5), // Indigo
  ];

  late Color _selectedColor;
  final Set<String> _selectedMemberIds = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_selectedMemberIds.isEmpty) {
      final appState = context.read<AppState>();
      if (appState.users.isNotEmpty) {
        _selectedMemberIds.add(appState.users.first.id);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _selectedColor = _colors.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a project name'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final newProject = await context.read<AppState>().createProject(
        name: name,
        colorCode: '#${_selectedColor.value.toRadixString(16).substring(2).toUpperCase()}',
        memberIds: _selectedMemberIds.toList(),
      );

      widget.onProjectCreated?.call(newProject);
      if (mounted) {
        Navigator.of(context).pop(newProject);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating project: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
                      color: _selectedColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.create_new_folder_outlined,
                      color: _selectedColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Create New Project',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Add a project to organize tasks and team members',
                          style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
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

              // Project Name
              const Text(
                'Project Name *',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Color(0xFF374151),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'e.g. Mobile App Redesign',
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
                    borderSide: BorderSide(color: _selectedColor, width: 2),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                ),
              ),
              const SizedBox(height: 20),

              // Color theme
              const Text(
                'Project Color Badge',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Color(0xFF374151),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _colors.map((c) {
                  final isSel = _selectedColor == c;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = c),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSel ? Colors.white : Colors.transparent,
                          width: 2.5,
                        ),
                        boxShadow: [
                          if (isSel)
                            BoxShadow(
                              color: c.withValues(alpha: 0.5),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                        ],
                      ),
                      child: isSel
                          ? const Icon(Icons.check, size: 18, color: Colors.white)
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Assign Initial Members
              const Text(
                'Assign Team Members',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Color(0xFF374151),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Choose who is working on this project',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  borderRadius: BorderRadius.circular(10),
                  color: const Color(0xFFF8FAFC),
                ),
                child: Consumer<AppState>(
                  builder: (context, appState, child) {
                    return Column(
                      children: appState.users.map((m) {
                        final isChecked = _selectedMemberIds.contains(m.id);
                        return CheckboxListTile(
                          value: isChecked,
                          dense: true,
                          activeColor: _selectedColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          secondary: CircleAvatar(
                            radius: 14,
                            backgroundImage: m.avatarUrl != null ? NetworkImage(m.avatarUrl!) : null,
                            backgroundColor: m.color.withValues(alpha: 0.2),
                          ),
                          title: Text(
                            m.name,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          subtitle: Text(
                            m.role,
                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                          ),
                          onChanged: (bool? val) {
                            setState(() {
                              if (val == true) {
                                _selectedMemberIds.add(m.id);
                              } else {
                                _selectedMemberIds.remove(m.id);
                              }
                            });
                          },
                        );
                      }).toList(),
                    );
                  }
                ),
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
                        'Create Project',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedColor,
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
