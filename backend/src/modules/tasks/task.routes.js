const express = require('express');
const router = express.Router();
const ctrl = require('./task.controller');

// GET /api/tasks?projectId=xxx
router.get('/', ctrl.getAll);

// GET /api/tasks/:id
router.get('/:id', ctrl.getById);

// POST /api/tasks
router.post('/', ctrl.create);

// PUT /api/tasks/:id  (full update)
router.put('/:id', ctrl.update);

// PATCH /api/tasks/:id/status  (status only)
router.patch('/:id/status', ctrl.updateStatus);

// PATCH /api/tasks/:id/assign
router.patch('/:id/assign', ctrl.assign);

// DELETE /api/tasks/:id
router.delete('/:id', ctrl.remove);

module.exports = router;
