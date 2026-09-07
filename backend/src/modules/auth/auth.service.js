const prisma = require('../../config/db');

/**
 * Get all users with their assigned tasks
 */
const getAllUsers = async () => {
  return prisma.user.findMany({
    include: {
      assignedTasks: {
        include: { project: true },
        orderBy: { createdAt: 'desc' },
      },
      projects: true,
    },
    orderBy: { createdAt: 'asc' },
  });
};

/**
 * Get a single user by id
 */
const getUserById = async (id) => {
  return prisma.user.findUnique({
    where: { id },
    include: {
      assignedTasks: {
        include: { project: true },
        orderBy: { createdAt: 'desc' },
      },
      projects: true,
    },
  });
};

/**
 * Create a new user (team member)
 */
const createUser = async ({ name, email, role, avatarUrl, avatarColor }) => {
  return prisma.user.create({
    data: { name, email, role, avatarUrl, avatarColor },
  });
};

/**
 * Update a user
 */
const updateUser = async (id, data) => {
  return prisma.user.update({ where: { id }, data });
};

/**
 * Delete a user
 */
const deleteUser = async (id) => {
  return prisma.user.delete({ where: { id } });
};

module.exports = { getAllUsers, getUserById, createUser, updateUser, deleteUser };
