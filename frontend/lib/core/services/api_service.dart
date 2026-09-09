import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Base URL of the TaskSync backend.
/// Change this if deploying to a remote server.
const String _baseUrl = 'https://taskmaanager.onrender.com/api';

// ─────────────────────────────────────────────────────────────────────────────
// Lightweight API models (match backend JSON exactly)
// ─────────────────────────────────────────────────────────────────────────────

class ApiTag {
  final String id;
  final String name;
  final String color;
  final String? projectId;

  ApiTag({required this.id, required this.name, required this.color, this.projectId});

  factory ApiTag.fromJson(Map<String, dynamic> json) => ApiTag(
        id: json['id'] as String,
        name: json['name'] as String,
        color: json['color'] as String,
        projectId: json['projectId'] as String?,
      );

  Color get parsedColor {
    try {
      final hex = color.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return const Color(0xFF2563EB);
    }
  }
}

class ApiTask {
  final String id;
  final String title;
  final String description;
  final String status; // TO_DO | IN_PROGRESS | DONE
  final List<ApiTag> tags;
  final String priority;
  final String? dueDate;
  final String projectId;
  final String? assigneeId;
  ApiTask? _dummy;

  ApiTask({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.tags,
    required this.priority,
    this.dueDate,
    required this.projectId,
    this.assigneeId,
  });

  factory ApiTask.fromJson(Map<String, dynamic> j) => ApiTask(
        id: j['id'] as String,
        title: j['title'] as String,
        description: (j['description'] as String?) ?? '',
        status: j['status'] as String,
        tags: (j['tags'] as List<dynamic>?)
                ?.map((t) => ApiTag.fromJson(t as Map<String, dynamic>))
                .toList() ??
            [],
        priority: (j['priority'] as String?) ?? 'Medium',
        dueDate: j['dueDate'] as String?,
        projectId: j['projectId'] as String,
        assigneeId: j['assigneeId'] as String?,
      );

  /// Formatted due date for display (e.g. "Sep 10")
  String get formattedDue {
    if (dueDate == null) return 'No date';
    try {
      final dt = DateTime.parse(dueDate!).toLocal();
      const months = [
        'Jan','Feb','Mar','Apr','May','Jun',
        'Jul','Aug','Sep','Oct','Nov','Dec'
      ];
      return '${months[dt.month - 1]} ${dt.day}';
    } catch (_) {
      return dueDate!;
    }
  }
}

class ApiUser {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? avatarUrl;
  final String? avatarColor;
  final List<ApiTask> assignedTasks;
  final List<ApiProject> projects;

  ApiUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.avatarUrl,
    this.avatarColor,
    required this.assignedTasks,
    required this.projects,
  });

  factory ApiUser.fromJson(Map<String, dynamic> j) => ApiUser(
        id: j['id'] as String,
        name: j['name'] as String,
        email: j['email'] as String,
        role: (j['role'] as String?) ?? 'Member',
        avatarUrl: j['avatarUrl'] as String?,
        avatarColor: (j['avatarColor'] as String?) ?? '#2563EB',
        assignedTasks: (j['assignedTasks'] as List<dynamic>?)
                ?.map((t) => ApiTask.fromJson(t as Map<String, dynamic>))
                .toList() ??
            [],
        projects: (j['projects'] as List<dynamic>?)
                ?.map((p) => ApiProject.fromJson(p as Map<String, dynamic>))
                .toList() ??
            [],
      );

  Color get color {
    try {
      final hex = (avatarColor ?? '#2563EB').replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return const Color(0xFF2563EB);
    }
  }
}

class ApiProject {
  final String id;
  final String name;
  final String? colorCode;
  final String? ownerId;
  final List<ApiUser> members;
  final List<ApiTask> tasks;

  ApiProject({
    required this.id,
    required this.name,
    this.colorCode,
    this.ownerId,
    required this.members,
    required this.tasks,
  });

  factory ApiProject.fromJson(Map<String, dynamic> j) => ApiProject(
        id: j['id'] as String,
        name: j['name'] as String,
        colorCode: j['colorCode'] as String?,
        ownerId: j['ownerId'] as String?,
        members: (j['members'] as List<dynamic>?)
                ?.map((m) => ApiUser.fromJson(m as Map<String, dynamic>))
                .toList() ??
            [],
        tasks: (j['tasks'] as List<dynamic>?)
                ?.map((t) => ApiTask.fromJson(t as Map<String, dynamic>))
                .toList() ??
            [],
      );

  Color get color {
    try {
      final hex = (colorCode ?? '#2563EB').replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return const Color(0xFF2563EB);
    }
  }
}

class ApiStats {
  final int total;
  final int todo;
  final int inProgress;
  final int done;

