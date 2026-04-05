import oracledb from "oracledb";

type OracleCredentials = {
  oracleUser: string;
  oraclePassword: string;
};

function readConnectString(): string {
  const value = process.env.ORACLE_CONNECTION_STRING;
  if (!value || !value.trim()) {
    throw new Error("Missing ORACLE_CONNECTION_STRING in environment.");
  }
  return value.trim();
}

export async function getConnection(credentials: OracleCredentials): Promise<oracledb.Connection> {
  const conn = await oracledb.getConnection({
    user: credentials.oracleUser,
    password: credentials.oraclePassword,
    connectString: readConnectString(),
  });

  // Chuyển schema sang DIGIBOOK (Owner của các đối tượng)
  // Việc này giúp DIGIBOOK_ADMIN có thể truy cập các View và Procedure mà không cần prefix
  try {
    await conn.execute(`ALTER SESSION SET CURRENT_SCHEMA = DIGIBOOK`);
  } catch (err) {
    console.warn("WARN: Khong the chuyen sang schema DIGIBOOK:", err);
  }

  return conn;
}

export async function testOracleLogin(credentials: OracleCredentials): Promise<{ currentUser: string; currentSchema: string }> {
  const conn = await getConnection(credentials);
  try {
    const rows = await conn.execute<{ CURRENT_USER: string; CURRENT_SCHEMA: string }>(
      `SELECT USER AS current_user, SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA') AS current_schema FROM dual`,
      [],
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );

    const first = rows.rows?.[0];
    return {
      currentUser: first?.CURRENT_USER ?? credentials.oracleUser.toUpperCase(),
      currentSchema: first?.CURRENT_SCHEMA ?? "UNKNOWN",
    };
  } finally {
    await conn.close();
  }
}

export function normalizeOracleError(error: unknown): { message: string; code?: number } {
  if (typeof error === "object" && error !== null) {
    const maybe = error as { message?: string; errorNum?: number };
    return {
      message: maybe.message ?? "Unknown Oracle error",
      code: maybe.errorNum,
    };
  }

  return { message: "Unknown Oracle error" };
}
