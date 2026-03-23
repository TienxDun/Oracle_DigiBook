const express = require('express');
const os = require('os');
const path = require('path');
require('dotenv').config({ path: path.resolve(__dirname, '..', '.env') });

const { closePool, initPool, query } = require('./db');
const adminRoutes = require('./routes/adminRoutes');
const storeRoutes = require('./routes/storeRoutes');

const app = express();
const port = Number(process.env.PORT || 3000);
const maxPortAttempts = 20;
const startedAt = new Date().toISOString();

const runtimeState = {
  preferredPort: port,
  actualPort: null,
  hostname: os.hostname(),
  pid: process.pid,
  nodeVersion: process.version,
  startedAt
};

app.use(express.json());
app.use(express.static(path.resolve(__dirname, '..', 'public')));

// --- API Routes ---
app.get('/api/health', async (req, res) => {
  try {
    await query('SELECT 1 AS ok FROM dual');
    res.json({ ok: true, database: 'connected' });
  } catch (error) {
    res.status(500).json({ ok: false, message: error.message });
  }
});

app.get('/api/runtime', (req, res) => {
  res.json({
    appName: 'DigiBook Oracle Web UI',
    ...runtimeState,
    baseUrl: runtimeState.actualPort ? `http://localhost:${runtimeState.actualPort}` : null
  });
});

// Mount modules
app.use('/api', adminRoutes);
app.use('/api/store', storeRoutes);

// --- Static Pages ---
app.get('/admin', (req, res) => {
  res.sendFile(path.resolve(__dirname, '..', 'public', 'admin.html'));
});

app.get('/store', (req, res) => {
  res.sendFile(path.resolve(__dirname, '..', 'public', 'store.html'));
});

app.get('/store/*', (req, res) => {
  res.sendFile(path.resolve(__dirname, '..', 'public', 'store.html'));
});

// Fallback to admin for unknown routes
app.get('*', (req, res) => {
  res.sendFile(path.resolve(__dirname, '..', 'public', 'admin.html'));
});

// --- Server Lifecycle ---
function listenOnAvailablePort(preferredPort, attempt = 0) {
  const candidatePort = preferredPort + attempt;
  return new Promise((resolve, reject) => {
    const server = app.listen(candidatePort);
    server.once('listening', () => resolve({ server, actualPort: candidatePort }));
    server.once('error', (err) => {
      if (err.code === 'EADDRINUSE' && attempt < maxPortAttempts) {
        console.warn(`Port ${candidatePort} in use, trying ${candidatePort + 1}...`);
        return listenOnAvailablePort(preferredPort, attempt + 1).then(resolve).catch(reject);
      }
      reject(err);
    });
  });
}

async function start() {
  try {
    await initPool();
    const { server, actualPort } = await listenOnAvailablePort(port);
    runtimeState.actualPort = actualPort;
    console.log(`DigiBook UI running at http://localhost:${actualPort}`);

    server.on('error', async (err) => {
      await closePool();
      console.error('Server error:', err.message);
      process.exit(1);
    });
  } catch (err) {
    await closePool();
    console.error('Bootstrap error:', err.message);
    process.exit(1);
  }
}

process.on('SIGINT', async () => { await closePool(); process.exit(0); });
process.on('SIGTERM', async () => { await closePool(); process.exit(0); });

start();