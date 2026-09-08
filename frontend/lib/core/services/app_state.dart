import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'api_service.dart';
import 'package:uuid/uuid.dart';

/// Central state for the TaskSync app.
/// All screens consume this via Provider / context.watch<AppState>().
class AppState extends ChangeNotifier {
  // ── Raw data from API ─────────────────────────────────────────────────────
  List<ApiProject> _projects = [];
  List<ApiUser> _users = [];
  List<ApiTask> _tasks = [];
  List<ApiTag> _tags = [];
  ApiStats _stats = ApiStats(total: 0, todo: 0, inProgress: 0, done: 0);
  List<ProjectInvitation> _invitations = [];

  bool _loading = true;
  String? _error;
  ApiUser? _currentUser;
  List<ProjectInvitation> _pendingInvitations = [];

  // ── Public getters ────────────────────────────────────────────────────────
  List<ApiProject> get projects => _projects;
  List<ApiUser> get users => _users;
  List<ApiTask> get tasks => _tasks;
  List<ApiTag> get tags => _tags;
  ApiStats get stats => _stats;
  bool get loading => _loading;
  String? get error => _error;
  ApiUser? get currentUser => _currentUser;
  List<ProjectInvitation> get pendingInvitations => _pendingInvitations;
  List<ProjectInvitation> get invitations => _invitations;

  /// Checks if the current user is the owner (manager) of the given project ID
  bool isManagerOfProject(String? projectId) {
    if (projectId == null || _currentUser == null) return false;
    try {
      final project = _projects.firstWhere((p) => p.id == projectId);
      return project.ownerId == _currentUser!.id;
    } catch (e) {
      return false;
    }
  }

  /// Checks if the current user owns *any* project (e.g. for global permissions like Tags)
  bool get isManagerOfAnyProject {
    if (_currentUser == null) return false;
    return _projects.any((p) => p.ownerId == _currentUser!.id);
  }

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

  List<ApiTag> tagsForProject(String? projectId) {
    if (projectId == null) return [];
    return _tags.where((t) => t.projectId == projectId || t.projectId == null).toList();
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

  Future<void> checkAuth(String? token) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      if (token != null) ApiService.setToken(token);
      _currentUser = await ApiService.checkAuth();
      // If null is returned with a token, the token is invalid — clear it
      if (_currentUser == null && token != null) {
        html.window.localStorage.remove('auth_token');
        ApiService.clearToken();
      }
    } catch (e) {
      // Only surface the error if it's a real connectivity issue
      if (_isConnectionError(e)) {
        _error = 'connection_failed';
      }
      // For 401/other HTTP errors: user is simply not logged in — no error shown
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await ApiService.logout();
    _currentUser = null;
    html.window.localStorage.remove('auth_token');
    notifyListeners();
  }

  Future<void> updateUserName(String newName) async {
    if (_currentUser == null) return;
    try {
      final updatedUser = await ApiService.updateUser(_currentUser!.id, newName);
      _currentUser = updatedUser;
      
      // Update user in the _users list if present
      final idx = _users.indexWhere((u) => u.id == _currentUser!.id);
      if (idx != -1) {
        _users[idx] = updatedUser;
      }
      notifyListeners();
    } catch (e) {
      print('Failed to update name: $e');
    }
  }

