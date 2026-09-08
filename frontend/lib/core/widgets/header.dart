import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../services/api_service.dart';

class Header extends StatelessWidget {
  final String? selectedProjectId;
  const Header({super.key, this.selectedProjectId});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final user = appState.currentUser;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
      ),
      child: Row(
        children: [
          // Search Bar
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const TextField(
                decoration: InputDecoration(
                  hintText: 'Search tasks, projects...',
                  hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                  prefixIcon: Icon(Icons.search, color: Color(0xFF94A3B8), size: 20),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Inbox / Notifications Icon
          _InboxButton(appState: appState),

          const SizedBox(width: 8),

          // User Profile
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    user?.name ?? 'User',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
                  ),
                  Text(
                    appState.isManagerOfProject(selectedProjectId) ? 'Project Manager' : (user?.role ?? 'Member'),
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              _UserAvatar(user: user),
            ],
          ),
        ],
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  final ApiUser? user;
  const _UserAvatar({required this.user});

  @override
  Widget build(BuildContext context) {
    if (user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 18,
        backgroundImage: NetworkImage(user!.avatarUrl!),
        backgroundColor: const Color(0xFFE2E8F0),
      );
    }
    // Initials fallback
    final name = user?.name ?? 'U';
    final initials = name.trim().split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase();
    final colors = [
      const Color(0xFF2563EB), const Color(0xFF7C3AED), const Color(0xFF0D9488),
      const Color(0xFFD97706), const Color(0xFFDC2626), const Color(0xFF4F46E5),
    ];
    final colorIndex = name.codeUnits.fold(0, (a, b) => a + b) % colors.length;
    return CircleAvatar(
      radius: 18,
      backgroundColor: colors[colorIndex],
      child: Text(initials, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
    );
  }
}

class _InboxButton extends StatelessWidget {
  final AppState appState;
  const _InboxButton({required this.appState});

  @override
  Widget build(BuildContext context) {
    final pendingInvites = appState.pendingInvitations;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          tooltip: 'Inbox',
          icon: const Icon(Icons.inbox_outlined, color: Color(0xFF64748B), size: 22),
          onPressed: () => _showInboxPanel(context, appState),
        ),
        if (pendingInvites.isNotEmpty)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              width: 16,
              height: 16,
              decoration: const BoxDecoration(color: Color(0xFFDC2626), shape: BoxShape.circle),
              child: Center(
                child: Text(
                  '${pendingInvites.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _showInboxPanel(BuildContext context, AppState appState) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        alignment: Alignment.topRight,
        insetPadding: const EdgeInsets.only(top: 60, right: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: SizedBox(
          width: 360,
          child: _InboxPanel(appState: appState),
        ),
      ),
    );
  }
}

class _InboxPanel extends StatelessWidget {
  final AppState appState;
  const _InboxPanel({required this.appState});

  @override
  Widget build(BuildContext context) {
    final invites = appState.pendingInvitations;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Inbox', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const Divider(),
          if (invites.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.mark_email_read_outlined, size: 40, color: Color(0xFF94A3B8)),
                    SizedBox(height: 8),
                    Text('No pending invitations', style: TextStyle(color: Color(0xFF64748B))),
                  ],
                ),
              ),
            )
          else
            ...invites.map((inv) => _InviteCard(invitation: inv, appState: appState)),
        ],
      ),
    );
  }
}

class _InviteCard extends StatelessWidget {
  final ProjectInvitation invitation;
  final AppState appState;
  const _InviteCard({required this.invitation, required this.appState});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.folder_outlined, size: 16, color: Color(0xFF2563EB)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'You\'ve been invited to join "${invitation.projectName}"',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF1E293B)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('From: ${invitation.inviterName}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    appState.acceptInvitation(invitation.id);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  child: const Text('Accept', style: TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    appState.declineInvitation(invitation.id);
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red[600],
                    side: BorderSide(color: Colors.red[200]!),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  child: const Text('Decline', style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
