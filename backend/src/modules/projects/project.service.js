const prisma = require('../../config/db');
const taskService = require('../tasks/task.service');

const include = {
  members: true,
  tasks: {
    include: { assignee: true },
    orderBy: { createdAt: 'asc' },
  },
};

/**
 * Get all projects with members and tasks
 */
const getAllProjects = async (userId) => {
  return prisma.project.findMany({
    where: {
      OR: [
        { ownerId: userId },
        { members: { some: { id: userId } } }
      ]
    },
    include,
    orderBy: { createdAt: 'asc' }
  });
};

/**
 * Get a single project by id
 */
const getProjectById = async (id) => {
  return prisma.project.findUnique({ where: { id }, include });
};

/**
 * Create a new project and optionally assign initial members
 */
const createProject = async ({ id, name, colorCode, memberIds = [], creatorId }) => {
  const finalMemberIds = Array.from(new Set([...memberIds, creatorId]));
  
  return prisma.$transaction(async (tx) => {
    const project = await tx.project.create({
      data: {
        id,
        name,
        colorCode: colorCode || '#2563EB',
        ownerId: creatorId,
        members: { connect: finalMemberIds.map((id) => ({ id })) },
      },
      include,
    });
    return project;
  }, {
    maxWait: 10000,
    timeout: 20000,
  });
};

/**
 * Update project details
 */
const updateProject = async (id, data) => {
  return prisma.project.update({ where: { id }, data, include });
};

/**
 * Add a member to a project
 */
const addMember = async (projectId, userId) => {
  return prisma.project.update({
    where: { id: projectId },
    data: { members: { connect: { id: userId } } },
    include,
  });
};

/**
 * Remove a member from a project
 */
const removeMember = async (projectId, userId) => {
  return prisma.project.update({
    where: { id: projectId },
    data: { members: { disconnect: { id: userId } } },
    include,
  });
};

/**
 * Finish a project — mark all tasks as DONE
 */
const finishProject = async (projectId) => {
  await taskService.finishProject(projectId);
  return getProjectById(projectId);
};

/**
 * Delete a project
 */
const deleteProject = async (id) => {
  return prisma.project.delete({ where: { id } });
};

module.exports = {
  getAllProjects,
  getProjectById,
  createProject,
  updateProject,
  addMember,
  removeMember,
  finishProject,
  deleteProject,
};