  Future<void> loadAll({int attempt = 0}) async {
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
        ApiService.getMyInvitations(),
      ]);
      _projects = results[0] as List<ApiProject>;
      _users = results[1] as List<ApiUser>;
      _tasks = results[2] as List<ApiTask>;
      _stats = results[3] as ApiStats;
      _tags = results[4] as List<ApiTag>;
      _invitations = results[5] as List<ProjectInvitation>;
      _pendingInvitations = _invitations.where((i) => i.status == 'PENDING').toList();
      _error = null;
    } catch (e) {
      if (_isConnectionError(e) && attempt < 3) {
        // Auto-retry with backoff: 1s, 2s, 3s
        await Future.delayed(Duration(seconds: attempt + 1));
        return loadAll(attempt: attempt + 1);
      }
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  bool _isConnectionError(Object e) {
    final msg = e.toString().toLowerCase();
    return msg.contains('failed host lookup') ||
        msg.contains('connection refused') ||
        msg.contains('socketexception') ||
        msg.contains('network is unreachable') ||
        msg.contains('connection timed out') ||
        msg.contains('xmlhttprequest error') ||
        msg.contains('os error');
  }

  /// Re-fetches the current user from /auth/me to pick up role changes.
  Future<void> refreshUserRole() async {
    try {
      _currentUser = await ApiService.checkAuth();
      notifyListeners();
    } catch (_) {}
  }

  // ── Invitation actions ────────────────────────────────────────────────────

  Future<void> acceptInvitation(String id) async {
    await ApiService.respondInvitation(id, 'ACCEPTED');
    _invitations = _invitations.map((i) => i.id == id
        ? ProjectInvitation(id: i.id, projectId: i.projectId, projectName: i.projectName,
            inviterId: i.inviterId, inviterName: i.inviterName, status: 'ACCEPTED', createdAt: i.createdAt)
        : i).toList();
    _pendingInvitations.removeWhere((i) => i.id == id);
    // Reload data to get the new project
    await loadAll();
  }

  Future<void> declineInvitation(String id) async {
    await ApiService.respondInvitation(id, 'DECLINED');
    _invitations = _invitations.map((i) => i.id == id
        ? ProjectInvitation(id: i.id, projectId: i.projectId, projectName: i.projectName,
            inviterId: i.inviterId, inviterName: i.inviterName, status: 'DECLINED', createdAt: i.createdAt)
        : i).toList();
    _pendingInvitations.removeWhere((i) => i.id == id);
    notifyListeners();
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

  Future<void> createTag({required String name, required String color, required String projectId}) async {
    final tag = await ApiService.createTag(name: name, color: color, projectId: projectId);
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
    const uuid = Uuid();
    final realId = uuid.v4();
    
    // Find the current user and selected members for optimistic rendering
    final members = _users.where((u) => memberIds.contains(u.id) || u.id == _currentUser?.id).toSet().toList();
    
    final optimisticProject = ApiProject(
      id: realId,
      name: name,
      colorCode: colorCode,
      ownerId: _currentUser?.id,
      members: members,
      tasks: [],
    );
    
    _projects.add(optimisticProject);
    notifyListeners();

    // Background sync
    ApiService.createProject(
      id: realId,
      name: name,
      colorCode: colorCode,
      memberIds: memberIds,
    ).then((savedProject) {
      final idx = _projects.indexWhere((p) => p.id == realId);
      if (idx != -1) {
        _projects[idx] = savedProject;
        // Update selectedProjectId in UI if necessary by notifying listeners again
        notifyListeners();
      }
    }).catchError((_) {
      _projects.removeWhere((p) => p.id == realId);
      notifyListeners();
    });

    return optimisticProject;
  }

  Future<void> sendInvitation({required String projectId, required String inviteeId}) async {
    await ApiService.sendInvitation(projectId: projectId, inviteeId: inviteeId);
  }

  Future<void> inviteUserByEmail(String projectId, String email) async {
    await ApiService.sendInvitationByEmail(projectId, email);
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
    
    if (idx != -1) {
      if (_currentUser != null && _currentUser!.id == userId) {
        // Current user was removed/left, so they can no longer access this project
        _projects.removeAt(idx);
        _tasks.removeWhere((t) => t.projectId == projectId);
      } else {
        _projects[idx] = updated;
      }
    }
    notifyListeners();
  }

  Future<void> transferManagerRole(String projectId, String newOwnerId) async {
    final updated = await ApiService.updateProject(projectId, {'ownerId': newOwnerId});
    final idx = _projects.indexWhere((p) => p.id == projectId);
    if (idx != -1) _projects[idx] = updated;
    notifyListeners();
  }

  Future<void> deleteProject(String projectId) async {
    await ApiService.deleteProject(projectId);
    _projects.removeWhere((p) => p.id == projectId);
    _tasks.removeWhere((t) => t.projectId == projectId);
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
