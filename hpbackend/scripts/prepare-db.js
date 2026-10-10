// Runs before the server starts (see "start" in package.json).
// 1. Syncs the database tables with prisma/schema.prisma.
// 2. Creates the first Admin from BOOTSTRAP_ADMIN_* if none exists yet.
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

// The Super Admin role was removed: its accounts become Admins (which now have
// every Admin permission). Must run before `db push`, which would
// otherwise refuse to drop the SUPER_ADMIN enum value while rows still use it.
const migrateSuperAdmins = async () => {
  if (!process.env.DATABASE_URL) return;
  const { PrismaClient } = require('@prisma/client');
  const prisma = new PrismaClient();
  try {
    const moved = await prisma.$executeRawUnsafe("UPDATE `users` SET `role` = 'ADMIN' WHERE `role` = 'SUPER_ADMIN'");
    if (moved > 0) console.log(`[prepare-db] Converted ${moved} Super Admin account(s) to Admin.`);
    // `db push` refuses to drop an enum value without --accept-data-loss, so
    // drop it here, now that no row uses it. Only touches the old enum shape.
    const cols = await prisma.$queryRawUnsafe("SHOW COLUMNS FROM `users` LIKE 'role'");
    if (cols[0] && String(cols[0].Type).includes('SUPER_ADMIN')) {
      await prisma.$executeRawUnsafe(
        "ALTER TABLE `users` MODIFY `role` ENUM('ADMIN','BRANCH_MANAGER','BRANCH_STAFF','KITCHEN_STAFF','RIDER','WAITER','CUSTOMER') NOT NULL DEFAULT 'CUSTOMER'"
      );
      console.log('[prepare-db] Removed SUPER_ADMIN from the users.role column.');
    }
  } catch (err) {
    // Fresh database (no users table yet) or already migrated — nothing to do.
  } finally {
    await prisma.$disconnect();
  }
};

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

const bootstrapAdmin = async () => {
  const phone = (process.env.BOOTSTRAP_ADMIN_PHONE || '').trim();
  const password = process.env.BOOTSTRAP_ADMIN_PASSWORD || '';

  const { PrismaClient } = require('@prisma/client');
  const bcrypt = require('bcryptjs');
  const prisma = new PrismaClient();
  try {
    const existing = await prisma.user.count({ where: { role: 'ADMIN' } });
    if (!phone || !password) {
      if (existing === 0) {
        console.warn('[prepare-db] No Admin exists and BOOTSTRAP_ADMIN_PHONE / BOOTSTRAP_ADMIN_PASSWORD are not set — nobody can log in to /admin yet.');
      }
      return;
    }
    if (password.length < 10) {
      console.error('[prepare-db] BOOTSTRAP_ADMIN_PASSWORD must be at least 10 characters — Admin not created.');
      return;
    }
    if (existing > 0) {
      console.log('[prepare-db] A Admin already exists — bootstrap skipped (you can remove the BOOTSTRAP_ADMIN_* secrets).');
      return;
    }
    const taken = await prisma.user.findUnique({ where: { phone } });
    if (taken) {
      console.error(`[prepare-db] ${phone} is already used by a ${taken.role} account — Admin not created.`);
      return;
    }
    await prisma.user.create({
      data: {
        name: process.env.BOOTSTRAP_ADMIN_NAME || 'Administrator',
        phone,
        email: (process.env.BOOTSTRAP_ADMIN_EMAIL || '').trim().toLowerCase() || undefined,
        password: await bcrypt.hash(password, 12),
        role: 'ADMIN',
        isVerified: true,
      },
    });
    console.log(`[prepare-db] Admin created for ${phone}. Log in at /admin, then remove the BOOTSTRAP_ADMIN_* secrets.`);
  } catch (err) {
    console.error('[prepare-db] Admin bootstrap failed:', err.message || err);
  } finally {
    await prisma.$disconnect();
  }
};

(async () => {
  await migrateSuperAdmins();
  if (syncSchema()) await bootstrapAdmin();
})().finally(() => process.exit(0));
