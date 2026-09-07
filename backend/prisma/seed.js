require('dotenv').config();
const { Pool } = require('pg');
const { PrismaPg } = require('@prisma/adapter-pg');
const { PrismaClient } = require('@prisma/client');

const pool = new Pool({ connectionString: process.env.DATABASE_URL });
const adapter = new PrismaPg(pool);
const prisma = new PrismaClient({ adapter });


async function main() {
  console.log('🌱 Seeding TaskSync database...\n');

  // ── Clean existing data ────────────────────────────────────────────────────
  await prisma.task.deleteMany();
  await prisma.tag.deleteMany();
  await prisma.project.deleteMany();
  await prisma.user.deleteMany();
  console.log('✅ Cleared existing data');

  // ── Tags ───────────────────────────────────────────────────────────────────
  const tagsList = [
    { name: 'Dev', color: '#2563EB' },
    { name: 'Design', color: '#7C3AED' },
    { name: 'Bug', color: '#EA580C' },
    { name: 'Marketing', color: '#4F46E5' },
    { name: 'QA', color: '#DB2777' },
    { name: 'Docs', color: '#0D9488' }
  ];
  const createdTags = await Promise.all(tagsList.map(t => prisma.tag.create({ data: t })));
  const tagMap = {};
  createdTags.forEach(t => tagMap[t.name] = t.id);
  console.log('✅ Created 6 global tags');

  // ── Users / Team Members ───────────────────────────────────────────────────
  const alex = await prisma.user.create({
    data: {
      name: 'Alex Johnson',
      email: 'alex@tasksync.dev',
      role: 'Frontend Developer',
      avatarUrl: 'https://i.pravatar.cc/150?img=3',
      avatarColor: '#2563EB',
    },
  });

  const sarah = await prisma.user.create({
    data: {
      name: 'Sarah Miller',
      email: 'sarah@tasksync.dev',
      role: 'UX Designer',
      avatarUrl: 'https://i.pravatar.cc/150?img=5',
      avatarColor: '#7C3AED',
    },
  });

  const james = await prisma.user.create({
    data: {
      name: 'James Carter',
      email: 'james@tasksync.dev',
      role: 'Backend Developer',
      avatarUrl: 'https://i.pravatar.cc/150?img=12',
      avatarColor: '#059669',
    },
  });

  const priya = await prisma.user.create({
    data: {
      name: 'Priya Nair',
      email: 'priya@tasksync.dev',
      role: 'QA Engineer',
      avatarUrl: 'https://i.pravatar.cc/150?img=16',
      avatarColor: '#DB2777',
    },
  });

  console.log('✅ Created 4 team members');

  // ── Projects ────────────────────────────────────────────────────────────────
  const websiteRedesign = await prisma.project.create({
    data: {
      name: 'Website Redesign',
      colorCode: '#2563EB',
      members: { connect: [{ id: alex.id }, { id: sarah.id }] },
    },
  });

  const q4Marketing = await prisma.project.create({
    data: {
      name: 'Q4 Marketing',
      colorCode: '#7C3AED',
      members: { connect: [{ id: sarah.id }, { id: priya.id }] },
    },
  });

  const mobileApp = await prisma.project.create({
    data: {
      name: 'Mobile App',
      colorCode: '#059669',
      members: { connect: [{ id: alex.id }, { id: james.id }, { id: priya.id }] },
    },
  });

  console.log('✅ Created 3 projects');

  // ── Tasks ───────────────────────────────────────────────────────────────────
  const tasksData = [
    // Website Redesign — Alex
    {
      title: 'Build dashboard components',
      description: 'Create the main layout components for the new dashboard.',
      tags: { connect: [{ id: tagMap['Dev'] }] },
      priority: 'High',
      dueDate: new Date('2026-09-10'),
      status: 'IN_PROGRESS',
      projectId: websiteRedesign.id,
      assigneeId: alex.id,
    },
    {
      title: 'Implement dark mode toggle',
      description: 'Add a switch for dark mode in the header.',
      tags: { connect: [{ id: tagMap['Design'] }] },
      priority: 'Low',
      dueDate: new Date('2026-09-08'),
      status: 'DONE',
      projectId: websiteRedesign.id,
      assigneeId: alex.id,
    },
    // Website Redesign — Sarah
    {
      title: 'Design new landing page hero',
      description: 'Create a modern hero section for the marketing site.',
      tags: { connect: [{ id: tagMap['Design'] }] },
      priority: 'Medium',
      dueDate: new Date('2026-09-14'),
      status: 'TO_DO',
      projectId: websiteRedesign.id,
      assigneeId: sarah.id,
    },
    // Q4 Marketing — Sarah
    {
      title: 'Create onboarding wireframes',
      description: 'Design wireframes for the new user onboarding flow.',
      tags: { connect: [{ id: tagMap['Design'] }] },
      priority: 'High',
      dueDate: new Date('2026-09-09'),
      status: 'IN_PROGRESS',
      projectId: q4Marketing.id,
      assigneeId: sarah.id,
    },
    // Q4 Marketing — Priya
    {
      title: 'Write end-to-end test cases',
      description: 'Create test scenarios for the new checkout flow.',
      tags: { connect: [{ id: tagMap['QA'] }] },
      priority: 'Medium',
      dueDate: new Date('2026-09-13'),
      status: 'TO_DO',
      projectId: q4Marketing.id,
      assigneeId: priya.id,
    },
    // Mobile App — Alex
    {
      title: 'Fix mobile responsive layout',
      description: 'Ensure the layout works on small screens.',
      tags: { connect: [{ id: tagMap['Bug'] }] },
      priority: 'Medium',
      dueDate: new Date('2026-09-12'),
      status: 'TO_DO',
      projectId: mobileApp.id,
      assigneeId: alex.id,
    },
    // Mobile App — James
    {
      title: 'Set up CI/CD pipeline',
      description: 'Configure GitHub Actions for automated builds.',
      tags: { connect: [{ id: tagMap['Dev'] }] },
      priority: 'High',
      dueDate: new Date('2026-09-11'),
      status: 'DONE',
      projectId: mobileApp.id,
      assigneeId: james.id,
    },
    {
      title: 'Write API documentation',
      description: 'Document all REST endpoints for the v2 API.',
      tags: { connect: [{ id: tagMap['Docs'] }] },
      priority: 'Low',
      dueDate: new Date('2026-09-18'),
      status: 'TO_DO',
      projectId: mobileApp.id,
      assigneeId: james.id,
    },
    {
      title: 'Implement authentication flow',
      description: 'Build JWT-based auth with refresh tokens.',
      tags: { connect: [{ id: tagMap['Dev'] }] },
      priority: 'High',
      dueDate: new Date('2026-09-07'),
      status: 'IN_PROGRESS',
      projectId: mobileApp.id,
      assigneeId: james.id,
    },
  ];

  await Promise.all(tasksData.map(data => prisma.task.create({ data })));
  console.log(`✅ Created ${tasksData.length} tasks`);

  console.log('\n🎉 Seeding complete! Database is ready.');
}

main()
  .catch((err) => {
    console.error('❌ Seeding failed:', err);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
