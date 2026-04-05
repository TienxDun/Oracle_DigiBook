import { NextRequest, NextResponse } from "next/server";
import oracledb from "oracledb";
import { requireSession } from "@/lib/auth";
import { VIEW_ALLOWLIST } from "@/lib/contracts";
import { getConnection, normalizeOracleError } from "@/lib/oracle";

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

    const result = await connection.execute<{ OBJECT_NAME: string; OBJECT_TYPE: string }>(
      `
      SELECT object_name, object_type
      FROM all_objects
      WHERE object_name IN (${VIEW_ALLOWLIST.map((name) => `'${name}'`).join(",")})
        AND object_type IN ('VIEW', 'MATERIALIZED VIEW')
      ORDER BY object_name
      `,
      [],
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );

    return NextResponse.json({
      success: true,
      views: result.rows ?? [],
      allowlist: VIEW_ALLOWLIST,
    });
  } catch (error) {
    const detail = normalizeOracleError(error);
    return NextResponse.json(
      { success: false, message: detail.message, code: detail.code },
      { status: 500 }
    );
  } finally {
    if (connection) await connection.close();
  }
}
