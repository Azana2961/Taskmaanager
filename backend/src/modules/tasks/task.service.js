const prisma = require('../../config/db');

const include = {
  project: true,
  assignee: true,
  tags: true,
};

/**
 * Get all tasks, optionally filtered by projectId
 */
const getAllTasks = async (projectId) => {
  return prisma.task.findMany({
    where: projectId ? { projectId } : {},
    include,
    orderBy: { createdAt: 'asc' },
  });
};

/**
 * Get a task by id
 */
const getTaskById = async (id) => {
  return prisma.task.findUnique({ where: { id }, include });
};

/**
 * Create a new task
 */
const createTask = async ({ title, description, status, tagIds, priority, dueDate, projectId, assigneeId }) => {
  return prisma.task.create({
    data: {
      title,
      description: description || '',
      status: status || 'TO_DO',
      priority: priority || 'Medium',
      dueDate: dueDate ? new Date(dueDate) : null,
      projectId,
      assigneeId: assigneeId || null,
      tags: tagIds && tagIds.length > 0 ? { connect: tagIds.map(id => ({ id })) } : undefined,
    },
    include,
  });
};

/**
 * Update a task (full or partial update)
 */
const updateTask = async (id, data) => {
  const updateData = { ...data };
  if (data.dueDate) updateData.dueDate = new Date(data.dueDate);
  if (data.tagIds !== undefined) {
    updateData.tags = { set: data.tagIds.map(tagId => ({ id: tagId })) };
    delete updateData.tagIds;
  }
  return prisma.task.update({ where: { id }, data: updateData, include });
};

/**
 * Update only the status of a task
 */
const updateTaskStatus = async (id, status) => {
  return prisma.task.update({ where: { id }, data: { status }, include });
};

/**
 * Assign a task to a user
 */
const assignTask = async (id, assigneeId) => {
  return prisma.task.update({
    where: { id },
    data: {
      assigneeId,
      status: assigneeId ? 'TO_DO' : 'TO_DO',
    },
    include,
  });
};

/**
 * Delete a task
 */
const deleteTask = async (id) => {
  return prisma.task.delete({ where: { id } });
};

/**
 * Mark all tasks in a project as DONE
 */
const finishProject = async (projectId) => {
  return prisma.task.updateMany({
    where: {
      projectId,
      status: { not: 'DONE' },
    },
    data: { status: 'DONE' },
  });
};

module.exports = {
  getAllTasks,
  getTaskById,
  createTask,
  updateTask,
  updateTaskStatus,
  assignTask,
  deleteTask,
  finishProject,
};
