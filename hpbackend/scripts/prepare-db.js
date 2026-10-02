// Runs before the server starts (see "start" in package.json).
// 1. Syncs the database tables with prisma/schema.prisma.
// 2. Creates the first Super Admin from BOOTSTRAP_ADMIN_* if none exists yet.
// Hosts like GoDaddy's Node.js apps give no terminal, so this is how an empty
// production database gets set up. Failures are logged but never stop the
// server from starting.

require('dotenv/config');
const { spawnSync } = require('child_process');
const path = require('path');

// Same composition as src/config/database.ts, for hosts that inject DB_* only.
if (process.env.DB_HOST) {
  const user = encodeURIComponent(process.env.DB_USER || '');
  const password = encodeURIComponent(process.env.DB_PASSWORD || '');
  const port = process.env.DB_PORT || '3306';
  process.env.DATABASE_URL = `mysql://${user}:${password}@${process.env.DB_HOST}:${port}/${process.env.DB_NAME || ''}`;
}

const syncSchema = () => {
  if (!process.env.DATABASE_URL) {
    console.warn('[prepare-db] No DATABASE_URL or DB_HOST set — skipping schema sync.');
    return false;
  }
  let prismaCli;
  try {
    prismaCli = require.resolve('prisma/build/index.js');
  } catch {
    console.warn('[prepare-db] Prisma CLI not installed — skipping schema sync.');
    return false;
  }
  console.log('[prepare-db] Syncing database schema…');
  // No --accept-data-loss: a change that would drop data fails instead.
  const result = spawnSync(process.execPath, [prismaCli, 'db', 'push', '--skip-generate'], {
    cwd: path.join(__dirname, '..'),
    stdio: 'inherit',
    env: process.env,
  });
  if (result.status !== 0) {
    console.error('[prepare-db] Schema sync failed — the server will still start. Check the log above.');
    return false;
  }
  return true;
};

const bootstrapSuperAdmin = async () => {
  const phone = (process.env.BOOTSTRAP_ADMIN_PHONE || '').trim();
  const password = process.env.BOOTSTRAP_ADMIN_PASSWORD || '';

  const { PrismaClient } = require('@prisma/client');
  const bcrypt = require('bcryptjs');
  const prisma = new PrismaClient();
  try {
    const existing = await prisma.user.count({ where: { role: 'SUPER_ADMIN' } });
    if (!phone || !password) {
      if (existing === 0) {
        console.warn('[prepare-db] No Super Admin exists and BOOTSTRAP_ADMIN_PHONE / BOOTSTRAP_ADMIN_PASSWORD are not set — nobody can log in to /admin yet.');
      }
      return;
    }
    if (password.length < 10) {
      console.error('[prepare-db] BOOTSTRAP_ADMIN_PASSWORD must be at least 10 characters — Super Admin not created.');
      return;
    }
    if (existing > 0) {
      console.log('[prepare-db] A Super Admin already exists — bootstrap skipped (you can remove the BOOTSTRAP_ADMIN_* secrets).');
      return;
    }
    const taken = await prisma.user.findUnique({ where: { phone } });
    if (taken) {
      console.error(`[prepare-db] ${phone} is already used by a ${taken.role} account — Super Admin not created.`);
      return;
    }
    await prisma.user.create({
      data: {
        name: process.env.BOOTSTRAP_ADMIN_NAME || 'Super Administrator',
        phone,
        email: (process.env.BOOTSTRAP_ADMIN_EMAIL || '').trim().toLowerCase() || undefined,
        password: await bcrypt.hash(password, 12),
        role: 'SUPER_ADMIN',
        isVerified: true,
      },
    });
    console.log(`[prepare-db] Super Admin created for ${phone}. Log in at /admin, then remove the BOOTSTRAP_ADMIN_* secrets.`);
  } catch (err) {
    console.error('[prepare-db] Super Admin bootstrap failed:', err.message || err);
  } finally {
    await prisma.$disconnect();
  }
};

(async () => {
  if (syncSchema()) await bootstrapSuperAdmin();
})().finally(() => process.exit(0));
