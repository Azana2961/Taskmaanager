import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/app_state.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/widgets/sidebar.dart';
import '../../../../core/widgets/header.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.activeItem,
    required this.selectedProjectId,
    required this.onNavTap,
    required this.onProjectTap,
  });

  final String activeItem;
  final String? selectedProjectId;
  final Function(String) onNavTap;
  final Function(String?) onProjectTap;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          Sidebar(
            activeItem: activeItem,
            selectedProjectId: selectedProjectId,
            onNavTap: onNavTap,
            onProjectTap: onProjectTap,
          ),
          Expanded(
            child: Column(
              children: [
                Header(selectedProjectId: selectedProjectId),
                Expanded(
                  child: _SettingsContent(selectedProjectId: selectedProjectId),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsContent extends StatefulWidget {
  final String? selectedProjectId;
  const _SettingsContent({this.selectedProjectId});

  @override
  State<_SettingsContent> createState() => _SettingsContentState();
}

class _SettingsContentState extends State<_SettingsContent> {
  final _tagController = TextEditingController();
  final _nameController = TextEditingController();
  Color _pickerColor = const Color(0xFF2563EB);

  @override
  void dispose() {
    _tagController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _showAddTagDialog(BuildContext context, AppState appState, String projectId) {
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: const Text('Add Global Tag'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _tagController,
                      decoration: const InputDecoration(
                        labelText: 'Tag Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Select Color:'),
                    const SizedBox(height: 8),
                    BlockPicker(
                      pickerColor: _pickerColor,
                      onColorChanged: (c) {
                        setStateDialog(() => _pickerColor = c);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel', style: TextStyle(color: Colors.black54)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
                  onPressed: () {
                    if (_tagController.text.trim().isNotEmpty) {
                      final hex = '#${_pickerColor.value.toRadixString(16).substring(2).toUpperCase()}';
                      appState.createTag(name: _tagController.text.trim(), color: hex, projectId: projectId);
                      _tagController.clear();
                      _pickerColor = const Color(0xFF2563EB);
                      Navigator.pop(ctx);
                    }
                  },
                  child: const Text('Add Tag', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditNameDialog(BuildContext context, AppState appState, String currentName) {
    _nameController.text = currentName;
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Edit Profile Name'),
          content: TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Name',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.black54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
              onPressed: () async {
                if (_nameController.text.trim().isNotEmpty) {
                  final newName = _nameController.text.trim();
                  // We'll add updateUserName to AppState
                  await appState.updateUserName(newName);
                  if (mounted) {
                    Navigator.pop(ctx);
                  }
                }
              },
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final user = appState.currentUser;
    final projectId = widget.selectedProjectId;
    final isManager = projectId != null && appState.isManagerOfProject(projectId);
    final tags = appState.tagsForProject(projectId);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Page Header ─────────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Settings',
                style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
              ),
              if (isManager)
                ElevatedButton.icon(
                  onPressed: () => _showAddTagDialog(context, appState, projectId!),
                  icon: const Icon(Icons.add, color: Colors.white, size: 20),
                  label: const Text('Add Tag', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 32),

          // ── Profile Card ─────────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Profile', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Avatar
                    _ProfileAvatar(user: user),
                    const SizedBox(width: 24),
                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                user?.name ?? 'User',
                                style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.edit, size: 16, color: Color(0xFF94A3B8)),
                                onPressed: () => _showEditNameDialog(context, appState, user?.name ?? ''),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.email ?? '',
                            style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: isManager ? const Color(0xFFEFF6FF) : const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              isManager ? '⭐ Manager' : '👤 Member',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isManager ? const Color(0xFF2563EB) : const Color(0xFF16A34A),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Logout Button
                    ElevatedButton.icon(
                      onPressed: () => appState.logout(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[50],
                        foregroundColor: Colors.red[600],
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: Colors.red[200]!),
                        ),
                      ),
                      icon: const Icon(Icons.logout_rounded, size: 18),
                      label: Text('Log Out', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // ── Tags Section ─────────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Project Tags',
                style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
              ),
              if (!isManager)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber[200]!),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_outline, size: 14, color: Colors.amber[700]),
                      const SizedBox(width: 6),
                      Text(
                        'Only Managers can manage tags',
                        style: GoogleFonts.inter(fontSize: 12, color: Colors.amber[800]),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            projectId == null 
              ? 'Select a project from the sidebar to view its tags.'
              : 'Manage tags that can be applied to tasks in this project.',
            style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF64748B)),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: tags.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text('No tags yet.', style: TextStyle(color: Color(0xFF94A3B8)))),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: tags.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final tag = tags[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        leading: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(color: tag.parsedColor, shape: BoxShape.circle),
                        ),
                        title: Text(tag.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        trailing: isManager
                            ? IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () => appState.deleteTag(tag.id),
                              )
                            : null,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  final ApiUser? user;
  const _ProfileAvatar({required this.user});

  @override
  Widget build(BuildContext context) {
    if (user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty) {
      return CircleAvatar(radius: 40, backgroundImage: NetworkImage(user!.avatarUrl!));
    }
    final name = user?.name ?? 'U';
    final initials = name.trim().split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase();
    final colors = [
      const Color(0xFF2563EB), const Color(0xFF7C3AED), const Color(0xFF0D9488),
      const Color(0xFFD97706), const Color(0xFFDC2626), const Color(0xFF4F46E5),
    ];
    final colorIndex = name.codeUnits.fold(0, (a, b) => a + b) % colors.length;
    return CircleAvatar(
      radius: 40,
      backgroundColor: colors[colorIndex],
      child: Text(initials, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
    );
  }
}
