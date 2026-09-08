const express = require('express');
const router = express.Router();
const prisma = require('../../config/db');

/**
 * GET /api/stats?projectId=xxx
 * Returns task counts by status + member workload for dashboard
 */
router.get('/', async (req, res, next) => {
  try {
    const { projectId } = req.query;
    const where = projectId ? { projectId } : {};

    const [total, todo, inProgress, done, members] = await Promise.all([
      prisma.task.count({ where }),
      prisma.task.count({ where: { ...where, status: 'TO_DO' } }),
      prisma.task.count({ where: { ...where, status: 'IN_PROGRESS' } }),
      prisma.task.count({ where: { ...where, status: 'DONE' } }),
      prisma.user.findMany({
        include: {
          assignedTasks: {
            where,
            select: { id: true, status: true },
          },
        },
      }),
    ]);

    const memberWorkload = members.map((m) => ({
      id: m.id,
      name: m.name,
      role: m.role,
      avatarUrl: m.avatarUrl,
      total: m.assignedTasks.length,
      todo: m.assignedTasks.filter((t) => t.status === 'TO_DO').length,
      inProgress: m.assignedTasks.filter((t) => t.status === 'IN_PROGRESS').length,
      done: m.assignedTasks.filter((t) => t.status === 'DONE').length,
    }));

    res.json({ total, todo, inProgress, done, memberWorkload });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
