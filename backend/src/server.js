require('dotenv').config();
const app = require('./app');

const PORT = process.env.PORT || 5000;

app.listen(PORT, () => {
  console.log(`✅ TaskSync API server running on http://localhost:${PORT}`);
});

// Trigger nodemon restart

// Trigger nodemon restart after env change

// Force nodemon restart again for Prisma Client

// Force nodemon restart for project-specific tags
