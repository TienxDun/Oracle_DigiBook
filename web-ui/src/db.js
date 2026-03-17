const oracledb = require('oracledb');
const path = require('path');
require('dotenv').config({ path: path.resolve(__dirname, '..', '.env') });

oracledb.outFormat = oracledb.OUT_FORMAT_OBJECT;
oracledb.autoCommit = false;

let pool;

async function initPool() {
  if (pool) {
    return pool;
  }

  pool = await oracledb.createPool({
    user: process.env.ORACLE_USER,
    password: process.env.ORACLE_PASSWORD,
    connectString: process.env.ORACLE_CONNECTION_STRING,
    poolMin: Number(process.env.ORACLE_POOL_MIN || 1),
    poolMax: Number(process.env.ORACLE_POOL_MAX || 5),
    poolIncrement: Number(process.env.ORACLE_POOL_INCREMENT || 1)
  });

  return pool;
}

async function closePool() {
  if (!pool) {
    return;
  }

  await pool.close(0);
  pool = null;
}

async function query(sql, binds = {}, options = {}) {
  const activePool = await initPool();
  const connection = await activePool.getConnection();

  try {
    const result = await connection.execute(sql, binds, options);
    return result.rows || [];
  } finally {
    await connection.close();
  }
}

async function execute(sql, binds = {}, options = {}) {
  const activePool = await initPool();
  const connection = await activePool.getConnection();

  try {
    return await connection.execute(sql, binds, options);
  } finally {
    await connection.close();
  }
}

module.exports = {
  closePool,
  execute,
  initPool,
  query
};