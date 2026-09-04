// ============================================================
// HungerPoint Backend — Entry Point
// ============================================================

import app from './app';
import { createServer } from 'http';
import { initSocket } from './sockets';
import { prisma } from './config/database';

const PORT = process.env.PORT || 5000;

const httpServer = createServer(app);

// Initialize Socket.IO
initSocket(httpServer);

// Start server
httpServer.listen(PORT, async () => {
  console.log('');
  console.log('╔══════════════════════════════════════════╗');
  console.log('║         HUNGERPOINT BACKEND              ║');
  console.log('╠══════════════════════════════════════════╣');
  console.log(`║  🚀 Server running on port ${PORT}          ║`);
  console.log(`║  🌍 ENV: ${process.env.NODE_ENV}                  ║`);
  console.log(`║  🗄️  DB:  hungerpointdb                   ║`);
  console.log('╚══════════════════════════════════════════╝');
  console.log('');
});

// Graceful shutdown
process.on('SIGINT', async () => {
  console.log('\n🔴 Shutting down HungerPoint backend...');
  await prisma.$disconnect();
  process.exit(0);
});

process.on('SIGTERM', async () => {
  console.log('\n🔴 Shutting down HungerPoint backend...');
  await prisma.$disconnect();
  process.exit(0);
});
