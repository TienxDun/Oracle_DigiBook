import { NextRequest, NextResponse } from "next/server";
import oracledb from "oracledb";
import { requireSession } from "@/lib/auth";
import { getConnection, normalizeOracleError } from "@/lib/oracle";

const ROLES = ["ADMIN_ROLE", "STAFF_ROLE", "GUEST_ROLE"];

export const dynamic = "force-dynamic";

export async function GET(request: NextRequest) {
  const auth = requireSession(request);
  if (!auth.ok) return auth.response;

  let connection;
  try {
    connection = await getConnection({
      oracleUser: auth.session.oracleUser,
      oraclePassword: auth.session.oraclePassword,
    });

    const tablePrivs = await connection.execute<{
      GRANTEE: string;
      TABLE_NAME: string;
      PRIVILEGE: string;
    }>(
      `
      SELECT grantee, table_name, privilege
      FROM all_tab_privs
      WHERE grantee IN ('ADMIN_ROLE', 'STAFF_ROLE', 'GUEST_ROLE')
      ORDER BY grantee, table_name, privilege
      `,
      [],
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );

    const rolePrivs = tablePrivs.rows ?? [];
    const grouped: Record<string, Record<string, string[]>> = {};

    for (const role of ROLES) {
      grouped[role] = {};
    }

    for (const row of rolePrivs) {
      const role = row.GRANTEE;
      if (!grouped[role]) grouped[role] = {};
      if (!grouped[role][row.TABLE_NAME]) grouped[role][row.TABLE_NAME] = [];
      grouped[role][row.TABLE_NAME].push(row.PRIVILEGE);
    }

    return NextResponse.json({
      success: true,
      matrix: grouped,
      totalPrivileges: rolePrivs.length,
    });
  } catch (error) {
    const detail = normalizeOracleError(error);
    return NextResponse.json(
      {
        success: false,
        message: detail.message,
        code: detail.code,
        hint: "Neu user Oracle hien tai khong du quyen xem all_tab_privs, hay login bang DIGIBOOK_ADMIN.",
      },
      { status: 500 }
    );
  } finally {
    if (connection) await connection.close();
  }
}
