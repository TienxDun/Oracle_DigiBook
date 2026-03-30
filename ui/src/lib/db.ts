import oracledb from "oracledb";

// oracledb v6+ mặc định dùng Thin mode (không cần Oracle Instant Client)
// Không set oracledb.thin trực tiếp vì là getter-only property

let pool: oracledb.Pool | null = null;

export async function getPool(): Promise<oracledb.Pool> {
  if (pool) return pool;

  pool = await oracledb.createPool({
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    connectString: process.env.DB_CONNECTION_STRING,
    poolMin: 2,
    poolMax: 10,
    poolIncrement: 1,
  });

  console.log("[DB] Oracle Connection Pool initialized (Thin mode).");
  return pool;
}

export async function query<T = Record<string, unknown>>(
  sql: string,
  binds: oracledb.BindParameters = [],
  options: oracledb.ExecuteOptions = {}
): Promise<T[]> {
  const currentPool = await getPool();
  const connection = await currentPool.getConnection();

  try {
    const result = await connection.execute<T>(sql, binds, {
      outFormat: oracledb.OUT_FORMAT_OBJECT,
      ...options,
    });
    return (result.rows as T[]) ?? [];
  } finally {
    await connection.close();
  }
}

export async function withTransaction<T>(
  callback: (connection: oracledb.Connection) => Promise<T>
): Promise<T> {
  const currentPool = await getPool();
  const connection = await currentPool.getConnection();
  try {
    const result = await callback(connection);
    await connection.commit();
    return result;
  } catch (err) {
    await connection.rollback();
    throw err;
  } finally {
    await connection.close();
  }
}
