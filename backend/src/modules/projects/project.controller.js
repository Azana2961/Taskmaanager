const projectService = require('./project.service');

const getAll = async (req, res, next) => {
  try {
    const projects = await projectService.getAllProjects();
    res.json(projects);
  } catch (err) {
    next(err);
  }
};

const getById = async (req, res, next) => {
  try {
    const project = await projectService.getProjectById(req.params.id);
    if (!project) return res.status(404).json({ error: 'Project not found' });
    res.json(project);
  } catch (err) {
    next(err);
  }
};

const create = async (req, res, next) => {
  try {
    const { name, colorCode, memberIds } = req.body;
    if (!name) return res.status(400).json({ error: 'name is required' });
    const project = await projectService.createProject({ name, colorCode, memberIds });
    res.status(201).json(project);
  } catch (err) {
    next(err);
  }
};

const update = async (req, res, next) => {
  try {
    const project = await projectService.updateProject(req.params.id, req.body);
    res.json(project);
  } catch (err) {
    next(err);
  }
};

const addMember = async (req, res, next) => {
  try {
    const { userId } = req.body;
    if (!userId) return res.status(400).json({ error: 'userId is required' });
    const project = await projectService.addMember(req.params.id, userId);
    res.json(project);
  } catch (err) {
    next(err);
  }
};

const removeMember = async (req, res, next) => {
  try {
    const project = await projectService.removeMember(req.params.id, req.params.userId);
    res.json(project);
  } catch (err) {
    next(err);
  }
};

const finishProject = async (req, res, next) => {
  try {
    const project = await projectService.finishProject(req.params.id);
    res.json(project);
  } catch (err) {
    next(err);
  }
};

const remove = async (req, res, next) => {
  try {
    await projectService.deleteProject(req.params.id);
    res.json({ message: 'Project deleted' });
  } catch (err) {
    next(err);
  }
};

module.exports = { getAll, getById, create, update, addMember, removeMember, finishProject, remove };
