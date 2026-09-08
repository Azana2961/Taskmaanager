const taskService = require('./task.service');

const getAll = async (req, res, next) => {
  try {
    const { projectId } = req.query;
    const tasks = await taskService.getAllTasks(projectId);
    res.json(tasks);
  } catch (err) {
    next(err);
  }
};

const getById = async (req, res, next) => {
  try {
    const task = await taskService.getTaskById(req.params.id);
    if (!task) return res.status(404).json({ error: 'Task not found' });
    res.json(task);
  } catch (err) {
    next(err);
  }
};

const create = async (req, res, next) => {
  try {
    const { title, projectId } = req.body;
    if (!title || !projectId) {
      return res.status(400).json({ error: 'title and projectId are required' });
    }
    const task = await taskService.createTask(req.body);
    res.status(201).json(task);
  } catch (err) {
    next(err);
  }
};

const update = async (req, res, next) => {
  try {
    const task = await taskService.updateTask(req.params.id, req.body);
    res.json(task);
  } catch (err) {
    next(err);
  }
};

const updateStatus = async (req, res, next) => {
  try {
    const { status } = req.body;
    const validStatuses = ['TO_DO', 'IN_PROGRESS', 'DONE'];
    if (!status || !validStatuses.includes(status)) {
      return res.status(400).json({ error: `status must be one of: ${validStatuses.join(', ')}` });
    }
    const task = await taskService.updateTaskStatus(req.params.id, status);
    res.json(task);
  } catch (err) {
    next(err);
  }
};

const assign = async (req, res, next) => {
  try {
    const { assigneeId } = req.body;
    const task = await taskService.assignTask(req.params.id, assigneeId);
    res.json(task);
  } catch (err) {
    next(err);
  }
};

const remove = async (req, res, next) => {
  try {
    await taskService.deleteTask(req.params.id);
    res.json({ message: 'Task deleted' });
  } catch (err) {
    next(err);
  }
};

module.exports = { getAll, getById, create, update, updateStatus, assign, remove };
