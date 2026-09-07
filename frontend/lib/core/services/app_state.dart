import 'package:flutter/material.dart';
import 'api_service.dart';

/// Central state for the TaskSync app.
/// All screens consume this via Provider / context.watch<AppState>().
class AppState extends ChangeNotifier {
  // ── Raw data from API ─────────────────────────────────────────────────────
  List<ApiProject> _projects = [];
  List<ApiUser> _users = [];
  List<ApiTask> _tasks = [];
  List<ApiTag> _tags = [];
  ApiStats _stats = ApiStats(total: 0, todo: 0, inProgress: 0, done: 0);

  bool _loading = true;
  String? _error;

  // ── Public getters ────────────────────────────────────────────────────────
  List<ApiProject> get projects => _projects;
  List<ApiUser> get users => _users;
  List<ApiTask> get tasks => _tasks;
  List<ApiTag> get tags => _tags;
  ApiStats get stats => _stats;
  bool get loading => _loading;
  String? get error => _error;

  // ── Filtered helpers ──────────────────────────────────────────────────────

  List<ApiTask> tasksForProject(String? projectId) {
    if (projectId == null) return _tasks;
    return _tasks.where((t) => t.projectId == projectId).toList();
  }

  List<ApiUser> membersForProject(String? projectId) {
    if (projectId == null) return _users;
    try {
      final project = _projects.firstWhere((p) => p.id == projectId);
      final memberIds = project.members.map((m) => m.id).toSet();
      return _users.where((u) => memberIds.contains(u.id)).toList();
    } catch (_) {
      return [];
    }
  }

  ApiProject? projectById(String? id) {
    if (id == null) return null;
    try {
      return _projects.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  ApiUser? userById(String? id) {
    if (id == null) return null;
    try {
      return _users.firstWhere((u) => u.id == id);
    } catch (_) {
      return null;
    }
  }

  // ── Boot load ─────────────────────────────────────────────────────────────

  Future<void> loadAll() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        ApiService.getProjects(),
        ApiService.getUsers(),
        ApiService.getTasks(),
        ApiService.getStats(),
        ApiService.getTags(),
      ]);
      _projects = results[0] as List<ApiProject>;
      _users = results[1] as List<ApiUser>;
      _tasks = results[2] as List<ApiTask>;
      _stats = results[3] as ApiStats;
      _tags = results[4] as List<ApiTag>;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ── Task mutations ────────────────────────────────────────────────────────

  Future<void> createTask({
    required String title,
    required String description,
    required String status,
    required List<String> tagIds,
    required String priority,
    required String dueDate,
    required String projectId,
    String? assigneeId,
  }) async {
    // Optimistic UI update
    final tempId = DateTime.now().millisecondsSinceEpoch.toString();
    
    // Find matching tags for optimistic UI rendering
    final selectedTags = _tags.where((t) => tagIds.contains(t.id)).toList();

    final optimisticTask = ApiTask(
      id: tempId,
      title: title,
      description: description,
      status: status,
      tags: selectedTags,
      priority: priority,
      dueDate: dueDate,
      projectId: projectId,
      assigneeId: assigneeId,
    );
    _tasks.add(optimisticTask);
    notifyListeners();

    // Background API sync
    ApiService.createTask(
      title: title,
      description: description,
      status: status,
      tagIds: tagIds,
      priority: priority,
      dueDate: dueDate,
      projectId: projectId,
      assigneeId: assigneeId,
    ).then((newTask) {
      final idx = _tasks.indexWhere((t) => t.id == tempId);
      if (idx != -1) {
        _tasks[idx] = newTask;
        notifyListeners();
      }
      _refreshStats();
    }).catchError((_) {
      // Revert if API call fails
      _tasks.removeWhere((t) => t.id == tempId);
      notifyListeners();
    });
  }

