import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../services/api_service.dart';
import 'create_project_dialog.dart';

class Sidebar extends StatefulWidget {
  const Sidebar({
    super.key,
    this.activeItem = 'Dashboard',
    this.selectedProjectId,
    this.onNavTap,
    this.onProjectTap,
    this.onProjectAdded,
  });

  final String activeItem;
  final String? selectedProjectId;
  final void Function(String item)? onNavTap;
  final void Function(String? projectId)? onProjectTap;
  final void Function(ApiProject project)? onProjectAdded;

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> with SingleTickerProviderStateMixin {
  bool _collapsed = false;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  late final AnimationController _animController;
  late final Animation<double> _widthAnim;

  static const double _expandedWidth = 250;
  static const double _collapsedWidth = 64;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 220));
    _widthAnim = Tween<double>(begin: _expandedWidth, end: _collapsedWidth)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _animController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _toggleCollapse() {
    setState(() => _collapsed = !_collapsed);
    if (_collapsed) {
      _animController.forward();
    } else {
      _animController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isManagerOfCurrentProject = appState.isManagerOfProject(widget.selectedProjectId);

    return AnimatedBuilder(
      animation: _widthAnim,
      builder: (context, child) {
        return Container(
          width: _widthAnim.value,
          color: const Color(0xFF1E1F25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Logo + Toggle ──────────────────────────────────────────────
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                child: SizedBox(
                  width: _expandedWidth,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.check, color: Colors.white, size: 20),
                        ),
                        if (!_collapsed) ...[
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'TaskSync',
                              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.clip,
                            ),
                          ),
                        ],
                        if (!_collapsed) const SizedBox(width: 4),
                        // Toggle button
                        InkWell(
                          onTap: _toggleCollapse,
                          borderRadius: BorderRadius.circular(6),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              _collapsed ? Icons.chevron_right_rounded : Icons.chevron_left_rounded,
                              color: Colors.white54,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // ── Navigation Items ───────────────────────────────────────────
              if (isManagerOfCurrentProject) _buildNavItem(Icons.dashboard_outlined, 'Dashboard'),
              _buildNavItem(Icons.check_circle_outline, 'My Tasks'),
              if (isManagerOfCurrentProject) _buildNavItem(Icons.people_outline, 'Team'),
              _buildNavItem(Icons.settings_outlined, 'Settings'),

              const SizedBox(height: 24),

              // ── Projects Section ───────────────────────────────────────────
              if (!_collapsed)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'PROJECTS',
                        style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2),
                      ),
                      Tooltip(
                        message: 'Add Project',
                        child: InkWell(
                          borderRadius: BorderRadius.circular(6),
                          onTap: () => _showCreateProject(context),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(Icons.add, color: Colors.white70, size: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              if (_collapsed)
                Tooltip(
                  message: 'Add Project',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: () => _showCreateProject(context),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.add, color: Colors.white70, size: 20),
                    ),
                  ),
                ),

              if (!_collapsed)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Container(
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Search projects...',
                        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 13),
                        prefixIcon: Icon(Icons.search, color: Colors.white.withValues(alpha: 0.5), size: 16),
                        prefixIconConstraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                    ),
                  ),
                ),

              // Projects list
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: appState.projects
                      .where((p) => _searchQuery.isEmpty || p.name.toLowerCase().contains(_searchQuery))
                      .map((p) => _buildProjectItem(appState, p))
                      .toList(),
                ),
              ),

              // ── Bottom section ─────────────────────────────────────────────
              if (!_collapsed)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.white.withValues(alpha: 0.0), Colors.white.withValues(alpha: 0.05)],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Team Size', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                        widget.selectedProjectId == null
                            ? 'No project selected'
                            : '${appState.projectById(widget.selectedProjectId)?.members.length ?? 0} Members',
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showCreateProject(BuildContext context) async {
    final result = await CreateProjectDialog.show(
      context,
      onProjectCreated: (proj) {
        widget.onProjectAdded?.call(proj);
        widget.onProjectTap?.call(proj.id);
      },
    );
    if (result != null && widget.onProjectTap != null) {
      widget.onProjectTap!(result.id);
    }
  }

  Widget _buildNavItem(IconData icon, String title) {
    final isActive = widget.activeItem == title;

    if (_collapsed) {
      return Tooltip(
        message: title,
        preferBelow: false,
        child: InkWell(
          onTap: widget.onNavTap != null ? () => widget.onNavTap!(title) : null,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isActive ? Colors.white.withValues(alpha: 0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: isActive ? Colors.white : Colors.white54, size: 20),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? Colors.white.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(icon, color: isActive ? Colors.white : Colors.white54, size: 20),
        title: Text(
          title,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white54,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            fontSize: 14,
          ),
        ),
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        onTap: widget.onNavTap != null ? () => widget.onNavTap!(title) : null,
      ),
    );
  }

  Widget _buildProjectItem(AppState appState, ApiProject project) {
    final isActive = widget.selectedProjectId == project.id;
    final tasks = appState.tasksForProject(project.id);
    final isFinished = tasks.isNotEmpty && tasks.every((t) => t.status == 'DONE');

    if (_collapsed) {
      return Tooltip(
        message: project.name,
        preferBelow: false,
        child: InkWell(
          onTap: widget.onProjectTap != null ? () => widget.onProjectTap!(project.id) : null,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isActive ? Colors.white.withValues(alpha: 0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: project.color, shape: BoxShape.circle),
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: isActive ? Colors.white.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Container(width: 8, height: 8, decoration: BoxDecoration(color: project.color, shape: BoxShape.circle)),
        title: Row(
          children: [
            Expanded(
              child: Text(
                project.name,
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.white54,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isFinished)
              Container(
                margin: const EdgeInsets.only(left: 4),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('DONE', style: TextStyle(color: Colors.green, fontSize: 9, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        onTap: widget.onProjectTap != null ? () => widget.onProjectTap!(project.id) : null,
      ),
    );
  }
}
