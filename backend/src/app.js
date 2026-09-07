const express = require('express');
const cors = require('cors');

const userRoutes = require('./modules/auth/auth.routes');
const taskRoutes = require('./modules/tasks/task.routes');
const projectRoutes = require('./modules/projects/project.routes');
const statsRoutes = require('./modules/stats/stats.routes');
const tagRoutes = require('./modules/tags/tag.routes');

const app = express();

// ── Middleware ──────────────────────────────────────────────────────────────
app.use(cors());
app.use(express.json());

// ── Health check ────────────────────────────────────────────────────────────
app.get('/', (req, res) => {
  res.json({ status: 'ok', message: 'TaskSync API is running 🚀' });
});

// ── Routes ──────────────────────────────────────────────────────────────────
app.use('/api/users', userRoutes);
app.use('/api/tasks', taskRoutes);
app.use('/api/projects', projectRoutes);
app.use('/api/stats', statsRoutes);
app.use('/api/tags', tagRoutes);

// ── 404 handler ─────────────────────────────────────────────────────────────
app.use((req, res) => {
  res.status(404).json({ error: 'Route not found' });
});

// ── Global error handler ─────────────────────────────────────────────────────
app.use((err, req, res, next) => {
  console.error('[Error]', err);
  res.status(500).json({ error: err.message || 'Internal server error' });
});

module.exports = app;
