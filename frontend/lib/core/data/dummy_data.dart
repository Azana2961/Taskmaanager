import 'package:flutter/material.dart';

enum TaskStatus { assigned, inProgress, done }

class Task {
  final String id;
  final String title;
  final String description;
  final String tag;
  final Color tagColor;
  final String priority;
  final String dueDate;
  final String projectId;
  TaskStatus status;
  final double? progress;

  Task({
    required this.id,
    required this.title,
    this.description = '',
    required this.tag,
    required this.tagColor,
    required this.priority,
    required this.dueDate,
    required this.projectId,
    this.status = TaskStatus.assigned,
    this.progress,
  });
}

class TeamMember {
  final String id;
  final String name;
  final String role;
  final String avatarUrl;
  final Color avatarColor;
  List<Task> tasks;

  TeamMember({
    required this.id,
    required this.name,
    required this.role,
    required this.avatarUrl,
    required this.avatarColor,
    required this.tasks,
  });
}

class Project {
  final String id;
  final String name;
  final Color color;
  List<String> memberIds;

  Project({
    required this.id,
    required this.name,
    required this.color,
    required this.memberIds,
  });
}

class DummyData {
  static final List<Project> projects = [
    Project(
      id: 'p1',
      name: 'Website Redesign',
      color: Colors.blue,
      memberIds: ['m1', 'm2'],
    ),
    Project(
      id: 'p2',
      name: 'Q4 Marketing',
      color: Colors.purple,
      memberIds: ['m2', 'm4'],
    ),
    Project(
      id: 'p3',
      name: 'Mobile App',
      color: Colors.green,
      memberIds: ['m1', 'm3', 'm4'],
    ),
  ];

  static final List<TeamMember> members = [
    TeamMember(
      id: 'm1',
      name: 'Alex Johnson',
      role: 'Frontend Developer',
      avatarUrl: 'https://i.pravatar.cc/150?img=3',
      avatarColor: const Color(0xFF2563EB),
      tasks: [
        Task(
          id: 't1',
          projectId: 'p1',
          title: 'Build dashboard components',
          description: 'Create the main layout components for the new dashboard.',
          tag: 'Dev',
          tagColor: Colors.blue,
          priority: 'High',
          dueDate: 'Sep 10',
          status: TaskStatus.inProgress,
          progress: 0.6,
        ),
        Task(
          id: 't2',
          projectId: 'p3',
          title: 'Fix mobile responsive layout',
          description: 'Ensure the layout works on small screens.',
          tag: 'Bug',
          tagColor: Colors.orange,
          priority: 'Medium',
          dueDate: 'Sep 12',
          status: TaskStatus.assigned,
        ),
        Task(
          id: 't3',
          projectId: 'p1',
          title: 'Implement dark mode toggle',
          description: 'Add a switch for dark mode in the header.',
          tag: 'Design',
          tagColor: Colors.purple,
          priority: 'Low',
          dueDate: 'Sep 8',
          status: TaskStatus.done,
        ),
      ],
    ),
    TeamMember(
      id: 'm2',
      name: 'Sarah Miller',
      role: 'UX Designer',
      avatarUrl: 'https://i.pravatar.cc/150?img=5',
      avatarColor: const Color(0xFF7C3AED),
      tasks: [
        Task(
          id: 't4',
          projectId: 'p2',
          title: 'Create onboarding wireframes',
          description: 'Design wireframes for the new user onboarding flow.',
          tag: 'Design',
          tagColor: Colors.purple,
          priority: 'High',
          dueDate: 'Sep 9',
          status: TaskStatus.inProgress,
          progress: 0.4,
        ),
        Task(
          id: 't5',
          projectId: 'p1',
          title: 'Design new landing page hero',
          description: 'Create a modern hero section for the marketing site.',
          tag: 'Design',
          tagColor: Colors.purple,
          priority: 'Medium',
          dueDate: 'Sep 14',
          status: TaskStatus.assigned,
        ),
      ],
    ),
    TeamMember(
      id: 'm3',
      name: 'James Carter',
      role: 'Backend Developer',
      avatarUrl: 'https://i.pravatar.cc/150?img=12',
      avatarColor: const Color(0xFF059669),
      tasks: [
        Task(
          id: 't6',
          projectId: 'p3',
          title: 'Set up CI/CD pipeline',
          description: 'Configure GitHub Actions for automated builds.',
          tag: 'Dev',
          tagColor: Colors.blue,
          priority: 'High',
          dueDate: 'Sep 11',
          status: TaskStatus.done,
        ),
        Task(
          id: 't7',
          projectId: 'p3',
          title: 'Write API documentation',
          description: 'Document all REST endpoints for the v2 API.',
          tag: 'Docs',
          tagColor: Colors.teal,
          priority: 'Low',
          dueDate: 'Sep 18',
          status: TaskStatus.assigned,
        ),
        Task(
          id: 't8',
          projectId: 'p3',
          title: 'Implement authentication flow',
          description: 'Build JWT-based auth with refresh tokens.',
          tag: 'Dev',
          tagColor: Colors.blue,
          priority: 'High',
          dueDate: 'Sep 7',
          status: TaskStatus.inProgress,
          progress: 0.65,
        ),
      ],
    ),
    TeamMember(
      id: 'm4',
      name: 'Priya Nair',
      role: 'QA Engineer',
      avatarUrl: 'https://i.pravatar.cc/150?img=16',
      avatarColor: const Color(0xFFDB2777),
      tasks: [
        Task(
          id: 't9',
          projectId: 'p2',
          title: 'Write end-to-end test cases',
          description: 'Create test scenarios for the new checkout flow.',
          tag: 'QA',
          tagColor: Colors.pink,
          priority: 'Medium',
          dueDate: 'Sep 13',
          status: TaskStatus.assigned,
        ),
      ],
    ),
  ];

  static List<Task> getTasksForProject(String? projectId) {
    if (projectId == null) {
      return members.expand((m) => m.tasks).toList();
    }
    return members
        .expand((m) => m.tasks)
        .where((t) => t.projectId == projectId)
        .toList();
  }

  static List<TeamMember> getMembersForProject(String? projectId) {
    if (projectId == null) {
      return members;
    }
    final project = projects.firstWhere((p) => p.id == projectId);
    return members.where((m) => project.memberIds.contains(m.id)).toList();
  }
}