  ApiStats({
    required this.total,
    required this.todo,
    required this.inProgress,
    required this.done,
  });

  factory ApiStats.fromJson(Map<String, dynamic> j) => ApiStats(
        total: (j['total'] as num).toInt(),
        todo: (j['todo'] as num).toInt(),
        inProgress: (j['inProgress'] as num).toInt(),
        done: (j['done'] as num).toInt(),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Project Invitation Model
// ─────────────────────────────────────────────────────────────────────────────

class ProjectInvitation {
  final String id;
  final String projectId;
  final String projectName;
  final String inviterId;
  final String inviterName;
  final String status; // PENDING | ACCEPTED | DECLINED
  final DateTime createdAt;

  ProjectInvitation({
    required this.id,
    required this.projectId,
    required this.projectName,
    required this.inviterId,
    required this.inviterName,
    required this.status,
    required this.createdAt,
  });

  factory ProjectInvitation.fromJson(Map<String, dynamic> j) => ProjectInvitation(
        id: j['id'] as String,
        projectId: j['projectId'] as String,
        projectName: (j['project'] as Map<String, dynamic>?)?['name'] as String? ?? '',
        inviterId: j['inviterId'] as String,
        inviterName: (j['inviter'] as Map<String, dynamic>?)?['name'] as String? ?? 'Manager',
        status: j['status'] as String,
        createdAt: DateTime.parse(j['createdAt'] as String),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// API Service
// ─────────────────────────────────────────────────────────────────────────────

class ApiService {
  static final _client = http.Client();
  static String? _token;

  static void setToken(String token) => _token = token;
  static void clearToken() => _token = null;

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  // ─────────────────────────────────────────────────────────────────────────────
  // Auth
  // ─────────────────────────────────────────────────────────────────────────────

  static Future<ApiUser?> checkAuth() async {
    if (_token == null) return null;
    final res = await _client.get(Uri.parse('$_baseUrl/auth/me'), headers: _headers);
    if (res.statusCode == 200) {
      return ApiUser.fromJson(jsonDecode(res.body));
    }
    return null;
  }

  static Future<void> logout() async {
    await _client.post(Uri.parse('$_baseUrl/auth/logout'), headers: _headers);
    _token = null;
  }

  static Future<ApiUser> updateUser(String id, String name) async {
    final res = await _client.put(
      Uri.parse('$_baseUrl/users/$id'),
      headers: _headers,
      body: jsonEncode({'name': name}),
    );
    _check(res);
    return ApiUser.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  // ── Tags ──────────────────────────────────────────────────────────────────

  static Future<List<ApiTag>> getTags() async {
    final res = await _client.get(Uri.parse('$_baseUrl/tags'), headers: _headers);
    _check(res);
    return (jsonDecode(res.body) as List)
        .map((j) => ApiTag.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  static Future<ApiTag> createTag({required String name, required String color, required String projectId}) async {
    final res = await _client.post(
      Uri.parse('$_baseUrl/tags'),
      headers: _headers,
      body: jsonEncode({'name': name, 'color': color, 'projectId': projectId}),
    );
    _check(res);
    return ApiTag.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  static Future<ApiTag> updateTag(String id, {required String name, required String color}) async {
    final res = await _client.patch(
      Uri.parse('$_baseUrl/tags/$id'),
      headers: _headers,
      body: jsonEncode({'name': name, 'color': color}),
    );
    _check(res);
    return ApiTag.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  static Future<void> deleteTag(String id) async {
    final res = await _client.delete(Uri.parse('$_baseUrl/tags/$id'), headers: _headers);
    _check(res);
  }

  // ── Users ─────────────────────────────────────────────────────────────────

  static Future<List<ApiUser>> getUsers() async {
    final res = await _client.get(Uri.parse('$_baseUrl/users'), headers: _headers);
    _check(res);
    return (jsonDecode(res.body) as List)
        .map((j) => ApiUser.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  // ── Projects ──────────────────────────────────────────────────────────────

  static Future<List<ApiProject>> getProjects() async {
    final res = await _client.get(Uri.parse('$_baseUrl/projects'), headers: _headers);
    _check(res);
    return (jsonDecode(res.body) as List)
        .map((j) => ApiProject.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  static Future<ApiProject> createProject({
    required String id,
    required String name,
    required String colorCode,
    required List<String> memberIds,
  }) async {
    final res = await _client.post(
      Uri.parse('$_baseUrl/projects'),
      headers: _headers,
      body: jsonEncode({'id': id, 'name': name, 'colorCode': colorCode, 'memberIds': memberIds}),
    );
    _check(res);
    return ApiProject.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  static Future<ApiProject> addMemberToProject(String projectId, String userId) async {
    final res = await _client.post(
      Uri.parse('$_baseUrl/projects/$projectId/members'),
      headers: _headers,
      body: jsonEncode({'userId': userId}),
    );
    _check(res);
    return ApiProject.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  static Future<ApiProject> removeMemberFromProject(String projectId, String userId) async {
    final res = await _client.delete(
      Uri.parse('$_baseUrl/projects/$projectId/members/$userId'),
      headers: _headers,
    );
    _check(res);
    return ApiProject.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  static Future<ApiProject> finishProject(String projectId) async {
    final res = await _client.patch(
      Uri.parse('$_baseUrl/projects/$projectId/finish'),
      headers: _headers,
    );
    _check(res);
    return ApiProject.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  static Future<ApiProject> updateProject(String projectId, Map<String, dynamic> data) async {
    final res = await _client.put(
      Uri.parse('$_baseUrl/projects/$projectId'),
      headers: _headers,
      body: jsonEncode(data),
    );
    _check(res);
    return ApiProject.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  static Future<void> deleteProject(String projectId) async {
    final res = await _client.delete(
      Uri.parse('$_baseUrl/projects/$projectId'),
      headers: _headers,
    );
    _check(res);
  }

  // ── Tasks ─────────────────────────────────────────────────────────────────

  static Future<List<ApiTask>> getTasks({String? projectId}) async {
    final uri = projectId != null
        ? Uri.parse('$_baseUrl/tasks?projectId=$projectId')
        : Uri.parse('$_baseUrl/tasks');
    final res = await _client.get(uri, headers: _headers);
    _check(res);
    return (jsonDecode(res.body) as List)
        .map((j) => ApiTask.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  static Future<ApiTask> createTask({
    required String title,
    required String description,
    required String status,
    required List<String> tagIds,
    required String priority,
    required String dueDate,
    required String projectId,
    String? assigneeId,
  }) async {
    final res = await _client.post(
      Uri.parse('$_baseUrl/tasks'),
      headers: _headers,
      body: jsonEncode({
        'title': title,
        'description': description,
        'status': status,
        'tagIds': tagIds,
        'priority': priority,
        'dueDate': dueDate,
        'projectId': projectId,
        if (assigneeId != null) 'assigneeId': assigneeId,
      }),
    );
    _check(res);
    return ApiTask.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  static Future<ApiTask> updateTaskStatus(String taskId, String status) async {
    final res = await _client.patch(
      Uri.parse('$_baseUrl/tasks/$taskId/status'),
      headers: _headers,
      body: jsonEncode({'status': status}),
    );
    _check(res);
    return ApiTask.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  static Future<ApiTask> assignTask(String taskId, String? assigneeId) async {
    final res = await _client.patch(
      Uri.parse('$_baseUrl/tasks/$taskId/assign'),
      headers: _headers,
      body: jsonEncode({'assigneeId': assigneeId}),
    );
    _check(res);
    return ApiTask.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  // ── Stats ─────────────────────────────────────────────────────────────────

  static Future<ApiStats> getStats({String? projectId}) async {
    final uri = projectId != null
        ? Uri.parse('$_baseUrl/stats?projectId=$projectId')
        : Uri.parse('$_baseUrl/stats');
    final res = await _client.get(uri, headers: _headers);
    _check(res);
    return ApiStats.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static void _check(http.Response res) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('API error ${res.statusCode}: ${res.body}');
    }
  }

  // ── Invitations ───────────────────────────────────────────────────────────

  static Future<List<ProjectInvitation>> getMyInvitations() async {
    final res = await _client.get(Uri.parse('$_baseUrl/invitations/mine'), headers: _headers);
    if (res.statusCode == 404) return []; // route not set up yet
    _check(res);
    return (jsonDecode(res.body) as List)
        .map((j) => ProjectInvitation.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  static Future<void> sendInvitation({required String projectId, required String inviteeId}) async {
    final res = await _client.post(
      Uri.parse('$_baseUrl/invitations'),
      headers: _headers,
      body: jsonEncode({'projectId': projectId, 'inviteeId': inviteeId}),
    );
    _check(res);
  }

  static Future<void> sendInvitationByEmail(String projectId, String email) async {
    final res = await _client.post(
      Uri.parse('$_baseUrl/invitations'),
      headers: _headers,
      body: jsonEncode({'projectId': projectId, 'email': email}),
    );
    _check(res);
  }

  static Future<void> respondInvitation(String id, String status) async {
    final res = await _client.patch(
      Uri.parse('$_baseUrl/invitations/$id'),
      headers: _headers,
      body: jsonEncode({'status': status}),
    );
    _check(res);
  }
}