  Future<void> updateTaskStatus(String taskId, String status) async {
    // Optimistic update
    final idx = _tasks.indexWhere((t) => t.id == taskId);
    if (idx != -1) {
      _tasks[idx] = ApiTask(
        id: _tasks[idx].id,
        title: _tasks[idx].title,
        description: _tasks[idx].description,
        status: status,
        tags: _tasks[idx].tags,
        priority: _tasks[idx].priority,
        dueDate: _tasks[idx].dueDate,
        projectId: _tasks[idx].projectId,
        assigneeId: _tasks[idx].assigneeId,
      );
      notifyListeners();
    }
    // Background API sync
    ApiService.updateTaskStatus(taskId, status).then((_) {
      _refreshStats();
      _refreshUsers();
    }).catchError((_) {});
  }

  Future<void> assignTask(String taskId, String? assigneeId) async {
    // Optimistic update
    final idx = _tasks.indexWhere((t) => t.id == taskId);
    if (idx != -1) {
      _tasks[idx] = ApiTask(
        id: _tasks[idx].id,
        title: _tasks[idx].title,
        description: _tasks[idx].description,
        status: assigneeId != null ? 'TO_DO' : 'TO_DO',
        tags: _tasks[idx].tags,
        priority: _tasks[idx].priority,
        dueDate: _tasks[idx].dueDate,
        projectId: _tasks[idx].projectId,
        assigneeId: assigneeId,
      );
      notifyListeners();
    }
    ApiService.assignTask(taskId, assigneeId).then((_) {
      _refreshUsers();
    }).catchError((_) {});
  }

  Future<void> finishProject(String projectId) async {
    // Optimistic
    for (int i = 0; i < _tasks.length; i++) {
      if (_tasks[i].projectId == projectId) {
        _tasks[i] = ApiTask(
          id: _tasks[i].id,
          title: _tasks[i].title,
          description: _tasks[i].description,
          status: 'DONE',
          tags: _tasks[i].tags,
          priority: _tasks[i].priority,
          dueDate: _tasks[i].dueDate,
          projectId: _tasks[i].projectId,
          assigneeId: _tasks[i].assigneeId,
        );
      }
    }
    notifyListeners();
    ApiService.finishProject(projectId).then((_) {
      _refreshStats();
      _refreshUsers();
    }).catchError((_) {});
  }

  // ── Tag mutations ─────────────────────────────────────────────────────────

  Future<void> createTag({required String name, required String color}) async {
    final tag = await ApiService.createTag(name: name, color: color);
    _tags.add(tag);
    notifyListeners();
  }

  Future<void> updateTag(String id, {required String name, required String color}) async {
    final updated = await ApiService.updateTag(id, name: name, color: color);
    final idx = _tags.indexWhere((t) => t.id == id);
    if (idx != -1) _tags[idx] = updated;
    notifyListeners();
  }

  Future<void> deleteTag(String id) async {
    _tags.removeWhere((t) => t.id == id);
    notifyListeners();
    ApiService.deleteTag(id).then((_) {
      _refreshTasks(); // reload tasks to strip deleted tag
    }).catchError((_) {});
  }

  // ── Project mutations ─────────────────────────────────────────────────────

  Future<ApiProject> createProject({
    required String name,
    required String colorCode,
    required List<String> memberIds,
  }) async {
    final project = await ApiService.createProject(
      name: name,
      colorCode: colorCode,
      memberIds: memberIds,
    );
    _projects.add(project);
    notifyListeners();
    return project;
  }

  Future<void> addMemberToProject(String projectId, String userId) async {
    final updated = await ApiService.addMemberToProject(projectId, userId);
    final idx = _projects.indexWhere((p) => p.id == projectId);
    if (idx != -1) _projects[idx] = updated;
    notifyListeners();
  }

  Future<void> removeMemberFromProject(String projectId, String userId) async {
    final updated = await ApiService.removeMemberFromProject(projectId, userId);
    final idx = _projects.indexWhere((p) => p.id == projectId);
    if (idx != -1) _projects[idx] = updated;
    notifyListeners();
  }

  // ── Private refresh helpers ───────────────────────────────────────────────

  Future<void> _refreshTasks() async {
    _tasks = await ApiService.getTasks();
    notifyListeners();
  }

  Future<void> _refreshStats() async {
    _stats = await ApiService.getStats();
    notifyListeners();
  }

  Future<void> _refreshUsers() async {
    _users = await ApiService.getUsers();
    notifyListeners();
  }
}
