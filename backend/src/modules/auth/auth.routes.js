const express = require('express');
const router = express.Router();
const ctrl = require('./auth.controller');

// GET /api/users
router.get('/', ctrl.getAll);

// GET /api/users/:id
router.get('/:id', ctrl.getById);

// POST /api/users
router.post('/', ctrl.create);

// PUT /api/users/:id
router.put('/:id', ctrl.update);

// DELETE /api/users/:id
router.delete('/:id', ctrl.remove);

module.exports = router;
