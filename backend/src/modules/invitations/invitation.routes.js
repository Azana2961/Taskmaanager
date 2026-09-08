const express = require('express');
const prisma = require('../../config/db');
const { requireAuth } = require('../../middlewares/auth.middleware');

const router = express.Router();

// GET /api/invitations/mine  — Get current user's pending invitations
router.get('/mine', requireAuth, async (req, res) => {
  try {
    const invitations = await prisma.projectInvitation.findMany({
      where: { inviteeId: req.user.id, status: 'PENDING' },
      include: {
        project: { select: { id: true, name: true, colorCode: true } },
        inviter: { select: { id: true, name: true, avatarUrl: true } },
      },
      orderBy: { createdAt: 'desc' },
    });
    res.json(invitations);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to fetch invitations' });
  }
});

// POST /api/invitations  — Manager sends an invitation to a user
router.post('/', requireAuth, async (req, res) => {
  try {
    const { projectId, inviteeId, email } = req.body;

    if (!projectId) {
      return res.status(400).json({ error: 'projectId is required' });
    }
    if (!inviteeId && !email) {
      return res.status(400).json({ error: 'inviteeId or email is required' });
    }

    // Make sure the inviter is a member of the project (or is a Manager)
    const project = await prisma.project.findFirst({
      where: { id: projectId, members: { some: { id: req.user.id } } },
    });
    if (!project) {
      return res.status(403).json({ error: 'You are not a member of this project' });
    }
    
    let targetInviteeId = inviteeId;
    if (!targetInviteeId && email) {
      const targetUser = await prisma.user.findUnique({ where: { email } });
      if (!targetUser) {
        return res.status(404).json({ error: 'User not found with that email' });
      }
      targetInviteeId = targetUser.id;
    }

    // Avoid duplicate pending invitations
    const existing = await prisma.projectInvitation.findFirst({
      where: { projectId, inviteeId: targetInviteeId, status: 'PENDING' },
    });
    if (existing) {
      return res.status(409).json({ error: 'Invitation already pending' });
    }

    // Avoid if already member
    const alreadyMember = await prisma.project.findFirst({
      where: { id: projectId, members: { some: { id: targetInviteeId } } },
    });
    if (alreadyMember) {
      return res.status(409).json({ error: 'User is already a member of this project' });
    }

    const invitation = await prisma.projectInvitation.create({
      data: {
        projectId,
        inviterId: req.user.id,
        inviteeId: targetInviteeId,
        status: 'PENDING',
      },
      include: {
        project: { select: { id: true, name: true } },
        inviter: { select: { id: true, name: true } },
      },
    });

    res.status(201).json(invitation);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to send invitation' });
  }
});

// PATCH /api/invitations/:id  — Accept or decline an invitation
router.patch('/:id', requireAuth, async (req, res) => {
  try {
    const { id } = req.params;
    const { status } = req.body;

    if (!['ACCEPTED', 'DECLINED'].includes(status)) {
      return res.status(400).json({ error: 'status must be ACCEPTED or DECLINED' });
    }

    const invitation = await prisma.projectInvitation.findFirst({
      where: { id, inviteeId: req.user.id },
    });

    if (!invitation) {
      return res.status(404).json({ error: 'Invitation not found' });
    }

    if (invitation.status !== 'PENDING') {
      return res.status(409).json({ error: 'Invitation already responded to' });
    }

    // If accepted, add the user to the project
    if (status === 'ACCEPTED') {
      await prisma.project.update({
        where: { id: invitation.projectId },
        data: { members: { connect: { id: req.user.id } } },
      });
    }

    const updated = await prisma.projectInvitation.update({
      where: { id },
      data: { status },
      include: {
        project: { select: { id: true, name: true } },
        inviter: { select: { id: true, name: true } },
      },
    });

    res.json(updated);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to respond to invitation' });
  }
});

module.exports = router;
