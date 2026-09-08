const express = require('express');
const router = express.Router();
const ctrl = require('./project.controller');

// GET /api/projects
router.get('/', ctrl.getAll);

// POST /api/projects
router.post('/', ctrl.create);

// GET /api/projects/:id
router.get('/:id', ctrl.getById);

// PUT /api/projects/:id
router.put('/:id', ctrl.update);

// PATCH /api/projects/:id/finish  — mark all tasks as DONE
router.patch('/:id/finish', ctrl.finishProject);

// POST /api/projects/:id/members  — add a member
router.post('/:id/members', ctrl.addMember);

// DELETE /api/projects/:id/members/:userId  — remove a member
router.delete('/:id/members/:userId', ctrl.removeMember);

// DELETE /api/projects/:id
router.delete('/:id', ctrl.remove);

module.exports = router;
