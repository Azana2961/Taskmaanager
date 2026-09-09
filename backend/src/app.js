const express = require('express');
const cors = require('cors');
const cookieParser = require('cookie-parser');
const session = require('express-session');
const passport = require('./config/passport');

const oauthRoutes = require('./modules/auth/oauth.routes');
const userRoutes = require('./modules/auth/auth.routes');
const taskRoutes = require('./modules/tasks/task.routes');
const projectRoutes = require('./modules/projects/project.routes');
const statsRoutes = require('./modules/stats/stats.routes');
const tagRoutes = require('./modules/tags/tag.routes');
const invitationRoutes = require('./modules/invitations/invitation.routes');

const app = express();

// ── Middleware ──────────────────────────────────────────────────────────────
app.use(cors({ 
  origin: process.env.CLIENT_URL || 'http://localhost:8080', 
  credentials: true 
}));
app.use(express.json());
app.use(cookieParser());
app.use(session({
  secret: process.env.SESSION_SECRET || 'fallback_session_secret',
  resave: false,
  saveUninitialized: false,
}));
app.use(passport.initialize());
app.use(passport.session());

// ── Health check ────────────────────────────────────────────────────────────
app.get('/', (req, res) => {
  res.json({ status: 'ok', message: 'TaskSync API is running 🚀' });
});

const { requireAuth } = require('./middlewares/auth.middleware');

// ── Routes ──────────────────────────────────────────────────────────────────
app.use('/api/auth', oauthRoutes);
app.use('/api/users', requireAuth, userRoutes);
app.use('/api/tasks', requireAuth, taskRoutes);
app.use('/api/projects', requireAuth, projectRoutes);
app.use('/api/stats', requireAuth, statsRoutes);
app.use('/api/tags', requireAuth, tagRoutes);
app.use('/api/invitations', requireAuth, invitationRoutes);

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
