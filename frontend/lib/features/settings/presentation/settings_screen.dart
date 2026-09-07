import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/app_state.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/widgets/sidebar.dart';
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
          const Expanded(
            child: _SettingsContent(),
          ),
        ],
      ),
    );
  }
}

class _SettingsContent extends StatefulWidget {
  const _SettingsContent();

  @override
  State<_SettingsContent> createState() => _SettingsContentState();
}

class _SettingsContentState extends State<_SettingsContent> {
  final _tagController = TextEditingController();
  Color _pickerColor = const Color(0xFF2563EB);

  @override
  void dispose() {
    _tagController.dispose();
    super.dispose();
  }

  void _showAddTagDialog(BuildContext context, AppState appState) {
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
                      appState.createTag(name: _tagController.text.trim(), color: hex);
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

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final tags = appState.tags;

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Settings',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddTagDialog(context, appState),
                icon: const Icon(Icons.add, color: Colors.white, size: 20),
                label: const Text('Add Global Tag', style: TextStyle(color: Colors.white)),
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
          const Text(
            'Global Tags',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Manage tags that can be applied to tasks across all projects.',
            style: TextStyle(color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: ListView.separated(
                itemCount: tags.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final tag = tags[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    leading: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: tag.parsedColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    title: Text(tag.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => appState.deleteTag(tag.id),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
